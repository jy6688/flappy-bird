`timescale 1ns / 1ps

module vga_bitchange(
    input clk,
    input reset,
    input bright,
    input button,                // flap button
    input [9:0] hCount, vCount,
    output reg [11:0] rgb,
    output reg [15:0] score
);

    localparam BLACK        = 12'h000;
    localparam BACKGROUND   = 12'h5CC;
    localparam PIPE_COLOR   = 12'h0F0;
    localparam TEXT_COLOR   = 12'hFFF;
    localparam GROUND_COLOR = 12'hDD9; // Flappy Bird ground tan

    localparam integer PIXEL_SCALE  = 2; // scale up 5x7 font
    localparam integer CHAR_W = 6 * PIXEL_SCALE;   // 5 px glyph + 1 px spacing
    localparam integer CHAR_H = 8 * PIXEL_SCALE;   // 7 px glyph + 1 px spacing
    localparam integer ACTIVE_X_START = 144;       // visible area offset from display_controller
    localparam integer ACTIVE_Y_START = 35;
    localparam integer ACTIVE_WIDTH   = 640;
    localparam integer ACTIVE_HEIGHT  = 481;       // matches bright region (v=35..515)

    // Limited glyph codes
    localparam [4:0] CHAR_G     = 5'd10;
    localparam [4:0] CHAR_A     = 5'd11;
    localparam [4:0] CHAR_M     = 5'd12;
    localparam [4:0] CHAR_E     = 5'd13;
    localparam [4:0] CHAR_O     = 5'd14;
    localparam [4:0] CHAR_V     = 5'd15;
    localparam [4:0] CHAR_R     = 5'd16;
    localparam [4:0] CHAR_SPACE = 5'd31;

    localparam SPRITE_W = 24;
    localparam SPRITE_H = 24;
    localparam BIRD_X   = 200;
    localparam integer GROUND_H = 24;
    localparam integer GROUND_Y = ACTIVE_Y_START + ACTIVE_HEIGHT - GROUND_H;
    localparam integer SCORE_Y = ACTIVE_Y_START + (8 * PIXEL_SCALE);
    localparam integer GO_Y    = ACTIVE_Y_START + (ACTIVE_HEIGHT / 2) - CHAR_H;
    localparam integer GO_SCORE_Y = GO_Y + CHAR_H + (4 * PIXEL_SCALE);
    localparam integer GO_LEN  = 9;   // "GAME OVER"

    wire [9:0] bird_y;
    wire bird_alive;
    wire pipe_collision;
    wire pipe_passed;

    reg was_alive;
    reg game_over;

    // Score digits and layout
    wire [3:0] score_d0 = score % 10;
    wire [3:0] score_d1 = (score / 10) % 10;
    wire [3:0] score_d2 = (score / 100) % 10;
    wire [3:0] score_d3 = (score / 1000) % 10;
    wire [1:0] score_chars = (score >= 1000) ? 2'd4 :
                             (score >= 100)  ? 2'd3 :
                             (score >= 10)   ? 2'd2 : 2'd1;
    wire [9:0] score_width    = score_chars * CHAR_W;
    wire [9:0] score_x_start  = ACTIVE_X_START + ((ACTIVE_WIDTH - score_width) / 2);
    wire [9:0] go_title_start = ACTIVE_X_START + ((ACTIVE_WIDTH - (GO_LEN*CHAR_W)) / 2);

    wire score_text_on;
    wire game_over_text_on;
    wire game_over_score_on;

    function [4:0] score_code;
        input [1:0] idx;
        input [1:0] len;
    begin
        case (len)
            2'd4: case (idx)
                2'd0: score_code = score_d3;
                2'd1: score_code = score_d2;
                2'd2: score_code = score_d1;
                default: score_code = score_d0;
            endcase
            2'd3: case (idx)
                2'd0: score_code = score_d2;
                2'd1: score_code = score_d1;
                default: score_code = score_d0;
            endcase
            2'd2: score_code = (idx == 0) ? score_d1 : score_d0;
            default: score_code = score_d0;
        endcase
    end
    endfunction

    function [4:0] go_code;
        input [3:0] idx;
    begin
        case (idx)
            4'd0: go_code = CHAR_G;
            4'd1: go_code = CHAR_A;
            4'd2: go_code = CHAR_M;
            4'd3: go_code = CHAR_E;
            4'd4: go_code = CHAR_SPACE;
            4'd5: go_code = CHAR_O;
            4'd6: go_code = CHAR_V;
            4'd7: go_code = CHAR_E;
            4'd8: go_code = CHAR_R;
            default: go_code = CHAR_SPACE;
        endcase
    end
    endfunction

    // -----------------------
    // Text rendering helpers
    // -----------------------
    wire score_line_active =
        (vCount >= SCORE_Y) && (vCount < SCORE_Y + CHAR_H) &&
        (hCount >= score_x_start) && (hCount < score_x_start + score_width);
    wire [9:0] score_cx        = hCount - score_x_start;
    wire [1:0] score_char_idx  = score_cx / CHAR_W;
    wire [2:0] score_char_col  = (score_cx % CHAR_W) / PIXEL_SCALE;
    wire [2:0] score_char_row  = (vCount - SCORE_Y) / PIXEL_SCALE;
    wire [4:0] score_glyph     = glyph_bits(score_code(score_char_idx, score_chars), score_char_row);
    assign score_text_on = score_line_active && (score_char_col < 5) &&
                           score_glyph[4 - score_char_col];

    wire go_line_active = game_over &&
        (vCount >= GO_Y) && (vCount < GO_Y + CHAR_H) &&
        (hCount >= go_title_start) && (hCount < go_title_start + (GO_LEN*CHAR_W));
    wire [9:0] go_cx        = hCount - go_title_start;
    wire [3:0] go_char_idx  = go_cx / CHAR_W;
    wire [2:0] go_char_col  = (go_cx % CHAR_W) / PIXEL_SCALE;
    wire [2:0] go_char_row  = (vCount - GO_Y) / PIXEL_SCALE;
    wire [4:0] go_glyph     = glyph_bits(go_code(go_char_idx), go_char_row);
    assign game_over_text_on = go_line_active && (go_char_col < 5) &&
                               go_glyph[4 - go_char_col];

    wire go_score_line_active = game_over &&
        (vCount >= GO_SCORE_Y) && (vCount < GO_SCORE_Y + CHAR_H) &&
        (hCount >= score_x_start) && (hCount < score_x_start + score_width);
    wire [9:0] go_score_cx        = hCount - score_x_start;
    wire [1:0] go_score_char_idx  = go_score_cx / CHAR_W;
    wire [2:0] go_score_char_col  = (go_score_cx % CHAR_W) / PIXEL_SCALE;
    wire [2:0] go_score_char_row  = (vCount - GO_SCORE_Y) / PIXEL_SCALE;
    wire [4:0] go_score_glyph     = glyph_bits(score_code(go_score_char_idx, score_chars), go_score_char_row);
    assign game_over_score_on = go_score_line_active && (go_score_char_col < 5) &&
                                go_score_glyph[4 - go_score_char_col];

    // 5x7 font for digits and GAME OVER letters (row 0 is top)
    function [4:0] glyph_bits;
        input [4:0] code;
        input [2:0] row;
    begin
        case (code)
            5'd0: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10011;
                3: glyph_bits = 5'b10101;
                4: glyph_bits = 5'b11001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            5'd1: case (row)
                0: glyph_bits = 5'b00100;
                1: glyph_bits = 5'b01100;
                2: glyph_bits = 5'b00100;
                3: glyph_bits = 5'b00100;
                4: glyph_bits = 5'b00100;
                5: glyph_bits = 5'b00100;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            5'd2: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b00001;
                3: glyph_bits = 5'b00010;
                4: glyph_bits = 5'b00100;
                5: glyph_bits = 5'b01000;
                6: glyph_bits = 5'b11111;
                default: glyph_bits = 5'b00000;
            endcase
            5'd3: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b00001;
                3: glyph_bits = 5'b00110;
                4: glyph_bits = 5'b00001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            5'd4: case (row)
                0: glyph_bits = 5'b00010;
                1: glyph_bits = 5'b00110;
                2: glyph_bits = 5'b01010;
                3: glyph_bits = 5'b10010;
                4: glyph_bits = 5'b11111;
                5: glyph_bits = 5'b00010;
                6: glyph_bits = 5'b00010;
                default: glyph_bits = 5'b00000;
            endcase
            5'd5: case (row)
                0: glyph_bits = 5'b11111;
                1: glyph_bits = 5'b10000;
                2: glyph_bits = 5'b11110;
                3: glyph_bits = 5'b00001;
                4: glyph_bits = 5'b00001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            5'd6: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10000;
                2: glyph_bits = 5'b11110;
                3: glyph_bits = 5'b10001;
                4: glyph_bits = 5'b10001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            5'd7: case (row)
                0: glyph_bits = 5'b11111;
                1: glyph_bits = 5'b00001;
                2: glyph_bits = 5'b00010;
                3: glyph_bits = 5'b00100;
                4: glyph_bits = 5'b01000;
                5: glyph_bits = 5'b01000;
                6: glyph_bits = 5'b01000;
                default: glyph_bits = 5'b00000;
            endcase
            5'd8: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10001;
                3: glyph_bits = 5'b01110;
                4: glyph_bits = 5'b10001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            5'd9: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10001;
                3: glyph_bits = 5'b01111;
                4: glyph_bits = 5'b00001;
                5: glyph_bits = 5'b00001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_G: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10000;
                3: glyph_bits = 5'b10111;
                4: glyph_bits = 5'b10001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_A: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10001;
                3: glyph_bits = 5'b11111;
                4: glyph_bits = 5'b10001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b10001;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_M: case (row)
                0: glyph_bits = 5'b10001;
                1: glyph_bits = 5'b11011;
                2: glyph_bits = 5'b10101;
                3: glyph_bits = 5'b10101;
                4: glyph_bits = 5'b10001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b10001;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_E: case (row)
                0: glyph_bits = 5'b11111;
                1: glyph_bits = 5'b10000;
                2: glyph_bits = 5'b10000;
                3: glyph_bits = 5'b11110;
                4: glyph_bits = 5'b10000;
                5: glyph_bits = 5'b10000;
                6: glyph_bits = 5'b11111;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_O: case (row)
                0: glyph_bits = 5'b01110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10001;
                3: glyph_bits = 5'b10001;
                4: glyph_bits = 5'b10001;
                5: glyph_bits = 5'b10001;
                6: glyph_bits = 5'b01110;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_V: case (row)
                0: glyph_bits = 5'b10001;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10001;
                3: glyph_bits = 5'b10001;
                4: glyph_bits = 5'b01010;
                5: glyph_bits = 5'b01010;
                6: glyph_bits = 5'b00100;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_R: case (row)
                0: glyph_bits = 5'b11110;
                1: glyph_bits = 5'b10001;
                2: glyph_bits = 5'b10001;
                3: glyph_bits = 5'b11110;
                4: glyph_bits = 5'b10100;
                5: glyph_bits = 5'b10010;
                6: glyph_bits = 5'b10001;
                default: glyph_bits = 5'b00000;
            endcase
            CHAR_SPACE: glyph_bits = 5'b00000;
            default: glyph_bits = 5'b00000;
        endcase
    end
    endfunction

    bird_physics #(
        .Y_MIN(ACTIVE_Y_START),
        .ACTIVE_HEIGHT(ACTIVE_HEIGHT),
        .SPRITE_H(SPRITE_H),
        .GROUND_H(GROUND_H)
    ) bp(
        .clk(clk),
        .reset(reset),   // RESET GOES IN
        .flap_btn(button), // FLAP BUTTON
        .collision(pipe_collision),
        .bird_y(bird_y),
        .alive(bird_alive)
    );

    wire show_sprite =
        (hCount >= BIRD_X) &&
        (hCount < BIRD_X + SPRITE_W) &&
        (vCount >= bird_y) &&
        (vCount < bird_y + SPRITE_H);

    wire [4:0] sprite_row = vCount - bird_y;
    wire [4:0] sprite_col = hCount - BIRD_X;

    wire [11:0] sprite_px;

    bird_rom rom(
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .pixel(sprite_px)
    );

    wire pipe_pixel;
    wire ground_on = bright && (vCount >= GROUND_Y) && (vCount < GROUND_Y + GROUND_H);
    // Connect pipe renderer to clock, reset and enable it only while bird is alive (game running)
    pipe_renderer pipes(
        .clk(clk),
        .reset(reset),
        .enable(bird_alive),
        .hCount(hCount),
        .vCount(vCount),
        .bird_x(BIRD_X),
        .bird_y(bird_y),
        .bird_w(SPRITE_W),
        .bird_h(SPRITE_H),
        .pipe_pixel(pipe_pixel),
        .pipe_collision(pipe_collision),
        .pipe_passed(pipe_passed)
    );

    initial score = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            score      <= 0;
            was_alive  <= 0;
            game_over  <= 0;
        end else begin
            was_alive <= bird_alive;
            if (pipe_passed && bird_alive)
                score <= score + 1;

            // latch game over when alive drops
            if (was_alive && !bird_alive)
                game_over <= 1'b1;
            else if (bird_alive)
                game_over <= 1'b0;
        end
    end

    always @(*) begin
        if (!bright)
            rgb = BLACK;
        else if (game_over_text_on || game_over_score_on)
            rgb = TEXT_COLOR;
        else if (score_text_on)
            rgb = TEXT_COLOR;
        else if (show_sprite)
            rgb = sprite_px;
        else if (ground_on)        // draw ground in front of pipes
            rgb = GROUND_COLOR;
        else if (pipe_pixel)
            rgb = PIPE_COLOR;
        else
            rgb = BACKGROUND;
    end
endmodule

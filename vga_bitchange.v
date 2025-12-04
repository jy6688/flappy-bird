`timescale 1ns / 1ps

module vga_bitchange(
    input clk,
    input reset,
    input bright,
    input button,
    input [9:0] hCount, vCount,
    output reg [11:0] rgb,
    output reg [15:0] score
);

    // ---------------- COLORS ---------------- //
    localparam BLACK       = 12'h000;
    localparam BACKGROUND  = 12'h5CC;
    localparam PIPE_COLOR  = 12'h0F0;

    // ---------------- BIRD SETTINGS ---------------- //
    localparam SPRITE_W = 24;
    localparam SPRITE_H = 24;
    localparam BIRD_X   = 200;

    // ---------------- BIRD PHYSICS ---------------- //
    wire [9:0] bird_y;
    wire bird_alive;
    wire pipe_collision;

    bird_physics bp(
        .clk(clk),
        .reset(reset),
        .flap_btn(button),
        .collision(pipe_collision),
        .bird_y(bird_y),
        .alive(bird_alive)
    );

    // ---------------- BIRD SPRITE ---------------- //
    wire show_sprite =
        (hCount >= BIRD_X) &&
        (hCount <  BIRD_X + SPRITE_W) &&
        (vCount >= bird_y) &&
        (vCount <  bird_y + SPRITE_H);

    wire [4:0] sprite_row = vCount - bird_y;
    wire [4:0] sprite_col = hCount - BIRD_X;
    wire [11:0] sprite_px;

    bird_rom rom(
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .pixel(sprite_px)
    );

    // ---------------- PIPE RENDERER ---------------- //
    wire pipe_pixel;
    wire pipe_pass;

    pipe_renderer pipes(
        .clk(clk),
        .reset(reset),
        .enable(bird_alive),
        .hCount(hCount),
        .vCount(vCount),
        .bird_x(BIRD_X + (SPRITE_W/2)),     // <<< FIXED (use bird center for scoring)
        .bird_y(bird_y),
        .bird_w(SPRITE_W),
        .bird_h(SPRITE_H),
        .pipe_pixel(pipe_pixel),
        .pipe_collision(pipe_collision),
        .pipe_pass(pipe_pass)
    );

    // ---------------- SCORE COUNTER ---------------- //
    reg prev_pass = 0;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            score <= 0;
            prev_pass <= 0;
        end
        else begin
            if(pipe_pass && !prev_pass && bird_alive)
                score <= score + 1;
            prev_pass <= pipe_pass;
        end
    end

    // ---------------- PIXEL OUTPUT ---------------- //
    always @(*) begin
        if(!bright)
            rgb = BLACK;
        else if(show_sprite)
            rgb = sprite_px;
        else if(pipe_pixel)
            rgb = PIPE_COLOR;
        else
            rgb = BACKGROUND;
    end

endmodule

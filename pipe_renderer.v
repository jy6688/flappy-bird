`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pipe Renderer – Flappy Bird Pipes With Working Score
//////////////////////////////////////////////////////////////////////////////////

module pipe_renderer(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [9:0]  hCount,
    input  wire [9:0]  vCount,
    input  wire [9:0]  bird_x,
    input  wire [9:0]  bird_y,
    input  wire [4:0]  bird_w,
    input  wire [4:0]  bird_h,
    output reg         pipe_pixel,
    output wire        pipe_collision,
    output reg         pipe_passed     // pulse high for one clk when any pipe crosses bird_x
);

    // ===============================
    // Pipe Dimensions / Animation
    // ===============================
    localparam integer PIPE_WIDTH    = 40;
    localparam integer PIPE_SPEED    = 1;
    localparam integer SPEED_DIVIDER = 1_000_000;  // pixels shift every N clocks
    localparam integer SCREEN_WIDTH  = 800;
    localparam integer PIPE_SPACING  = 220;
    localparam integer SPAWN_OFFSET  = 80;
    localparam integer RESPAWN_X     = SCREEN_WIDTH + SPAWN_OFFSET;

    // ===============================
    // Gap limits (vertical window)
    // ===============================
    localparam integer GAP_MIN_TOP   = 60;
    localparam integer GAP_MAX_TOP   = 320;
    localparam integer GAP_MIN_SIZE  = 150;
    localparam integer GAP_MAX_SIZE  = 150; // fixed size; can loosen later

    // ===============================
    // Pipe positions / gaps
    // ===============================
    reg [10:0] pipe1_x, pipe2_x, pipe3_x, pipe4_x;
    reg [9:0]  gap1_top, gap2_top, gap3_top, gap4_top;
    reg [8:0]  gap1_size, gap2_size, gap3_size, gap4_size;

    // Gap bottoms for simpler comparisons
    wire [10:0] gap1_bottom = gap1_top + gap1_size;
    wire [10:0] gap2_bottom = gap2_top + gap2_size;
    wire [10:0] gap3_bottom = gap3_top + gap3_size;
    wire [10:0] gap4_bottom = gap4_top + gap4_size;

    // Bird geometry for collision checks
    wire [10:0] bird_left   = {1'b0, bird_x};
    wire [10:0] bird_right  = bird_left + bird_w;
    wire [10:0] bird_top    = {1'b0, bird_y};
    wire [10:0] bird_bottom = bird_top + bird_h;

    // ===============================
    // Animation Counter / LFSR
    // ===============================
    reg [21:0] anim_counter;
    reg [9:0]  lfsr;
    wire       lfsr_feedback = lfsr[9] ^ lfsr[6]; // x^10 + x^7 + 1

    // Score pulse (pipe passed bird)
    reg pass_next;

    // ===============================
    // Helpers
    // ===============================
    function [9:0] clamp_gap_top(input [9:0] raw);
    begin
        if (raw < GAP_MIN_TOP)      clamp_gap_top = GAP_MIN_TOP;
        else if (raw > GAP_MAX_TOP) clamp_gap_top = GAP_MAX_TOP;
        else                        clamp_gap_top = raw;
    end
    endfunction

    function [8:0] clamp_gap_size(input [8:0] raw);
    begin
        if (raw < GAP_MIN_SIZE)      clamp_gap_size = GAP_MIN_SIZE;
        else if (raw > GAP_MAX_SIZE) clamp_gap_size = GAP_MAX_SIZE;
        else                         clamp_gap_size = raw;
    end
    endfunction

    // Helper: detect collision of the bird with a specific pipe column
    function collision_for_pipe;
        input [10:0] pipe_x;
        input [10:0] gap_top;
        input [10:0] gap_bottom;
    begin
        collision_for_pipe = 1'b0;
        if ((bird_right > pipe_x) && (bird_left < pipe_x + PIPE_WIDTH)) begin
            if ((bird_top < gap_top) || (bird_bottom > gap_bottom))
                collision_for_pipe = 1'b1;
        end
    end
    endfunction

    // ===============================
    // Initialization
    // ===============================
    initial begin
        pipe1_x      = RESPAWN_X;
        pipe2_x      = RESPAWN_X + PIPE_SPACING;
        pipe3_x      = RESPAWN_X + (2*PIPE_SPACING);
        pipe4_x      = RESPAWN_X + (3*PIPE_SPACING);
        gap1_top     = 180;
        gap2_top     = 240;
        gap3_top     = 300;
        gap4_top     = 120;
        gap1_size    = GAP_MIN_SIZE;
        gap2_size    = GAP_MIN_SIZE;
        gap3_size    = GAP_MIN_SIZE;
        gap4_size    = GAP_MIN_SIZE;
        anim_counter = 0;
        lfsr         = 10'h3FF;
        pipe_passed  = 1'b0;
    end

    // ===============================
    // ANIMATION LOGIC
    // ===============================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pipe1_x       <= RESPAWN_X;
            pipe2_x       <= RESPAWN_X + PIPE_SPACING;
            pipe3_x       <= RESPAWN_X + (2*PIPE_SPACING);
            pipe4_x       <= RESPAWN_X + (3*PIPE_SPACING);
            gap1_top      <= GAP_MIN_TOP;
            gap2_top      <= GAP_MIN_TOP + 60;
            gap3_top      <= GAP_MIN_TOP + 120;
            gap4_top      <= GAP_MIN_TOP + 180;
            gap1_size     <= GAP_MIN_SIZE;
            gap2_size     <= GAP_MIN_SIZE;
            gap3_size     <= GAP_MIN_SIZE;
            gap4_size     <= GAP_MIN_SIZE;
            anim_counter  <= 0;
            lfsr          <= 10'h3FF;
            pipe_passed   <= 1'b0;
        end else if (enable) begin
            pass_next = 1'b0;
            if (anim_counter == SPEED_DIVIDER-1) begin
                anim_counter <= 0;
                lfsr <= {lfsr[8:0], lfsr_feedback};

                // Pipe 1
                if (pipe1_x > PIPE_SPEED) begin
                    if ((pipe1_x + PIPE_WIDTH > bird_left) &&
                        ((pipe1_x - PIPE_SPEED) + PIPE_WIDTH <= bird_left))
                        pass_next = 1'b1;
                    pipe1_x <= pipe1_x - PIPE_SPEED;
                end else begin
                    pipe1_x  <= ((pipe2_x > pipe3_x ? pipe2_x : pipe3_x) > pipe4_x
                                 ? (pipe2_x > pipe3_x ? pipe2_x : pipe3_x)
                                 : pipe4_x) + PIPE_SPACING;
                    if (pipe1_x < RESPAWN_X) pipe1_x <= RESPAWN_X;
                    gap1_top  <= clamp_gap_top(lfsr[9:0]);
                    gap1_size <= clamp_gap_size({1'b0, lfsr[9:3]});
                end

                // Pipe 2
                if (pipe2_x > PIPE_SPEED) begin
                    if ((pipe2_x + PIPE_WIDTH > bird_left) &&
                        ((pipe2_x - PIPE_SPEED) + PIPE_WIDTH <= bird_left))
                        pass_next = 1'b1;
                    pipe2_x <= pipe2_x - PIPE_SPEED;
                end else begin
                    pipe2_x  <= ((pipe1_x > pipe3_x ? pipe1_x : pipe3_x) > pipe4_x
                                 ? (pipe1_x > pipe3_x ? pipe1_x : pipe3_x)
                                 : pipe4_x) + PIPE_SPACING;
                    if (pipe2_x < RESPAWN_X) pipe2_x <= RESPAWN_X;
                    gap2_top  <= clamp_gap_top(lfsr[9:0] ^ 10'h155);
                    gap2_size <= clamp_gap_size({1'b0, (lfsr[9:3] ^ 7'h2D)});
                end

                // Pipe 3
                if (pipe3_x > PIPE_SPEED) begin
                    if ((pipe3_x + PIPE_WIDTH > bird_left) &&
                        ((pipe3_x - PIPE_SPEED) + PIPE_WIDTH <= bird_left))
                        pass_next = 1'b1;
                    pipe3_x <= pipe3_x - PIPE_SPEED;
                end else begin
                    pipe3_x  <= ((pipe1_x > pipe2_x ? pipe1_x : pipe2_x) > pipe4_x
                                 ? (pipe1_x > pipe2_x ? pipe1_x : pipe2_x)
                                 : pipe4_x) + PIPE_SPACING;
                    if (pipe3_x < RESPAWN_X) pipe3_x <= RESPAWN_X;
                    gap3_top  <= clamp_gap_top(lfsr[9:0] ^ 10'h2AA);
                    gap3_size <= clamp_gap_size({1'b0, (lfsr[9:3] ^ 7'h12)});
                end

                // Pipe 4
                if (pipe4_x > PIPE_SPEED) begin
                    if ((pipe4_x + PIPE_WIDTH > bird_left) &&
                        ((pipe4_x - PIPE_SPEED) + PIPE_WIDTH <= bird_left))
                        pass_next = 1'b1;
                    pipe4_x <= pipe4_x - PIPE_SPEED;
                end else begin
                    pipe4_x  <= ((pipe1_x > pipe2_x ? pipe1_x : pipe2_x) > pipe3_x
                                 ? (pipe1_x > pipe2_x ? pipe1_x : pipe2_x)
                                 : pipe3_x) + PIPE_SPACING;
                    if (pipe4_x < RESPAWN_X) pipe4_x <= RESPAWN_X;
                    gap4_top  <= clamp_gap_top(lfsr[9:0] ^ 10'h0F0);
                    gap4_size <= clamp_gap_size({1'b0, (lfsr[9:3] ^ 7'h35)});
                end
            end else begin
                anim_counter <= anim_counter + 1;
            end
            pipe_passed <= pass_next;
        end else begin
            pipe_passed <= 1'b0;
        end
    end

    // -----------------------
    // Pipe pixel checks / collisions
    // -----------------------
    wire pipe1_pixel =
        (hCount >= pipe1_x && hCount < pipe1_x + PIPE_WIDTH) &&
        !((vCount >= gap1_top) && (vCount < gap1_top + gap1_size));
    wire pipe1_collision = collision_for_pipe(pipe1_x, gap1_top, gap1_bottom);

    wire pipe2_pixel =
        (hCount >= pipe2_x && hCount < pipe2_x + PIPE_WIDTH) &&
        !((vCount >= gap2_top) && (vCount < gap2_top + gap2_size));
    wire pipe2_collision = collision_for_pipe(pipe2_x, gap2_top, gap2_bottom);

    wire pipe3_pixel =
        (hCount >= pipe3_x && hCount < pipe3_x + PIPE_WIDTH) &&
        !((vCount >= gap3_top) && (vCount < gap3_top + gap3_size));
    wire pipe3_collision = collision_for_pipe(pipe3_x, gap3_top, gap3_bottom);

    wire pipe4_pixel =
        (hCount >= pipe4_x && hCount < pipe4_x + PIPE_WIDTH) &&
        !((vCount >= gap4_top) && (vCount < gap4_top + gap4_size));
    wire pipe4_collision = collision_for_pipe(pipe4_x, gap4_top, gap4_bottom);

    // -----------------------
    // Output combined result
    // -----------------------
    assign pipe_collision = pipe1_collision | pipe2_collision | pipe3_collision | pipe4_collision;

    always @(*) begin
        pipe_pixel = pipe1_pixel | pipe2_pixel | pipe3_pixel | pipe4_pixel;
    end

endmodule

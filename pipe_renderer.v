`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pipe Renderer Module
// Draws two vertical Flappy Bird style pipes with gaps.
// Can later be animated by changing PIPE_X positions.
//
//////////////////////////////////////////////////////////////////////////////////

module pipe_renderer(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [9:0]  hCount,
    input  wire [9:0]  vCount,
    output reg         pipe_pixel
);

    // ===============================
    // Pipe Dimensions
    // ===============================
    localparam integer PIPE_WIDTH = 40;

    // ===============================
    // Animation Parameters
    // ===============================
    localparam integer PIPE_SPEED     = 1;          // Pixels per move step
    localparam integer SPEED_DIVIDER  = 1_000_000;     // Clock cycles per move step (~0.5 ms at 100MHz)
    localparam integer SCREEN_WIDTH   = 800;        // Full scan width (hCount 0..799)
    localparam integer PIPE_SPACING   = 220;        // Distance between pipes (tighter spacing for 4 pipes)
    localparam integer SPAWN_OFFSET   = 80;         // How far off-screen to spawn pipes
    localparam integer RESPAWN_X      = SCREEN_WIDTH + SPAWN_OFFSET;

    // ===============================
    // Pipe Positions (DYNAMIC)
    // ===============================
    reg [10:0] pipe1_x;
    reg [10:0] pipe2_x;
    reg [10:0] pipe3_x;
    reg [10:0] pipe4_x;

    // Initial positions
    localparam integer PIPE1_INIT = RESPAWN_X;
    localparam integer PIPE2_INIT = RESPAWN_X + PIPE_SPACING;
    localparam integer PIPE3_INIT = RESPAWN_X + (2*PIPE_SPACING);
    localparam integer PIPE4_INIT = RESPAWN_X + (3*PIPE_SPACING);

    // ===============================
    // Pipe Gaps (VERTICAL OPENINGS)
    // You can randomize or change later
    // ===============================
    // Gap vertical bounds and size limits
    localparam integer VISIBLE_HEIGHT = 480;  // visible lines from display controller
    localparam integer GAP_MIN_TOP    = 60;
    localparam integer GAP_MAX_TOP    = 320;  // ensure GAP_MAX_TOP + GAP_MAX_SIZE <= VISIBLE_HEIGHT
    localparam integer GAP_MIN_SIZE   = 110;
    localparam integer GAP_MAX_SIZE   = 150;

    // Current gap positions and sizes (mutable)
    reg [9:0] gap1_top, gap2_top, gap3_top, gap4_top;
    reg [8:0] gap1_size, gap2_size, gap3_size, gap4_size;

    // ===============================
    // Animation Counter
    // ===============================
    reg [21:0] anim_counter;

    // ===============================
    // Pseudo-Random Generator (LFSR)
    // ===============================
    reg [9:0] lfsr;
    wire lfsr_feedback = lfsr[9] ^ lfsr[6]; // x^10 + x^7 + 1

    // ===============================
    // INITIALIZATION
    // ===============================
    initial begin
        pipe1_x = PIPE1_INIT;
        pipe2_x = PIPE2_INIT;
        pipe3_x = PIPE3_INIT;
        pipe4_x = PIPE4_INIT;
        anim_counter = 0;
        gap1_top = 180;
        gap2_top = 240;
        gap3_top = 300;
        gap4_top = 120;
        gap1_size = GAP_MIN_SIZE;
        gap2_size = GAP_MIN_SIZE;
        gap3_size = GAP_MIN_SIZE;
        gap4_size = GAP_MIN_SIZE;
        lfsr = 10'h3FF; // non-zero seed
    end

    // Helper: wrap random values into valid ranges instead of clamping to the edges
    function [9:0] rand_gap_top(input [9:0] raw);
        localparam integer TOP_RANGE = GAP_MAX_TOP - GAP_MIN_TOP + 1;
    begin
        rand_gap_top = GAP_MIN_TOP + (raw % TOP_RANGE);
    end
    endfunction

    function [8:0] rand_gap_size(input [9:0] raw);
        localparam integer SIZE_RANGE = GAP_MAX_SIZE - GAP_MIN_SIZE + 1;
    begin
        rand_gap_size = GAP_MIN_SIZE + (raw % SIZE_RANGE);
    end
    endfunction

    // ===============================
    // ANIMATION LOGIC
    // ===============================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pipe1_x       <= PIPE1_INIT;
            pipe2_x       <= PIPE2_INIT;
            pipe3_x       <= PIPE3_INIT;
            pipe4_x       <= PIPE4_INIT;
            anim_counter  <= 0;
            gap1_top      <= GAP_MIN_TOP;
            gap2_top      <= GAP_MIN_TOP + 60;
            gap3_top      <= GAP_MIN_TOP + 120;
            gap4_top      <= GAP_MIN_TOP + 180;
            gap1_size     <= GAP_MIN_SIZE;
            gap2_size     <= GAP_MIN_SIZE + 10;
            gap3_size     <= GAP_MIN_SIZE + 20;
            gap4_size     <= GAP_MIN_SIZE + 30;
            lfsr          <= 10'h3FF;
        end else if (enable) begin
            if (anim_counter == SPEED_DIVIDER-1) begin
                anim_counter <= 0;

                // advance LFSR once per move step
                lfsr <= {lfsr[8:0], lfsr_feedback};

                // helper: furthest right position among others
                // Move left; wrap to furthest-right + spacing keeping consistent separation
                if (pipe1_x > PIPE_SPEED)
                    pipe1_x <= pipe1_x - PIPE_SPEED;
                else begin
                    // furthest of pipe2/pipe3/pipe4 + spacing, at least RESPAWN_X
                    pipe1_x  <= ((pipe2_x > pipe3_x ? pipe2_x : pipe3_x) > pipe4_x
                                 ? (pipe2_x > pipe3_x ? pipe2_x : pipe3_x)
                                 : pipe4_x) + PIPE_SPACING;
                    if (pipe1_x < RESPAWN_X) pipe1_x <= RESPAWN_X;
                    gap1_top <= rand_gap_top(lfsr[9:0]);
                    gap1_size<= rand_gap_size({1'b0, lfsr[9:3]}); // use upper bits for size
                end

                if (pipe2_x > PIPE_SPEED)
                    pipe2_x <= pipe2_x - PIPE_SPEED;
                else begin
                    pipe2_x  <= ((pipe1_x > pipe3_x ? pipe1_x : pipe3_x) > pipe4_x
                                 ? (pipe1_x > pipe3_x ? pipe1_x : pipe3_x)
                                 : pipe4_x) + PIPE_SPACING;
                    if (pipe2_x < RESPAWN_X) pipe2_x <= RESPAWN_X;
                    gap2_top <= rand_gap_top(lfsr[9:0] ^ 10'h155); // mix bits so pipes differ
                    gap2_size<= rand_gap_size({1'b0, (lfsr[9:3] ^ 7'h2D)});
                end

                if (pipe3_x > PIPE_SPEED)
                    pipe3_x <= pipe3_x - PIPE_SPEED;
                else begin
                    pipe3_x  <= ((pipe1_x > pipe2_x ? pipe1_x : pipe2_x) > pipe4_x
                                 ? (pipe1_x > pipe2_x ? pipe1_x : pipe2_x)
                                 : pipe4_x) + PIPE_SPACING;
                    if (pipe3_x < RESPAWN_X) pipe3_x <= RESPAWN_X;
                    gap3_top <= rand_gap_top(lfsr[9:0] ^ 10'h2AA); // another mix for variety
                    gap3_size<= rand_gap_size({1'b0, (lfsr[9:3] ^ 7'h12)});
                end

                if (pipe4_x > PIPE_SPEED)
                    pipe4_x <= pipe4_x - PIPE_SPEED;
                else begin
                    pipe4_x  <= ((pipe1_x > pipe2_x ? pipe1_x : pipe2_x) > pipe3_x
                                 ? (pipe1_x > pipe2_x ? pipe1_x : pipe2_x)
                                 : pipe3_x) + PIPE_SPACING;
                    if (pipe4_x < RESPAWN_X) pipe4_x <= RESPAWN_X;
                    gap4_top <= rand_gap_top(lfsr[9:0] ^ 10'h0F0);
                    gap4_size<= rand_gap_size({1'b0, (lfsr[9:3] ^ 7'h35)});
                end
            end else begin
                anim_counter <= anim_counter + 1;
            end
        end
    end

    // -----------------------
    // Pipe #1 pixel check
    // -----------------------
    wire pipe1_pixel =
        (hCount >= pipe1_x && hCount < pipe1_x + PIPE_WIDTH) &&
        !((vCount >= gap1_top) && (vCount < gap1_top + gap1_size));

    // -----------------------
    // Pipe #2 pixel check
    // -----------------------
    wire pipe2_pixel =
        (hCount >= pipe2_x && hCount < pipe2_x + PIPE_WIDTH) &&
        !((vCount >= gap2_top) && (vCount < gap2_top + gap2_size));

    // -----------------------
    // Pipe #3 pixel check
    // -----------------------
    wire pipe3_pixel =
        (hCount >= pipe3_x && hCount < pipe3_x + PIPE_WIDTH) &&
        !((vCount >= gap3_top) && (vCount < gap3_top + gap3_size));

    // -----------------------
    // Pipe #4 pixel check
    // -----------------------
    wire pipe4_pixel =
        (hCount >= pipe4_x && hCount < pipe4_x + PIPE_WIDTH) &&
        !((vCount >= gap4_top) && (vCount < gap4_top + gap4_size));


    // -----------------------
    // Output combined result
    // -----------------------
    always @(*) begin
        pipe_pixel = pipe1_pixel | pipe2_pixel | pipe3_pixel | pipe4_pixel;
    end

endmodule

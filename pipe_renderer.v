`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pipe Renderer Module
// Draws two vertical Flappy Bird style pipes with gaps.
// Can later be animated by changing PIPE_X positions.
//
//////////////////////////////////////////////////////////////////////////////////

module pipe_renderer(
    input  wire [9:0] hCount,
    input  wire [9:0] vCount,
    output reg        pipe_pixel
);

    // ===============================
    // Pipe Dimensions
    // ===============================
    localparam PIPE_WIDTH = 40;
    localparam GAP_SIZE   = 120;

    // ===============================
    // Pipe Positions (STATIC FOR NOW)
    // ===============================
    localparam PIPE1_X = 300;
    localparam PIPE2_X = 550;

    // ===============================
    // Pipe Gaps (VERTICAL OPENINGS)
    // You can randomize or change later
    // ===============================
    localparam GAP1_TOP = 180;
    localparam GAP2_TOP = 240;


    // -----------------------
    // Pipe #1 pixel check
    // -----------------------
    wire pipe1_pixel = 
        (hCount >= PIPE1_X && hCount < PIPE1_X + PIPE_WIDTH) &&
        !((vCount >= GAP1_TOP) && (vCount < GAP1_TOP + GAP_SIZE));

    // -----------------------
    // Pipe #2 pixel check
    // -----------------------
    wire pipe2_pixel = 
        (hCount >= PIPE2_X && hCount < PIPE2_X + PIPE_WIDTH) &&
        !((vCount >= GAP2_TOP) && (vCount < GAP2_TOP + GAP_SIZE));


    // -----------------------
    // Output combined result
    // -----------------------
    always @(*) begin
        pipe_pixel = pipe1_pixel | pipe2_pixel;
    end

endmodule

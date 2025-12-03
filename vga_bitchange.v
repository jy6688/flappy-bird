`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA Display: Flappy Bird Prototype
// Uses: Bird Sprite + External Pipe Renderer Module
// Static layout (no motion yet)
//
//////////////////////////////////////////////////////////////////////////////////

module vga_bitchange(
	input clk,
	input bright,
	input start_button,
	input reset_button,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [15:0] score
);

	reg pipe_run_en;

	// ==========================
	// COLOR CONSTANTS
	// ==========================
	localparam BLACK       = 12'h000;
	localparam BACKGROUND  = 12'b0101_1100_1100;   // teal sky
	localparam PIPE_COLOR  = 12'h0F0;             // green pipe


	// ==========================
	// BIRD SPRITE (16x16 PX)
	// ==========================
	localparam BIRD_X = 100;
	localparam BIRD_Y = 220;
	localparam SPRITE_W = 16;
	localparam SPRITE_H = 16;

	wire show_sprite =
		(hCount >= BIRD_X) && (hCount < BIRD_X + SPRITE_W) &&
		(vCount >= BIRD_Y) && (vCount < BIRD_Y + SPRITE_H);

	wire [3:0] sprite_row = vCount - BIRD_Y;
	wire [3:0] sprite_col = hCount - BIRD_X;

	wire [11:0] sprite_px;

	// sprite ROM instance
	bird_rom bird(
		.clk(clk),
		.row(sprite_row),
		.col(sprite_col),
		.pixel(sprite_px)
	);


	// ==========================
	// PIPE RENDERER MODULE
	// ==========================
	wire pipe_pixel;

	pipe_renderer pipes(
		.clk(clk),
		.reset(reset_button),
		.enable(pipe_run_en),
		.hCount(hCount),
		.vCount(vCount),
		.pipe_pixel(pipe_pixel)
	);


	// ==========================
	// SCORE (unused now but needed by top file)
	// ==========================
	initial score = 0;
	initial pipe_run_en = 1'b0;

	// Pipes sit still after reset until the start button is pressed.
	always @(posedge clk or posedge reset_button) begin
		if (reset_button)
			pipe_run_en <= 1'b0;
		else if (start_button)
			pipe_run_en <= 1'b1;
	end


	// ==========================
	// PIXEL PRIORITY LOGIC
	// ORDER: sprite → pipe → background
	// ==========================
	always @(*) begin
		if (!bright)
			rgb = BLACK;

		// sprite drawn first unless transparent (0x0FF)
		else if (show_sprite && sprite_px != 12'h0FF)
			rgb = sprite_px;

		else if (pipe_pixel)
			rgb = PIPE_COLOR;

		else
			rgb = BACKGROUND;
	end

endmodule

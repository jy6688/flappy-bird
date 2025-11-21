`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:15:38 12/14/2017 
// Design Name: 
// Module Name:    vga_bitchange 
// Description: Updated background color to #4EBAC4
//////////////////////////////////////////////////////////////////////////////////
module vga_bitchange(
	input clk,
	input bright,
	input button,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [15:0] score
   );
	
	parameter BLACK = 12'b0000_0000_0000;
	parameter WHITE = 12'b1111_1111_1111;
	parameter RED   = 12'b1111_0000_0000;
	parameter GREEN = 12'b0000_1111_0000;

	// New background color (#4EBAC4 converted to 12-bit RGB ≈ 5C C)
	parameter BG = 12'b0101_1100_1100;  

	wire whiteZone;
	wire greenMiddleSquare;
	reg reset;
	reg[9:0] greenMiddleSquareY;
	reg[49:0] greenMiddleSquareSpeed; 

	initial begin
		greenMiddleSquareY = 10'd320;
		score = 15'd0;
		reset = 1'b0;
	end
	
	// VGA pixel coloring logic
	always @(*) 
		if (~bright)
			rgb = BLACK;
		else if (greenMiddleSquare)
			rgb = GREEN;
		else if (whiteZone)
			rgb = WHITE;
		else
			rgb = BG; // Updated background color

	
	// Square movement logic
	always @(posedge clk)
	begin
		greenMiddleSquareSpeed = greenMiddleSquareSpeed + 50'd1;
		if (greenMiddleSquareSpeed >= 50'd500000)
		begin
			greenMiddleSquareY = greenMiddleSquareY + 10'd1;
			greenMiddleSquareSpeed = 50'd0;
			
			if (greenMiddleSquareY == 10'd779)
				greenMiddleSquareY = 10'd0;
		end
	end

	// Collision detection / scoring
	always @(posedge clk)
		if ((reset == 1'b0) && (button == 1'b1) && 
			(hCount >= 10'd144) && (hCount <= 10'd784) &&
			(greenMiddleSquareY >= 10'd400) && (greenMiddleSquareY <= 10'd475))
		begin
			score = score + 16'd1;
			reset = 1'b1;
		end
		else if (greenMiddleSquareY <= 10'd20)
			reset = 1'b0;

	assign whiteZone = ((hCount >= 10'd144) && (hCount <= 10'd784)) &&
					   ((vCount >= 10'd400) && (vCount <= 10'd475));

	assign greenMiddleSquare = ((hCount >= 10'd340) && (hCount < 10'd380)) &&
							   ((vCount >= greenMiddleSquareY) && (vCount <= greenMiddleSquareY + 10'd40));
	
endmodule

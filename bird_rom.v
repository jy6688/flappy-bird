`timescale 1ns / 1ps

module bird_rom(
    input wire clk,
    input wire [4:0] row,   // 0–31
    input wire [4:0] col,   // 0–31
    output reg [11:0] pixel
);

    // 32x32 ROM
    reg [11:0] ROM [0:1023];

    integer i;

    initial begin
        // Fill entire 32×32 block with yellow (RGB = FF0)
        for (i = 0; i < 1024; i = i + 1)
            ROM[i] = 12'hFF0;   // bright yellow
    end

    // Pixel read
    wire [9:0] addr = (row * 32) + col;

    always @(posedge clk)
        pixel <= ROM[addr];

endmodule

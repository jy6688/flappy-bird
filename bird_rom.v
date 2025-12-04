`timescale 1ns / 1ps

module bird_rom(
    input wire clk,
    input wire [4:0] row,   // 0–31
    input wire [4:0] col,   // 0–31
    output reg [11:0] pixel
);

    // 24x24 ROM
    // 24*24 = 576 entries
    reg [11:0] ROM [0:575];

    integer i;

    initial begin
        // Fill entire 24×24 block with yellow (RGB = FF0)
        for (i = 0; i < 576; i = i + 1)
            ROM[i] = 12'hFF0;   // bright yellow
    end

    // Pixel read
    wire [9:0] addr = (row * 24) + col;

    always @(posedge clk)
        pixel <= ROM[addr];

endmodule

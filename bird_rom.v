`timescale 1ns / 1ps

module bird_rom(
    input wire clk,
    input wire [4:0] row,   // 0–23
    input wire [4:0] col,   // 0–23
    output reg [11:0] pixel
);

    reg [11:0] ROM [0:575];     // 24×24 bird sprite

    initial begin
        $readmemh("bird.mem", ROM);  // << load bird graphic
    end

    wire [9:0] addr = row*24 + col;

    always @(posedge clk)
        pixel <= ROM[addr];          // output pixel color

endmodule

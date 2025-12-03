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

    localparam BLACK      = 12'h000;
    localparam BACKGROUND = 12'h5CC;
    localparam PIPE_COLOR = 12'h0F0;

    localparam SPRITE_W = 24;
    localparam SPRITE_H = 24;
    localparam BIRD_X   = 200;

    wire [9:0] bird_y;
    wire bird_alive;

    bird_physics bp(
        .clk(clk),
        .reset(reset),   // RESET GOES IN
        .flap_btn(button), // FLAP BUTTON
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
    // Connect pipe renderer to clock, reset and enable it only while bird is alive (game running)
    pipe_renderer pipes(
        .clk(clk),
        .reset(reset),
        .enable(bird_alive),
        .hCount(hCount),
        .vCount(vCount),
        .pipe_pixel(pipe_pixel)
    );

    initial score = 0;

    always @(*) begin
        if (!bright)
            rgb = BLACK;
        else if (show_sprite)
            rgb = sprite_px;
        else if (pipe_pixel)
            rgb = PIPE_COLOR;
        else
            rgb = BACKGROUND;
    end
endmodule

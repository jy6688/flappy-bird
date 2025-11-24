`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Classic Flappy Bird 16x16 Sprite ROM
// Transparent background uses: 12'h0FF
//////////////////////////////////////////////////////////////////////////////////

module bird_rom(
    input wire clk,
    input wire [3:0] row,
    input wire [3:0] col,
    output reg [11:0] pixel
);

    (* rom_style = "block" *)

    reg [3:0] row_reg;
    reg [3:0] col_reg;

    always @(posedge clk) begin
        row_reg <= row;
        col_reg <= col;
    end

    always @* begin
        case ({row_reg, col_reg})

            // Row 0
            8'h00: pixel = 12'h0FF;  
            8'h01: pixel = 12'h0FF;
            8'h02: pixel = 12'h0FF;
            8'h03: pixel = 12'h0FF;
            8'h04: pixel = 12'hFF0;
            8'h05: pixel = 12'hFF0;
            8'h06: pixel = 12'hFF0;
            8'h07: pixel = 12'h0FF;
            8'h08: pixel = 12'h0FF;
            8'h09: pixel = 12'h0FF;
            8'h0A: pixel = 12'h0FF;
            8'h0B: pixel = 12'h0FF;
            8'h0C: pixel = 12'h0FF; 
            8'h0D: pixel = 12'h0FF;
            8'h0E: pixel = 12'h0FF;
            8'h0F: pixel = 12'h0FF;

            // Row 1
            8'h10: pixel = 12'h0FF;
            8'h11: pixel = 12'h0FF;
            8'h12: pixel = 12'hFF0;
            8'h13: pixel = 12'hFF0;
            8'h14: pixel = 12'hFFF;  // eye white
            8'h15: pixel = 12'h000;  // pupil
            8'h16: pixel = 12'hFF0;
            8'h17: pixel = 12'hFF0;
            8'h18: pixel = 12'hFF0;
            8'h19: pixel = 12'hFF0;
            8'h1A: pixel = 12'h0FF;
            8'h1B: pixel = 12'h0FF;
            8'h1C: pixel = 12'h0FF;
            8'h1D: pixel = 12'h0FF;
            8'h1E: pixel = 12'h0FF;
            8'h1F: pixel = 12'h0FF;

            // Row 2
            8'h20: pixel = 12'h0FF;
            8'h21: pixel = 12'hFF0;
            8'h22: pixel = 12'hFF0;
            8'h23: pixel = 12'hFF0;
            8'h24: pixel = 12'hFF0;
            8'h25: pixel = 12'hFA0; // beak
            8'h26: pixel = 12'hFA0;
            8'h27: pixel = 12'hFA0;
            8'h28: pixel = 12'hFF0;
            8'h29: pixel = 12'hFF0;
            8'h2A: pixel = 12'hFF0;
            8'h2B: pixel = 12'h0FF;
            8'h2C: pixel = 12'h0FF;
            8'h2D: pixel = 12'h0FF;
            8'h2E: pixel = 12'h0FF;
            8'h2F: pixel = 12'h0FF;

            // Row 3
            8'h30: pixel = 12'h0FF;
            8'h31: pixel = 12'hFF0;
            8'h32: pixel = 12'hFF0;
            8'h33: pixel = 12'hDD0; // wing shading
            8'h34: pixel = 12'hDD0;
            8'h35: pixel = 12'hFA0;
            8'h36: pixel = 12'hFA0;
            8'h37: pixel = 12'hDD0;
            8'h38: pixel = 12'hDD0;
            8'h39: pixel = 12'hFF0;
            8'h3A: pixel = 12'hFF0;
            8'h3B: pixel = 12'hFF0;
            8'h3C: pixel = 12'h0FF;
            8'h3D: pixel = 12'h0FF;
            8'h3E: pixel = 12'h0FF;
            8'h3F: pixel = 12'h0FF;

            // Row 4
            8'h40: pixel = 12'h0FF;
            8'h41: pixel = 12'hFF0;
            8'h42: pixel = 12'hFF0;
            8'h43: pixel = 12'hDD0;
            8'h44: pixel = 12'hDD0;
            8'h45: pixel = 12'hDD0;
            8'h46: pixel = 12'hDD0;
            8'h47: pixel = 12'hFF0;
            8'h48: pixel = 12'hFF0;
            8'h49: pixel = 12'hFF0;
            8'h4A: pixel = 12'hFF0;
            8'h4B: pixel = 12'hFF0;
            8'h4C: pixel = 12'h0FF;
            8'h4D: pixel = 12'h0FF;
            8'h4E: pixel = 12'h0FF;
            8'h4F: pixel = 12'h0FF;

            // Rows 5–15 (body taper & transparent edge)
            default: pixel = 12'hFF0; // fill rest of sprite so it's visible

        endcase
    end

endmodule

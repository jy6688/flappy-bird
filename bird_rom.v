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
            8'h05: pixel = 12'hF00;
            8'h06: pixel = 12'hF00;

            // Row 1
            8'h14: pixel = 12'h000;
            8'h15: pixel = 12'hFF0;
            8'h16: pixel = 12'hFF0;
            8'h17: pixel = 12'hF00;

            // Row 2
            8'h23: pixel = 12'h000;
            8'h24: pixel = 12'hFF0;
            8'h25: pixel = 12'hFF0;
            8'h26: pixel = 12'hFF0;
            8'h27: pixel = 12'hFF0;
            8'h28: pixel = 12'hFF0;
            8'h29: pixel = 12'h000;

            // Row 3
            8'h32: pixel = 12'h000;
            8'h33: pixel = 12'hFF0;
            8'h34: pixel = 12'hFF0;
            8'h35: pixel = 12'hFFF; // eye white
            8'h36: pixel = 12'h000; // pupil
            8'h37: pixel = 12'hFF0;
            8'h38: pixel = 12'hFF0;
            8'h39: pixel = 12'hFF0;
            8'h3A: pixel = 12'h000;

            // Row 4
            8'h42: pixel = 12'h000;
            8'h43: pixel = 12'hFF0;
            8'h44: pixel = 12'hFF0;
            8'h45: pixel = 12'hFF0;
            8'h46: pixel = 12'hFF0;
            8'h47: pixel = 12'hFF0;
            8'h48: pixel = 12'hFF0;
            8'h49: pixel = 12'hFF0;
            8'h4A: pixel = 12'h000;

            // Row 5
            8'h51: pixel = 12'h000;
            8'h52: pixel = 12'hFF0;
            8'h53: pixel = 12'hFF0;
            8'h54: pixel = 12'hFF0;
            8'h55: pixel = 12'hF80; // beak
            8'h56: pixel = 12'hF80;
            8'h57: pixel = 12'hFF0;
            8'h58: pixel = 12'hFF0;
            8'h59: pixel = 12'hFF0;
            8'h5A: pixel = 12'hFF0;
            8'h5B: pixel = 12'h000;

            // Row 6
            8'h61: pixel = 12'h000;
            8'h62: pixel = 12'hFF0;
            8'h63: pixel = 12'hFF0;
            8'h64: pixel = 12'hF80;
            8'h65: pixel = 12'hF80;
            8'h66: pixel = 12'hF80;
            8'h67: pixel = 12'hF80;
            8'h68: pixel = 12'hFF0;
            8'h69: pixel = 12'hFF0;
            8'h6A: pixel = 12'hFF0;
            8'h6B: pixel = 12'hFF0;
            8'h6C: pixel = 12'h000;

            // Row 7
            8'h71: pixel = 12'h000;
            8'h72: pixel = 12'hFF0;
            8'h73: pixel = 12'hFF0;
            8'h74: pixel = 12'hFF0;
            8'h75: pixel = 12'hF80;
            8'h76: pixel = 12'hF80;
            8'h77: pixel = 12'hFF0;
            8'h78: pixel = 12'hFF0;
            8'h79: pixel = 12'hFF0;
            8'h7A: pixel = 12'hFF0;
            8'h7B: pixel = 12'h000;

            // Row 8
            8'h82: pixel = 12'h000;
            8'h83: pixel = 12'hFF0;
            8'h84: pixel = 12'hFF0;
            8'h85: pixel = 12'hFF0;
            8'h86: pixel = 12'hFF0;
            8'h87: pixel = 12'hFF0;
            8'h88: pixel = 12'hFF0;
            8'h89: pixel = 12'hFF0;
            8'h8A: pixel = 12'h000;

            // Row 9
            8'h92: pixel = 12'h000;
            8'h93: pixel = 12'hFF0;
            8'h94: pixel = 12'hFF0;
            8'h95: pixel = 12'hFF0;
            8'h96: pixel = 12'hFF0;
            8'h97: pixel = 12'hFF0;
            8'h98: pixel = 12'hFF0;
            8'h99: pixel = 12'h000;

            // Row 10
            8'hA3: pixel = 12'h000;
            8'hA4: pixel = 12'hFF0;
            8'hA5: pixel = 12'hFF0;
            8'hA6: pixel = 12'hFF0;
            8'hA7: pixel = 12'hFF0;
            8'hA8: pixel = 12'h000;

            // Row 11
            8'hB3: pixel = 12'h000;
            8'hB4: pixel = 12'h000;
            8'hB5: pixel = 12'hFF0;
            8'hB6: pixel = 12'hFF0;
            8'hB7: pixel = 12'h000;

            // Row 12
            8'hC4: pixel = 12'h000;
            8'hC5: pixel = 12'h000;
            8'hC6: pixel = 12'h000;

            // Rows 13–15 transparent by default
            default: pixel = 12'h0FF;
        endcase
    end

endmodule

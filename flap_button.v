`timescale 1ns / 1ps

module flap_button(
    input wire clk,
    input wire reset,
    input wire btn_raw,
    output wire flap_pulse
);

    wire DPB, SCEN, MCEN, CCEN;

    ee354_debouncer deb(
        .CLK(clk),
        .RESET(reset),
        .PB(btn_raw),
        .DPB(DPB),
        .SCEN(SCEN),
        .MCEN(MCEN),
        .CCEN(CCEN)
    );

    // rising edge detector
    reg prev = 0;
    always @(posedge clk)
        prev <= DPB;

    assign flap_pulse = DPB & ~prev;

endmodule

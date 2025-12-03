`timescale 1ns / 1ps

module vga_top(
    input ClkPort,
    input BtnC,   // RESET (this worked)
    input BtnU,   // FLAP (this did NOT work previously)

    output hSync, vSync,
    output [3:0] vgaR, vgaG, vgaB,

    output An0, An1, An2, An3, An4, An5, An6, An7,
    output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

    output QuadSpiFlashCS
);

    wire bright;
    wire [9:0] hc, vc;
    wire [11:0] rgb;
    wire [15:0] score;
    wire [6:0] ssdOut;
    wire [3:0] anode;

    display_controller dc(
        .clk(ClkPort),
        .hSync(hSync),
        .vSync(vSync),
        .bright(bright),
        .hCount(hc),
        .vCount(vc)
    );

    // PASS RESET AND FLAP INTO VGA MODULE
    vga_bitchange vbc(
        .clk(ClkPort),
        .reset(BtnC),   // CENTER = RESET
        .button(BtnU),  // UP = FLAP
        .bright(bright),
        .hCount(hc),
        .vCount(vc),
        .rgb(rgb),
        .score(score)
    );

    counter cnt(
        .clk(ClkPort),
        .displayNumber(score),
        .anode(anode),
        .ssdOut(ssdOut)
    );

    assign Dp = 1;
    assign {Ca,Cb,Cc,Cd,Ce,Cf,Cg} = ssdOut;
    assign {An7,An6,An5,An4,An3,An2,An1,An0} = {4'b1111, anode};

    assign vgaR = rgb[11:8];
    assign vgaG = rgb[7:4];
    assign vgaB = rgb[3:0];

    assign QuadSpiFlashCS = 1'b1;
endmodule

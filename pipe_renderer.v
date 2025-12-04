`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pipe Renderer – Flappy Bird Pipes With Working Score
//////////////////////////////////////////////////////////////////////////////////

module pipe_renderer(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [9:0]  hCount,
    input  wire [9:0]  vCount,
    input  wire [9:0]  bird_x,
    input  wire [9:0]  bird_y,
    input  wire [4:0]  bird_w,
    input  wire [4:0]  bird_h,
    output reg         pipe_pixel,
    output wire        pipe_collision,
    output reg         pipe_pass
);

    localparam PIPE_WIDTH=40, PIPE_SPEED=1, SCREEN_WIDTH=800;
    localparam SPAWN_OFFSET=80, RESPAWN_X=SCREEN_WIDTH+SPAWN_OFFSET;
    localparam SPEED_DIVIDER=1_000_000;   // pipe scroll speed
    localparam PIPE_SPACING=220;

    reg [10:0] pipe1_x, pipe2_x, pipe3_x, pipe4_x;

    localparam PIPE1_INIT=RESPAWN_X,
               PIPE2_INIT=RESPAWN_X+PIPE_SPACING,
               PIPE3_INIT=RESPAWN_X+PIPE_SPACING*2,
               PIPE4_INIT=RESPAWN_X+PIPE_SPACING*3;

    localparam GAP_MIN_TOP=60, GAP_MAX_TOP=320;
    localparam GAP_MIN_SIZE=150, GAP_MAX_SIZE=150;

    reg [9:0] gap1_top,gap2_top,gap3_top,gap4_top;
    reg [8:0] gap1_size,gap2_size,gap3_size,gap4_size;

    wire [10:0] bird_left   ={1'b0,bird_x};
    wire [10:0] bird_right  =bird_left + bird_w;
    wire [10:0] bird_top    ={1'b0,bird_y};
    wire [10:0] bird_bottom =bird_top + bird_h;

    wire [10:0] gap1_bottom=gap1_top+gap1_size,
                gap2_bottom=gap2_top+gap2_size,
                gap3_bottom=gap3_top+gap3_size,
                gap4_bottom=gap4_top+gap4_size;

    reg [21:0] anim_counter;
    reg [9:0]  lfsr;
    wire lfsr_feedback=lfsr[9]^lfsr[6];

    initial begin
        pipe1_x=PIPE1_INIT; pipe2_x=PIPE2_INIT;
        pipe3_x=PIPE3_INIT; pipe4_x=PIPE4_INIT;
        gap1_top=180; gap2_top=240; gap3_top=300; gap4_top=120;
        gap1_size=150; gap2_size=150; gap3_size=150; gap4_size=150;
        anim_counter=0; pipe_pass=0; lfsr=10'h3FF;
    end

    function [9:0] clamp_top(input[9:0]r);
        clamp_top=(r<GAP_MIN_TOP)?GAP_MIN_TOP:(r>GAP_MAX_TOP?GAP_MAX_TOP:r);
    endfunction

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            pipe1_x<=PIPE1_INIT; pipe2_x<=PIPE2_INIT;
            pipe3_x<=PIPE3_INIT; pipe4_x<=PIPE4_INIT;
            anim_counter<=0; lfsr<=10'h3FF;
        end
        else if(enable) begin
            if(anim_counter==SPEED_DIVIDER-1) begin
                anim_counter<=0;
                lfsr<={lfsr[8:0],lfsr_feedback};

                pipe1_x <= (pipe1_x>PIPE_SPEED)?pipe1_x-PIPE_SPEED:RESPAWN_X;
                pipe2_x <= (pipe2_x>PIPE_SPEED)?pipe2_x-PIPE_SPEED:RESPAWN_X;
                pipe3_x <= (pipe3_x>PIPE_SPEED)?pipe3_x-PIPE_SPEED:RESPAWN_X;
                pipe4_x <= (pipe4_x>PIPE_SPEED)?pipe4_x-PIPE_SPEED:RESPAWN_X;

                if(pipe1_x<=PIPE_SPEED) gap1_top<=clamp_top(lfsr);
                if(pipe2_x<=PIPE_SPEED) gap2_top<=clamp_top(lfsr^10'h155);
                if(pipe3_x<=PIPE_SPEED) gap3_top<=clamp_top(lfsr^10'h2AA);
                if(pipe4_x<=PIPE_SPEED) gap4_top<=clamp_top(lfsr^10'h0F0);
            end else anim_counter<=anim_counter+1;
        end
    end

    wire p1=(hCount>=pipe1_x&&hCount<pipe1_x+PIPE_WIDTH)&&!(vCount>=gap1_top&&vCount<gap1_bottom);
    wire p2=(hCount>=pipe2_x&&hCount<pipe2_x+PIPE_WIDTH)&&!(vCount>=gap2_top&&vCount<gap2_bottom);
    wire p3=(hCount>=pipe3_x&&hCount<pipe3_x+PIPE_WIDTH)&&!(vCount>=gap3_top&&vCount<gap3_bottom);
    wire p4=(hCount>=pipe4_x&&hCount<pipe4_x+PIPE_WIDTH)&&!(vCount>=gap4_top&&vCount<gap4_bottom);

    always @(*) pipe_pixel = p1|p2|p3|p4;

    assign pipe_collision=
        ((bird_right>pipe1_x&&bird_left<pipe1_x+PIPE_WIDTH)&&((bird_top<gap1_top)||(bird_bottom>gap1_bottom)))|
        ((bird_right>pipe2_x&&bird_left<pipe2_x+PIPE_WIDTH)&&((bird_top<gap2_top)||(bird_bottom>gap2_bottom)))|
        ((bird_right>pipe3_x&&bird_left<pipe3_x+PIPE_WIDTH)&&((bird_top<gap3_top)||(bird_bottom>gap3_bottom)))|
        ((bird_right>pipe4_x&&bird_left<pipe4_x+PIPE_WIDTH)&&((bird_top<gap4_top)||(bird_bottom>gap4_bottom)));

    // SCORE when pipe center passes bird_x
    reg [10:0] prev1,prev2,prev3,prev4;
    wire pass1=(prev1+PIPE_WIDTH/2>bird_x)&&(pipe1_x+PIPE_WIDTH/2<=bird_x);
    wire pass2=(prev2+PIPE_WIDTH/2>bird_x)&&(pipe2_x+PIPE_WIDTH/2<=bird_x);
    wire pass3=(prev3+PIPE_WIDTH/2>bird_x)&&(pipe3_x+PIPE_WIDTH/2<=bird_x);
    wire pass4=(prev4+PIPE_WIDTH/2>bird_x)&&(pipe4_x+PIPE_WIDTH/2<=bird_x);

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            prev1<=PIPE1_INIT; prev2<=PIPE2_INIT; prev3<=PIPE3_INIT; prev4<=PIPE4_INIT;
            pipe_pass<=0;
        end else begin
            pipe_pass <= pass1|pass2|pass3|pass4;
            prev1<=pipe1_x; prev2<=pipe2_x; prev3<=pipe3_x; prev4<=pipe4_x;
        end
    end

endmodule

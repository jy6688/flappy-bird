`timescale 1ns / 1ps

module bird_physics(
    input wire clk,
    input wire reset,
    input wire flap_btn,
    output reg [9:0] bird_y
);

    localparam GRAVITY = 2;
    localparam FLAP_POWER = -10;
    localparam MAX_FALL = 5;

    integer velocity;
    reg [19:0] tick;

    initial begin
        bird_y = 200;
        velocity = 0;
        tick = 0;
    end

    always @(posedge clk) begin
        tick <= tick + 1;

        if (reset) begin
            bird_y <= 200;
            velocity <= 0;
        end
        else if (tick == 0) begin
            if (flap_btn)
                velocity <= FLAP_POWER;
            else begin
                velocity <= velocity + GRAVITY;
                if (velocity > MAX_FALL)
                    velocity <= MAX_FALL;
            end

            bird_y <= bird_y + velocity;

            if (bird_y < 0)
                bird_y <= 0;
            else if (bird_y > 480-32)
                bird_y <= 480-32;
        end
    end

endmodule

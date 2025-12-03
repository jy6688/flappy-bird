`timescale 1ns / 1ps

module bird_physics(
    input wire clk,
    input wire reset,
    input wire flap_btn,
    output reg [9:0] bird_y,
    output reg alive
);

    localparam GRAVITY = 2;
    localparam FLAP_POWER = -6; // smaller jump magnitude
    localparam MAX_FALL = 5;

    integer velocity;
    integer next_y;
    reg [19:0] tick;
    
    integer vtemp;
    reg game_over;

    initial begin
        bird_y = 200;
        velocity = 0;
        tick = 0;
        alive = 0; // start paused at origin
        game_over = 0;
    end

    always @(posedge clk) begin
        tick <= tick + 1;
        if (reset) begin
            bird_y <= 200;
            velocity <= 0;
            alive <= 0; // pause after reset
            game_over <= 0;
        end
        else if (tick == 0) begin
                // If not alive, a flap starts the game and applies initial flap power
                if (!alive) begin
                    if (flap_btn && !game_over) begin
                        // starting flap
                        vtemp = FLAP_POWER;
                        next_y = bird_y + vtemp;
                        // check collisions on the next position
                        if (next_y <= 0) begin
                            bird_y <= 0;
                            alive <= 0;
                            velocity <= 0;
                            game_over <= 1;
                        end else if (next_y >= 480-32) begin
                            bird_y <= 480-32;
                            alive <= 0;
                            velocity <= 0;
                            game_over <= 1;
                        end else begin
                            alive <= 1;
                            velocity <= vtemp;
                            bird_y <= next_y;
                        end
                    end
                end
                else begin
                    // Normal physics while alive
                    if (flap_btn)
                        vtemp = FLAP_POWER;
                    else begin
                        vtemp = velocity + GRAVITY;
                        if (vtemp > MAX_FALL)
                            vtemp = MAX_FALL;
                    end

                    // compute next position using signed arithmetic
                    next_y = bird_y + vtemp;

                    // collision with ceiling or floor => stop the game (alive -> 0)
                    if (next_y <= 0) begin
                        bird_y <= 0;
                        alive <= 0;
                        velocity <= 0;
                        game_over <= 1;
                    end
                    else if (next_y >= 480-24) begin
                        bird_y <= 480-24;
                        alive <= 0;
                        velocity <= 0;
                        game_over <= 1;
                    end
                    else begin
                        velocity <= vtemp;
                        bird_y <= next_y;
                    end
                end
        end
    end

endmodule

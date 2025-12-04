`timescale 1ns / 1ps

module bird_physics #(
    parameter integer Y_MIN         = 0,
    parameter integer ACTIVE_HEIGHT = 480,
    parameter integer SPRITE_H      = 24,
    parameter integer GROUND_H      = 0
)(
    input wire clk,
    input wire reset,
    input wire flap_btn,
    input wire collision,        // high when the bird intersects a pipe
    output reg [9:0] bird_y,
    output reg alive
);

    localparam GRAVITY = 2;
    localparam FLAP_POWER = -6; // smaller jump magnitude
    localparam MAX_FALL = 5;
    localparam integer CEIL_LIMIT  = Y_MIN;
    localparam integer FLOOR_LIMIT = Y_MIN + ACTIVE_HEIGHT - GROUND_H - SPRITE_H;
    localparam integer START_Y     = Y_MIN + 200;

    integer velocity;
    integer next_y;
    reg [19:0] tick;
    
    integer vtemp;
    reg game_over;

    initial begin
        bird_y = START_Y;
        velocity = 0;
        tick = 0;
        alive = 0; // start paused at origin
        game_over = 0;
    end

    always @(posedge clk) begin
        tick <= tick + 1;
        if (reset) begin
            bird_y <= START_Y;
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
                        if (next_y <= CEIL_LIMIT) begin
                            bird_y <= CEIL_LIMIT;
                            alive <= 0;
                            velocity <= 0;
                            game_over <= 1;
                        end else if (next_y >= FLOOR_LIMIT) begin
                            bird_y <= FLOOR_LIMIT;
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
                    // stop immediately on pipe collision
                    if (collision) begin
                        alive <= 0;
                        velocity <= 0;
                        game_over <= 1;
                    end else begin
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
                        if (next_y <= CEIL_LIMIT) begin
                            bird_y <= CEIL_LIMIT;
                            alive <= 0;
                            velocity <= 0;
                            game_over <= 1;
                        end
                        else if (next_y >= FLOOR_LIMIT) begin
                            bird_y <= FLOOR_LIMIT;
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
    end

endmodule

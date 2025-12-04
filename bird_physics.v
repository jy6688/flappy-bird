`timescale 1ns / 1ps

module bird_physics(
    input wire clk,
    input wire reset,
    input wire flap_btn,
    input wire collision,
    output reg [9:0] bird_y,
    output reg alive
);

    // ↓ Slightly lighter gravity & softer flap
    localparam GRAVITY    = 1;    // was 2
    localparam FLAP_POWER = -7;   // was -6
    localparam MAX_FALL   = 4;    // fall slower

    integer velocity;
    integer next_y;
    reg [19:0] tick;
    reg game_over;

    initial begin
        bird_y     = 200;
        velocity   = 0;
        tick       = 0;
        alive      = 0;     // start paused
        game_over  = 0;
    end

    always @(posedge clk) begin
        tick <= tick + 1;

        if (reset) begin
            bird_y    <= 200;
            velocity  <= 0;
            alive     <= 0;
            game_over <= 0;
        end

        else if (tick == 20'd0) begin   // physics tick
            // start game on flap
            if (!alive) begin
                if (flap_btn && !game_over) begin
                    velocity <= FLAP_POWER;
                    bird_y   <= bird_y + FLAP_POWER;
                    alive    <= 1;
                end
            end
            else begin
                // collision stops game
                if (collision) begin
                    alive     <= 0;
                    velocity  <= 0;
                    game_over <= 1;
                end else begin
                    // flap or gravity
                    if (flap_btn)
                        velocity <= FLAP_POWER;
                    else begin
                        velocity <= velocity + GRAVITY;
                        if (velocity > MAX_FALL)
                            velocity <= MAX_FALL;
                    end

                    next_y = bird_y + velocity;

                    // bounds
                    if (next_y <= 0) begin
                        bird_y <= 0; alive<=0; game_over<=1; velocity<=0;
                    end else if (next_y >= 480-24) begin // bird is 24px tall
                        bird_y <= 480-24; alive<=0; game_over<=1; velocity<=0;
                    end else begin
                        bird_y <= next_y;
                    end
                end
            end
        end
    end

endmodule

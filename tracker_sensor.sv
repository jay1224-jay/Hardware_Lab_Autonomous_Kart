
/*

Notes:
    IR_outs:
        1: white
        0: black

*/

module tracker_sensor(
    input logic clk,
    input logic rst,
    input logic [4:0] IR_outs,
    output logic [2:0] state
);
    // TODO: Receive IR outputs and make your own policy.
    // Hint: You can use output state to change your action.

    localparam STATE_IDLE       = 3'b000;
    localparam STATE_HARD_LEFT  = 3'b001;
    localparam STATE_LIGHT_LEFT = 3'b010;
    localparam STATE_HARD_RIGHT = 3'b011;
    localparam STATE_LIGHT_RIGHT= 3'b100;
    localparam STATE_RECOVER    = 3'b101;
    localparam STATE_STRAIGHT   = 3'b110;

    logic [2:0] next_state;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst)
            state <= STATE_IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (IR_outs)
            5'b11111:
                next_state = STATE_STRAIGHT;
            5'b00000, 5'b11011:
                next_state = STATE_STRAIGHT;
            5'b01111:
                next_state = STATE_HARD_LEFT;
            5'b10111:
                next_state = STATE_LIGHT_LEFT;
            5'b11101:
                next_state = STATE_LIGHT_RIGHT;
            5'b11110:
                next_state = STATE_HARD_RIGHT;
            default: 
                next_state = STATE_STRAIGHT;
        endcase
    end

    /*
    always_comb begin
        next_state = state;
        case (IR_outs)
            5'b11111:
                next_state = STATE_STRAIGHT;
            5'b00000, 5'b11011:
                next_state = STATE_STRAIGHT;
            5'b00001, 5'b00011, 5'b00111, 5'b01111, 5'b01111, 5'b10111:
                next_state = STATE_LEFT;
            5'b10000, 5'b11000, 5'b11100, 5'b11110, 5'b11110, 5'b11101:
                next_state = STATE_RIGHT;
            default: 
                next_state = STATE_STRAIGHT;
        endcase
    end
    */

endmodule

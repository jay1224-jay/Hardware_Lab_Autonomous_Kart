module lab6_advanced(
    input logic clk,
    input logic rst,
    input logic IR_out1,    // far-left
    input logic IR_out2,    // inner-left  
    input logic IR_out3,    // center
    input logic IR_out4,    // inner-right
    input logic IR_out5,    // far-right
    input logic echo,
    output logic trig,
    output logic IN1,
    output logic IN2,
    output logic IN3,
    output logic IN4,
    output logic left_pwm,  // ENA
    output logic right_pwm, // ENB

    output logic [6:0] DISPLAY,
    output logic [3:0] DIGIT,
    output logic [15:0] LED
    // You may modify or add more input/ouput yourself.
);

    localparam STATE_IDLE       = 3'b000;
    localparam STATE_LEFT       = 3'b001;
    localparam STATE_RIGHT      = 3'b010;
    localparam STATE_RECOVER    = 3'b011;
    localparam STATE_STRAIGHT   = 3'b100;

    localparam MODE_STOP     = 3'b000;
    localparam MODE_FORWARD  = 3'b001;
    localparam MODE_LEFT     = 3'b010;
    localparam MODE_RIGHT    = 3'b011;
    localparam MODE_BACKWARD = 3'b100;

    localparam STOP_DISTANCE = 19'd15;

    logic rst_de, rst_op;
    debounce de(.clk(clk), .pb(rst), .pb_debounced(rst_de));
    one_pulse op(.clk(clk), .pb_in(rst_de), .pb_out(rst_op));
    
    // We have connected the tracker_sensor, sonic_top, and motor modules in the template file for you.
    // TODO: control the motors with the information you get from ultrasonic sensor and 5-way track sensor.
    logic [2:0] state;      // output of track_sensor
    logic [2:0] mode;       // input of motor
    logic [19:0] distance;  // output of sonic_top

    always_comb begin
        case (state)
            STATE_IDLE:
                mode = MODE_STOP;
            STATE_LEFT:
                mode = MODE_LEFT;
            STATE_RIGHT:
                mode = MODE_RIGHT;
            STATE_RECOVER:
                mode = MODE_BACKWARD;
            STATE_STRAIGHT:
                mode = MODE_FORWARD; 
            default: 
                mode = MODE_STOP;
        endcase

        if (distance <= STOP_DISTANCE)
            mode = MODE_STOP;
    end
    
    tracker_sensor A(
        .clk(clk),
        .rst(rst_op),
        .IR_outs({IR_out1, IR_out2, IR_out3, IR_out4, IR_out5}),
        .state(state)
    );        

    sonic_top B(
        .clk(clk), 
        .rst(rst_op), 
        .echo(echo), 
        .trig(trig),
        .distance(distance)
    );

    motor C(
        .clk(clk),
        .rst(rst_op),
        .mode(mode),
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );

endmodule
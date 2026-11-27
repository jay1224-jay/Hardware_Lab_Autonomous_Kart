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
    localparam STATE_HARD_LEFT  = 3'b001;
    localparam STATE_LIGHT_LEFT = 3'b010;
    localparam STATE_HARD_RIGHT = 3'b011;
    localparam STATE_LIGHT_RIGHT= 3'b100;
    localparam STATE_RECOVER    = 3'b101;
    localparam STATE_STRAIGHT   = 3'b110;

    localparam MODE_STOP     = 3'b000;
    localparam MODE_FORWARD  = 3'b001;
    localparam MODE_HARD_LEFT   = 3'b010;
    localparam MODE_LIGHT_LEFT  = 3'b011;
    localparam MODE_HARD_RIGHT  = 3'b100;
    localparam MODE_LIGHT_RIGHT = 3'b101;
    localparam MODE_BACKWARD = 3'b110;

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

        /*
        if (distance <= STOP_DISTANCE)
            mode = MODE_STOP;
        */
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

    /* ===== DEBUG ===== */

    logic [31:0] cnt, t_cnt;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst)
            cnt <= 0;
            t_cnt <= 0;
        else begin
            if (echo)
                cnt <= cnt + 1;
            if (trig)
                t_cnt <= t_cnt + 1;
        end
    end

    always_comb begin
        LED[15:13] = state;
        LED[12] = 0;
        LED[11:9] = mode;
        LED[8:7] = {echo, trig};
        LED[6:0] = distance;
    end

    SevenSegment my_seven(DISPLAY, DIGIT, distance % 100 + (cnt % 10) * 1000 + (t_cnt % 10) * 100, rst, clk);



    /* ===== DEBUG ===== */

endmodule

module SevenSegment(
	output logic [6:0] display,
	output logic [3:0] digit,
	input logic [15:0] nums,
	input logic rst,
	input logic clk
);
    
    logic [15:0] clk_divider;
    logic [3:0] display_num;
    
    always_ff @(posedge clk or posedge rst) begin
    	if (rst) begin
    		clk_divider <= 16'd0;
    	end else begin
    		clk_divider <= clk_divider + 16'd1;
    	end
    end
    
    always_ff @(posedge clk_divider[15] or posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
					display_num <= (nums % 100) / 10;
					digit <= 4'b1101;
    			end
    			4'b1101 : begin
					display_num <= (nums % 1000) / 100;
					digit <= 4'b1011;
				end
    			4'b1011 : begin
					display_num <= (nums % 10000) / 1000;
					digit <= 4'b0111;
				end
    			4'b0111 : begin
					display_num <= nums % 10;
					digit <= 4'b1110;
				end
    			default : begin
					display_num <= nums[3:0];
					digit <= 4'b1110;
				end				
    		endcase
    	end
    end
    
    always_comb begin
    	case (display_num)
    		4'd0: display = 7'b1000000;
            4'd1: display = 7'b1111001;
            4'd2: display = 7'b0100100;
            4'd3: display = 7'b0110000;
            4'd4: display = 7'b0011001;
            4'd5: display = 7'b0010010;
            4'd6: display = 7'b0000010;
            4'd7: display = 7'b1111000;
            4'd8: display = 7'b0000000;
            4'd9: display = 7'b0010000;
			default : display = 7'b1111111;
    	endcase
    end
endmodule

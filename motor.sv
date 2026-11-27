// This module take "mode" input and control two motors accordingly.
// clk should be 100MHz for PWM_gen module to work correctly.
// You can modify / add more inputs and outputs by yourself.
module motor(
    input logic clk,
    input logic rst,
    input logic [2:0] mode,
    output logic [1:0] pwm,
    output logic [1:0] r_IN,
    output logic [1:0] l_IN
);
    logic [9:0] left_motor, right_motor;
    logic left_pwm, right_pwm;
	
	always_comb begin
        left_motor = 0;
        right_motor = 0;
		case(mode)
			0: begin //stop
				left_motor = 650;
    			right_motor = 650;
			end
			1: begin //forward
				left_motor = 650;
    			right_motor = 650;
			end
			2: begin //hard_left
				left_motor = 350;
    			right_motor = 700;
			end
			3: begin //light_left
				left_motor = 600;
    			right_motor = 750;
			end
			4: begin //hard_right
				left_motor = 700;
    			right_motor = 350;
			end
			5: begin //light_right
				left_motor = 750;
    			right_motor = 600;
			end
			default: begin //backward 
                left_motor = 650;
    			right_motor = 650;
			end
		endcase
	end
	
    assign pwm = {left_pwm, right_pwm};

    PWM_gen m0 (
        .clk(clk),
        .rst(rst),
        .freq(32'd25000),
        .duty(left_motor),
        .PWM(left_pwm)
    );
    
    PWM_gen m1 (
        .clk(clk),
        .rst(rst),
        .freq(32'd25000),
        .duty(right_motor),
        .PWM(right_pwm)
    );

    // TODO: trace the rest of motor.v and control the speed and direction of the two motors

	assign {l_IN, r_IN} = (mode == 0) ? 4'b0000 : 4'b0101;
    
endmodule


//generte PWM by input frequency & duty cycle
module PWM_gen (
    input logic clk,
    input logic rst,
	input logic [31:0] freq,
    input logic [9:0] duty,
    output logic PWM
);
	logic [31:0] count_max;
	assign count_max = 100_000_000 / freq;
	logic [31:0] count_duty;
	assign count_duty = count_max * duty / 1024;
    logic [31:0] count;
    
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            PWM <= 0;
        end else begin
            if (count >= (count_max - 32'd1)) begin
                count <= 0;
                PWM <= 0;
            end else begin
                count <= count + 1;
                if (count <= count_duty) begin
                    PWM <= 1;
                end else begin
                    PWM <= 0;
                end
                // TODO: set <PWM> accordingly
            end
        end
    end
endmodule


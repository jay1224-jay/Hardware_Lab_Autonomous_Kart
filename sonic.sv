// sonic_top is the module to interface with sonic sensors
// clk = 100MHz
// <trig> and <echo> should connect to the sensor
// <distance> is the output distance in cm
module sonic_top(
    input logic clk,
    input logic rst,
    input logic echo,
    output logic trig,
    output logic [19:0] distance
);
    logic clk1M;
    div clk1(clk, clk1M);

    trig_signal ts(.clk(clk), .rst(rst), .trig(trig));
    pos_counter pc(.clk1M(clk1M), .rst(rst), .echo(echo), .distance_count(distance));
endmodule


// clock divider for T = 1us clock
module div(
    input logic clk,
    output logic out_clk
);
    logic [6:0] cnt;

    always_ff @(posedge clk) begin
        if (cnt >= 7'd99) begin
            cnt <= 7'd0;
        end else begin
            cnt <= cnt + 1'b1;
        end

        out_clk <= (cnt < 7'd50) ? 1'b1 : 1'b0;
    end
endmodule


// send trigger signal to sensor
module trig_signal(
    input logic clk,
    input logic rst,
    output logic trig
);
    logic next_trig;
    logic [23:0] count, next_count;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            trig <= 0;
        end else begin
            count <= next_count;
            trig <= next_trig;
        end
    end

    // generate a 10us high pulse on <trig> every 100ms
    always_comb begin
        if (count >= 24'd9_999_999) begin
            next_count = 24'd0;
        end else begin
            next_count = count + 1'b1;
        end
        if (count > 24'd1_000_000) begin
            next_trig = 1'b0;
        end else begin
            next_trig = 1'b1;
        end
        // TODO: set <next_trig> to let the sensor work properly
    end
endmodule


module pos_counter(
    input logic clk1M,
    input logic rst,
    input logic echo,
    output logic [19:0] distance_count
); 
    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b10;
    logic [1:0] state, next_state;
    logic [19:0] count, distance_register;

    logic echo_reg1, echo_reg2;
    logic start;
    assign start = echo_reg1 & ~echo_reg2;
    logic finish;
    assign finish = ~echo_reg1 & echo_reg2;
    
    always_ff @(posedge clk1M) begin
        if (rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register <= 0;
            state <= S0;
        
        end else begin
            echo_reg1 <= echo;
            echo_reg2 <= echo_reg1;

            case(state)
                S0: begin
                    if (start) state <= next_state;
                    else count <= 0;
                end

                S1: begin
                    if (finish) state <= next_state;
                    else count <= count + 1;
                end

                S2: begin
                    distance_register <= count;
                    count <= 0;
                    state <= next_state;
                end
            endcase
        end
    end

    always_comb begin
        case(state)
            S0: next_state = S1;
            S1: next_state = S2;
            S2: next_state = S0;
            default: next_state = S0;
        endcase
    end

    assign distance_count = distance_register * 17 / 1000; // Avoid non-constant real-value error
    // TODO: trace the code and calculate the distance, output it to <distance_count>
endmodule


module nes_controller_interface #(
    parameter NUM_CONTROLLERS = 4,  // width of serial_LIST and data_LIST
    parameter LATCH_PULSE_WIDTH = 1 // increase for higher frequencies
) (
    input   wire                            clk,
    input   wire                            rst,
    input   wire                            start_fetch_i,
    output  wire                            valid_o,

    output  wire                            controller_clk_o, // max of 500 kHz
    output  wire                            controller_latch_o,
    input   wire  [NUM_CONTROLLERS-1:0]     controller_serial_LIST_ni,

    output  wire  [8*NUM_CONTROLLERS-1:0]   data_LIST_o
);


    // Latch Timing State Machine

    localparam WAIT     = 2'b00;
    localparam LATCH    = 2'b01;
    localparam READ     = 2'b10;

    reg [1:0]   state_d, state_q = WAIT;
    reg         latch_d, latch_q = 0;
    reg [3:0]   num_bits_left_d, num_bits_left_q = 0;

    localparam LATCH_TIMER_WIDTH = (LATCH_PULSE_WIDTH < 1) ? ($clog2(LATCH_PULSE_WIDTH)) : (1);
    localparam LATCH_TIMER_MAX = LATCH_PULSE_WIDTH - 1;

    reg [LATCH_TIMER_WIDTH-1:0] latch_timer_d, latch_timer_q = 0;

    wire has_bits_left = (num_bits_left_q != 0);
    assign valid_o = ( !has_bits_left ) && ( !latch_q );
    assign controller_latch_o = latch_q;
    assign controller_clk_o = clk && (has_bits_left || controller_latch_o);

    always @* begin
        num_bits_left_d = num_bits_left_q;
        latch_d = latch_q;
        state_d = state_q;
        latch_timer_d = latch_timer_q;
        case ( state_q )
            WAIT: begin
                if ( start_fetch_i ) begin
                    latch_d = 1;
                    state_d = LATCH;
                    latch_timer_d = LATCH_TIMER_MAX;
                end
            end
            LATCH: begin
                if ( latch_timer_q == 0 ) begin
                    state_d = READ;
                    num_bits_left_d = 4'd8;
                    latch_d = 0;
                end else begin
                    latch_timer_d = latch_timer_q - 1;
                end
            end
            READ: begin
                if ( has_bits_left ) begin
                    num_bits_left_d = num_bits_left_q - 1;
                end else if ( start_fetch_i ) begin
                    latch_d = 1;
                    state_d = LATCH;
                    latch_timer_d = LATCH_TIMER_MAX;
                end else begin
                    state_d = WAIT;
                end
            end
            default: ;
        endcase
    end

    always @(posedge clk) begin
        if ( rst ) begin
            num_bits_left_q <= 0;
            latch_q <= 0;
            state_q <= WAIT;
            latch_timer_q <= 0;
        end else begin
            num_bits_left_q <= num_bits_left_d;
            latch_q <= latch_d;
            state_q <= state_d;
            latch_timer_q <= latch_timer_d;
        end
    end



    // Individual Controller Logic

    genvar controller_GEN;
    generate for (controller_GEN = 1; controller_GEN <= NUM_CONTROLLERS; controller_GEN = controller_GEN+1 ) begin : controller

    reg [7:0] data_d, data_q = 0;
    assign data_LIST_o[8*(controller_GEN-1)+:8] = data_q;

    reg [7:0] shift_register_d, shift_register_q = 0;

    always @* begin
        shift_register_d = shift_register_q;
        data_d = data_q;
        if ( num_bits_left_q != 0 ) begin
            shift_register_d = {shift_register_q[6:0], ~controller_serial_LIST_ni[controller_GEN-1]};
            if ( num_bits_left_d == 0 ) begin
                data_d = shift_register_d;
            end
        end
    end

    always @(posedge clk) begin
        if ( rst ) begin
            shift_register_q <= 0;
            data_q <= 0;
        end else begin
            shift_register_q <= shift_register_d;
            data_q <= data_d;
        end
    end

    `ifdef SIM
    wire serial_n = controller_serial_LIST_ni[controller_GEN-1];
    wire [7:0] data = data_q;
    `endif

    end endgenerate

endmodule

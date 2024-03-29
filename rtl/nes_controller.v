
module nes_controller #(
    parameter SYNC_LATCH = 1
) (
    // {a,b,select,start,up,down,left,right}
    input   wire [7:0]  buttons_ni,
    input   wire        clk_i,
    input   wire        latch_i,
    output  wire        serial_no
);

    wire [7:0] shift_register_d;
    reg [7:0] shift_register_q = 0;


    // The NES controller's CD4021BC shift register allows for async loads
    // This module implements async loads, but uses sync loads by default due to poor support
    generate if (SYNC_LATCH==0) begin : async_latch

        assign shift_register_d = {shift_register_q[6:0], 1'b0};

        always @(posedge clk_i or posedge latch_i) begin
            if (latch_i) begin
                shift_register_q <= buttons_ni;
            end else begin
                shift_register_q <= shift_register_d;
            end
        end

    end else begin : sync_latch

        assign shift_register_d = latch_i ? buttons_ni : {shift_register_q[6:0], 1'b0};

        always @(posedge clk_i) begin
            shift_register_q <= shift_register_d;
        end

    end endgenerate

    assign serial_no = shift_register_q[7];

endmodule

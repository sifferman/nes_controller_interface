
module controller_interface_tb;

reg clk = 0;
always #(1) clk <= ~clk;

reg rst = 0;
reg start_fetch = 0;
wire valid;
wire controller_clk;
wire controller_latch;
reg [7:0] controller_1_buttons = 0;
reg [7:0] controller_2_buttons = 0;
reg [7:0] controller_3_buttons = 0;
reg [7:0] controller_4_buttons = 0;
wire controller_1_serial_n;
wire controller_2_serial_n;
wire controller_3_serial_n;
wire controller_4_serial_n;
wire [7:0] controller_1_data;
wire [7:0] controller_2_data;
wire [7:0] controller_3_data;
wire [7:0] controller_4_data;

nes_controller_interface #(
    .NUM_CONTROLLERS(4),
    .LATCH_PULSE_WIDTH(1)
) controller_interface (
    .clk(clk),
    .rst(rst),
    .start_fetch_i(start_fetch),
    .valid_o(valid),

    .controller_clk_o(controller_clk),
    .controller_latch_o(controller_latch),
    .controller_serial_LIST_ni({
        controller_1_serial_n,
        controller_2_serial_n,
        controller_3_serial_n,
        controller_4_serial_n
    }),
    .data_LIST_o({
        controller_1_data,
        controller_2_data,
        controller_3_data,
        controller_4_data
    })
);

nes_controller #(
    .SYNC_LATCH(1)
) controller_1 (
    .buttons_ni(~controller_1_buttons),
    .clk_i(controller_clk),
    .latch_i(controller_latch),
    .serial_no(controller_1_serial_n)
);

nes_controller #(
    .SYNC_LATCH(1)
) controller_2 (
    .buttons_ni(~controller_2_buttons),
    .clk_i(controller_clk),
    .latch_i(controller_latch),
    .serial_no(controller_2_serial_n)
);

nes_controller #(
    .SYNC_LATCH(1)
) controller_3 (
    .buttons_ni(~controller_3_buttons),
    .clk_i(controller_clk),
    .latch_i(controller_latch),
    .serial_no(controller_3_serial_n)
);

nes_controller #(
    .SYNC_LATCH(1)
) controller_4 (
    .buttons_ni(~controller_4_buttons),
    .clk_i(controller_clk),
    .latch_i(controller_latch),
    .serial_no(controller_4_serial_n)
);

initial begin
$dumpfile( "dump.fst" );
$dumpvars;
$display( "Begin simulation." );
//\\ =========================== \\//

`define ASSERT_EQUAL(EXPECTED, RECIEVED) if (EXPECTED != RECIEVED) begin    \
    $display("Error: expected %b, recieved %b", EXPECTED, RECIEVED);        \
end

rst = 1;
@(posedge clk);
rst = 0;

for (integer i = 0; i < 256; i=i+1) begin
    controller_1_buttons = i[7:0];
    controller_2_buttons = i[7:0];
    controller_3_buttons = i[7:0];
    controller_4_buttons = i[7:0];
    start_fetch = 1;
    @(posedge controller_latch);
    start_fetch = 0;
    @(posedge valid);
    @(posedge clk);
    `ASSERT_EQUAL(controller_1_buttons, controller_1_data);
    `ASSERT_EQUAL(controller_2_buttons, controller_2_data);
    `ASSERT_EQUAL(controller_3_buttons, controller_3_data);
    `ASSERT_EQUAL(controller_4_buttons, controller_4_data);
end

//\\ =========================== \\//
$display( "End simulation.");
$finish;
end

endmodule

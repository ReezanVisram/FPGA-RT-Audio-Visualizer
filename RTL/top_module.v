module top_module(
    input clk_100MHz,
    input line_in_sdout,
    input reset,
    output line_out_mclk,
    output line_out_ws,
    output line_out_sck,
    output line_out_sdin,
    output line_in_mclk,
    output line_in_ws,
    output line_in_sck,
    output test_led
);

  wire clk_22_579MHz;

  wire mclk;
  wire sck;
  wire ws;

  wire [31:0] data_left;
  wire [31:0] data_right;

  wire resetn = (reset == 0) ? 1'b0 : 1'b1;

  clk_wiz_0 inst
  (
    .clk_in1(clk_100MHz),         
    .clk_22_579MHz(clk_22_579MHz)
  );

  i2s_controller master (
    .clk(clk_22_579MHz),
    .resetn(resetn),
    .mclk(mclk),
    .sck(sck),
    .ws(ws)
  );

  // basic_i2s_receive rx(
  //   .clk(clk),
  //   .ws(ws),
  //   .sck(sck),
  //   .sd(line_in_sdout),
  //   .data_left(data_left),
  //   .data_right(data_right)
  // );

  // basic_i2s_transmit tx(
  //   .clk(clk),
  //   .ws(ws),
  //   .sck(sck),
  //   .data_left(data_left),
  //   .data_right(data_right),
  //   .sd(line_out_sdin)
  // );

  assign line_out_mclk = mclk;
  assign line_out_ws = ws;
  assign line_out_sck = sck;
  assign line_in_mclk = mclk;
  assign line_in_ws = ws;
  assign line_in_sck = sck;
  assign line_out_sdin = line_in_sdout;

endmodule
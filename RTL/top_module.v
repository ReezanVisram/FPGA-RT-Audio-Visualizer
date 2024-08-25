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

  wire resetn = (reset == 0) ? 1'b0 : 1'b1;

  wire tready;
  wire tvalid;
  wire [31:0] tdata;
  wire tlast;
 
  wire tready1;
  wire tvalid1;
  wire [31:0] tdata1;
  wire tlast1;

  wire tready2;
  wire tvalid2;
  wire [31:0] tdata2;
  wire tlast2;

  wire [31:0] mono_sample;
  
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

  i2s_receive rx1(
    .M_AXIS_ACLK(clk_22_579MHz),
    .M_AXIS_ARESETN(resetn),
    .M_AXIS_TREADY(tready),
    .M_AXIS_TVALID(tvalid),
    .M_AXIS_TDATA(tdata),
    .M_AXIS_TLAST(tlast),

    .sck(sck),
    .ws(ws),
    .sd(line_in_sdout)
  );

  axi4_stream_broadcaster broadcaster(
    .AXIS_ACLK(clk_22_579MHz),
    .AXIS_ARESETN(resetn),
    .S_AXIS_TDATA(tdata),
    .S_AXIS_TVALID(tvalid),
    .S_AXIS_TLAST(tlast),
    .S_AXIS_TREADY(tready),

    .M_AXIS_TDATA1(tdata1),
    .M_AXIS_TVALID1(tvalid1),
    .M_AXIS_TLAST1(tlast1),
    .M_AXIS_TREADY1(tready1),

    .M_AXIS_TDATA2(tdata2),
    .M_AXIS_TVALID2(tvalid2),
    .M_AXIS_TLAST2(tlast2),
    .M_AXIS_TREADY2(tready2)
  );

  i2s_transmit tx(
    .S_AXIS_ACLK(clk_22_579MHz),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TREADY(tready1),
    .S_AXIS_TVALID(tvalid1),
    .S_AXIS_TDATA(tdata1),
    .S_AXIS_TLAST(tlast1),

    .sck(sck),
    .ws(ws),
    .sd(line_out_sdin)
  );

  packet_to_mono_sample_converter conv(
    .S_AXIS_ACLK(clk_22_579MHz),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TREADY(tready2),
    .S_AXIS_TVALID(tvalid2),
    .S_AXIS_TDATA(tdata2),
    .S_AXIS_TLAST(tlast2),
    .mono_sample(mono_sample)
  );

  assign line_out_mclk = mclk;
  assign line_out_ws = ws;
  assign line_out_sck = sck;
  assign line_in_mclk = mclk;
  assign line_in_ws = ws;
  assign line_in_sck = sck;
endmodule
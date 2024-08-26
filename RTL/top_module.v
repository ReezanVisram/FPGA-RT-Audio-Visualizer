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
  wire clk_35MHz;

  wire mclk;
  wire sck;
  wire ws;

  wire resetn = (reset == 0) ? 1'b0 : 1'b1;

  wire rx_tready;
  wire rx_tvalid;
  wire [31:0] rx_tdata;
  wire rx_tlast;
 
  wire tx_to_br_tready;
  wire br_to_tx_tvalid;
  wire [31:0] br_to_tx_tdata;
  wire br_to_tx_tlast;

  wire conv_to_br_tready;
  wire br_to_conv_tvalid;
  wire [31:0] br_to_conv_tdata;
  wire br_to_conv_tlast;

  wire [31:0] mono_sample;
  wire mono_sample_valid;
  
  wire [31:0] fifo_to_translator_mono_sample;
  wire fifo_almost_empty;
  wire fifo_empty;
  wire fifo_almost_full;
  wire fifo_full;
  wire translator_to_fifo_rd_en;
  wire [13:0] translator_word_address;
  wire [4:0] translator_bit_offset;
  wire translator_word_and_offset_valid;

  clk_wiz_0 clk_gen
  (
    .clk_in1(clk_100MHz),         
    .clk_22_579MHz(clk_22_579MHz),
    .clk_35MHz(clk_35MHz)
  );

  i2s_controller i2s_master (
    .clk(clk_22_579MHz),
    .resetn(resetn),
    .mclk(mclk),
    .sck(sck),
    .ws(ws)
  );

  i2s_receive i2s_rx(
    .M_AXIS_ACLK(clk_22_579MHz),
    .M_AXIS_ARESETN(resetn),
    .M_AXIS_TREADY(rx_tready),
    .M_AXIS_TVALID(rx_tvalid),
    .M_AXIS_TDATA(rx_tdata),
    .M_AXIS_TLAST(rx_tlast),

    .sck(sck),
    .ws(ws),
    .sd(line_in_sdout)
  );

  axi4_stream_broadcaster broadcaster(
    .AXIS_ACLK(clk_22_579MHz),
    .AXIS_ARESETN(resetn),
    .S_AXIS_TDATA(rx_tdata),
    .S_AXIS_TVALID(rx_tvalid),
    .S_AXIS_TLAST(rx_tlast),
    .S_AXIS_TREADY(rx_tready),

    .M_AXIS_TDATA1(br_to_tx_tdata),
    .M_AXIS_TVALID1(br_to_tx_tvalid),
    .M_AXIS_TLAST1(br_to_tx_tlast),
    .M_AXIS_TREADY1(tx_to_br_tready),

    .M_AXIS_TDATA2(br_to_conv_tdata),
    .M_AXIS_TVALID2(br_to_conv_tvalid),
    .M_AXIS_TLAST2(br_to_conv_tlast),
    .M_AXIS_TREADY2(conv_to_br_tready)
  );

  i2s_transmit tx(
    .S_AXIS_ACLK(clk_22_579MHz),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TREADY(tx_to_br_tready),
    .S_AXIS_TVALID(br_to_tx_tvalid),
    .S_AXIS_TDATA(br_to_tx_tdata),
    .S_AXIS_TLAST(br_to_tx_tlast),

    .sck(sck),
    .ws(ws),
    .sd(line_out_sdin)
  );

  packet_to_mono_sample_converter conv(
    .S_AXIS_ACLK(clk_22_579MHz),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TREADY(conv_to_br_tready),
    .S_AXIS_TVALID(br_to_conv_tvalid),
    .S_AXIS_TDATA(br_to_conv_tdata),
    .S_AXIS_TLAST(br_to_conv_tlast),
    .mono_sample(mono_sample),
    .mono_sample_valid(mono_sample_valid)
  );

  fifo_generator_0 fifo_gen (
  .wr_clk(clk_22_579MHz),              // input wire wr_clk
  .rd_clk(clk_35MHz),              // input wire rd_clk
  .din(mono_sample),                    // input wire [31 : 0] din
  .wr_en(mono_sample_valid),                // input wire wr_en
  .rd_en(translator_to_fifo_rd_en),                // input wire rd_en
  .dout(fifo_to_translator_mono_sample),                  // output wire [31 : 0] dout
  .full(fifo_full),                  // output wire full
  .almost_full(fifo_almost_full),    // output wire almost_full
  .empty(fifo_empty),                // output wire empty
  .almost_empty(fifo_almost_empty)  // output wire almost_empty
  );

  mono_sample_to_memory_addr_translator translator(
    .clk(clk_35MHz),
    .resetn(resetn),
    .mono_sample(fifo_to_translator_mono_sample),
    .fifo_almost_empty(fifo_almost_empty),
    .fifo_rd_en(translator_to_fifo_rd_en),
    .word_address(translator_word_address),
    .bit_offset(translator_bit_offset),
    .word_and_offset_valid(translator_word_and_offset_valid)
  );

  assign line_out_mclk = mclk;
  assign line_out_ws = ws;
  assign line_out_sck = sck;
  assign line_in_mclk = mclk;
  assign line_in_ws = ws;
  assign line_in_sck = sck;
  assign test_led = translator_bit_offset[2];
endmodule
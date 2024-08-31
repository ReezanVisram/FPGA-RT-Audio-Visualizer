module top_module(
    input clk_100MHz,
    input line_in_sdout,
    input reset,
    input uart_txd_in,
    output line_out_mclk,
    output line_out_ws,
    output line_out_sck,
    output line_out_sdin,
    output line_in_mclk,
    output line_in_ws,
    output line_in_sck,
    output test_led,
    output [3:0] red,
    output [3:0] blue,
    output [3:0] green,
    output hsync,
    output vsync,
    output uart_rxd_out,
    output led0_r,
    output led0_g,
    output led0_b,
    output led1_r,
    output led1_g,
    output led1_b
);

  localparam SYSCLK_PERIOD = 10;
  localparam NUM_SAMPLES = 2000;
  localparam DATA_WIDTH = 32;
  localparam SCREEN_WIDTH=640;
  localparam SCREEN_HEIGHT=480;
  localparam ADDR_WIDTH=$clog2(SCREEN_WIDTH * SCREEN_HEIGHT);
  localparam SAMPLE_WIDTH=24;
  localparam COORD_WIDTH=16;

  // Clock signals + Generation
  wire clk_22_579MHz;
  wire clk_25_2MHz;

  wire resetn = (reset == 0) ? 1'b0 : 1'b1;

  // I2S Clocks
  wire mclk;
  wire sck;
  wire ws;

  // AXI Signals
  wire rx_tready;
  wire rx_tvalid;
  wire signed [DATA_WIDTH - 1:0] rx_tdata;
  wire rx_tlast;

  wire tx_to_br_tready;
  wire br_to_tx_tvalid;
  wire signed [DATA_WIDTH - 1:0] br_to_tx_tdata;
  wire br_to_tx_tlast;

  wire conv_to_br_tready;
  wire br_to_conv_tvalid;
  wire signed [DATA_WIDTH - 1:0] br_to_conv_tdata;
  wire br_to_conv_tlast;

  // Mono Sample
  wire mono_sample_valid;
  wire signed [DATA_WIDTH - 1:0] mono_sample;

  // FIFO Control
  wire fifo_empty;
  wire fifo_almost_empty;
  wire fifo_full;
  wire fifo_almost_full;

  // Sample To Pixel Signals
  wire [DATA_WIDTH - 1:0] fifo_to_stp_mono_sample;
  wire stp_to_fifo_rd_en;
  wire [ADDR_WIDTH - 1:0] stp_to_fb_pixel_addr;
  wire stp_to_fb_pixel_data;
  wire stp_to_fb_pixel_wr_en;

  // VGA Controller Signals
  wire fb_to_controller_pixel_data0;
  wire fb_to_controller_pixel_data1;
  wire controller_to_fb_rd_en;
  wire [ADDR_WIDTH - 1:0] controller_to_fb_pixel_addr;
  wire data_enable;
  wire frame_pulse;
  wire line_pulse;

  // Framebuffer Manager
  wire [ADDR_WIDTH - 1:0] fbuffer_mgr_pixel_addr;
  wire fbuffer_mgr_pixel_data;
  wire fbuffer_mgr_pixel_wr_en;
  wire fbuffer_mgr_clearing_framebuffer;
  wire buffer_sel;

  wire [ADDR_WIDTH - 1:0] fbuffer_wr_addr;
  wire fbuffer_wr_data;
  wire fbuffer_wr_en;

  wire fb_to_controller_pixel_data;

  // UART Signals
  wire uart_data_valid;
  wire [7:0] uart_data;
  wire uart_tx_active;
  wire uart_tx_done;

  // Colour Manager signals
  wire [2:0] curr_channel;
  wire [11:0] waveform_colour;
  wire [11:0] background_colour;

  // RGB LED Manager Signals
  wire led_r;
  wire led_g;
  wire led_b;

  clk_wiz_0 clk_generator(
    .clk_in1(clk_100MHz),
    .clk_22_579MHz(clk_22_579MHz),
    .clk_25_2MHz(clk_25_2MHz),
    .locked(locked)
  );

  i2s_controller i2s_master(
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

  i2s_transmit i2s_tx(
    .S_AXIS_ACLK(clk_22_579MHz),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TDATA(br_to_tx_tdata),
    .S_AXIS_TLAST(br_to_tx_tlast),
    .S_AXIS_TVALID(br_to_tx_tvalid),
    .S_AXIS_TREADY(tx_to_br_tready),

    .sck(sck),
    .ws(ws),
    .sd(line_out_sdin)
  );

  packet_to_mono_sample_converter conv(
    .S_AXIS_ACLK(clk_22_579MHz),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TDATA(br_to_conv_tdata),
    .S_AXIS_TLAST(br_to_conv_tlast),
    .S_AXIS_TVALID(br_to_conv_tvalid),
    .S_AXIS_TREADY(conv_to_br_tready),

    .mono_sample_valid(mono_sample_valid),
    .mono_sample(mono_sample)
  );

  fifo_generator_0 mono_sample_fifo (
    .wr_clk(clk_22_579MHz),
    .rd_clk(clk_100MHz),
    .din(mono_sample),
    .wr_en(mono_sample_valid),
    .rd_en(stp_to_fifo_rd_en),
    .dout(fifo_to_stp_mono_sample),
    .full(fifo_full),
    .almost_full(fifo_almost_full),
    .empty(fifo_empty),
    .almost_empty(fifo_almost_empty)
  );

  sample_to_pixel stp(
    .clk(clk_100MHz),
    .resetn(resetn),
    .frame_pulse(frame_pulse),
    .mono_sample(fifo_to_stp_mono_sample),
    .fifo_almost_empty(fifo_almost_empty),
    .clearing_framebuffer(fbuffer_mgr_clearing_framebuffer),
    .fifo_rd_en(stp_to_fifo_rd_en),
    .pixel_addr(stp_to_fb_pixel_addr),
    .pixel_data(stp_to_fb_pixel_data),
    .pixel_wr_en(stp_to_fb_pixel_wr_en)
  );

  framebuffer_manager fbuffer_mgr(
    .clk(clk_100MHz),
    .resetn(resetn),
    .frame_pulse(frame_pulse),
    .pixel_addr(fbuffer_mgr_pixel_addr),
    .pixel_wr_en(fbuffer_mgr_pixel_wr_en),
    .pixel_data(fbuffer_mgr_pixel_data),
    .clearing_framebuffer(fbuffer_mgr_clearing_framebuffer),
    .buffer_sel(buffer_sel)
  );

  framebuffer fbuffer0(
    .wrclk(clk_100MHz),
    .rdclk(clk_25_2MHz),
    .resetn(resetn),
    .wr_en(buffer_sel && fbuffer_wr_en),
    .rd_en(controller_to_fb_rd_en),
    .wr_addr(fbuffer_wr_addr),
    .rd_addr(controller_to_fb_pixel_addr),
    .wr_data(fbuffer_wr_data),
    .rd_data(fb_to_controller_pixel_data0)
  );

  framebuffer fbuffer1(
    .wrclk(clk_100MHz),
    .rdclk(clk_25_2MHz),
    .resetn(resetn),
    .wr_en(!buffer_sel && fbuffer_wr_en),
    .rd_en(controller_to_fb_rd_en),
    .wr_addr(fbuffer_wr_addr),
    .rd_addr(controller_to_fb_pixel_addr),
    .wr_data(fbuffer_wr_data),
    .rd_data(fb_to_controller_pixel_data1)
  );

  vga_controller controller(
    .clk(clk_25_2MHz),
    .resetn(resetn),
    .pixel_data(fb_to_controller_pixel_data),
    .framebuffer_rd_en(controller_to_fb_rd_en),
    .pixel_addr(controller_to_fb_pixel_addr),
    .waveform_colour(waveform_colour),
    .background_colour(background_colour),
    .red(red),
    .blue(blue),
    .green(green),
    .hsync(hsync),
    .vsync(vsync),
    .data_enable(data_enable),
    .frame_pulse(frame_pulse),
    .line_pulse(line_pulse)
  );

  uart_rx uartrx(
    .clk(clk_25_2MHz),
    .resetn(resetn),
    .rx_data(uart_txd_in),
    .data_valid(uart_data_valid),
    .data(uart_data)
  );

  uart_tx uarttx(
    .clk(clk_25_2MHz),
    .resetn(resetn),
    .data_valid(uart_data_valid),
    .data(uart_data),
    .tx_active(uart_tx_active),
    .tx_data(uart_rxd_out),
    .tx_done(uart_tx_done)
  );

  colour_manager colour_mgr(
    .clk(clk_25_2MHz),
    .resetn(resetn),
    .uart_data(uart_data),
    .uart_data_valid(uart_data_valid),
    .curr_channel(curr_channel),
    .background_colour(background_colour),
    .waveform_colour(waveform_colour)
  );

  rgb_led_manager rgb_led_mgr(
    .clk(clk_25_2MHz),
    .resetn(resetn),
    .curr_channel(curr_channel),
    .led_r(led_r),
    .led_g(led_g),
    .led_b(led_b)
  );

  assign fbuffer_wr_addr = fbuffer_mgr_clearing_framebuffer ? fbuffer_mgr_pixel_addr : stp_to_fb_pixel_addr;
  assign fbuffer_wr_data = fbuffer_mgr_clearing_framebuffer ? fbuffer_mgr_pixel_data : stp_to_fb_pixel_data;
  assign fbuffer_wr_en = fbuffer_mgr_clearing_framebuffer ? fbuffer_mgr_pixel_wr_en : stp_to_fb_pixel_wr_en;
  assign fb_to_controller_pixel_data = buffer_sel ? fb_to_controller_pixel_data1 : fb_to_controller_pixel_data0;

  assign line_out_mclk = mclk;
  assign line_out_ws = ws;
  assign line_out_sck = sck;
  assign line_in_mclk = mclk;
  assign line_in_ws = ws;
  assign line_in_sck = sck;
  
  assign led0_r = led_r;
  assign led0_g = led_g;
  assign led0_b = led_b;
  assign led1_r = led_r;
  assign led1_g = led_g;
  assign led1_b = led_b;

endmodule
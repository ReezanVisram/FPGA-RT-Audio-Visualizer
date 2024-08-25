`timescale 1ns / 1ps
module tb_top;
  // Parameters
  localparam SYSCLK_PERIOD = 10;
  localparam NUM_SAMPLES = 2000;
  localparam DATA_WIDTH = 32;

  reg resetn = 1'b0;

  // Clock signals + Generation
  reg clk_100MHz = 1'b0;
  wire clk_22_579MHz;
  wire locked;

  // Reading Samples
  reg [DATA_WIDTH - 1:0] sample_memory [0:NUM_SAMPLES - 1];
  reg [DATA_WIDTH - 1:0] sample;
  integer sample_line;

  // I2S Clocks
  wire mclk;
  wire sck;
  wire ws;

  // Sample Output
  reg sdin_pre;
  reg sdin;

  // Sample Input
  wire sdout;

  // AXI Signals
  wire rx_tready;
  wire rx_tvalid;
  wire [DATA_WIDTH - 1:0] rx_tdata;
  wire rx_tlast;

  wire tx_to_br_tready;
  wire br_to_tx_tvalid;
  wire [DATA_WIDTH - 1:0] br_to_tx_tdata;
  wire br_to_tx_tlast;

  wire conv_to_br_tready;
  wire br_to_conv_tvalid;
  wire [DATA_WIDTH - 1:0] br_to_conv_tdata;
  wire br_to_conv_tlast;

  // Mono Sample
  wire [DATA_WIDTH - 1:0] mono_sample;

  clk_wiz_0 clk_generator(
    .clk_in1(clk_100MHz),
    .clk_22_579MHz(clk_22_579MHz),
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
    .sd(sdin)
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
    .sd(sdout)
  );

  packet_to_mono_sample_converter conv(
    .S_AXIS_ACLK(clk_22_579MHz),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TDATA(br_to_conv_tdata),
    .S_AXIS_TLAST(br_to_conv_tlast),
    .S_AXIS_TVALID(br_to_conv_tvalid),
    .S_AXIS_TREADY(conv_to_br_tready),

    .mono_sample(mono_sample)
  );

  initial
  begin
    $timeformat(-9, 2, " ns", 20);
    wait(locked == 1'b1);
    resetn = 1'b1;

    $readmemb("samples.txt", sample_memory);

    wait(ws == 1'b1);
    for (sample_line = 0; sample_line < NUM_SAMPLES; sample_line = sample_line + 1)
    begin
      sample = sample_memory[sample_line];

      repeat(DATA_WIDTH) // We want to output the 24 bit sample, then another 8 cycles of don't cares
      begin
        sdin_pre <= sample[DATA_WIDTH - 1];
        sdin <= sdin_pre;
        sample <= sample << 1;
        @(negedge sck);
      end
    end

    #900 $finish;
  end

  always
  begin
    #(SYSCLK_PERIOD/2) clk_100MHz <= ~clk_100MHz;
  end

endmodule
`timescale 1ns / 1ps
module tb_top;
  // Parameters
  localparam SYSCLK_PERIOD = 10;
  localparam NUM_SAMPLES = 2000;
  localparam DATA_WIDTH = 32;
  localparam ADDRESS_LENGTH = 14;

  reg resetn = 1'b0;

  // Clock signals + Generation
  reg clk_100MHz = 1'b0;
  wire clk_22_579MHz;
  wire clk_35MHz;
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
  wire mono_sample_valid;
  wire [DATA_WIDTH - 1:0] mono_sample;

  // FIFO Control
  wire fifo_empty;
  wire fifo_almost_empty;
  wire fifo_full;
  wire fifo_almost_full;

  // Translator Control
  wire [DATA_WIDTH - 1:0] fifo_to_translator_mono_sample;
  wire translator_to_fifo_rd_en;

  // Translator Output
  wire [ADDRESS_LENGTH - 1:0] translator_word_address;
  wire [4:0] translator_bit_offset;
  wire translator_word_and_offset_valid;

  // Writer Input/Output
  wire writer_we;
  wire [ADDRESS_LENGTH - 1:0] writer_addr;
  wire [DATA_WIDTH - 1:0] writer_word_with_pixel_written;
  wire [DATA_WIDTH - 1:0] msys_to_writer_data;

  clk_wiz_0 clk_generator(
    .clk_in1(clk_100MHz),
    .clk_22_579MHz(clk_22_579MHz),
    .clk_35MHz(clk_35MHz),
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

    .mono_sample_valid(mono_sample_valid),
    .mono_sample(mono_sample)
  );

  fifo_generator_0 mono_sample_fifo (
    .wr_clk(clk_22_579MHz),
    .rd_clk(clk_35MHz),
    .din(mono_sample),
    .wr_en(mono_sample_valid),
    .rd_en(translator_to_fifo_rd_en),
    .dout(fifo_to_translator_mono_sample),
    .full(fifo_full),
    .almost_full(fifo_almost_full),
    .empty(fifo_empty),
    .almost_empty(fifo_almost_empty)
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

  memory msys1(
    .clk(clk_35MHz),
    .reset(~resetn),
    .we(writer_we),
    .rdaddr(writer_addr),
    .wraddr(writer_addr),
    .wrdata(writer_word_with_pixel_written),
    .rddata(msys_to_writer_data)
  );

  addr_to_pixel_writer writer(
    .clk(clk_35MHz),
    .resetn(resetn),
    .word_address(translator_word_address),
    .bit_offset(translator_bit_offset),
    .word_and_offset_valid(translator_word_and_offset_valid),
    .curr_word(msys_to_writer_data),
    .addr(writer_addr),
    .word_with_pixel_written(writer_word_with_pixel_written),
    .we(writer_we)
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
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

  // AXI Signals
  reg rx_tready = 1'b0;
  wire rx_tvalid;
  wire [DATA_WIDTH - 1:0] rx_tdata;
  wire rx_tlast;

  // Expected data to verify proper behaviour
  reg [DATA_WIDTH - 1:0] sent_rx_tdata;
  reg [DATA_WIDTH - 1:0] expected_rx_tdata;

  // Verification Events
  event check_rx_tdata;

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
      sent_rx_tdata = sample;

      repeat(DATA_WIDTH) // We want to output the 24 bit sample, then another 8 cycles of don't cares
      begin
        sdin_pre <= sample[DATA_WIDTH - 1];
        sdin <= sdin_pre;
        sample <= sample << 1;
        @(negedge sck);
      end
      expected_rx_tdata = sent_rx_tdata;
      ->check_rx_tdata;
    end

    #900 $finish;
  end

  always @(check_rx_tdata)
  begin
    // We wait 1 sck cycle for the LSB to be transmitted, and then 1 sck cycle for TDATA to be populated
    repeat(2) @(negedge sck); 
    if (expected_rx_tdata != rx_tdata)
    begin
      $display("Test failed. Time = %0t, Sample # = %0d, Expected = %0h, Received = %0h", $time, sample_line, expected_rx_tdata, rx_tdata);
    end
  end

  always
  begin
    #(SYSCLK_PERIOD/2) clk_100MHz <= ~clk_100MHz;
  end

endmodule
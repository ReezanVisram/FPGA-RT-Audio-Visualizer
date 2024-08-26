module tb_i2s_transmit;
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

  // AXI Signals
  wire tx_tready;
  reg tx_tvalid = 1'b0;
  reg [DATA_WIDTH - 1:0] tx_tdata;
  reg tx_tlast = 1'b0;

  // Signals to capture output
  wire sdout;
  reg [DATA_WIDTH - 1:0] captured_tx_data;

  // Expected data to verify proper behaviour
  reg [DATA_WIDTH - 1:0] expected_tx_tdata;

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

  i2s_transmit i2s_tx(
    .S_AXIS_ACLK(mclk),
    .S_AXIS_ARESETN(resetn),
    .S_AXIS_TDATA(tx_tdata),
    .S_AXIS_TLAST(tx_tlast),
    .S_AXIS_TVALID(tx_tvalid),
    .S_AXIS_TREADY(tx_tready),

    .sck(sck),
    .ws(ws),
    .sd(sdout)
  );

  initial
  begin
    $timeformat(-9, 2, " ns", 20);
    wait (locked == 1'b1);
    resetn = 1'b1;

    $readmemb("samples.txt", sample_memory);

    wait(ws == 1'b1);
    for (sample_line = 0; sample_line < NUM_SAMPLES; sample_line = sample_line + 1)
    begin
      sample = sample_memory[sample_line];
      expected_tx_tdata = sample;

      @(posedge mclk);
      tx_tdata <= sample; tx_tvalid <= 1'b1; tx_tlast = sample_line % 2 == 0;
      wait(tx_tready == 1'b1);
      @(posedge mclk);
      tx_tvalid <= 1'b0; tx_tlast <= 1'b0;
    end

    #900 $finish;
  end

  // Load all sdout bits into a shift register, and if we check it at the right time we can get the output for a given sample
  always @(negedge sck)
  begin
      captured_tx_data <= {captured_tx_data, sdout};
  end

  // The shift register contains the data from the previous sample 2 sck periods after ws changes
  always @(ws)
  begin
    repeat(2) @(negedge sck);
    // There is a delay of 1.5 ws cycles from when the sample is loaded into the transmitter to when it is actually output
    // And then half a ws cycle is required to shift in the transmitted data
    // There are 2 samples per ws cycle, hence the sample_line - 4
    if (sample_memory[sample_line - 4] != captured_tx_data)
    begin
      $display("Test failed. Time = %0t, Sample # = %0d, Expected = %0h, Captured - %0h", $time, sample_line, sample_memory[sample_line - 4], captured_tx_data);
    end
  end

  always
    #(SYSCLK_PERIOD/2) clk_100MHz <= ~clk_100MHz;

endmodule
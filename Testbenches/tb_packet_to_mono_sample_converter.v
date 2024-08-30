`timescale 1ns / 1ps

module tb_packet_to_mono_sample_converter;
  parameter AXIS_ACLK_PERIOD = 20;
  parameter DATA_WIDTH = 32;
  parameter SAMPLE_WIDTH = 24;
  parameter NUM_SAMPLES = 88200;

  // Reading Samples
  reg signed [DATA_WIDTH - 1:0] sample_memory [0:NUM_SAMPLES - 1];
  reg signed [DATA_WIDTH - 1:0] sample;
  integer sample_line;

  // AXI Signals
  reg axis_aclk = 1'b0;
  reg axis_aresetn = 1'b0;
  reg axis_tvalid = 1'b0;
  reg axis_tlast = 1'b0;
  reg [DATA_WIDTH - 1:0] axis_tdata;
  wire axis_tready;

  // Mono Sample Signals
  wire mono_sample_valid;
  wire signed [SAMPLE_WIDTH - 1:0] mono_sample;

  // Expected Values
  reg signed [SAMPLE_WIDTH - 1:0] expected_mono_sample;
  reg signed [SAMPLE_WIDTH:0] sum_expected_samples;

  integer f;

  packet_to_mono_sample_converter dut(
    .S_AXIS_ACLK(axis_aclk),
    .S_AXIS_ARESETN(axis_aresetn),
    .S_AXIS_TVALID(axis_tvalid),
    .S_AXIS_TLAST(axis_tlast),
    .S_AXIS_TDATA(axis_tdata),
    .S_AXIS_TREADY(axis_tready),

    .mono_sample_valid(mono_sample_valid),
    .mono_sample(mono_sample)
  );

  initial
  begin
    f = $fopen("mono_samples.txt", "w");
    $timeformat(-9, 2, " ns", 20);
    #15 axis_aresetn = 1'b1;
    
    $readmemb("samples.txt", sample_memory);

    for (sample_line = 0; sample_line < NUM_SAMPLES; sample_line = sample_line + 1)
    begin
      sample = sample_memory[sample_line];

      @(posedge axis_aclk);
      axis_tdata <= sample; axis_tvalid <= 1'b1; axis_tlast <= sample_line % 2;

      wait(axis_tready == 1'b1);
      repeat(3) @(posedge axis_aclk);
      #5 axis_tvalid <= 1'b0; axis_tlast <= 1'b0;
    end

    $fclose(f);
    #200 $finish;
  end

  always @(posedge mono_sample_valid)
  begin
    $fwrite(f, "%0d\n", mono_sample);
    // There is a 2 sample latency between when the left and right samples are given and when the mono sample is calculated
    sum_expected_samples = sample_memory[sample_line - 2][DATA_WIDTH - 1:(DATA_WIDTH - SAMPLE_WIDTH)] + sample_memory[sample_line - 1][DATA_WIDTH - 1:(DATA_WIDTH - SAMPLE_WIDTH)];

    expected_mono_sample = sum_expected_samples >>> 1; 
    if (expected_mono_sample != mono_sample)
    begin
      $display("Test Failed. Time = %0t, Expected = %0h, Received = %0h", $time, expected_mono_sample, mono_sample);
    end
  end

  always
    #(AXIS_ACLK_PERIOD/2) axis_aclk <= ~axis_aclk;

endmodule
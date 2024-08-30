`timescale 1ns / 1ps

module tb_uart_rx;
  parameter CLK_PERIOD=39.68;
  parameter CLK_CYCLES_PER_BIT=219;
  parameter NUM_SAMPLES=6;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  reg rx_data = 1'b1;
  wire data_valid;
  wire [7:0] data;

  reg [7:0] sample_memory [0:NUM_SAMPLES - 1];
  reg [7:0] sample;

  integer sample_line;
  integer bit_index;

  reg [7:0] expected_sample;

  uart_rx dut(
    .clk(clk),
    .resetn(resetn),
    .rx_data(rx_data),
    .data_valid(data_valid),
    .data(data)
  );

  initial
  begin
    $timeformat(-9, 2, " ns", 20);
    #25 resetn = 1'b1;
    $readmemh("uart_tests.txt", sample_memory);

    for (sample_line = 0; sample_line < NUM_SAMPLES; sample_line = sample_line + 1)
    begin
      sample = sample_memory[sample_line];
      // Start Bit
      @(posedge clk);
      rx_data <= 1'b0;
      // Transmitting Data Bits
      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) // Write memory out LSB to MSB
      begin
        repeat(CLK_CYCLES_PER_BIT) @(posedge clk);
        rx_data <= sample[bit_index];
      end
      // Stop Bit
      repeat(CLK_CYCLES_PER_BIT) @(posedge clk);
      rx_data <= 1'b1;

      wait(data_valid == 1'b1);
    end
    #200 $finish;
  end

  always @(posedge data_valid)
  begin
    expected_sample = sample_memory[sample_line - 1];
    if (data != expected_sample)
      $display("Test Failed. Time = %0t, Expected = %0h, Received = %0h", $time, expected_sample, data);
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;

endmodule
`timescale 1ns / 1ps

module tb_uart_tx;
  parameter CLK_PERIOD=39.68;
  parameter CLK_CYCLES_PER_BIT=219;
  parameter NUM_SAMPLES=6;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  reg data_valid = 1'b0;

  reg [7:0] sample;

  wire active;
  wire tx_data;
  wire tx_done;

  reg [7:0] sample_memory[0:NUM_SAMPLES - 1];

  reg [7:0] captured_tx_data;
  reg [7:0] expected_tx_data;

  uart_tx dut(
    .clk(clk),
    .resetn(resetn),
    .data_valid(data_valid),
    .data(sample),
    .active(active),
    .tx_data(tx_data),
    .tx_done(tx_done)
  );

  integer sample_line;
  integer bit_index;

  initial
  begin
    $timeformat(-9, 2, " ns", 20);
    #25 resetn = 1'b1;

    $readmemh("uart_tests.txt", sample_memory);

    for (sample_line = 0; sample_line < NUM_SAMPLES; sample_line = sample_line + 1)
    begin
      sample = sample_memory[sample_line];

      @(posedge clk);
      data_valid <= 1'b1;

      wait(tx_data == 1'b0); // Wait for start bit
      repeat((CLK_CYCLES_PER_BIT - 1)/2) @(posedge clk); // Sample at middle of the bit

      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
      begin
        repeat(CLK_CYCLES_PER_BIT) @(posedge clk);
        captured_tx_data[bit_index] <= tx_data;
      end

      wait (tx_done == 1'b1);
    end

    #200 $finish;
  end

  always @(posedge tx_done)
  begin
    expected_tx_data = sample_memory[sample_line - 1];
    if (expected_tx_data != captured_tx_data)
      $display("Test Failed: Time = %0t, Expected = %0h, Received = %0h", $time, expected_tx_data, captured_tx_data);
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;
endmodule
`timescale 1ns / 1ps

module tb_i2s_controller_rx_tx;
  parameter DATA_WIDTH=32;
  reg clk = 1'b0;
  reg resetn = 1'b0;
  wire mclk;
  wire sck;
  wire ws;

  wire [31:0] data_left;
  wire [31:0] data_right;
  reg sd_pre;
  reg sd;
  wire sdout;

  event capture_output;
  event check_output;

  reg [DATA_WIDTH - 1:0] captured_sample;

  reg [DATA_WIDTH - 1:0] prev_sent_left;
  reg [DATA_WIDTH - 1:0] prev_sent_right;
  reg [DATA_WIDTH - 1:0] prev_sent_leftd;
  reg [DATA_WIDTH - 1:0] prev_sent_rightd;

  reg [DATA_WIDTH - 1:0] sent;

  integer i;
  integer num_fails = 0;
  integer num_tests = 4;

  i2s_controller master(.clk(clk), .resetn(resetn), .mclk(mclk), .ws(ws), .sck(sck));

  basic_i2s_transmit tx(
    .clk(clk),
    .ws(ws),
    .sck(sck),
    .data_left(data_left),
    .data_right(data_right),
    .sd(sdout)
  );

  basic_i2s_receive rx(
    .clk(clk),
    .sck(sck),
    .ws(ws),
    .sd(sd),
    .data_left(data_left),
    .data_right(data_right)
  );

  reg [31:0] random_sample;
  
  initial
  begin
    $timeformat(-9, 2, " ns", 20);
    #15 resetn = 1'b1;
    wait(resetn);
    repeat(num_tests)
    begin
      random_sample = $random;
      sent = random_sample;
      for (i = 0; i < DATA_WIDTH; i = i + 1)
      begin
        sd_pre <= random_sample[DATA_WIDTH - 1];
        sd <= sd_pre;
        random_sample <= random_sample << 1;
        captured_sample[DATA_WIDTH - 1 - i] <= sdout;
        @(negedge sck);
      end
      sd <= sd_pre;

      if (ws)
        prev_sent_left <= sent;
      else
        prev_sent_right <= sent;

      ->check_output;
    end

    $display("%0d/%0d tests passed!", num_tests - num_fails, num_tests);

    #20000 $finish;
  end

  always @(check_output)
  begin
    @(negedge sck);
    prev_sent_leftd = prev_sent_left;
    prev_sent_rightd = prev_sent_right; 
    if (ws)
    begin
      if (captured_sample !== prev_sent_leftd)
      begin
        $display("Test Failed: Time = %0t, Expected = %0h, Received = %0h", $time, prev_sent_leftd, captured_sample);
        num_fails = num_fails + 1;
      end
    end
    else
    begin
      if (captured_sample !== prev_sent_rightd)
      begin
        $display("Test Failed: Time = %0t, Expected = %0h, Received = %0h", $time, prev_sent_rightd, captured_sample);
        num_fails = num_fails + 1;
      end
    end
  end

  always
    #10 clk <= ~clk;

endmodule
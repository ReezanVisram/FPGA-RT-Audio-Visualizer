`timescale 1ns / 1ps
module tb_basic_i2s_receive;
  parameter DATA_WIDTH = 32;
  parameter CLK_PERIOD=20;

  reg clk = 1'b1;
  
  reg sck = 1'b0;
  reg ws = 1'b0;
  reg sd = 1'b0;
  reg sd_pre = 1'b0;

  wire [DATA_WIDTH - 1:0] data_left;
  wire [DATA_WIDTH - 1:0] data_right;

  basic_i2s_receive rx(.clk(clk), .sck(sck), .ws(ws), .sd(sd), .data_left(data_left), .data_right(data_right));

  reg [DATA_WIDTH - 1:0] random_sample;
  reg [DATA_WIDTH - 1:0] sent;
  reg [DATA_WIDTH - 1:0] expected;

  reg [DATA_WIDTH - 1:0] sampled_data_left;
  reg [DATA_WIDTH - 1:0] sampled_data_right;
  reg [DATA_WIDTH - 1:0] sampled_expected;

  event check_output;

  integer num_tests = 200;
  integer num_fails = 0;

  integer old_length;
  integer length;

  initial
  begin
    @(ws);
    repeat(num_tests)
    begin
      for (length = 3; length <= 32; length = length + 1)
      begin
        begin
          random_sample = $random;
          sent = random_sample & (32'hFFFFFFFF << (32 - length));
          repeat(length)
          begin
            sd_pre <= random_sample[DATA_WIDTH - 1];
            sd <= sd_pre;
            random_sample <= random_sample << 1;
            @(negedge sck);      
          end
          sd <= sd_pre;
          repeat(DATA_WIDTH - length) @(negedge sck);
          expected = sent;

          old_length = length;
          ->check_output;
        end
      end
    end
    

    $display("%0d/%0d tests passed!", (num_tests * 30) - num_fails, num_tests * 30);
    #(((CLK_PERIOD/2) * 8) * 6) $finish;
  end

  always @(check_output)
  begin
    repeat(2) @(negedge sck);
    sampled_data_left = data_left & (32'hFFFFFFFF << (32 - old_length));
    sampled_data_right = data_right & (32'hFFFFFFFF << (32 - old_length));
    sampled_expected = expected & (32'hFFFFFFFF << (32 - old_length));

    if (ws) // We just finished populating the left channel
    begin
      if (sampled_data_left != sampled_expected)
      begin
        $display("Test Failed: Expected = %0h, Sent = %0h", sampled_expected, sampled_data_left);
        num_fails = num_fails + 1;
      end
    end
    else
    begin
      if (sampled_data_right != sampled_expected)
      begin
        $display("Test Failed: Expected = %0h, Sent = %0h", sampled_expected, sampled_data_right);
        num_fails = num_fails + 1;
      end
    end
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;

  always
    #((CLK_PERIOD/2) * 8) sck <= ~sck;

  always
    #(((CLK_PERIOD / 2) * 8) * 64) ws <= ~ws;

endmodule
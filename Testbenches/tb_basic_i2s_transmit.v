module tb_basic_i2s_transmit;
  parameter DATA_WIDTH=32;
  parameter CLK_PERIOD=20;

  reg clk=1'b1;
  reg ws = 1'b0;
  reg sck = 1'b0;

  reg [DATA_WIDTH - 1:0] data_left = {DATA_WIDTH{1'b0}};
  reg [DATA_WIDTH - 1:0] data_right = {DATA_WIDTH{1'b0}};

  reg [DATA_WIDTH - 1:0] random_data = {DATA_WIDTH{1'b0}};

  reg [DATA_WIDTH - 1:0] data_received = {DATA_WIDTH{1'b0}};
  wire sd;

  basic_i2s_transmit u1(.clk(clk), .sck(sck), .ws(ws), .data_left(data_left), .data_right(data_right), .sd(sd));

  integer i;

  integer num_tests = 100;
  integer num_fails = 0;

  event check_output;

  initial
  begin
    @(ws);
    repeat(2) @(negedge sck);
    repeat(num_tests)
    begin
      for (i = 0; i < DATA_WIDTH; i = i + 1)
      begin
        data_received[DATA_WIDTH - 1 - i] = sd;
        @(negedge sck);
      end
    end

    ->check_output;

    $display("%0d/%0d tests passed!", num_tests - num_fails, num_tests);
    #(((CLK_PERIOD/2) * 8) * 6) $finish;
  end

  always @(ws)
  begin
      random_data = $random;
      if (ws)
        data_right = random_data;
      else
        data_left = random_data;
  end

  always @(check_output)
  begin
    if (ws)
    begin
      if (data_left != data_received)
      begin
        $display("Test Failed: Expected = %0h, Received = %0h", data_left, data_received);
        num_fails = num_fails + 1;
      end
    end
    else
    begin
      if (data_right != data_received)
      begin
        $display("Test Failed: Expected = %0h, Received = %0h", data_right, data_received);
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
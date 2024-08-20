module tb_basic_i2s_transmit;
  parameter DATA_WIDTH=32;
  parameter CLK_PERIOD=20;

  reg clk=1'b1;
  reg ws = 1'b0;
  reg sck = 1'b0;

  reg [DATA_WIDTH - 1:0] data_left = {DATA_WIDTH{1'b0}};
  reg [DATA_WIDTH - 1:0] data_right = {DATA_WIDTH{1'b0}};

  reg [DATA_WIDTH - 1:0] random_sample = {DATA_WIDTH{1'b0}};

  reg [DATA_WIDTH - 1:0] data_received = {DATA_WIDTH{1'b0}};

  reg [DATA_WIDTH - 1:0] sampled_data_left;
  reg [DATA_WIDTH - 1:0] sampled_data_right;
  reg [DATA_WIDTH - 1:0] sampled_received;
  
  wire sd;

  basic_i2s_transmit u1(.clk(clk), .sck(sck), .ws(ws), .data_left(data_left), .data_right(data_right), .sd(sd));

  integer i;
  integer length = 3;
  integer old_length;

  integer num_tests = 100;
  integer num_fails = 0;

  event check_output;

  initial
  begin
    $timeformat(-9, 2, " ns", 20);
    @(ws);
    repeat(2) @(negedge sck);
    while (length <= DATA_WIDTH)
    begin
      repeat(num_tests)
      begin
        for (i = 0; i < DATA_WIDTH; i = i + 1)
        begin
          data_received[DATA_WIDTH - 1 - i] <= sd;
          @(negedge sck);
        end
        ->check_output;
      end
      old_length = length;
      length = length + 1;
    end


    $display("%0d/%0d tests passed!", (num_tests * 30) - num_fails, num_tests * 30);
    #(((CLK_PERIOD/2) * 8) * 6) $finish;
  end

  always @(ws)
  begin
      random_sample = $random;
      if (ws)
        data_right = random_sample & (32'hFFFFFFFF << (DATA_WIDTH - length));
      else
        data_left = random_sample & (32'hFFFFFFFF << (DATA_WIDTH - length));
  end

  always @(check_output)
  begin
      sampled_data_left = data_left & (32'hFFFFFFFF << (32 - old_length));
      sampled_data_right = data_right & (32'hFFFFFFFF << (32 - old_length));
      sampled_received = data_received & (32'hFFFFFFFF << (32 - old_length));
    if (ws)
    begin
      if (sampled_data_left != sampled_received)
      begin
        $display("Test Failed: Time = %0t, Expected = %0h, Received = %0h", $time, sampled_data_left, sampled_received);
        num_fails = num_fails + 1;
      end
    end
    else
    begin
      if (sampled_data_right != sampled_received)
      begin
        $display("Test Failed: Time = %0t, Expected = %0h, Received = %0h", $time, sampled_data_right, sampled_received);
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
`timescale 1ns / 1ps

module tb_i2s_controller_rx_tx;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  wire mclk;
  wire ws;
  wire sck;

  wire [31:0] data_left;
  wire [31:0] data_right;
  reg sd;
  wire sdout;

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
    random_sample = $random;
    #15 resetn = 1'b1;
    repeat(32)
    begin
      sd <= random_sample[31];
      random_sample <= random_sample << 1;
      @(negedge sck);
    end
    #20000 $finish;
  end

  always
    #10 clk <= ~clk;

endmodule
`timescale 1ns / 1ps

module tb_i2s_controller_rx_tx;
  parameter DATA_WIDTH = 32;
  parameter MCLK_PERIOD = 20;
  parameter SCK_PERIOD = MCLK_PERIOD * 8;
  parameter WS_PERIOD = SCK_PERIOD * 64;

  reg clk = 1'b0;
  wire mclk;
  wire sck;
  wire ws;

  wire [DATA_WIDTH - 1:0] data_left;
  wire [DATA_WIDTH - 1:0] data_right;
  reg sd_pre;
  reg sd;
  wire sdout;

  reg [DATA_WIDTH - 1:0] sent_random;
  reg [DATA_WIDTH - 1:0] sent_random_copy;
  reg [DATA_WIDTH - 1:0] sent_random_prev;

  integer i;
  reg [DATA_WIDTH - 1:0] captured_transmit;

  i2s_controller master(.clk(clk), .resetn(1'b1), .mclk(mclk), .ws(ws), .sck(sck));

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

  initial
  begin
    wait(ws == 1'b1);
    repeat(4)
    begin
      sent_random_prev = sent_random_copy;
      sent_random = 32'hAAAAAAAA;
      sent_random_copy = sent_random;
      for (i = 0; i < DATA_WIDTH; i = i + 1)
      begin
        sd_pre <= sent_random[DATA_WIDTH - 1];
        sd <= sd_pre;
        sent_random <= sent_random << 1;
        captured_transmit[DATA_WIDTH - 1 - i] <= sdout;
        @(negedge sck);
      end
    end
    sd <= sd_pre;
    

    #(SCK_PERIOD * 3) $finish;
  end

  always
    #(MCLK_PERIOD / 2) clk <= ~clk;

endmodule
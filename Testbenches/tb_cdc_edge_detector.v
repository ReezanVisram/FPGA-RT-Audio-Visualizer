module tb_cdc_edge_detector;
  parameter FAST_CLK_PERIOD = 20;
  parameter SLOW_CLK_PERIOD = 40;

  reg fast_clk = 1'b0;
  reg slow_clk = 1'b0;

  reg slow_data = 1'b0;

  wire data_rise;
  wire data_fall;

  cdc_edge_detector dut(
    .fast_clk(fast_clk),
    .slow_data(slow_data),
    .data_rise(data_rise),
    .data_fall(data_fall)
  );

  initial
  begin
    #30;
    @(posedge slow_clk);
    slow_data <= 1'b1;
    #100
    @(posedge slow_clk);
    slow_data <= 1'b0;

    #32
    @(posedge slow_clk);
    slow_data <= 1'b1;
    @(posedge slow_clk);
    slow_data <= 1'b0;
  end

  always
    #(FAST_CLK_PERIOD/2) fast_clk <= ~fast_clk;

  always 
    #(SLOW_CLK_PERIOD/2) slow_clk <= ~slow_clk;

endmodule
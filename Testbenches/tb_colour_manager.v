`timescale 1ns / 1ps

module tb_colour_manager;
  parameter CLK_PERIOD=20;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  reg [7:0] uart_data = 8'b0;
  reg uart_data_valid = 1'b0;

  wire [2:0] curr_channel;
  wire [11:0] waveform_colour;
  wire [11:0] background_colour;

  colour_manager dut(
    .clk(clk),
    .resetn(resetn),
    .uart_data(uart_data),
    .uart_data_valid(uart_data_valid),
    .curr_channel(curr_channel),
    .waveform_colour(waveform_colour),
    .background_colour(background_colour)
  );

  initial
  begin
    #15 resetn = 1'b1;

    // Valid channel (r)
    @(posedge clk);
    uart_data = 8'h72; uart_data_valid = 1'b1;
    @(posedge clk);
    uart_data = 8'h34; uart_data_valid = 1'b0;

    // Valid channel (g) but invalid intensity, so should not change states
    #25
    @(posedge clk);
    uart_data = 8'h67; uart_data_valid = 1'b1;
    @(posedge clk);
    uart_data = 8'h34; uart_data_valid = 1'b0;

    // Valid intensity (A)
    #35
    @(posedge clk);
    uart_data = 8'h41; uart_data_valid = 1'b1;
    @(posedge clk);
    uart_data = 8'h34; uart_data_valid = 1'b0;

    // Valid intensity (C) but inalid component, so should not change states
    #15
    @(posedge clk);
    uart_data = 8'h43; uart_data_valid = 1'b1;
    @(posedge clk);
    uart_data = 8'h34; uart_data_valid = 1'b0;

    // Valid component (B)
    #15
    @(posedge clk);
    uart_data = 8'h42; uart_data_valid = 1'b1;
    @(posedge clk);
    uart_data = 8'h34; uart_data_valid = 1'b0;

    #200 $finish;
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;
endmodule
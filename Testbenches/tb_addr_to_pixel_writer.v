`timescale 1ns / 1ps
module tb_addr_to_pixel_writer;
  localparam DATA_WIDTH = 32;
  localparam ADDRESS_LENGTH = 14;
  localparam CLK_PERIOD = 20;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  reg [ADDRESS_LENGTH - 1:0] word_address = {ADDRESS_LENGTH{1'b0}};
  reg [4:0] bit_offset = 5'b0;
  reg word_and_offset_valid = 1'b0;
  reg [DATA_WIDTH - 1:0] curr_word = {DATA_WIDTH{1'b0}};

  wire [ADDRESS_LENGTH - 1:0] addr;
  wire [DATA_WIDTH - 1:0] word_with_pixel_written;
  wire we;

  addr_to_pixel_writer dut(
    .clk(clk),
    .resetn(resetn),
    .word_address(word_address),
    .bit_offset(bit_offset),
    .word_and_offset_valid(word_and_offset_valid),
    .curr_word(curr_word),
    .addr(addr),
    .word_with_pixel_written(word_with_pixel_written),
    .we(we)
  );

  initial
  begin
    #15 resetn = 1'b1;

    #40
    @(posedge clk);
    word_address <= 14'h120; bit_offset <= 5'b0; word_and_offset_valid <= 1'b1;
    @(posedge clk);
    word_and_offset_valid <= 1'b0;
    repeat(2) @(posedge clk);
    curr_word <= 32'h00000120;
    wait(we);
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;

endmodule
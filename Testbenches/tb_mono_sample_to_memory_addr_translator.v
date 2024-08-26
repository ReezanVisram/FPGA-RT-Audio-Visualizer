`timescale 1ns / 1ps

module tb_mono_sample_to_memory_addr_translator;
  localparam CLK_PERIOD = 20;
  localparam DATA_WIDTH = 32;
  localparam ADDRESS_LENGTH = 14;
  localparam NUM_SAMPLES = 2000;

  reg clk = 1'b0;
  reg resetn = 1'b0;

  reg [DATA_WIDTH - 1:0] mono_sample = {DATA_WIDTH{1'b0}};

  reg fifo_almost_empty = 1'b1;

  wire fifo_rd_en;
  wire [ADDRESS_LENGTH - 1:0] word_address;
  wire [10:0] test;
  wire [4:0] bit_offset;
  wire word_and_offset_valid;

  mono_sample_to_memory_addr_translator dut(
    .clk(clk),
    .resetn(resetn),
    .mono_sample(mono_sample),
    .fifo_almost_empty(fifo_almost_empty),
    .fifo_rd_en(fifo_rd_en),
    .word_address(word_address),
    .bit_offset(bit_offset),
    .word_and_offset_valid(word_and_offset_valid),
    .test(test)
  );

  initial
  begin
    #15 resetn = 1'b1;
    #200 
    @(posedge clk); 
    fifo_almost_empty <= 1'b0;

    #500 resetn = 1'b0;
    @(posedge clk);
    fifo_almost_empty <= 1'b1;

    #30 resetn = 1'b1;
    @(posedge clk);
    mono_sample <= 32'h7FFFFF00; fifo_almost_empty <= 1'b0;
    wait(word_and_offset_valid == 1'b1);

    @(posedge clk);
    mono_sample <= 32'h80000100;
    wait(word_and_offset_valid == 1'b1);

  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;

endmodule
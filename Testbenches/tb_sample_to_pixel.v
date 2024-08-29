`timescale 1ns / 1ps

module tb_sample_to_pixel;
  localparam SCREEN_WIDTH=640;
  localparam SCREEN_HEIGHT=480;
  localparam ADDR_WIDTH=$clog2(SCREEN_WIDTH * SCREEN_HEIGHT);
  localparam DATA_WIDTH=32;
  localparam SMAPLE_WIDTH=24;
  localparam CLK_PERIOD=20;
  localparam NUM_SAMPLES=640;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  reg signed [DATA_WIDTH - 1:0] mono_sample = {DATA_WIDTH{1'b0}};
  reg fifo_almost_empty = 1'b1;
  
  wire fifo_rd_en;
  wire [ADDR_WIDTH - 1:0] pixel_addr;
  wire pixel_data;
  wire pixel_wr_en;

  integer f;

  sample_to_pixel dut(
    .clk(clk),
    .resetn(resetn),
    .mono_sample(mono_sample),
    .fifo_almost_empty(fifo_almost_empty),
    .fifo_rd_en(fifo_rd_en),
    .pixel_addr(pixel_addr),
    .pixel_data(pixel_data),
    .pixel_wr_en(pixel_wr_en)
  );

  framebuffer fbuffer(
    .wrclk(clk),
    .resetn(resetn),
    .wr_en(pixel_wr_en),
    .wr_addr(pixel_addr),
    .wr_data(pixel_data)
  );

  integer sample_line;
  reg signed [DATA_WIDTH - 1:0] sample_memory[0:NUM_SAMPLES - 1];

  integer i;
  integer j;
  initial 
  begin
    f = $fopen("memory2.txt", "w");
    #15 resetn = 1'b1;
    $readmemb("samples.txt", sample_memory);
    for (sample_line = 0; sample_line < NUM_SAMPLES; sample_line = sample_line + 1)
    begin
      @(posedge clk);
      fifo_almost_empty <= 1'b0; mono_sample <= sample_memory[sample_line];
      wait(fifo_rd_en == 1'b1);
      @(posedge clk);
      fifo_almost_empty <= 1'b1;
    end

    for (i = 0; i < SCREEN_HEIGHT; i = i + 1)
    begin
      for (j = 0; j < SCREEN_WIDTH; j = j + 1)
      begin
        $fwrite(f, "%0b", fbuffer.ram[i * SCREEN_WIDTH + j]);
      end
      $fwrite(f, "\n");
    end

    $fclose(f);
    $writememb("memory.txt", fbuffer.ram);
    #200 $finish;
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;

endmodule
// This module is the buffer that contains the bitmap
// It reads/writes individual pixels at a time

module framebuffer
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter ADDR_WIDTH=$clog2(SCREEN_WIDTH * SCREEN_HEIGHT)
)
(
  input wrclk,
  input rdclk,
  input resetn,
  input wr_en,
  input rd_en,
  input [ADDR_WIDTH - 1:0] wr_addr,
  input [ADDR_WIDTH - 1:0] rd_addr,
  input wr_data,
  output reg rd_data
);
  reg ram [0:(SCREEN_WIDTH * SCREEN_HEIGHT) - 1];
  integer i;

  always @(posedge wrclk)
  begin
    if (!resetn)
    begin
      `ifndef SYNTHESIS
        for (i = 0; i < (SCREEN_WIDTH * SCREEN_HEIGHT); i = i + 1)
          ram[i] <= 1'b0;
      `endif
    end 
    if (wr_en)
      ram[wr_addr] <= wr_data;
  end

  always @(posedge rdclk)
  begin
    if (rd_en)
      rd_data <= ram[rd_addr];
  end
endmodule
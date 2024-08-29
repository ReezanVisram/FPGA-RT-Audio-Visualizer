module vga_controller
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter TOTAL_COLS=800,
  parameter TOTAL_ROWS=525,
  parameter COORD_WIDTH=16
)(
  input clk,
  input resetn,
  input data_enable,
  input signed [COORD_WIDTH - 1:0] row,
  input signed [COORD_WIDTH - 1:0] col,
  input frame_pulse,
  input pixel_data,
  output reg framebuffer_rd_en,
  output reg [$clog2(SCREEN_WIDTH * SCREEN_HEIGHT) - 1:0] pixel_addr,
  output reg [3:0] red,
  output reg [3:0] blue,
  output reg [3:0] green,
  output reg hsync,
  output reg vsync
);

endmodule
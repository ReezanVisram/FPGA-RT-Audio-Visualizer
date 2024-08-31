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
  
  input pixel_data,

  input [11:0] waveform_colour,
  input [11:0] background_colour,

  output reg framebuffer_rd_en,
  output reg [$clog2(SCREEN_WIDTH * SCREEN_HEIGHT) - 1:0] pixel_addr,

  output reg [3:0] red,
  output reg [3:0] blue,
  output reg [3:0] green,
  output hsync,
  output vsync,
  output data_enable,
  output frame_pulse,
  output line_pulse
);
  localparam LATENCY = 2; // 1 Clock Cycle for determining `framebuffer_rd_en` and 1 Clock Cycle to get data from memory

  reg in_paint_area = 1'b0;

  wire signed [COORD_WIDTH - 1:0] sx;
  wire signed [COORD_WIDTH - 1:0] sy;

  vga_sync_ctrl_signal_gen gen(
    .clk(clk),
    .resetn(resetn),
    .sx(sx),
    .sy(sy),
    .hsync(hsync),
    .vsync(vsync),
    .data_enable(data_enable),
    .frame_pulse(frame_pulse),
    .line_pulse(line_pulse)
  );

  always @(posedge clk)
  begin
    framebuffer_rd_en <= (sy >= 0 && sy < SCREEN_HEIGHT && sx >= -LATENCY && sx < SCREEN_WIDTH - LATENCY);
    if (frame_pulse)
      pixel_addr <= 0;
    else if (framebuffer_rd_en)
      pixel_addr <= pixel_addr + 1;
  end

  always @(*)
  begin
    in_paint_area = (sy >= 0 && sy < SCREEN_HEIGHT && sx >= 0 && sx < SCREEN_WIDTH);
    if (in_paint_area)
    begin
      if (pixel_data)
      begin
        red = waveform_colour[3:0];
        green = waveform_colour[7:4];
        blue = waveform_colour[11:8];
      end
      else
      begin
        red = background_colour[3:0];
        green = background_colour[7:4];
        blue = background_colour[11:8];
      end
    end
    else
    begin
      red = 4'b000;
      blue = 4'b0000;
      green = 4'b0000;
    end
  end
endmodule
module vga_sync_ctrl_signal_gen
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter TOTAL_COLS=800,
  parameter TOTAL_ROWS=525,
  parameter COORD_WIDTH=16,
  
  parameter H_FRONT_PORCH = 16,
  parameter H_SYNC = 96,
  parameter H_BACK_PORCH = 48,

  parameter V_FRONT_PORCH = 10,
  parameter V_SYNC = 2,
  parameter V_BACK_PORCH = 33
)(
  input clk,
  input resetn,
  output reg signed [COORD_WIDTH - 1:0] sx,
  output reg signed [COORD_WIDTH - 1:0] sy,
  output reg hsync,
  output reg vsync,
  output reg data_enable,
  output reg frame_pulse,
  output reg line_pulse
);

  localparam signed H_START = 0 - H_FRONT_PORCH - H_SYNC - H_BACK_PORCH;
  localparam signed H_SYNC_START = H_START + H_FRONT_PORCH;
  localparam signed H_SYNC_END = H_SYNC_START + H_SYNC;
  localparam signed H_ACTIVE_START = 0;
  localparam signed H_ACTIVE_END = SCREEN_WIDTH - 1;

  localparam signed V_START = 0 - V_FRONT_PORCH - V_SYNC - V_BACK_PORCH;
  localparam signed V_SYNC_START = V_START + V_FRONT_PORCH;
  localparam signed V_SYNC_END = V_SYNC_START + V_SYNC;
  localparam signed V_ACTIVE_START = 0;
  localparam V_ACTIVE_END = SCREEN_HEIGHT - 1;

  reg signed [COORD_WIDTH - 1:0] x, y;

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      hsync <= 1'b1;
      vsync <= 1'b1;
    end
    else
    begin
      hsync <= ~(x >= H_SYNC_START && x < H_SYNC_END);
      vsync <= ~(y >= V_SYNC_START && y < V_SYNC_END);
    end
  end

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      data_enable <= 1'b0;
      frame_pulse <= 1'b0;
      line_pulse <= 1'b0;
    end
    else
    begin
      data_enable <= (y >= V_ACTIVE_START && x >= H_ACTIVE_START);
      frame_pulse <= (y == V_START && x == H_START);
      line_pulse <= (x == H_START);
    end
  end

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      x <= H_START;
      y <= V_START;
    end
    else
    begin
      if (x == H_ACTIVE_END)
      begin
        x <= H_START;
        y <= (y == V_ACTIVE_END) ? V_START : y + 1;
      end
      else
      begin
        x <= x + 1;
      end
    end
  end

  // Delay screen coordinates by one clock cycle to match the sync and control signals
  always @(posedge clk)
  begin
    if (!resetn)
    begin
      sx <= H_START;
      sy <= V_START;
    end
    else
    begin
      sx <= x;
      sy <= y;
    end
  end
endmodule
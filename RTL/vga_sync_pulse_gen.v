module vga_sync_pulse_gen
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter TOTAL_COLS=800,
  parameter TOTAL_ROWS=525,
  parameter COORD_WIDTH=16
)(
  input clk,
  input resetn,
  output reg signed [COORD_WIDTH - 1:0] row,
  output reg signed [COORD_WIDTH - 1:0] col,
  output hsync,
  output vsync,
  output data_enable,
  output frame_pulse
);

  parameter H_ACTIVE_END = 639; // End of active region
  parameter H_SYNC_START = H_ACTIVE_END + 16; // Start of Sync = End of Active Region + Front Porch
  parameter H_SYNC_END = H_SYNC_START + 96; 
  parameter ROW_END = 799; // Last pixel on the line (Active Region + Blanking Region)

  parameter V_ACTIVE_END = 479; // End of Active Region
  parameter V_SYNC_START = V_ACTIVE_END + 10; // Start of Sync = End of Active Region + Front Porch
  parameter V_SYNC_END = V_SYNC_START + 2;
  parameter SCREEN_END = 524; // Last line on screen (Active Region + Blanking Region)

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      row <= 1'b0;
      col <= 1'b0;
    end
    else
    begin
      if (col == ROW_END)
      begin
        row <= (row == SCREEN_END) ? 1'b0 : row + 1;
        col <= 1'b0;
      end
      else
      begin
        col <= col + 1;
      end
    end
  end


  assign hsync = ~(col >= H_SYNC_START && col < H_SYNC_END);
  assign vsync = ~(row >= V_SYNC_START && row < V_SYNC_END);
  assign data_enable = (col <= H_ACTIVE_END && row <= V_ACTIVE_END);
  assign frame_pulse = (col == 0) && (row == 0);
endmodule
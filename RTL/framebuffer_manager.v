module framebuffer_manager
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter ADDR_WIDTH=$clog2(SCREEN_WIDTH * SCREEN_HEIGHT),
  parameter DATA_WIDTH=32,
  parameter SAMPLE_WIDTH=24,
  parameter COORD_WIDTH=16
)
(
  input clk,
  input resetn,
  input frame_pulse, // This is in the pixel clock domain
  output reg [ADDR_WIDTH - 1:0] pixel_addr,
  output reg pixel_data,
  output reg pixel_wr_en,
  output reg clearing_framebuffer,
  output reg buffer_sel
);
  parameter [1:0] Idle = 2'b00, SwapBuffers = 2'b01, ClearBuffer = 2'b11, Done = 2'b10;
  reg [1:0] state = Idle;

  reg frame_pulse_q;
  reg frame_pulse_qd;
  reg frame_pulse_qdd;

  reg frame_pulse_sys;

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      state <= Idle;
    end
    else
    begin
      case (state)
        Idle:
        begin
          if (frame_pulse_sys)
            state <= SwapBuffers;
          else
            state <= Idle;
        end
        SwapBuffers:
        begin
          state <= ClearBuffer;
        end
        ClearBuffer:
        begin
          if (pixel_addr == (SCREEN_WIDTH * SCREEN_HEIGHT) - 1)
            state <= Done;
          else
            state <= ClearBuffer;
        end
        default: // Done
        begin
          state <= Idle;
        end
      endcase
    end
  end

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      pixel_addr <= 0;
      pixel_data <= 1'b0;
      clearing_framebuffer <= 1'b0;
      buffer_sel <= 1'b0;
      pixel_wr_en <= 1'b0;
    end
    else
    begin
      case (state)
        Idle:
        begin
          clearing_framebuffer <= 1'b0;
          pixel_wr_en <= 1'b0;
        end
        SwapBuffers:
        begin
          pixel_addr <= 0;
          pixel_data <= 1'b0;
          clearing_framebuffer <= 1'b1;
          buffer_sel <= ~buffer_sel;
          pixel_wr_en <= 1'b0;
        end
        ClearBuffer:
        begin
          pixel_addr <= pixel_addr + 1;
          pixel_wr_en <= 1'b1;
        end
        default: // Done
        begin
          clearing_framebuffer <= 1'b0;
          pixel_wr_en <= 1'b0;
        end
      endcase
    end
  end

  // Cross frame_pulse from 25.2 MHz clock domain to 100 MHz clock domain
  always @(posedge clk)
  begin
    frame_pulse_q <= frame_pulse;
    frame_pulse_qd <= frame_pulse_q;
    frame_pulse_qdd <= frame_pulse_qd;

    if (frame_pulse_qdd == 1'b0 && frame_pulse_qd == 1'b1)
      frame_pulse_sys = 1'b1;
    else
      frame_pulse_sys = 1'b0;
  end
endmodule
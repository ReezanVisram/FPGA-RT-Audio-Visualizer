module sample_to_pixel
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter ADDR_WIDTH=$clog2(SCREEN_WIDTH * SCREEN_HEIGHT),
  parameter DATA_WIDTH=32,
  parameter SAMPLE_WIDTH=24,
  parameter COORD_WIDTH=16
)(
  input clk,
  input resetn,
  input frame_pulse, // In Pixel Clock domain
  input signed [SAMPLE_WIDTH - 1:0] mono_sample,
  input fifo_almost_empty,
  input clearing_framebuffer,
  output reg fifo_rd_en,
  output reg [ADDR_WIDTH - 1:0] pixel_addr,
  output reg pixel_data,
  output reg pixel_wr_en
);

  localparam SCREEN_MIDDLE_ROW = (SCREEN_HEIGHT / 2) - 1;
  
  parameter [7:0] WaitForSample=8'b00000001, 
                  ReadyToReadSample = 8'b00000010, 
                  ReadSample = 8'b00000100, 
                  CalculatePixelAddr1 = 8'b00001000,
                  CalculatePixelAddr2 = 8'b00010000,
                  CalculatePixelAddr3 = 8'b00100000, 
                  RunBresenham = 8'b01000000,
                  WaitForNextFrame = 8'b10000000;
  
  reg [7:0] state = WaitForSample;
  reg signed [COORD_WIDTH - 1:0] counter = {COORD_WIDTH{1'b0}};
  reg signed [SAMPLE_WIDTH - 1:0] sample_q;

  reg signed [COORD_WIDTH - 1:0] unclamped_row;
  reg signed [COORD_WIDTH - 1:0] row;
  reg signed [COORD_WIDTH - 1:0] prev_row;

  reg run_bresenham = 1'b0;

  wire [ADDR_WIDTH - 1:0] bresenham_pixel_addr;
  wire bresenham_pixel_data;
  wire bresenham_complete;
  wire bresenham_valid; // Bresenham may be multicycle so need this to decide when to write pixel_addr and pixel_data

  reg frame_pulse1;
  reg frame_pulse1_d;
  reg frame_pulse1_dd;

  reg start_of_new_frame = 1'b0;

  bresenham br(
    .clk(clk),
    .resetn(resetn),
    .start(run_bresenham),
    .x1(counter - 1),
    .y1(prev_row),
    .x2(counter),
    .y2(row),
    .pixel_addr(bresenham_pixel_addr),
    .pixel_data(bresenham_pixel_data),
    .pixel_addr_and_data_valid(bresenham_valid),
    .done(bresenham_complete)
  );

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      state <= WaitForSample;
    end
    else
    begin
      case (state)
        WaitForSample:
        begin
          if (!fifo_almost_empty && !clearing_framebuffer)
            state <= ReadyToReadSample;
          else
            state <= WaitForSample;
        end
        ReadyToReadSample:
        begin
          state <= ReadSample;
        end
        ReadSample:
        begin
          state <= CalculatePixelAddr1;
        end
        CalculatePixelAddr1:
        begin
          state <= CalculatePixelAddr2;
        end
        CalculatePixelAddr2:
        begin
          state <= CalculatePixelAddr3;
        end
        CalculatePixelAddr3:
        begin
          if (counter > 1)
            state <= RunBresenham;
          else
            state <= WaitForSample;
        end
        RunBresenham:
        begin
          if (bresenham_complete)
          begin
            if (counter == SCREEN_WIDTH - 1)
              state <= WaitForNextFrame;
            else
              state <= WaitForSample;
          end
          else
            state <= RunBresenham;
        end
        default: // WaitForNextFrame
        begin
          if (start_of_new_frame)
            state <= WaitForSample;
          else
            state <= WaitForNextFrame;
        end
      endcase
    end
  end

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      counter <= {COORD_WIDTH{1'b0}};
      run_bresenham <= 1'b0;
    end
    else
    begin
      fifo_rd_en <= 1'b0;
      run_bresenham <= 1'b0;
      pixel_wr_en <= 1'b0;

      case (state)
        WaitForSample:
        begin
          
        end
        ReadyToReadSample:
        begin
          fifo_rd_en <= 1'b1;
        end
        ReadSample:
        begin
          sample_q <= mono_sample;
        end
        CalculatePixelAddr1:
        begin
          unclamped_row <= $signed((($signed(SCREEN_MIDDLE_ROW) * sample_q) >>> 23));
        end
        CalculatePixelAddr2:
        begin
          prev_row <= row;
          row <= $signed(SCREEN_MIDDLE_ROW) - $signed(unclamped_row);
        end
        CalculatePixelAddr3:
        begin
          pixel_addr <= !run_bresenham ? (row * SCREEN_WIDTH) + counter : bresenham_pixel_addr;
          pixel_data <= !run_bresenham ? 1'b1 : bresenham_pixel_data;
          pixel_wr_en <= 1'b1;
          counter <= counter + 1;
        end
        RunBresenham:
        begin
          run_bresenham <= 1'b1;
          if (bresenham_valid)
          begin
            pixel_addr <= run_bresenham ? bresenham_pixel_addr : (row * SCREEN_WIDTH) + counter;
            pixel_data <= run_bresenham ? bresenham_pixel_data : 1'b1;
            pixel_wr_en <= 1'b1;
          end
          else
          begin
            pixel_wr_en <= 1'b0;
          end
        end
        default: // WaitForNextFrame
        begin
          counter <= 1'b0;
        end
      endcase
    end
  end

  // Cross frame_pulse from 25.2 MHz clock domain to 100 MHz clock domain
  always @(posedge clk)
  begin
    frame_pulse1 <= frame_pulse;
    frame_pulse1_d <= frame_pulse1;
    frame_pulse1_dd <= frame_pulse1_d;

    if (frame_pulse1_dd == 1'b0 && frame_pulse1_d == 1'b1)
    begin
      start_of_new_frame <= 1'b1;
    end
    else
    begin
      start_of_new_frame <= 1'b0;
    end
  end

endmodule
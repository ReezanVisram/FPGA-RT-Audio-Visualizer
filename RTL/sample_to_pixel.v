module sample_to_pixel
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter ADDR_WIDTH=$clog2(SCREEN_WIDTH * SCREEN_HEIGHT),
  parameter DATA_WIDTH=32,
  parameter SAMPLE_WIDTH=24,
  parameter COUNTER_WIDTH=$clog2(SCREEN_WIDTH)
)(
  input clk,
  input resetn,
  // TODO: Add VGA Vsync signal to reset
  input signed [DATA_WIDTH - 1:0] mono_sample,
  input fifo_almost_empty,
  output reg fifo_rd_en,
  output reg [ADDR_WIDTH - 1:0] pixel_addr,
  output reg pixel_data,
  output reg pixel_wr_en
);

  localparam SCREEN_MIDDLE_ROW = (SCREEN_HEIGHT / 2) - 1;
  
  parameter [6:0] WaitForSample=7'b0000001, 
                  ReadyToReadSample = 7'b0000010, 
                  ReadSample = 7'b0000100, 
                  CalculatePixelAddr1 = 7'b0001000,
                  CalculatePixelAddr2 = 7'b0010000,
                  CalculatePixelAddr3 = 7'b0100000, 
                  RunBresenham = 7'b1000000;
  
  reg [6:0] state = WaitForSample;
  reg [COUNTER_WIDTH - 1:0] counter = {COUNTER_WIDTH{1'b0}};
  reg signed [SAMPLE_WIDTH - 1:0] sample_q;

  reg signed [$clog2(SCREEN_WIDTH) - 1:0] unclamped_row;
  reg [$clog2(SCREEN_WIDTH) - 1:0] row;
  reg [$clog2(SCREEN_WIDTH) - 1:0] prev_row;

  reg run_bresenham = 1'b0;

  wire [ADDR_WIDTH - 1:0] bresenham_pixel_addr;
  wire bresenham_pixel_data;
  wire bresenham_complete;
  wire bresenham_valid; // Bresenham may be multicycle so need this to decide when to write pixel_addr and pixel_data

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
      counter <= {COUNTER_WIDTH{1'b0}};
      run_bresenham <= 1'b0;
    end
    else
    begin
      case (state)
        WaitForSample:
        begin
          if (!fifo_almost_empty)
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
        default: // RunBresenham
        begin
          if (bresenham_complete)
            state <= WaitForSample;
          else
            state <= RunBresenham;
        end
      endcase
    end
  end

  always @(posedge clk)
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
        sample_q <= mono_sample[DATA_WIDTH - 1:(DATA_WIDTH - SAMPLE_WIDTH)];
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
      default: // RunBresenham
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
    endcase
  end

endmodule
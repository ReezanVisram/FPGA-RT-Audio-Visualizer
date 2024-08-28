module bresenham
#(
  parameter SCREEN_WIDTH=640,
  parameter SCREEN_HEIGHT=480,
  parameter ADDR_WIDTH=$clog2(SCREEN_WIDTH * SCREEN_HEIGHT),
  parameter DATA_WIDTH=32,
  parameter SAMPLE_WIDTH=24,
  parameter COUNTER_WIDTH = $clog2(SCREEN_WIDTH)
)(
  input clk,
  input resetn,
  input start,
  input [COUNTER_WIDTH - 1:0] x1,
  input [$clog2(SCREEN_WIDTH) - 1:0] y1,
  input [COUNTER_WIDTH - 1:0] x2,
  input [$clog2(SCREEN_WIDTH) - 1:0] y2,
  output reg [ADDR_WIDTH - 1:0] pixel_addr,
  output reg pixel_data,
  output reg pixel_addr_and_data_valid,
  output reg done
);
  parameter [5:0] Idle = 6'b000001, 
                  CalculateSteps = 6'b000010, 
                  RegisterCoordinates = 6'b000100,
                  CalculateNewCoordinates = 6'b001000,
                  ConvertCoordinatesToAddress = 6'b010000,
                  Done = 6'b100000;

  reg [5:0] state = Idle;

  reg swap;
  reg [$clog2(SCREEN_WIDTH) - 1:0] xa, ya;
  reg [$clog2(SCREEN_WIDTH) - 1:0] xb, yb;
  reg [$clog2(SCREEN_WIDTH) - 1:0] x_end, y_end;

  reg [$clog2(SCREEN_WIDTH) - 1:0] x, y;

  // A bit wider since they are signed
  reg signed [$clog2(SCREEN_WIDTH):0] err;
  reg signed [$clog2(SCREEN_WIDTH):0] dx, dy;

  reg movx, movy;
 
  always @(*)
  begin
    swap = y1 > y2;
    xa = swap ? x2 : x1;
    xb = swap ? x1 : x2;
    ya = swap ? y2 : y1;
    yb = swap ? y1 : y2;
  end

  always @(*)
  begin
    movx = (2*err >= dy);
    movy = (2*err <= dx);
  end

  always @(posedge clk)
  begin
    if (!resetn)
      state <= Idle;
    else
    begin
      case (state)
        Idle:
        begin
          if (start)
            state <= CalculateSteps;
          else
            state <= Idle;
        end
        CalculateSteps:
        begin
          state <= RegisterCoordinates;
        end
        RegisterCoordinates:
        begin
          state <= CalculateNewCoordinates;
        end
        CalculateNewCoordinates:
        begin
          state <= ConvertCoordinatesToAddress;
        end
        ConvertCoordinatesToAddress:
        begin
          if (x == x_end && y == y_end)
            state <= Done;
          else
            state <= CalculateNewCoordinates;
        end
        default: // Done
        begin
          if (start)
            state <= Done;
          else
            state <= Idle;
        end
      endcase
    end
  end

  always @(posedge clk)
  begin
    done <= 1'b0;
    pixel_addr_and_data_valid <= 1'b0;
    case (state)
      Idle:
      begin
        x <= 0;
        y <= 0;
        dx <= 0;
        dy <= 0;
        x_end <= 0;
        y_end <= 0;
        err <= 0;
      end
      CalculateSteps:
      begin
        dx <= xa < xb ? xb - xa : xa - xb;
        dy <= ya - yb;
      end
      RegisterCoordinates:
      begin
        err <= dx + dy;
        x <= xa;
        y <= ya;
        x_end <= xb;
        y_end <= yb;
      end
      CalculateNewCoordinates:
      begin
        if (movx)
        begin
          x <= xa < xb ? x + 1 : x - 1;
          err <= err + dy;
        end
        if (movy)
        begin
          y <= y + 1;
          err <= err + dx;
        end
        if (movx && movy)
        begin
          x <= xa < xb ? x + 1 : x - 1;
          y <= y + 1;
          err <= err + dx + dy;
        end
      end
      ConvertCoordinatesToAddress:
      begin
        pixel_addr <= (y * SCREEN_WIDTH) + x;
        pixel_data <= 1'b1;
        pixel_addr_and_data_valid <= 1'b1;
      end
      default: // Done
      begin
        done <= 1'b1;
      end
    endcase
  end

endmodule
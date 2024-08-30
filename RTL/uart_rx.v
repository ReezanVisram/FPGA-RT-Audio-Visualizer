// Clock frequency is 25.2 MHz and baud rate is 115200
// Reusing VGA frequency so no need to cross the UART data into the VGA clock domain where it will be used

module uart_rx
#(
  parameter CLK_CYCLES_PER_BIT=219 
)
(
  input clk,
  input resetn,
  input rx_data,
  output reg data_valid,
  output reg [7:0] data
);

  parameter [4:0] Idle = 5'b00001, SampleStartBit = 5'b00010, SampleDataBits = 5'b00100, SampleStopBit = 5'b01000, Done = 5'b10000;
  reg [4:0] state = Idle;

  localparam COUNTER_WIDTH = $clog2(CLK_CYCLES_PER_BIT);

  // Double flop incoming rx data to reduce chance of metastability
  reg rx_data_q;
  reg rx_data_qd;
  reg rx_data_qdd;

  reg [COUNTER_WIDTH - 1:0] clock_counter = {COUNTER_WIDTH{1'b0}};
  reg [2:0] bit_index;

  always @(posedge clk)
  begin
    rx_data_q <= rx_data;
    rx_data_qd <= rx_data_q;
    rx_data_qdd <= rx_data_qd;
  end

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
          if (rx_data_qdd == 1'b0) // Start bit detected
            state <= SampleStartBit;
          else
            state <= Idle;
        end
        SampleStartBit:
        begin
          if (clock_counter == (CLK_CYCLES_PER_BIT - 1) / 2) // At middle of start bit to make sure it is still low
          begin
            if (rx_data_qdd == 1'b0)
            begin
              state <= SampleDataBits;
            end
            else
            begin
              state <= Idle;
            end
          end
          else
            state <= SampleStartBit;
        end
        SampleDataBits:
        begin
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
          begin
            state <= SampleDataBits;
          end
          else
          begin
            if (bit_index < 7)
              state <= SampleDataBits;
            else
              state <= SampleStopBit;
          end
        end
        SampleStopBit:
        begin
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
          begin
            state <= SampleStopBit;
          end
          else
            state <= Done;
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
      data_valid <= 1'b0;
      clock_counter <= {COUNTER_WIDTH{1'b0}};
      bit_index <= 1'b0;
    end
    else
    begin
      case (state)
        Idle:
        begin
          data_valid <= 1'b0;
          clock_counter <= {COUNTER_WIDTH{1'b0}};
          bit_index <= 1'b0;
        end
        SampleStartBit:
        begin
          if (clock_counter == (CLK_CYCLES_PER_BIT - 1) / 2)
          begin
            if (rx_data_qdd == 1'b0)
              clock_counter <= {COUNTER_WIDTH{1'b0}};
          end
          else
            clock_counter <= clock_counter + 1;
        end
        SampleDataBits:
        begin
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            clock_counter <= clock_counter + 1;
          else
          begin
            clock_counter <= {COUNTER_WIDTH{1'b0}};
            data[bit_index] <= rx_data_qdd;
            if (bit_index < 7)
              bit_index <= bit_index + 1;
            else
              bit_index <= 0;
          end
        end
        SampleStopBit:
        begin
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            clock_counter <= clock_counter + 1;
          else
          begin
            data_valid <= 1'b1;
            clock_counter <= {COUNTER_WIDTH{1'b0}};
          end
        end
        default: // Done
        begin
          data_valid <= 1'b0;
        end
      endcase
    end
  end

endmodule
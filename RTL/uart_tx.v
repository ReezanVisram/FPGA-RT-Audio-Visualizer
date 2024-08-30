// Clock frequency is 25.2 MHz and baud rate is 115200 
// Reusing VGA frequency so no need to cross bitmap data into a different clock domain

module uart_tx
#(
  parameter CLK_CYCLES_PER_BIT=219
)
(
  input clk,
  input resetn,
  input data_valid,
  input [7:0] data,
  output reg tx_active,
  output reg tx_data,
  output reg tx_done
);

  parameter [4:0] Idle = 5'b00001, TransmitStartBit = 5'b00010, TransmitDataBits = 5'b00100, TransmitStopBit = 5'b01000, Done = 5'b10000;
  reg [4:0] state = Idle;

  localparam COUNTER_WIDTH = $clog2(CLK_CYCLES_PER_BIT);

  reg [COUNTER_WIDTH - 1:0] clock_counter = {COUNTER_WIDTH{1'b0}};
  reg [2:0] bit_index;
  reg [7:0] data_q;

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
          if (data_valid)
            state <= TransmitStartBit;
          else
            state <= Idle;
        end
        TransmitStartBit:
        begin
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            state <= TransmitStartBit;
          else
            state <= TransmitDataBits;
        end
        TransmitDataBits:
        begin
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            state <= TransmitDataBits;
          else
          begin
            if (bit_index < 7)
              state <= TransmitDataBits;
            else
              state <= TransmitStopBit;
          end
        end
        TransmitStopBit:
        begin
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            state <= TransmitStopBit;
          else
            state <= Done;
        end
        default: // Done
          state <= Idle;
      endcase
    end
  end

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      tx_data <= 1'b1;
      tx_done <= 1'b0;
      clock_counter <= {COUNTER_WIDTH{1'b0}};
      bit_index <= 0;
    end
    else
    begin
      case (state)
        Idle:
        begin
          tx_data <= 1'b1; // Line is high while idling
          tx_done <= 1'b0;
          clock_counter <= {COUNTER_WIDTH{1'b0}};
          bit_index <= 0;

          if (data_valid)
          begin
            tx_active <= 1'b1;
            data_q <= data;
          end
        end
        TransmitStartBit:
        begin
          tx_data <= 1'b0;
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            clock_counter <= clock_counter + 1;
          else
            clock_counter <= {COUNTER_WIDTH{1'b0}};
        end
        TransmitDataBits:
        begin
          tx_data <= data_q[bit_index];
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            clock_counter <= clock_counter + 1;
          else
          begin
            clock_counter <= {COUNTER_WIDTH{1'b0}};
            if (bit_index < 7)
              bit_index <= bit_index + 1;
            else
              bit_index <= 0;
          end
        end
        TransmitStopBit:
        begin
          tx_data <= 1'b1; // Stop bit is 1
          if (clock_counter < CLK_CYCLES_PER_BIT - 1)
            clock_counter <= clock_counter + 1;
          else
          begin
            tx_done <= 1'b1;
            clock_counter <= {COUNTER_WIDTH{1'b0}};
            tx_active <= 1'b0;
          end
        end
        default: // Done
            tx_done <= 1'b0;
      endcase
    end
  end

endmodule
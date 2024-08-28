module addr_to_pixel_writer
#(
  parameter DATA_WIDTH = 32,
  parameter ADDRESS_LENGTH = 14
)
(
  input clk,
  input resetn,
  input [ADDRESS_LENGTH - 1:0] word_address,
  input [4:0] bit_offset,
  input word_and_offset_valid,
  input [DATA_WIDTH - 1:0] curr_word,
  output reg [ADDRESS_LENGTH - 1:0] addr,
  output reg [DATA_WIDTH - 1:0] word_with_pixel_written,
  output reg we
);

  parameter [1:0] Idle = 2'b00, SetReadAddress = 2'b01, ReadWordFromMemory = 2'b11, WriteWordToMemory = 2'b10;
  reg [1:0] state = Idle;
  
  always @(posedge clk)
  begin
    if (!resetn)
      state <= Idle;
    else
    begin
      case (state)
        Idle:
        begin
          if (word_and_offset_valid)
            state <= SetReadAddress;
          else
            state <= Idle;
        end
        SetReadAddress:
        begin
          state <= ReadWordFromMemory;
        end
        ReadWordFromMemory:
        begin
          state <= WriteWordToMemory;
        end
        default: // WriteWordToMemory
        begin
          state <= Idle;
        end
      endcase
    end
  end

  always @(posedge clk)
  begin
    we <= 1'b0;
    case (state)
      Idle:
      begin
      end
      SetReadAddress:
      begin
        addr <= word_address;
      end
      ReadWordFromMemory:
      begin
        
      end
      default: // WriteWordToMemory
      begin
        we <= 1'b1;
        word_with_pixel_written <= curr_word | ((2 ** (DATA_WIDTH - 1)) >> bit_offset);
      end
    endcase
  end

endmodule
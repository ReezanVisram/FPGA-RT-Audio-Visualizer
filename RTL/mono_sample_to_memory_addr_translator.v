module mono_sample_to_memory_addr_translator
#(
  parameter DATA_WIDTH = 32,
  parameter ADDRESS_LENGTH = 14
)
(
  input clk,
  input resetn,
  // TODO: Add VGA VSYNC signal to reset counter
  input signed [DATA_WIDTH - 1:0] mono_sample,
  input fifo_almost_empty,
  output reg fifo_rd_en,
  output reg [ADDRESS_LENGTH - 1:0] word_address,
  output reg [4:0] bit_offset,
  output reg word_and_offset_valid
);
  parameter [4:0] Idle = 5'b00001, ReadyToReadSample = 5'b00010, StoreSample = 5'b00100, ScaleSample1 = 5'b01000, ScaleSample2 = 5'b10000;
  reg [4:0] state = Idle;
  reg [9:0] sample_counter = 1'b0;
  reg signed [23:0] mono_sample_copy;
  reg signed [32:0] scaled_mono_sample;

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      state <= Idle;
      sample_counter <= 1'b0;
    end
    else
    begin
      case (state)
        Idle:
        begin
          if (!fifo_almost_empty)
            state <= ReadyToReadSample;
          else
            state <= Idle;
        end
        ReadyToReadSample:
        begin
          state <= StoreSample;
        end
        StoreSample:
        begin
          state <= ScaleSample1;
        end
        ScaleSample1:
        begin
          state <= ScaleSample2;
        end
        default: // ScaleSample2
        begin
          state <= Idle;
        end
      endcase
    end
  end

  always @(posedge clk)
  begin
    fifo_rd_en <= 1'b0;
    word_and_offset_valid <= 1'b0;
    case (state)
      Idle:
      begin
        
      end
      ReadyToReadSample:
      begin
        fifo_rd_en <= 1'b1;
      end
      StoreSample:
      begin
        mono_sample_copy <= mono_sample[31:8];
        sample_counter <= sample_counter + 1;
      end
      ScaleSample1:
      begin
        scaled_mono_sample <= 288 * mono_sample_copy;
      end
      default: // ScaleSample2
      begin
        word_address <= ($signed(288) - $signed($signed(scaled_mono_sample) >>> 23)) * 24 + (sample_counter >> 5);
        bit_offset <= sample_counter % 32;
        word_and_offset_valid <= 1'b1;
      end
    endcase
  end

endmodule
module packet_to_mono_sample_converter
#(
  parameter DATA_WIDTH=32
)
(
  input S_AXIS_ACLK,
  input S_AXIS_ARESETN,
  input S_AXIS_TVALID,
  input S_AXIS_TLAST,
  input [DATA_WIDTH - 1:0] S_AXIS_TDATA,
  output reg S_AXIS_TREADY,

  output reg mono_sample_valid,
  output reg [DATA_WIDTH - 1:0] mono_sample
);
  reg sample_counter = 1'b0;
  reg [DATA_WIDTH - 1:0] samples [1:0];

  parameter [1:0] AcceptData = 2'b00, StoreData1 = 2'b01, StoreData2 = 2'b11, CalculateMono = 2'b10;
  reg [1:0] state = AcceptData;

  reg tvalidd;
  reg tvalid_rise;

  reg tlastd;
  reg tlast_rise;

  always @(posedge S_AXIS_ACLK)
  begin
    tvalidd <= S_AXIS_TVALID;
    if (S_AXIS_TVALID && !tvalidd)
      tvalid_rise <= 1'b1;
    else
      tvalid_rise <= 1'b0;
  end

  always @(posedge S_AXIS_ACLK)
  begin
    tlastd <= S_AXIS_TLAST;
    if (S_AXIS_TLAST & !tlastd)
      tlast_rise <= 1'b1;
    else
      tlast_rise <= 1'b0;
  end


  always @(posedge S_AXIS_ACLK)
  begin    
    if (!S_AXIS_ARESETN)
      state <= AcceptData;
    else
    begin
      case (state)
        AcceptData:
        begin
          if (tvalid_rise && tlast_rise)
            state <= StoreData2;
          else if (tvalid_rise && !tlast_rise)
            state <= StoreData1;
          else
            state <= AcceptData;
        end
        StoreData1:
        begin
            state <= AcceptData;
        end 
        StoreData2:
        begin
          state <= CalculateMono;
        end
        default: // Calculate Mono
        begin
          state <= AcceptData;
        end
      endcase
    end
  end

  always @(posedge S_AXIS_ACLK)
  begin
    mono_sample_valid <= 1'b0;
    case (state)
      AcceptData:
      begin
        samples[sample_counter] <= S_AXIS_TDATA;
      end
      StoreData1:
      begin
        sample_counter <= sample_counter + 1;
      end
      StoreData2:
      begin
        sample_counter <= sample_counter + 1;
      end
      default: // CalculateMono
      begin
        mono_sample <= (samples[0] + samples[1]) >> 1;
        mono_sample_valid <= 1'b1;
      end
    endcase
  end

  always @(*)
  begin
    case (state)
      AcceptData:
      begin
        S_AXIS_TREADY = 1'b1;
      end
      default: // CalculateMono and StoreData1/StoreData2
      begin
        S_AXIS_TREADY = 1'b0;
      end
    endcase
  end
endmodule
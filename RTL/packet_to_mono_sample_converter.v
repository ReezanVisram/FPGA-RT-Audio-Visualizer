module packet_to_mono_sample_converter
#(
  parameter DATA_WIDTH=32,
  parameter SAMPLE_WIDTH=24
)
(
  input S_AXIS_ACLK,
  input S_AXIS_ARESETN,
  input S_AXIS_TVALID,
  input S_AXIS_TLAST,
  input signed [DATA_WIDTH - 1:0] S_AXIS_TDATA,
  output reg S_AXIS_TREADY,

  output reg mono_sample_valid,
  output reg signed [SAMPLE_WIDTH - 1:0] mono_sample
);
  reg sample_counter = 1'b0;
  reg signed [SAMPLE_WIDTH - 1:0] samples [1:0];
  reg signed [SAMPLE_WIDTH:0] sum_samples;

  parameter [4:0] AcceptData = 5'b00001, StoreData1 = 5'b00010, StoreData2 = 5'b00100, CalculateMono1 = 5'b01000, CalculateMono2 = 5'b10000;
  reg [4:0] state = AcceptData;

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
    begin
      state <= AcceptData;
    end
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
          state <= CalculateMono1;
        end
        CalculateMono1: // CalculateMono
        begin
          state <= CalculateMono2;
        end
        default: // CalculateMono2
        begin
          state <= AcceptData;
        end
      endcase
    end
  end

  always @(posedge S_AXIS_ACLK)
  begin
    mono_sample_valid <= 1'b0;
    if (!S_AXIS_ARESETN)
    begin
      `ifndef SYNTHESIS
        samples[0] <= {SAMPLE_WIDTH{1'b0}};
        samples[1] <= {SAMPLE_WIDTH{1'b0}};
      `endif
    end
    else
    begin
      case (state)
        AcceptData:
        begin
          samples[sample_counter] <= S_AXIS_TDATA[DATA_WIDTH - 1:(DATA_WIDTH - SAMPLE_WIDTH)];
          sum_samples <= {DATA_WIDTH{1'b0}};
        end
        StoreData1:
        begin
          sample_counter <= sample_counter + 1;
        end
        StoreData2:
        begin
          sample_counter <= sample_counter + 1;
        end
        CalculateMono1: // CalculateMono
        begin
          sum_samples <= samples[0] + samples[1];
        end
        default: // CalculateMono2
        begin
          mono_sample <= sum_samples >>> 1;
          mono_sample_valid <= 1'b1;
          `ifndef SYNTHESIS
            if (^samples[0] === 1'bX || ^samples[1] === 1'bX)
              mono_sample_valid <= 1'b0;
          `endif
        end
      endcase
    end

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
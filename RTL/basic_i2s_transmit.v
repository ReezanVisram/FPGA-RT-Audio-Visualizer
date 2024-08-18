module basic_i2s_transmit
#(
  DATA_WIDTH=32  
)(
  input clk,
  input ws,
  input sck,
  input [DATA_WIDTH - 1:0] data_left,
  input [DATA_WIDTH - 1:0] data_right,
  output reg sd
);

  reg sckd;
  reg sckdd;
  wire sck_rise;
  wire sck_fall;

  reg wsd;
  reg wsdd;

  wire wsp;

  reg [DATA_WIDTH - 1:0] data;

  always @(posedge clk)
  begin
    sckd <= sck;
    sckdd <= sckd;
  end

  always @(posedge clk)
  begin
    if (sck_rise)
    begin
      wsd <= ws;
    end
    wsdd <= wsd;
  end

  always @(posedge clk)
  begin
    if (wsp)
    begin
      data <= wsd ? data_right : data_left;
    end
    else if (sck_rise)
      data <= {data, 1'b0};
  end

  always @(negedge sck)
    sd <= data[DATA_WIDTH - 1];

  assign sck_rise = sckd & ~sckdd;
  assign sck_fall = ~sckd & sckdd;
  assign wsp = wsd ^ wsdd;

endmodule
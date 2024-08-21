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

  reg [2:0] mclk_counter = 3'b0;

  reg sck_rise;
  reg sck_fall;

  reg wsd;
  reg wsdd;

  wire wsp;

  reg [DATA_WIDTH - 1:0] data;

  always @(posedge clk)
  begin
    mclk_counter <= mclk_counter + 1;
    if (mclk_counter == 3'b100)
      sck_rise <= 1'b1;
    else
      sck_rise <= 1'b0;
    
    if (mclk_counter == 3'b000)
      sck_fall <= 1'b1;
    else
      sck_fall <= 1'b0;
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


  assign wsp = wsd ^ wsdd;

endmodule
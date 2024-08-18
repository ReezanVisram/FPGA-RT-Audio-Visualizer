module basic_i2s_receive
#(
  parameter DATA_WIDTH=32
)
(
  input clk,
  input sck,
  input ws,
  input sd,
  output reg [DATA_WIDTH - 1:0] data_left,
  output reg [DATA_WIDTH - 1:0] data_right
);

  reg wsd;
  reg wsdd;
  wire wsp;

  reg [$clog2(DATA_WIDTH + 1) - 1:0] counter = 6'b0;

  integer i;

  reg [DATA_WIDTH - 1:0] data;

  wire sck_rise;
  wire sck_fall;
  reg sckd;
  reg sckdd;

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
      wsdd <= wsd;      
    end
  end

  always @(posedge clk)
  begin
    if (sck_fall)
    begin
      if (wsp)
        counter <= 6'b0;
      else
      begin
        if (counter < DATA_WIDTH)
          counter <= counter + 1;
      end
    end
  end

  always @(posedge clk)
  begin
    if (sck_rise)
    begin
      if (wsp)
      begin
        data <= {DATA_WIDTH{1'b0}};
        data[DATA_WIDTH - 1] <= sd; // When wsp is high, counter == 0
      end
      else
      begin
        if (counter < DATA_WIDTH)
          data[DATA_WIDTH - 1 - counter] <= sd;       
      end
    end

  end

  always @(posedge clk)
  begin
    if (sck_rise)
    begin
      if (wsd & wsp)
        data_left <= data;
      else if (~wsd & wsp)
        data_right <= data;
    end
  end


  assign wsp = wsd ^ wsdd;
  assign sck_rise = sckd & ~sckdd;
  assign sck_fall = ~sckd & sckdd;
endmodule
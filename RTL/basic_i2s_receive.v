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
  reg [2:0] mclk_counter = 3'b0;

  integer i;

  reg [DATA_WIDTH - 1:0] data;

  reg sck_rise = 1'b0;
  reg sck_fall = 1'b0;

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
endmodule
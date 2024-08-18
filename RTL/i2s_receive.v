module i2s_receive
#(
  parameter DATA_WIDTH=32
)
(
  input M_AXIS_ACLK,
  input M_AXIS_ARESETN,
  input M_AXIS_TREADY,
  output reg M_AXIS_TVALID,
  output reg [DATA_WIDTH - 1:0] M_AXIS_TDATA,
  output reg M_AXIS_TLAST,

  input sck,
  input ws,
  input sd
);

  reg wsd;
  reg wsdd;
  wire wsp;

  reg [$clog2(DATA_WIDTH + 1) - 1:0] counter = 6'b0;

  integer i;

  reg [DATA_WIDTH - 1:0] data = {DATA_WIDTH{1'b0}};

  wire sck_rise;
  wire sck_fall;

  reg [1:0] sck_sync;
  always @(posedge M_AXIS_ACLK)
  begin
    sck_sync <= {sck_sync, sck};
  end

  always @(posedge M_AXIS_ACLK)
  begin
    if (sck_rise)
    begin
      wsd <= ws;
      wsdd <= wsd;      
    end
  end

  always @(posedge M_AXIS_ACLK)
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

  always @(posedge M_AXIS_ACLK)
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

  always @(posedge M_AXIS_ACLK)
  begin
    if (sck_rise && wsp)
    begin
      M_AXIS_TDATA <= data;
    end
  end

  always @(posedge M_AXIS_ACLK)
  begin
    if (!M_AXIS_ARESETN)
      M_AXIS_TVALID <= 0;
    else if (sck_rise && wsp)
      M_AXIS_TVALID <= 1;
    else if (M_AXIS_TREADY)
      M_AXIS_TVALID <= 0;
  end

  always @(posedge M_AXIS_ACLK)
  begin
    if (sck_rise && wsp)
      M_AXIS_TLAST <= !wsd;
  end


  assign wsp = wsd ^ wsdd;
  assign sck_rise = sck_sync == 2'b01;
  assign sck_fall = sck_sync == 2'b10;
endmodule
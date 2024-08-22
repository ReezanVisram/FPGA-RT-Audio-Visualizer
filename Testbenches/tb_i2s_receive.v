module tb_i2s_receive;
  parameter DATA_WIDTH=32;
  parameter MCLK_PERIOD=20;
  parameter SCK_PERIOD = MCLK_PERIOD * 8;
  parameter WS_PERIOD = SCK_PERIOD * 64;

  reg AXIS_ACLK = 1'b0;
  reg AXIS_ARESETN = 1'b0;
  wire AXIS_TREADY;
  wire AXIS_TVALID;
  wire [DATA_WIDTH - 1:0] AXIS_TDATA;
  wire AXIS_TLAST;

  reg sck = 1'b0;
  reg ws = 1'b0;
  reg sd = 1'b0;

  wire sdout;

  i2s_receive u1(
    .M_AXIS_ACLK(AXIS_ACLK), 
    .M_AXIS_ARESETN(AXIS_ARESETN), 
    .M_AXIS_TREADY(AXIS_TREADY), 
    .M_AXIS_TVALID(AXIS_TVALID),
    .M_AXIS_TDATA(AXIS_TDATA),
    .M_AXIS_TLAST(AXIS_TLAST),

    .sck(sck),
    .ws(ws),
    .sd(sd)
  );

  i2s_transmit u2(
    .S_AXIS_ACLK(AXIS_ACLK),
    .S_AXIS_ARESETN(AXIS_ARESETN),
    .S_AXIS_TREADY(AXIS_TREADY),
    .S_AXIS_TVALID(AXIS_TVALID),
    .S_AXIS_TDATA(AXIS_TDATA),
    .S_AXIS_TLAST(AXIS_TLAST),

    .sck(sck),
    .ws(ws),
    .sd(sdout)
  );

  initial
  begin
    #15 AXIS_ARESETN = 1'b1;
    wait(ws == 1'b1);
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;
    #SCK_PERIOD sd = 1'b1;
    #SCK_PERIOD sd = 1'b0;    
    #(SCK_PERIOD * 10) $finish;
  end

  always
    #(MCLK_PERIOD/2) AXIS_ACLK <= ~AXIS_ACLK;

  always
    #(SCK_PERIOD/2) sck <= ~sck;

  always
    #(WS_PERIOD/2) ws <= ~ws;
endmodule
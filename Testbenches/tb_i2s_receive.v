module tb_i2s_receive;
  parameter DATA_WIDTH=32;
  parameter MCLK_PERIOD=20;
  parameter SCK_PERIOD = MCLK_PERIOD * 8;
  parameter WS_PERIOD = SCK_PERIOD * 64;

  reg M_AXIS_ACLK = 1'b0;
  reg M_AXIS_ARESETN = 1'b0;
  reg M_AXIS_TREADY = 1'b0;
  wire M_AXIS_TVALID;
  wire [DATA_WIDTH - 1:0] M_AXIS_TDATA;
  wire M_AXIS_TLAST;

  reg sck = 1'b0;
  reg ws = 1'b0;
  reg sd = 1'b0;


  i2s_receive u1(
    .M_AXIS_ACLK(M_AXIS_ACLK), 
    .M_AXIS_ARESETN(M_AXIS_ARESETN), 
    .M_AXIS_TREADY(M_AXIS_TREADY), 
    .M_AXIS_TVALID(M_AXIS_VALID),
    .M_AXIS_TDATA(M_AXIS_TDATA),
    .M_AXIS_TLAST(M_AXIS_TLAST),

    .sck(sck),
    .ws(ws),
    .sd(sd)
  );

  initial
  begin
    #15 M_AXIS_ARESETN = 1'b1;
  end

  always
    #(MCLK_PERIOD/2) M_AXIS_ACLK <= ~M_AXIS_ACLK;

  always
    #(SCK_PERIOD/2) sck <= ~sck;

  always
    #(WS_PERIOD/2) ws <= ~ws;
endmodule
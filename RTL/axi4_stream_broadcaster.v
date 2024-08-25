module axi4_stream_broadcaster
#(
  parameter DATA_WIDTH=32
)
(
  input AXIS_ACLK,
  input AXIS_ARESETN,

  input [DATA_WIDTH - 1:0] S_AXIS_TDATA,
  input S_AXIS_TVALID,
  input S_AXIS_TLAST,
  output S_AXIS_TREADY,

  output [DATA_WIDTH - 1:0] M_AXIS_TDATA1,
  output M_AXIS_TVALID1,
  output M_AXIS_TLAST1,
  input M_AXIS_TREADY1,

  output [DATA_WIDTH - 1:0] M_AXIS_TDATA2,
  output M_AXIS_TVALID2,
  output M_AXIS_TLAST2,
  input M_AXIS_TREADY2
);

  assign M_AXIS_TDATA1 = S_AXIS_TDATA;
  assign M_AXIS_TDATA2 = S_AXIS_TDATA;
  
  assign M_AXIS_TVALID1 = S_AXIS_TVALID;
  assign M_AXIS_TVALID2 = S_AXIS_TVALID;

  assign M_AXIS_TLAST1 = S_AXIS_TLAST;
  assign M_AXIS_TLAST2 = S_AXIS_TLAST;

  assign S_AXIS_TREADY = M_AXIS_TREADY1 & M_AXIS_TREADY2;
endmodule
`timescale 1ns / 1ps

module tb_packet_to_mono_sample_converter;
  parameter AXIS_ACLK_PERIOD = 20;
  parameter CLK_PERIOD = 4;
  parameter DATA_WIDTH = 32;

  reg axis_aclk = 1'b0;
  reg axis_aresetn = 1'b0;
  reg axis_tvalid = 1'b0;
  reg axis_tlast = 1'b0;
  reg [DATA_WIDTH - 1:0] axis_tdata;
  wire axis_tready;

  reg clk = 1'b0;
  wire mono_sample_valid;
  wire [DATA_WIDTH - 1:0] mono_sample;


  packet_to_mono_sample_converter dut(
    .S_AXIS_ACLK(axis_aclk),
    .S_AXIS_ARESETN(axis_aresetn),
    .S_AXIS_TVALID(axis_tvalid),
    .S_AXIS_TLAST(axis_tlast),
    .S_AXIS_TDATA(axis_tdata),
    .S_AXIS_TREADY(axis_tready),

    .clk_100MHz(clk),
    .mono_sample_valid(mono_sample_valid),
    .mono_sample(mono_sample)
  );

  initial
  begin
    #15 axis_aresetn = 1'b1;
    #10 axis_tdata = 32'h00000001; axis_tvalid = 1'b1;
    wait (axis_tready == 1'b1);
    @(posedge axis_aclk);
    #5 axis_tvalid = 1'b0;
    #20 axis_tdata = 32'h00000003; axis_tvalid = 1'b1;
    wait(axis_tready == 1'b1);
    @(posedge axis_aclk);
    #5 axis_tvalid = 1'b0;

    #10 axis_tdata = 32'hFFFFFFFF; axis_tvalid = 1'b1;
    wait (axis_tready == 1'b1);
    @(posedge axis_aclk);
    #5 axis_tvalid = 1'b0;
    
    #10 axis_tdata = 32'h00000000; axis_tvalid = 1'b1;
    wait (axis_tready == 1'b1);
    @(posedge axis_aclk);
    #5 axis_tvalid = 1'b0;

    #200 $finish;
  end

  always
    #(AXIS_ACLK_PERIOD/2) axis_aclk <= ~axis_aclk;

  always
    #(CLK_PERIOD/2) clk <= ~clk;

endmodule
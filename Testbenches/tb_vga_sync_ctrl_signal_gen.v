`timescale 1ns / 1ps

module tb_vga_sync_ctrl_signal_gen;
  parameter CLK_PERIOD=40;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  wire [15:0] sx;
  wire [15:0] sy;
  wire hsync;
  wire vsync;
  wire data_enable;
  wire frame_pulse;
  wire line_pulse;

  vga_sync_ctrl_signal_gen dut(
    .clk(clk),
    .resetn(resetn),
    .sx(sx),
    .sy(sy),
    .hsync(hsync),
    .vsync(vsync),
    .data_enable(data_enable),
    .frame_pulse(frame_pulse),
    .line_pulse(line_pulse)
  );

  reg [5:0] frame_counter = 6'b0;

  initial 
  begin
    #25 resetn = 1'b1;

    #1000000000  // 1 second should be enough for 60 frames
    $display("Number of frames: %0d", frame_counter);
    
    #200
    $finish;
  end

  always @(posedge frame_pulse)
  begin
    frame_counter <= frame_counter + 1;
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;
endmodule
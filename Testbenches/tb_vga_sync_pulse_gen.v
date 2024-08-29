`timescale 1ns / 1ps

module tb_vga_sync_pulse_gen;
  parameter CLK_PERIOD=40;

  reg clk = 1'b0;
  reg resetn = 1'b0;
  wire [9:0] row;
  wire [9:0] col;
  wire hsync;
  wire vsync;
  wire data_enable;
  wire frame_pulse;

  vga_sync_pulse_gen dut(
    .clk(clk),
    .resetn(resetn),
    .row(row),
    .col(col),
    .hsync(hsync),
    .vsync(vsync),
    .data_enable(data_enable),
    .frame_pulse(frame_pulse)
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

  always @(negedge vsync)
  begin
    frame_counter <= frame_counter + 1;
  end

  always
    #(CLK_PERIOD/2) clk <= ~clk;
endmodule
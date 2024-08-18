// This module is only concerned with generating the required clock signals for I2S, 
// and providing them to the `i2s_transmit` and `i2s_receive` modules
// All of these will work in the mclk domain
module i2s_controller(
  input clk, // 22.579 MHz
  input resetn,
  output mclk,
  output sck,
  output ws
);
  reg [8:0] counter = {9{1'b0}};

  always @(posedge clk)
  begin
    if (!resetn)
      counter <= {9{1'b0}};
    else
      counter <= counter + 1;
  end

  assign mclk = clk;
  assign sck = counter[2]; // Edge every 4 (m)clk cycles => `fully toggles once every 8 mclk periods`
  assign ws = counter[8]; // Edge every 256 (m)clk cycles => `fully toggles once very 64 sck periods`
endmodule
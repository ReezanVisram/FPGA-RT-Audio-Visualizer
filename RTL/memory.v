module memory
#(
  parameter DATA_WIDTH = 32,
  parameter ADDR_LENGTH = 14
)
(
  input clk,
  input reset,
  input we,
  input [ADDR_LENGTH - 1:0] rdaddr,
  input [ADDR_LENGTH - 1:0] wraddr,
  input [DATA_WIDTH - 1:0] wrdata,
  output reg [DATA_WIDTH - 1:0] rddata
);

  reg [DATA_WIDTH - 1:0] mem [(2 ** ADDR_LENGTH) - 1:0];
  integer i;

  always @(posedge clk)
  begin
    if (we)
      mem[wraddr] <= wrdata;
    
    rddata <= mem[rdaddr];
  end
endmodule
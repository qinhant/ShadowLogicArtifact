`include "topsim.v"


module topsim_verilator (
  input clk,
  input rst
);

topsim inst(.clk(clk), .reset_x(~rst));

endmodule


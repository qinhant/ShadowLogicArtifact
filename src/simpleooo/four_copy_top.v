
`include "src/simpleooo/cpu_ooo.v"
`include "src/simpleooo_1cycle/cpu_1cycle.v"

module top(
    input clk,
    input rst
);

reg init;
  always @(posedge clk) begin
    if (rst)
      init <= 1;
    else
      init <= 0;
   end

cpu_1cycle isa1(.clk(clk), .rst(rst));
cpu_1cycle isa2(.clk(clk), .rst(rst));
cpu_ooo ooo1(.clk(clk), .rst(rst));
cpu_ooo ooo2(.clk(clk), .rst(rst));

endmodule
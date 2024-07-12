`include "constants.vh"
`default_nettype none
//8KB Single PORT synchronous BRAM
module dmem
  (
   input wire 		      clk,
   input wire           reset_x,
   input wire [`ADDR_LEN-1:0] addr,
   input wire [`DATA_LEN-1:0] wdata,
   input wire 		      we,
   output reg [`DATA_LEN-1:0] rdata
   );

   reg [`DATA_LEN-1:0] 	      mem [0:`DMEM_SIZE-1];
   
   always @ (posedge clk) begin
      if (!reset_x) begin
`ifdef CONCRETE_DMEM
        mem[0] <= 1;
`endif
      end else begin
        rdata <= mem[addr[`DMEM_SIZE_LOG-1:0]];
        if (we)
  	       mem[addr[`DMEM_SIZE_LOG-1:0]] <= wdata;
      end
   end
endmodule // dmem
`default_nettype wire

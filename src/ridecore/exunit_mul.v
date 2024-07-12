`include "constants.vh"
`default_nettype none
module exunit_mul
  (
   input wire 			 clk,
   input wire 			 reset,
   input wire [`DATA_LEN-1:0] 	 ex_src1,
   input wire [`DATA_LEN-1:0] 	 ex_src2,
   input wire 			 dstval,
   input wire [`SPECTAG_LEN-1:0] spectag,
   input wire 			 specbit,
   input wire 			 src1_signed,
   input wire 			 src2_signed,
   input wire 			 sel_lohi,
   input wire 			 issue,
   input wire 			 prmiss,
   input wire [`SPECTAG_LEN-1:0] spectagfix,
   output wire [`DATA_LEN-1:0] 	 result,
   output wire 			 rrf_we,
   output wire 			 rob_we, //set finish
   output wire 			 kill_speculative
   );

   wire 			       busy = (state != 0);
   wire             finish;
   `ifdef CONSTANT_MUL
   assign             finish = state == `MUL_CYCLES;
   `else
   assign             finish = (state == `MUL_CYCLES) || (state == 1 && (ex_src1 == 0 || ex_src2 == 0));
   `endif
   reg     [2:0]   state;
   
  //  assign rob_we = busy;
  //  assign rrf_we = busy & dstval;
  assign rob_we = busy & finish;
  assign rrf_we = busy & finish & dstval;
  assign kill_speculative = ((spectag & spectagfix) != 0) && specbit && prmiss;
   
   always @ (posedge clk) begin
      if (reset) begin
        state <= 0;
      end else begin
        if (kill_speculative) begin
          state <= 0;
        end else begin
        case(state) 
          0: begin
            if (issue)
              state <= 1;
          end
          1: begin
            `ifdef CONSTANT_MUL
              state <= 2;
            `else
            if (ex_src1 == 0 || ex_src2 == 0)
              state <= 0;
            else
              state <= 2;
              `endif
          end
          2: state <= 3;
          3: state <= 4;
          4: state <= 0;
          5: state <= 0;
        endcase
        end
      end
   end
`ifndef ABSTRACT_MUL
   multiplier bob
     (
      .src1(ex_src1),
      .src2(ex_src2),
      .src1_signed(src1_signed),
      .src2_signed(src2_signed),
      .sel_lohi(sel_lohi),
      .result(result)
      );
`endif
   
endmodule // exunit_mul

   
`default_nettype wire

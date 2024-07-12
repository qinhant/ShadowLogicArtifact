`include "constants.vh"
`default_nettype none
module reorderbuf
  (
   input wire 			  clk,
   input wire 			  reset,
   //Write Signal
   input wire 			  dp1,
   input wire [`RRF_SEL-1:0] 	  dp1_addr,
   input wire [`INSN_LEN-1:0] 	  pc_dp1,
   input wire 			  storebit_dp1,
   input wire 			  dstvalid_dp1,
   input wire [`REG_SEL-1:0] 	  dst_dp1,
   input wire [`GSH_BHR_LEN-1:0]  bhr_dp1,
   input wire 			  isbranch_dp1,
   input wire 			  dp2,
   input wire [`RRF_SEL-1:0] 	  dp2_addr,
   input wire [`INSN_LEN-1:0] 	  pc_dp2,
   input wire 			  storebit_dp2,
   input wire 			  dstvalid_dp2,
   input wire [`REG_SEL-1:0] 	  dst_dp2,
   input wire [`GSH_BHR_LEN-1:0]  bhr_dp2,
   input wire 			  isbranch_dp2,
   input wire 			  exfin_alu1,
   input wire [`RRF_SEL-1:0] 	  exfin_alu1_addr,
   input wire 			  exfin_alu2,
   input wire [`RRF_SEL-1:0] 	  exfin_alu2_addr,
   input wire 			  exfin_mul,
   input wire [`RRF_SEL-1:0] 	  exfin_mul_addr,
   input wire [`DATA_LEN-1:0]   exfin_mul_src1,
   input wire [`DATA_LEN-1:0]   exfin_mul_src2,
   input wire 			  exfin_ldst,
   input wire [`RRF_SEL-1:0] 	  exfin_ldst_addr,
   input wire [`ADDR_LEN-1:0]   exfin_ldst_mem_addr,
   input wire [`DATA_LEN-1:0]   exfin_ld_mem_data,
   input wire 			  exfin_branch,
   input wire [`RRF_SEL-1:0] 	  exfin_branch_addr,
   input wire 			  exfin_branch_brcond,
   input wire [`ADDR_LEN-1:0] 	  exfin_branch_jmpaddr, 
  
   output reg [`RRF_SEL-1:0] 	  comptr,
   output wire [`RRF_SEL-1:0] 	  comptr2,
   output wire [1:0] 		  comnum,
   output wire 			  stcommit,
   output wire 			  arfwe1,
   output wire 			  arfwe2,
   output wire [`REG_SEL-1:0] 	  dstarf1,
   output wire [`REG_SEL-1:0] 	  dstarf2,
   output wire [`ADDR_LEN-1:0] 	  pc_combranch,
   output wire [`GSH_BHR_LEN-1:0] bhr_combranch,
   output wire 			  brcond_combranch,
   output wire [`ADDR_LEN-1:0] 	  jmpaddr_combranch,
   output wire 			  combranch,
   input wire [`RRF_SEL-1:0] 	  dispatchptr,
   input wire [`RRF_SEL:0] 	  rrf_freenum,
   input wire 			  prmiss
   );

   reg [`RRF_NUM-1:0] 		  finish;
   reg [`RRF_NUM-1:0] 		  storebit;
   reg [`RRF_NUM-1:0] 		  dstvalid;
   reg [`RRF_NUM-1:0] 		  brcond;
   reg [`RRF_NUM-1:0] 		  isbranch;
   
   reg [`ADDR_LEN-1:0] 		  inst_pc [0:`RRF_NUM-1];
   reg [`ADDR_LEN-1:0] 		  jmpaddr [0:`RRF_NUM-1];   
   reg [`REG_SEL-1:0] 		  dst [0:`RRF_NUM-1];
   reg [`GSH_BHR_LEN-1:0] 	  bhr [0:`RRF_NUM-1];

   `ifdef TWO_COPY_CT
   reg [`ADDR_LEN-1:0]      ldst_mem_addr [0:`RRF_NUM-1];
   reg [`RRF_NUM-1:0]       ismem;
   reg [`RRF_NUM-1:0]       isldst;

   reg [`DATA_LEN-1:0]      mult_op1 [0:`RRF_NUM-1];
   reg [`DATA_LEN-1:0]      mult_op2 [0:`RRF_NUM-1];
   reg [`RRF_NUM-1:0]       ismul;
   `endif
   `ifdef TWO_COPY_SANDBOX
   reg [`RRF_NUM-1:0]       ismem;
   reg [`DATA_LEN-1:0]      ld_mem_data [0:`RRF_NUM-1];
   `endif
   // ADDED BEGIN
   reg [`ADDR_LEN-1:0] last_committed_pc;

   always @ (posedge clk) begin
      if (reset) begin
         last_committed_pc <= 0;
      end else begin
         if (!prmiss & comnum==1)
            last_committed_pc <= inst_pc[comptr];
         if (!prmiss & comnum==2)
            last_committed_pc <= inst_pc[comptr2];
      end
   end
   // ADDED END
   
   assign comptr2 = comptr+1;
   
   wire 			  hidp = (comptr > dispatchptr) || (rrf_freenum == 0) ?
				  1'b1 : 1'b0;
   wire 			  com_en1 = ({hidp, dispatchptr} - {1'b0, comptr}) > 0 ? 1'b1 : 1'b0;
   wire 			  com_en2 = ({hidp, dispatchptr} - {1'b0, comptr}) > 1 ? 1'b1 : 1'b0;
   wire 			  commit1 = com_en1 & finish[comptr];
   //   wire commit2 = commit1 & com_en2 & finish[comptr2];

  `ifndef SINGLE_COMMIT
   wire 			  commit2 = 
				  ~(~prmiss & commit1 & isbranch[comptr]) &
				  ~(commit1 & storebit[comptr] & ~prmiss) &
				  commit1 & com_en2 & finish[comptr2];
  `else
  wire commit2 = 0;
  `endif

   assign comnum = {1'b0, commit1} + {1'b0, commit2};
   assign stcommit = (commit1 & storebit[comptr] & ~prmiss) |
		     (commit2 & storebit[comptr2] & ~prmiss);
   assign arfwe1 = ~prmiss & commit1 & dstvalid[comptr];
   assign arfwe2 = ~prmiss & commit2 & dstvalid[comptr2];
   assign dstarf1 = dst[comptr];
   assign dstarf2 = dst[comptr2];
   assign combranch = (~prmiss & commit1 & isbranch[comptr]) |
		      (~prmiss & commit2 & isbranch[comptr2]);
   assign pc_combranch = (~prmiss & commit1 & isbranch[comptr]) ? 
			 inst_pc[comptr] : inst_pc[comptr2];
   assign bhr_combranch = (~prmiss & commit1 & isbranch[comptr]) ?
			  bhr[comptr] : bhr[comptr2];
   assign brcond_combranch = (~prmiss & commit1 & isbranch[comptr]) ?
			     brcond[comptr] : brcond[comptr2];
   assign jmpaddr_combranch = (~prmiss & commit1 & isbranch[comptr]) ?
			      jmpaddr[comptr] : jmpaddr[comptr2];
   

   always @ (posedge clk) begin
      if (reset) begin
	 comptr <= 0;
      end else if (~prmiss) begin
	 comptr <= comptr + commit1 + commit2;
      end
   end
   
   always @ (posedge clk) begin
      if (reset) begin
	 finish <= 0;
	 brcond <= 0;
`ifdef TWO_COPY_CT
   for (int i=0; i<`RRF_NUM; i=i+1) begin
     ldst_mem_addr[i] <= 0;
     ismem[i] <= 0;
     isldst[i] <= 0;
     ismul[i] <= 0;
     mult_op1[i] <= 0;
     mult_op2[i] <= 0;
   end
`endif
`ifdef TWO_COPY_SANDBOX
   for (int i=0; i<`RRF_NUM; i=i+1) begin
     ismem[i] <= 0;
     ld_mem_data[i] <= 0;
   end
`endif
      end else begin
	 if (dp1) begin
	   finish[dp1_addr] <= 1'b0;
      `ifdef TWO_COPY_CT
     ismem[dp1_addr] <= 1'b0;
     ismul[dp1_addr] <= 1'b0;
     `endif
     `ifdef TWO_COPY_SANDBOX
     ismem[dp1_addr] <= 1'b0;
     `endif
   end
	 if (dp2) begin
	   finish[dp2_addr] <= 1'b0;
      `ifdef TWO_COPY_CT
     ismem[dp2_addr] <= 1'b0;
     ismul[dp2_addr] <= 1'b0;
     `endif
     `ifdef TWO_COPY_SANDBOX
     ismem[dp1_addr] <= 1'b0;
     `endif
   end
	 if (exfin_alu1)
	   finish[exfin_alu1_addr] <= 1'b1;
	 if (exfin_alu2)
	   finish[exfin_alu2_addr] <= 1'b1;
	 if (exfin_mul) begin
	   finish[exfin_mul_addr] <= 1'b1;
   `ifdef TWO_COPY_CT
     ismul[exfin_mul_addr] <= 1'b1;
     mult_op1[exfin_mul_addr] <= exfin_mul_src1;
     mult_op2[exfin_mul_addr] <= exfin_mul_src2;
   `endif
   end
	 if (exfin_ldst) begin
	   finish[exfin_ldst_addr] <= 1'b1;
   `ifdef TWO_COPY_CT
     ldst_mem_addr[exfin_ldst_addr] <= exfin_ldst_mem_addr;
     ismem[exfin_ldst_addr] <= 1'b1;
     isldst[exfin_ldst_addr] <= dstvalid[exfin_ldst_addr];
   `endif
   `ifdef TWO_COPY_SANDBOX
     ld_mem_data[exfin_ldst_addr] <= exfin_ld_mem_data;
     ismem[exfin_ldst_addr] <= 1'b1;
   `endif
   end
	 if (exfin_branch) begin
	    finish[exfin_branch_addr] <= 1'b1;
	    brcond[exfin_branch_addr] <= exfin_branch_brcond;
	    jmpaddr[exfin_branch_addr] <= exfin_branch_jmpaddr;
	 end
      end
   end // always @ (posedge clk)

   always @ (posedge clk) begin
      if (dp1) begin
	 isbranch[dp1_addr] <= isbranch_dp1;
	 storebit[dp1_addr] <= storebit_dp1;
	 dstvalid[dp1_addr] <= dstvalid_dp1;
	 dst[dp1_addr] <= dst_dp1;
	 bhr[dp1_addr] <= bhr_dp1;
	 inst_pc[dp1_addr] <= pc_dp1;
      end
      if (dp2) begin
	 isbranch[dp2_addr] <= isbranch_dp2;
	 storebit[dp2_addr] <= storebit_dp2;
	 dstvalid[dp2_addr] <= dstvalid_dp2;
	 dst[dp2_addr] <= dst_dp2;
	 bhr[dp2_addr] <= bhr_dp2;
	 inst_pc[dp2_addr] <= pc_dp2;
      end
   end
endmodule // reorderbuf
`default_nettype wire

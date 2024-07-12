`include "src/ridecore/define.v"
`include "src/ridecore/constants.vh"

module two_copy_top_ct(
    input clk,
    input rst
);


reg [`ROB_SEL-1:0] ROB_tail_1, ROB_tail_2;
reg stall_1, stall_2, finish_1, finish_2, commit_deviation, addr_deviation, invalid_program;
reg [1:0] C_mem_valid_r, C_mem_rdwt_r, C_is_br_r, C_taken_r, C_is_mul_r;
reg [`ADDR_LEN-1:0] C_branch_addr_r[1:0];
reg [1:0] record_val;
reg [`ADDR_LEN-1:0] C_mem_addr_r[1:0];
reg [`DATA_LEN-1:0] C_mult_src1_r[1:0], C_mult_src2_r[1:0];

wire [1:0] comnum_1, comnum_2;
`ifdef USE_ADDR_OBSV
wire deviation_found = commit_deviation | addr_deviation;
`else
wire deviation_found = commit_deviation;
`endif

// Use a register to record if the input to the branch predictor in two copies are always the same
`ifdef ABSTRACT_PREDICTOR
reg predictor_deviation_reg;
wire predict_input_deviation = (copy1.pipe.pipe_if.pc!=copy2.pipe.pipe_if.pc || copy1.pipe.pipe_if.btbpht_we!=copy2.pipe.pipe_if.btbpht_we
             || copy1.pipe.pipe_if.btbpht_pc!=copy2.pipe.pipe_if.btbpht_pc || copy1.pipe.pipe_if.btb_jmpdst!=copy2.pipe.pipe_if.btb_jmpdst
             || copy1.pipe.pipe_if.pht_wcond!=copy2.pipe.pipe_if.pht_wcond || copy1.pipe.pipe_if.mpft_valid!=copy2.pipe.pipe_if.mpft_valid
             || copy1.pipe.pipe_if.pht_bhr!=copy2.pipe.pipe_if.pht_bhr || copy1.pipe.pipe_if.prmiss!=copy2.pipe.pipe_if.prmiss || copy1.pipe.pipe_if.prsuccess!=copy2.pipe.pipe_if.prsuccess
             || copy1.pipe.pipe_if.prtag!=copy2.pipe.pipe_if.prtag || copy1.pipe.pipe_if.spectagnow!=copy2.pipe.pipe_if.spectagnow || copy1.pipe.pipe_if.invalid2!=copy2.pipe.pipe_if.invalid2);
wire predict_output_deviation = (copy1.pipe.pipe_if.hit!=copy2.pipe.pipe_if.hit || copy1.pipe.pipe_if.predict_cond!=copy2.pipe.pipe_if.predict_cond
                                || copy1.pipe.pipe_if.pred_pc!=copy2.pipe.pipe_if.pred_pc || copy1.pipe.pipe_if.bhr!=copy2.pipe.pipe_if.bhr);
always @(posedge clk) begin
    if (rst)
        predictor_deviation_reg <= 0;
    else begin
        if (predict_input_deviation)
            predictor_deviation_reg <= 1;
    end
end
// Assumptions for abstract branch predictor
assume property ((~predictor_deviation_reg && ~predict_input_deviation) -> ~predict_output_deviation);
`endif

`ifdef ABSTRACT_ALU
wire alu_deviation_1 = (copy1.pipe.byakko.result != copy2.pipe.byakko.result);
wire alu_deviation_2 = (copy1.pipe.suzaku.result != copy2.pipe.suzaku.result);
wire alu_deviation_3 = (copy1.pipe.byakko.result != copy2.pipe.suzaku.result);
wire alu_deviation_4 = (copy1.pipe.suzaku.result != copy2.pipe.byakko.result);
wire alu_op_match_1 = (copy1.pipe.byakko.alusrc1 == copy2.pipe.byakko.alusrc1 && copy1.pipe.byakko.alusrc2 == copy2.pipe.byakko.alusrc2);
wire alu_op_match_2 = (copy1.pipe.suzaku.alusrc1 == copy2.pipe.suzaku.alusrc1 && copy1.pipe.suzaku.alusrc2 == copy2.pipe.suzaku.alusrc2);
wire alu_op_match_3 = (copy1.pipe.byakko.alusrc1 == copy2.pipe.suzaku.alusrc1 && copy1.pipe.byakko.alusrc2 == copy2.pipe.suzaku.alusrc2);
wire alu_op_match_4 = (copy1.pipe.suzaku.alusrc1 == copy2.pipe.byakko.alusrc1 && copy1.pipe.suzaku.alusrc2 == copy2.pipe.byakko.alusrc2);
assume property (alu_op_match_1 -> ~alu_deviation_1);
assume property (alu_op_match_2 -> ~alu_deviation_2);
assume property (alu_op_match_3 -> ~alu_deviation_3);
assume property (alu_op_match_4 -> ~alu_deviation_4);
`endif

`ifdef ABSTRACT_MUL
wire mul_deviation = (copy1.pipe.genbu.result != copy2.pipe.genbu.result);
wire mul_op_match = (copy1.pipe.genbu.ex_src1 == copy2.pipe.genbu.ex_src1 && copy1.pipe.genbu.ex_src2 == copy2.pipe.genbu.ex_src2);
assume property (mul_op_match -> ~mul_deviation);
`endif

`ifdef ABSTRACT_BRANCH
wire branch_deviation = (copy1.pipe.kirin.comprslt != copy2.pipe.kirin.comprslt);
wire branch_op_match = (copy1.pipe.kirin.ex_src1 == copy2.pipe.kirin.ex_src1 && copy1.pipe.kirin.ex_src2 == copy2.pipe.kirin.ex_src2);
assume property (branch_op_match -> ~branch_deviation);
`endif


reg init;
  always @(posedge clk) begin
    if (rst)
      init <= 1;
    else
      init <= 0;
  end
  
`ifdef SAME_INIT
// Same initial state assumption

wire same_reg =  copy1.pipe.aregfile.regfile.mem[ 0]==copy2.pipe.aregfile.regfile.mem[ 0]
 && copy1.pipe.aregfile.regfile.mem[ 1]==copy2.pipe.aregfile.regfile.mem[ 1]
 && copy1.pipe.aregfile.regfile.mem[ 2]==copy2.pipe.aregfile.regfile.mem[ 2]
 && copy1.pipe.aregfile.regfile.mem[ 3]==copy2.pipe.aregfile.regfile.mem[ 3]
 && copy1.pipe.aregfile.regfile.mem[ 4]==copy2.pipe.aregfile.regfile.mem[ 4]
 && copy1.pipe.aregfile.regfile.mem[ 5]==copy2.pipe.aregfile.regfile.mem[ 5]
 && copy1.pipe.aregfile.regfile.mem[ 6]==copy2.pipe.aregfile.regfile.mem[ 6]
 && copy1.pipe.aregfile.regfile.mem[ 7]==copy2.pipe.aregfile.regfile.mem[ 7]
 && copy1.pipe.aregfile.regfile.mem[ 8]==copy2.pipe.aregfile.regfile.mem[ 8]
 && copy1.pipe.aregfile.regfile.mem[ 9]==copy2.pipe.aregfile.regfile.mem[ 9]
 && copy1.pipe.aregfile.regfile.mem[10]==copy2.pipe.aregfile.regfile.mem[10]
 && copy1.pipe.aregfile.regfile.mem[11]==copy2.pipe.aregfile.regfile.mem[11]
 && copy1.pipe.aregfile.regfile.mem[12]==copy2.pipe.aregfile.regfile.mem[12]
 && copy1.pipe.aregfile.regfile.mem[13]==copy2.pipe.aregfile.regfile.mem[13]
 && copy1.pipe.aregfile.regfile.mem[14]==copy2.pipe.aregfile.regfile.mem[14]
 && copy1.pipe.aregfile.regfile.mem[15]==copy2.pipe.aregfile.regfile.mem[15]
 && copy1.pipe.aregfile.regfile.mem[16]==copy2.pipe.aregfile.regfile.mem[16]
 && copy1.pipe.aregfile.regfile.mem[17]==copy2.pipe.aregfile.regfile.mem[17]
 && copy1.pipe.aregfile.regfile.mem[18]==copy2.pipe.aregfile.regfile.mem[18]
 && copy1.pipe.aregfile.regfile.mem[19]==copy2.pipe.aregfile.regfile.mem[19]
 && copy1.pipe.aregfile.regfile.mem[20]==copy2.pipe.aregfile.regfile.mem[20]
 && copy1.pipe.aregfile.regfile.mem[21]==copy2.pipe.aregfile.regfile.mem[21]
 && copy1.pipe.aregfile.regfile.mem[22]==copy2.pipe.aregfile.regfile.mem[22]
 && copy1.pipe.aregfile.regfile.mem[23]==copy2.pipe.aregfile.regfile.mem[23]
 && copy1.pipe.aregfile.regfile.mem[24]==copy2.pipe.aregfile.regfile.mem[24]
 && copy1.pipe.aregfile.regfile.mem[25]==copy2.pipe.aregfile.regfile.mem[25]
 && copy1.pipe.aregfile.regfile.mem[26]==copy2.pipe.aregfile.regfile.mem[26]
 && copy1.pipe.aregfile.regfile.mem[27]==copy2.pipe.aregfile.regfile.mem[27]
 && copy1.pipe.aregfile.regfile.mem[28]==copy2.pipe.aregfile.regfile.mem[28]
 && copy1.pipe.aregfile.regfile.mem[29]==copy2.pipe.aregfile.regfile.mem[29]
 && copy1.pipe.aregfile.regfile.mem[30]==copy2.pipe.aregfile.regfile.mem[30]
 && copy1.pipe.aregfile.regfile.mem[31]==copy2.pipe.aregfile.regfile.mem[31]
  ;
wire same_init_reg = init? same_reg : 1;

wire same_memd =
    // copy1.datamemory.mem[0]==copy2.datamemory.mem[0]
 copy1.datamemory.mem[1]==copy2.datamemory.mem[1]
 && copy1.datamemory.mem[2]==copy2.datamemory.mem[2]
 && copy1.datamemory.mem[3]==copy2.datamemory.mem[3]
 && copy1.datamemory.mem[4]==copy2.datamemory.mem[4]
 && copy1.datamemory.mem[5]==copy2.datamemory.mem[5]
 && copy1.datamemory.mem[6]==copy2.datamemory.mem[6]
 && copy1.datamemory.mem[7]==copy2.datamemory.mem[7]
  ;
wire same_init_memd = init? same_memd : 1;

assume property (@(posedge clk) disable iff(rst) (same_init_reg && same_init_memd));
`endif

// When misprediction happens, ridecore will delay the commit.
assign comnum_1 = copy1.pipe.prmiss ? 0 : copy1.pipe.comnum;
assign comnum_2 = copy2.pipe.prmiss ? 0 : copy2.pipe.comnum;


topsim copy1(.clk(stall_1 ? 0 : clk), .reset_x(~rst));
topsim copy2(.clk(stall_2 ? 0 : clk), .reset_x(~rst));



prog_val checker();
always @(posedge clk) begin
    if (rst) begin
        stall_1 <= 0;
        stall_2 <= 0;
        finish_1 <= 0;
        finish_2 <= 0;
        addr_deviation <= 0;
        commit_deviation <= 0;
        invalid_program <= 0;
        record_val <= 0;
        C_is_br_r <= 0;
        C_taken_r <= 0;
        C_is_mul_r <= 0;
    end  
    else begin
        // If commit at same time, check if the program is valid, consider all possible cases
        if (!stall_1 && !stall_2) begin
            // Both copies commit 2 instructions, compare both instructions
            if (comnum_1 == 2 && comnum_2 == 2) begin
                invalid_program <= checker.mismatch_com1 | checker.mismatch_com2;
                end
            // Compare only the first one
            else if (comnum_1 == 1 &&  comnum_2 == 1) begin
                invalid_program <= checker.mismatch_com1;
            end
            // Compare the first one, record the second one in copy1
            else if (comnum_1 == 2 &&  comnum_2 == 1) begin
                commit_deviation <= 1;
                stall_1 <= 1;
                if (!deviation_found) begin
                    ROB_tail_1 <= copy1.pipe.rrf_fl.rrfptr-1;
                    ROB_tail_2 <= copy2.pipe.rrf_fl.rrfptr-1;
                end
                record_val <= 2'b01;
                C_is_br_r[0] <= copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr2];
                C_taken_r[0] <= copy1.pipe.rob.brcond_combranch;
                C_branch_addr_r[0] <= copy1.pipe.jmpaddr_combranch;
                C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                C_mem_addr_r[0] <= copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr2];
                C_is_mul_r[0] <= copy1.pipe.rob.ismul[copy1.pipe.rob.comptr2];
                C_mult_src1_r[0] <= copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr2];
                C_mult_src2_r[0] <= copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr2];
                invalid_program <= checker.mismatch_com1;
            end
            // Compare the first one, record the second one in copy2
            else if (comnum_1 == 1 &&  comnum_2 == 2) begin
                commit_deviation <= 1;
                stall_2 <= 1;
                if (!deviation_found) begin
                    ROB_tail_1 <= copy1.pipe.rrf_fl.rrfptr-1;
                    ROB_tail_2 <= copy2.pipe.rrf_fl.rrfptr-1;
                end
                record_val <= 2'b01;
                C_is_mul_r[0] <= copy2.pipe.rob.ismul[copy2.pipe.rob.comptr2];
                C_mult_src1_r[0] <= copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr2];
                C_mult_src2_r[0] <= copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr2];
                C_is_br_r[0] <= copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr2];
                C_taken_r[0] <= copy2.pipe.rob.brcond_combranch;
                C_branch_addr_r[0] <= copy2.pipe.jmpaddr_combranch;
                C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                C_mem_addr_r[0] <= copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr2];
                invalid_program <= checker.mismatch_com1;
            end
            // Record both in copy1
            else if (comnum_1 == 2 &&  comnum_2 == 0) begin
                commit_deviation <= 1;
                stall_1 <= 1;
                if (!deviation_found) begin
                    ROB_tail_1 <= copy1.pipe.rrf_fl.rrfptr-1;
                    ROB_tail_2 <= copy2.pipe.rrf_fl.rrfptr-1;
                end
                record_val <= 2'b11;
                C_is_mul_r[0] <= copy1.pipe.rob.ismul[copy1.pipe.rob.comptr];
                C_mult_src1_r[0] <= copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr];
                C_mult_src2_r[0] <= copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr];
                C_is_br_r[0] <= copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr];
                C_taken_r[0] <= copy1.pipe.rob.brcond_combranch;
                C_branch_addr_r[0] <= copy1.pipe.jmpaddr_combranch;
                C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr];
                C_mem_addr_r[0] <= copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr];
                C_is_mul_r[1] <= copy1.pipe.rob.ismul[copy1.pipe.rob.comptr2];
                C_mult_src1_r[1] <= copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr2];
                C_mult_src2_r[1] <= copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr2];
                C_is_br_r[1] <= copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr2];
                C_taken_r[1] <= copy1.pipe.rob.brcond_combranch;
                C_branch_addr_r[1] <= copy1.pipe.jmpaddr_combranch;
                C_mem_valid_r[1] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                C_mem_addr_r[1] <= copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr2];
            end
            // Record both in copy1
            else if (comnum_1 == 0 &&  comnum_2 == 2) begin
                commit_deviation <= 1;
                stall_2 <= 1;
                if (!deviation_found) begin
                    ROB_tail_1 <= copy1.pipe.rrf_fl.rrfptr-1;
                    ROB_tail_2 <= copy2.pipe.rrf_fl.rrfptr-1;
                end
                record_val <= 2'b11;
                C_is_mul_r[0] <= copy2.pipe.rob.ismul[copy2.pipe.rob.comptr];
                C_mult_src1_r[0] <= copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr];
                C_mult_src2_r[0] <= copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr];
                C_is_br_r[0] <= copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr];
                C_taken_r[0] <= copy2.pipe.rob.brcond_combranch;
                C_branch_addr_r[0] <= copy2.pipe.jmpaddr_combranch;
                C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr];
                C_mem_addr_r[0] <= copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr];
                C_is_mul_r[1] <= copy2.pipe.rob.ismul[copy2.pipe.rob.comptr2];
                C_mult_src1_r[1] <= copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr2];
                C_mult_src2_r[1] <= copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr2];
                C_is_br_r[1] <= copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr2];
                C_taken_r[1] <= copy2.pipe.rob.brcond_combranch;
                C_branch_addr_r[1] <= copy2.pipe.jmpaddr_combranch;
                C_mem_valid_r[1] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                C_mem_addr_r[1] <= copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr2];
            end
            // Only record the first one in copy1
            else if (comnum_1 == 1 &&  comnum_2 == 0) begin
                commit_deviation <= 1;
                stall_1 <= 1;
                if (!deviation_found) begin
                    ROB_tail_1 <= copy1.pipe.rrf_fl.rrfptr-1;
                    ROB_tail_2 <= copy2.pipe.rrf_fl.rrfptr-1;
                end
                record_val <= 2'b01;
                C_is_mul_r[0] <= copy1.pipe.rob.ismul[copy1.pipe.rob.comptr];
                C_mult_src1_r[0] <= copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr];
                C_mult_src2_r[0] <= copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr];
                C_is_br_r[0] <= copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr];
                C_taken_r[0] <= copy1.pipe.rob.brcond_combranch;
                C_branch_addr_r[0] <= copy1.pipe.jmpaddr_combranch;
                C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr];
                C_mem_addr_r[0] <= copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr];
            end
            // Only record the first one in copy2
            else if (comnum_1 == 0 &&  comnum_2 == 1) begin
                commit_deviation <= 1;
                stall_2 <= 1;
                if (!deviation_found) begin
                    ROB_tail_1 <= copy1.pipe.rrf_fl.rrfptr-1;
                    ROB_tail_2 <= copy2.pipe.rrf_fl.rrfptr-1;
                end
                record_val <= 2'b01;
                C_is_mul_r[0] <= copy2.pipe.rob.ismul[copy2.pipe.rob.comptr];
                C_mult_src1_r[0] <= copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr];
                C_mult_src2_r[0] <= copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr];
                C_is_br_r[0] <= copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr];
                C_taken_r[0] <= copy2.pipe.rob.brcond_combranch;
                C_branch_addr_r[0] <= copy2.pipe.jmpaddr_combranch;
                C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr];
                C_mem_addr_r[0] <= copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr];
            end
        end
        else if (stall_1 && !stall_2) begin
            if ( comnum_2 == 2) begin
                // Compare two recorded of copy1 with two committed in copy2
                if (record_val == 2'b11) begin
                    if ((C_is_br_r[0] && (C_taken_r[0] != copy2.pipe.rob.brcond_combranch || C_branch_addr_r[0] != copy2.pipe.jmpaddr_combranch))
                        || (C_is_br_r[1] && (C_taken_r[1] != copy2.pipe.rob.brcond_combranch || C_branch_addr_r[1] != copy2.pipe.jmpaddr_combranch)))
                        invalid_program <= 1;
                    if ((C_mem_valid_r[0] && C_mem_addr_r[0] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr])
                        || (C_mem_valid_r[1] && C_mem_addr_r[1] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr2]))
                        invalid_program <= 1;
                    if ((C_is_mul_r[0] && (C_mult_src1_r[0] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr] || C_mult_src2_r[0] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr]))
                        || (C_is_mul_r[1] && (C_mult_src1_r[1] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr2] || C_mult_src2_r[1] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr2])))
                        invalid_program <= 1;
                    stall_1 <= 0;
                    record_val <= 2'b00;
                end
                // Compare the first one with the one recorded, record the second one of copy2
                // Let copy1 continue and stall copy2
                else if (record_val == 2'b01) begin
                    if (C_is_br_r[0] && (C_taken_r[0] != copy2.pipe.rob.brcond_combranch || C_branch_addr_r[0] != copy2.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[0] && C_mem_addr_r[0] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[0] && (C_mult_src1_r[0] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr] || C_mult_src2_r[0] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr]))
                        invalid_program <= 1;
                    C_is_mul_r[0] <= copy2.pipe.rob.ismul[copy2.pipe.rob.comptr2];
                    C_mult_src1_r[0] <= copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr2];
                    C_mult_src2_r[0] <= copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr2];
                    C_is_br_r[0] <= copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr2];
                    C_taken_r[0] <= copy2.pipe.rob.brcond_combranch;
                    C_branch_addr_r[0] <= copy2.pipe.jmpaddr_combranch;
                    C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                    C_mem_addr_r[0] <= copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 0;
                    stall_2 <= 1;
                end
                else if (record_val == 2'b10) begin
                    if (C_is_br_r[1] && (C_taken_r[1] != copy2.pipe.rob.brcond_combranch || C_branch_addr_r[1] != copy2.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[1] && C_mem_addr_r[1] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[1] && (C_mult_src1_r[1] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr] || C_mult_src2_r[1] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr]))
                        invalid_program <= 1;
                    C_is_mul_r[0] <= copy2.pipe.rob.ismul[copy2.pipe.rob.comptr2];
                    C_mult_src1_r[0] <= copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr2];
                    C_mult_src2_r[0] <= copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr2];
                    C_is_br_r[0] <= copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr2];
                    C_taken_r[0] <= copy2.pipe.rob.brcond_combranch;
                    C_branch_addr_r[0] <= copy2.pipe.jmpaddr_combranch;
                    C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                    C_mem_addr_r[0] <= copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 0;
                    stall_2 <= 1;
                end
            end
            // Compare the first one of copy2 with the early one of copy1 recorded
            // Continue copy1 if record_val == 2'b00
            else if ( comnum_2 == 1) begin
                if (record_val == 2'b01 || record_val == 2'b11) begin
                    if (C_is_br_r[0] && (C_taken_r[0] != copy2.pipe.rob.brcond_combranch || C_branch_addr_r[0] != copy2.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[0] && C_mem_addr_r[0] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[0] && (C_mult_src1_r[0] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr] || C_mult_src2_r[0] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr]))
                        invalid_program <= 1;
                    stall_1 <= record_val[1];
                    record_val[0] <= 0;
                end
                else if (record_val == 2'b10) begin
                    if (C_is_br_r[1] && (C_taken_r[1] != copy2.pipe.rob.brcond_combranch || C_branch_addr_r[1] != copy2.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[1] && C_mem_addr_r[1] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[1] && (C_mult_src1_r[1] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr] || C_mult_src2_r[1] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr]))
                        invalid_program <= 1;
                    stall_1 <= 0;
                    record_val <= 2'b00;
                end
            end
        end
        // Symmetric to the above case: (stall_1 && !stall_2)
        else if (!stall_1 && stall_2) begin
            if (comnum_1 == 2) begin
                // Compare two recorded of copy2 with two committed in copy1
                if (record_val == 2'b11) begin
                    if ((C_is_br_r[0] && (C_taken_r[0] != copy1.pipe.rob.brcond_combranch || C_branch_addr_r[0] != copy1.pipe.jmpaddr_combranch))
                        || (C_is_br_r[1] && (C_taken_r[1] != copy1.pipe.rob.brcond_combranch || C_branch_addr_r[1] != copy1.pipe.jmpaddr_combranch)))
                        invalid_program <= 1;
                    if ((C_mem_valid_r[0] && C_mem_addr_r[0] != copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr])
                        || (C_mem_valid_r[1] && C_mem_addr_r[1] != copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr2]))
                        invalid_program <= 1;
                    if ((C_is_mul_r[0] && (C_mult_src1_r[0] != copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr] || C_mult_src2_r[0] != copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr]))
                        || (C_is_mul_r[1] && (C_mult_src1_r[1] != copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr2] || C_mult_src2_r[1] != copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr2])))
                        invalid_program <= 1;
                    stall_2 <= 0;
                    record_val <= 2'b00;
                end
                // Compare the first one with the one recorded, record the second one of copy1
                // Let copy2 continue and stall copy1
                else if (record_val == 2'b01) begin
                    if (C_is_br_r[0] && (C_taken_r[0] != copy1.pipe.rob.brcond_combranch || C_branch_addr_r[0] != copy1.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[0] && C_mem_addr_r[0] != copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[0] && (C_mult_src1_r[0] != copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr] || C_mult_src2_r[0] != copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr]))
                        invalid_program <= 1;
                    C_is_mul_r[0] <= copy1.pipe.rob.ismul[copy1.pipe.rob.comptr2];
                    C_mult_src1_r[0] <= copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr2];
                    C_mult_src2_r[0] <= copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr2];
                    C_is_br_r[0] <= copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr2];
                    C_taken_r[0] <= copy1.pipe.rob.brcond_combranch;
                    C_branch_addr_r[0] <= copy1.pipe.jmpaddr_combranch;
                    C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                    C_mem_addr_r[0] <= copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 1;
                    stall_2 <= 0;
                end
                else if (record_val == 2'b10) begin
                    if (C_is_br_r[1] && (C_taken_r[1] != copy1.pipe.rob.brcond_combranch || C_branch_addr_r[1] != copy1.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[1] && C_mem_addr_r[1] != copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[1] && (C_mult_src1_r[1] != copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr] || C_mult_src2_r[1] != copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr]))
                        invalid_program <= 1;
                    C_is_mul_r[0] <= copy1.pipe.rob.ismul[copy1.pipe.rob.comptr2];
                    C_mult_src1_r[0] <= copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr2];
                    C_is_br_r[0] <= copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr2];
                    C_taken_r[0] <= copy1.pipe.rob.brcond_combranch;
                    C_branch_addr_r[0] <= copy1.pipe.jmpaddr_combranch;
                    C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                    C_mem_addr_r[0] <= copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 1;
                    stall_2 <= 0;
                end
            end
            // Compare the first one of copy1 with the early one of copy2 recorded
            // Continue copy2 if record_val == 2'b00
            else if (comnum_1 == 1) begin
                if (record_val == 2'b01 || record_val == 2'b11) begin
                    if (C_is_br_r[0] && (C_taken_r[0] != copy1.pipe.rob.brcond_combranch || C_branch_addr_r[0] != copy1.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[0] && C_mem_addr_r[0] != copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[0] && (C_mult_src1_r[0] != copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr] || C_mult_src2_r[0] != copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr]))
                        invalid_program <= 1;
                    stall_2 <= record_val[1];
                    record_val[0] <= 0;
                end
                else if (record_val == 2'b10) begin
                    if (C_is_br_r[1] && (C_taken_r[1] != copy1.pipe.rob.brcond_combranch || C_branch_addr_r[1] != copy1.pipe.jmpaddr_combranch))
                        invalid_program <= 1;
                    if (C_mem_valid_r[1] && C_mem_addr_r[1] != copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    if (C_is_mul_r[1] && (C_mult_src1_r[1] != copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr] || C_mult_src2_r[1] != copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr]))
                        invalid_program <= 1;
                    stall_2 <= 0;
                    record_val <= 2'b00;
                end
            end
        end
    end

    `ifdef USE_ADDR_OBSV
    if (copy1.dmem_addr != copy2.dmem_addr) begin
        addr_deviation <= 1;
        if (!deviation_found) begin
            ROB_tail_1 <= copy1.pipe.rrf_fl.rrfptr-1;
            ROB_tail_2 <= copy2.pipe.rrf_fl.rrfptr-1;
        end
    end
    `endif

    // Modify recorded tail upon misprediction, only when the misprediction is causde by old instructions (recorded ROB_tail is decreased in this case)
    if (deviation_found && copy1.pipe.prmiss) begin
        ROB_tail_1 <= ({copy1.pipe.rrf_fl.hi, copy1.pipe.rrftagfix} > {copy1.pipe.rrf_fl.comptr >= ROB_tail_1, ROB_tail_1}) ? ROB_tail_1: copy1.pipe.rrftagfix - 1;
    end
    if (deviation_found && copy2.pipe.prmiss) begin
        ROB_tail_2 <= ({copy2.pipe.rrf_fl.hi, copy2.pipe.rrftagfix} > {copy2.pipe.rrf_fl.comptr >= ROB_tail_2, ROB_tail_2}) ? ROB_tail_2: copy2.pipe.rrftagfix - 1;
    end

    // Drain the ROB, stop when recorded tail - 1 (last instruction) is finished.
    if ((deviation_found && !copy1.pipe.prmiss) && ((copy1.pipe.rob.commit1 && copy1.pipe.rob.comptr == ROB_tail_1) || (copy1.pipe.rob.commit2 && copy1.pipe.rob.comptr2 == ROB_tail_1)))
        finish_1 <= 1;
    if ((deviation_found && !copy2.pipe.prmiss) && ((copy2.pipe.rob.commit1 && copy2.pipe.rob.comptr == ROB_tail_2) || (copy2.pipe.rob.commit2 && copy2.pipe.rob.comptr2 == ROB_tail_2)))
        finish_2 <= 1;
end

endmodule


// Shortcut for comparing instructions committed in the same cycle
module prog_val();

wire mismatch_com1 = (copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr] && copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr] && (copy1.pipe.rob.brcond_combranch != copy2.pipe.rob.brcond_combranch || copy1.pipe.jmpaddr_combranch != copy2.pipe.jmpaddr_combranch)) 
                    || (copy1.pipe.rob.ismem[copy1.pipe.rob.comptr] && copy2.pipe.rob.ismem[copy2.pipe.rob.comptr] && copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr])
                    || (copy1.pipe.rob.ismul[copy1.pipe.rob.comptr] && copy2.pipe.rob.ismul[copy2.pipe.rob.comptr] && (copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr] || copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr]));
wire mismatch_com2 = (copy1.pipe.rob.isbranch[copy1.pipe.rob.comptr2] && copy2.pipe.rob.isbranch[copy2.pipe.rob.comptr2] && (copy1.pipe.rob.brcond_combranch != copy2.pipe.rob.brcond_combranch || copy1.pipe.jmpaddr_combranch != copy2.pipe.jmpaddr_combranch))
                    || (copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2] && copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2] && copy1.pipe.rob.ldst_mem_addr[copy1.pipe.rob.comptr2] != copy2.pipe.rob.ldst_mem_addr[copy2.pipe.rob.comptr2])
                    || (copy1.pipe.rob.ismul[copy1.pipe.rob.comptr2] && copy2.pipe.rob.ismul[copy2.pipe.rob.comptr2] && (copy1.pipe.rob.mult_op1[copy1.pipe.rob.comptr2] != copy2.pipe.rob.mult_op1[copy2.pipe.rob.comptr2] || copy1.pipe.rob.mult_op2[copy1.pipe.rob.comptr2] != copy2.pipe.rob.mult_op2[copy2.pipe.rob.comptr2]));


endmodule


`include "src/ridecore/define.v"
`include "src/ridecore/constants.vh"

module two_copy_top_sandbox(
    input clk,
    input rst
);


reg [`ROB_SEL-1:0] ROB_tail_1, ROB_tail_2;
reg stall_1, stall_2, finish_1, finish_2, commit_deviation, addr_deviation, invalid_program;
reg commit_deviation_ind, addr_deviation_ind, finish_1_ind, finish_2_ind;
reg [`ROB_SEL-1:0] ROB_tail_ind, ROB_tail_ind;
reg [1:0] C_mem_valid_r, C_mem_rdwt_r, C_is_br_r, C_taken_r, C_is_mul_r;
// reg [`ADDR_LEN-1:0] C_branch_addr_r[1:0];
reg [1:0] record_val;
// reg [`ADDR_LEN-1:0] C_mem_data_r[1:0];
// reg [`DATA_LEN-1:0] C_mult_src1_r[1:0], C_mult_src2_r[1:0];
reg [`DATA_LEN-1:0] C_mem_data_r[1:0];

wire [1:0] comnum_1, comnum_2;
`ifdef USE_ADDR_OBSV
wire deviation_found = commit_deviation | addr_deviation;
`else
wire deviation_found = commit_deviation;
`endif


reg init;
  always @(posedge clk) begin
    if (rst) begin
      init <= 1;
    end
    else begin
      init <= 0;
    end
  end

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
                C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                C_mem_data_r[0] <= copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr2];
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
                C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                C_mem_data_r[0] <= copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr2];
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
                C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr];
                C_mem_data_r[0] <= copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr];
                C_mem_valid_r[1] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                C_mem_data_r[1] <= copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr2];
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
                C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr];
                C_mem_data_r[0] <= copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr];
                C_mem_valid_r[1] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                C_mem_data_r[1] <= copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr2];
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
                C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr];
                C_mem_data_r[0] <= copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr];
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
                C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr];
                C_mem_data_r[0] <= copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr];
            end
        end
        else if (stall_1 && !stall_2) begin
            if ( comnum_2 == 2) begin
                // Compare two recorded of copy1 with two committed in copy2
                if (record_val == 2'b11) begin
                    if ((C_mem_valid_r[0] && C_mem_data_r[0] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr])
                        || (C_mem_valid_r[1] && C_mem_data_r[1] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr2]))
                        invalid_program <= 1;
                    stall_1 <= 0;
                    record_val <= 2'b00;
                end
                // Compare the first one with the one recorded, record the second one of copy2
                // Let copy1 continue and stall copy2
                else if (record_val == 2'b01) begin
                    if (C_mem_valid_r[0] && C_mem_data_r[0] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr])
                        invalid_program <= 1;
                    C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                    C_mem_data_r[0] <= copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 0;
                    stall_2 <= 1;
                end
                else if (record_val == 2'b10) begin
                    if (C_mem_valid_r[1] && C_mem_data_r[1] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr])
                        invalid_program <= 1;
                    C_mem_valid_r[0] <= copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2];
                    C_mem_data_r[0] <= copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 0;
                    stall_2 <= 1;
                end
            end
            // Compare the first one of copy2 with the early one of copy1 recorded
            // Continue copy1 if record_val == 2'b00
            else if ( comnum_2 == 1) begin
                if (record_val == 2'b01 || record_val == 2'b11) begin
                    if (C_mem_valid_r[0] && C_mem_data_r[0] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr])
                        invalid_program <= 1;
                    stall_1 <= record_val[1];
                    record_val[0] <= 0;
                end
                else if (record_val == 2'b10) begin
                    if (C_mem_valid_r[1] && C_mem_data_r[1] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr])
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
                    if ((C_mem_valid_r[0] && C_mem_data_r[0] != copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr])
                        || (C_mem_valid_r[1] && C_mem_data_r[1] != copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr2]))
                        invalid_program <= 1;
                    stall_2 <= 0;
                    record_val <= 2'b00;
                end
                // Compare the first one with the one recorded, record the second one of copy1
                // Let copy2 continue and stall copy1
                else if (record_val == 2'b01) begin
                    if (C_mem_valid_r[0] && C_mem_data_r[0] != copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                    C_mem_data_r[0] <= copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 1;
                    stall_2 <= 0;
                end
                else if (record_val == 2'b10) begin
                    if (C_mem_valid_r[1] && C_mem_data_r[1] != copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    C_mem_valid_r[0] <= copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2];
                    C_mem_data_r[0] <= copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr2];
                    record_val <= 2'b01;
                    stall_1 <= 1;
                    stall_2 <= 0;
                end
            end
            // Compare the first one of copy1 with the early one of copy2 recorded
            // Continue copy2 if record_val == 2'b00
            else if (comnum_1 == 1) begin
                if (record_val == 2'b01 || record_val == 2'b11) begin
                    if (C_mem_valid_r[0] && C_mem_data_r[0] != copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    stall_2 <= record_val[1];
                    record_val[0] <= 0;
                end
                else if (record_val == 2'b10) begin
                    if (C_mem_valid_r[1] && C_mem_data_r[1] != copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr])
                        invalid_program <= 1;
                    stall_2 <= 0;
                    record_val <= 2'b00;
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
    end

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

wire mismatch_com1 =  (copy1.pipe.rob.ismem[copy1.pipe.rob.comptr] && copy2.pipe.rob.ismem[copy2.pipe.rob.comptr] && copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr]);
wire mismatch_com2 = (copy1.pipe.rob.ismem[copy1.pipe.rob.comptr2] && copy2.pipe.rob.ismem[copy2.pipe.rob.comptr2] && copy1.pipe.rob.ld_mem_data[copy1.pipe.rob.comptr2] != copy2.pipe.rob.ld_mem_data[copy2.pipe.rob.comptr2]);


endmodule


`include "src/sodor2/param.vh"
`include "src/sodor2/sodor_2_stage.sv"

module top(
    input clk,
    input rst
);


// reg [`ROB_SIZE_LOG-1:0] ROB_tail_1, ROB_tail_2;
reg stall_1, stall_2, finish_1, finish_2, commit_deviation, addr_deviation, invalid_program;
reg init;
  always @(posedge clk) begin
    if (rst)
      init <= 1;
    else
      init <= 0;
   end

SodorInternalTile copy1(.clock(stall_1? 0: clk), 
                       .reset(rst),
                       .io_debug_port_req_valid(0),
                       .io_debug_port_req_bits_addr(0),
                       .io_debug_port_req_bits_data(0),
                       .io_debug_port_req_bits_fcn(0),
                       .io_debug_port_req_bits_typ(0),
                       .io_master_port_0_resp_valid(0),
                       .io_master_port_0_resp_bits_data(0),
                       .io_master_port_1_resp_valid(0),
                       .io_master_port_1_resp_bits_data(0),
                       .io_interrupt_debug(0),
                       .io_interrupt_mtip(0),
                       .io_interrupt_msip(0),
                       .io_interrupt_meip(0),
                       .io_hartid(0),
                       .io_reset_vector(0));

SodorInternalTile copy2(.clock(stall_2? 0: clk), 
                       .reset(rst),
                       .io_debug_port_req_valid(0),
                       .io_debug_port_req_bits_addr(0),
                       .io_debug_port_req_bits_data(0),
                       .io_debug_port_req_bits_fcn(0),
                       .io_debug_port_req_bits_typ(0),
                       .io_master_port_0_resp_valid(0),
                       .io_master_port_0_resp_bits_data(0),
                       .io_master_port_1_resp_valid(0),
                       .io_master_port_1_resp_bits_data(0),
                       .io_interrupt_debug(0),
                       .io_interrupt_mtip(0),
                       .io_interrupt_msip(0),
                       .io_interrupt_meip(0),
                       .io_hartid(0),
                       .io_reset_vector(0));

wire ld_valid_1 = copy1.core.d.io_ctl_wb_sel==1;
wire ld_valid_2 = copy2.core.d.io_ctl_wb_sel==1;
wire [31:0] mem_addr_1 = copy1.core_io_dmem_req_valid ? copy1.core_io_dmem_req_bits_addr : 0;
wire [31:0] mem_addr_2 = copy2.core_io_dmem_req_valid ? copy2.core_io_dmem_req_bits_addr : 0;
wire [31:0] if_pc_next_1 = copy1.core.d._if_pc_next_T ? copy1.core.d.if_pc_plus4 : copy1.core.d._if_pc_next_T_1 ? copy1.core.d.exe_br_target : copy1.core.d._if_pc_next_T_7;
wire [31:0] if_pc_next_2 = copy2.core.d._if_pc_next_T ? copy2.core.d.if_pc_plus4 : copy2.core.d._if_pc_next_T_1 ? copy2.core.d.exe_br_target : copy2.core.d._if_pc_next_T_7;

always @(posedge clk) begin
    if (rst) begin
        stall_1 <= 0;
        stall_2 <= 0;
        finish_1 <= 0;
        finish_2 <= 0;
        commit_deviation <= 0;
        addr_deviation <= 0;
        invalid_program <= 0;
    end  
    else begin
        if (!stall_1 && !stall_2 && copy1.core.d.exe_reg_valid && copy2.core.d.exe_reg_valid) begin
            if (copy1.core.d.exe_wbdata!=copy2.core.d.exe_wbdata)
                invalid_program = 1;
        end
        else if (!stall_1 && !stall_2 && copy1.core.d.exe_reg_valid && !copy2.core.d.exe_reg_valid) begin
            stall_1 = 1;
            commit_deviation <= 1;
            // if (!(commit_deviation || addr_deviation)) begin
            //     ROB_tail_1 <= copy1.ROB_tail;
            //     ROB_tail_2 <= copy2.ROB_tail;
            // end
        end
        else if (!stall_1 && !stall_2 && !copy1.core.d.exe_reg_valid && copy2.core.d.exe_reg_valid) begin
            stall_2 = 1;
            commit_deviation <= 1;
            // Record the youngest instruction in ROB
            // if (!commit_deviation) begin
            //     ROB_tail_1 <= copy1.ROB_tail;
            //     ROB_tail_2 <= copy2.ROB_tail;
            // end
        end
        // Compare the later committed instruction with the recorded early one
        else if (stall_1 && !stall_2 && copy2.core.d.exe_reg_valid) begin
            if (copy1.core.d.exe_wbdata!=copy2.core.d.exe_wbdata) 
                invalid_program = 1;
            // if (C_is_br_r && copy2.C_is_br && C_taken_r != copy2.C_taken)
            //     invalid_program <= 1;
            stall_1 = 0;
        end
        else if (!stall_1 && stall_2 && copy1.core.d.exe_reg_valid) begin
            if (copy1.core.d.exe_wbdata!=copy2.core.d.exe_wbdata) 
                invalid_program = 1;
            // if (copy1.C_is_br && C_is_br_r && copy1.C_taken != C_taken_r)
            //     invalid_program <= 1;
            stall_2 = 0;
        end

        // Detect deviation in address (only consider this when no commit deviation has been found)
        if (!commit_deviation && mem_addr_1!=mem_addr_2) begin
            addr_deviation <= 1;
        end

        // Drain the inflight instruction
        if ((commit_deviation || addr_deviation) && (copy1.core.d.exe_reg_valid))
            finish_1 <= 1;
        if ((commit_deviation || addr_deviation) && (copy2.core.d.exe_reg_valid))
            finish_2 <= 1;
    end
        

end




endmodule
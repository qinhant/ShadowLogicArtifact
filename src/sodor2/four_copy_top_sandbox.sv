`include "src/sodor2/sodor_1_stage.sv"
`include "src/sodor2/sodor_2_stage.sv"
`include "src/sodor2/param.vh"

module top(
  input clk,
  input rst
);


wire commit_num1 = copy1.core.d.exe_reg_valid;
wire commit_num2 = copy2.core.d.exe_reg_valid;
wire [31:0] mem_addr_1 = copy1.core_io_dmem_req_valid ? copy1.core_io_dmem_req_bits_addr : 0;
wire [31:0] mem_addr_2 = copy2.core_io_dmem_req_valid ? copy2.core_io_dmem_req_bits_addr : 0;

  // STEP: instantiate ooo and ISA
SodorInternalTile_1cycle ISA1(.clock(clk), 
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

SodorInternalTile_1cycle ISA2(.clock(clk), 
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
SodorInternalTile copy1(.clock(clk), 
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

SodorInternalTile copy2(.clock(clk), 
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

reg init;
  always @(posedge clk) begin
    if (rst)
      init <= 1;
    else
      init <= 0;
   end

// Same program assumption
// wire same_memi = ooo1.instmemory.mem == ooo2.instmemory.mem && ISA1.memi_instance.array == ISA2.memi_instance.array
//    && ooo1.instmemory.mem[0]=={ISA1.memi_instance.array[ 3],ISA1.memi_instance.array[ 2],
//                             ISA1.memi_instance.array[ 1],ISA1.memi_instance.array[ 0]}
//  && ooo1.instmemory.mem[1]=={ISA1.memi_instance.array[ 7],ISA1.memi_instance.array[ 6],
//                             ISA1.memi_instance.array[ 5],ISA1.memi_instance.array[ 4]};



// Valid program assumption (two ISA machines must agree on Load data)
assume property  (@(posedge clk) disable iff (rst) ISA1.core.d.wb_data==ISA2.core.d.wb_data);
// assume property  (@(posedge clk) disable iff (rst) ISA1.decodeExecute_instance.br_valid -> (ISA1.next_pc == ISA2.next_pc));

// Check if there's commit deviation or addr deviation in two ooo cpus
assert property  (@(posedge clk) disable iff (rst) !(commit_num1 != commit_num2 || mem_addr_1 != mem_addr_2));

endmodule
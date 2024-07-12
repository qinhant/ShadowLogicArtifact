`include "ridecore_1cycle.v"
`include "src/ridecore/topsim.v"

module four_copy_top_sandbox(
  input clk,
  input rst
);


wire [1:0] commit_num1 = ooo1.pipe.prmiss ? 0: ooo1.pipe.comnum;
wire [1:0] commit_num2 = ooo2.pipe.prmiss ? 0: ooo2.pipe.comnum;
  // STEP: instantiate ooo and ISA
topsim          ooo1(.clk(clk), .reset_x(~rst));
topsim          ooo2(.clk(clk), .reset_x(~rst));
ridecore_1cycle ISA1(.clk(clk), .rst(rst));
ridecore_1cycle ISA2(.clk(clk), .rst(rst));

reg init;
  always @(posedge clk) begin
    if (rst)
      init <= 1;
    else
      init <= 0;
   end

// Same program assumption
wire same_memi = ooo1.instmemory.mem == ooo2.instmemory.mem && ISA1.memi_instance.array == ISA2.memi_instance.array
   && ooo1.instmemory.mem[0]=={ISA1.memi_instance.array[ 3],ISA1.memi_instance.array[ 2],
                            ISA1.memi_instance.array[ 1],ISA1.memi_instance.array[ 0]}
 && ooo1.instmemory.mem[1]=={ISA1.memi_instance.array[ 7],ISA1.memi_instance.array[ 6],
                            ISA1.memi_instance.array[ 5],ISA1.memi_instance.array[ 4]};



// Valid program assumption (two ISA machines must agree on MUL, MEM, BR instructions)
// assume property (@(posedge clk) disable iff (rst) ISA1.decodeExecute_instance.muldiv_valid -> (ISA1.rs1_data == ISA2.rs1_data && ISA1.rs2_data == ISA2.rs2_data));
assume property  (@(posedge clk) disable iff (rst) ISA1.decodeExecute_instance.mem_valid -> (ISA1.mem_data_read == ISA2.mem_data_read));
// assume property  (@(posedge clk) disable iff (rst) ISA1.decodeExecute_instance.br_valid -> (ISA1.next_pc == ISA2.next_pc));

// Valid instruction (any non-zero instruction must be a legal instruction)
assume property  (@(posedge clk) disable iff (rst) ISA1.inst != 0 -> ISA1.valid_inst);
assume property  (@(posedge clk) disable iff (~rst) (ooo1.pipe.inst1_if != 0 -> ooo1.pipe.illegal_instruction_1 == 0) && (ooo1.pipe.inst2_if != 0 -> ooo1.pipe.illegal_instruction_2 == 0));

// Check if there's commit deviation or addr deviation in two ooo cpus
assert property  (@(posedge clk) disable iff (rst) !(commit_num1 != commit_num2 || ooo1.dmem_addr != ooo2.dmem_addr));

endmodule


`include "src/simpleooo_1cycle/param.v"

module execute_1(
  input [`INST_SIZE_LOG-1:0] opcode,
  input [`REG_LEN-1      :0] rs1_imm,
  input [`MEMI_SIZE_LOG-1:0] rs1_br_offset,
  input [`REG_LEN-1      :0] rs1_data,
  input [`REG_LEN-1      :0] rs2_data,

  output [`REG_LEN-1:0] rd_data_execute,

  output [`MEMD_SIZE_LOG-1:0] mem_addr,
  output [`REG_LEN-1      :0] mem_data,

  input  [`MEMI_SIZE_LOG-1:0] pc,
  output [`MEMI_SIZE_LOG-1:0] next_pc_branch
);

  assign rd_data_execute =
    {`REG_LEN{opcode==`INST_OP_LI }} & rs1_imm |
    {`REG_LEN{opcode==`INST_OP_ADD}} & (rs1_data + rs2_data) |
    {`REG_LEN{opcode==`INST_OP_MUL}} & (rs1_data * rs2_data);

  assign mem_addr = rs1_data[`MEMD_SIZE_LOG-1:0];
  assign mem_data = rs2_data;

  assign next_pc_branch  = (rs2_data==0)? (pc + rs1_br_offset) : (pc + 1);

endmodule




`include "src/simpleooo/param.v"

module execute(
  input  [`MEMI_SIZE_LOG-1:0] pc,
  input  [`INST_SIZE_LOG-1:0] op,
  input  [`REG_LEN-1      :0] rs1_imm,
  input  [`MEMI_SIZE_LOG-1:0] rs1_br_offset,
  input  [`REG_LEN-1      :0] rs1_data,
  input  [`REG_LEN-1      :0] rs2_data,
  input                       rd_data_use_execute,

  output [`REG_LEN-1      :0] rd_data,

  // input  [`REG_LEN-1      :0] memd [`MEMD_SIZE-1:0],
  input [`REG_LEN-1      :0] rd_data_memory,
  output [`MEMD_SIZE_LOG-1:0] mem_addr,
  output [`REG_LEN-1      :0] mem_data,

  input                       is_br,
  output                      taken,
  output [`MEMI_SIZE_LOG-1:0] next_pc
);

  // alu
  wire [`REG_LEN-1:0] rd_data_execute;
  assign rd_data_execute =
    {`REG_LEN{op==`INST_OP_LI }} & rs1_imm |
    {`REG_LEN{op==`INST_OP_ADD}} & (rs1_data + rs2_data) |
    {`REG_LEN{op==`INST_OP_MUL}} & (rs1_data * rs2_data);

  // rd
  assign rd_data = rd_data_use_execute?
    rd_data_execute:
    ({`REG_LEN{op==`INST_OP_LD}} & rd_data_memory);

  // memory read
  // wire [`REG_LEN-1      :0] rd_data_memory;
  wire                      mem_read_valid;
  wire [`MEMD_SIZE_LOG-1:0] mem_read_addr;
  assign mem_read_valid = op==`INST_OP_LD;
  assign mem_read_addr = mem_read_valid? mem_addr : 0;
  // assign rd_data_memory = memd[mem_read_addr];

  // memory write
  assign mem_addr = rs1_data[`MEMD_SIZE_LOG-1:0];
  assign mem_data = rs2_data;

  // branch
  wire [`MEMI_SIZE_LOG-1:0] next_pc_branch;
  assign taken = (rs2_data==0);
  assign next_pc_branch = taken? (pc + rs1_br_offset) : (pc + 1);
  assign next_pc = is_br? next_pc_branch : (pc + 1);

endmodule


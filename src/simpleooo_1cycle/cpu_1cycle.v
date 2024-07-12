

`include "src/simpleooo_1cycle/param.v"

`include "src/simpleooo_1cycle/rf_1.v"
`include "src/simpleooo_1cycle/memi_1.v"
`include "src/simpleooo_1cycle/memd_1.v"

`include "src/simpleooo_1cycle/decode_1.v"
`include "src/simpleooo_1cycle/execute_1.v"

module cpu_1cycle(
  input clk,
  input rst
);

  // STEP PC
  reg  [`MEMI_SIZE_LOG-1:0] pc;
  wire [`MEMI_SIZE_LOG-1:0] next_pc;
  always @(posedge clk) begin
    if (rst) pc <= 0;
    else     pc <= next_pc;
  end


  // STEP Fetch
  wire [`INST_LEN-1:0] inst;
  memi_1 memi_instance(
    .clk(clk), .rst(rst),
    .req_addr(pc), .resp_data(inst)
  );


  // STEP Decode
  wire [`INST_SIZE_LOG-1:0] opcode;
  wire [`REG_LEN-1      :0] rs1_imm;
  wire [`RF_SIZE_LOG-1  :0] rs1;
  wire [`MEMI_SIZE_LOG-1:0] rs1_br_offset;
  wire [`RF_SIZE_LOG-1  :0] rs2;

  wire                    wen;
  wire [`RF_SIZE_LOG-1:0] rd;
  wire                    rd_data_use_execute;

  wire mem_valid;
  wire mem_rdwt;

  wire is_br;

  decode_1 decode_instance(
    .inst(inst),
    .opcode(opcode), .rs1_imm(rs1_imm), .rs1(rs1),
    .rs1_br_offset(rs1_br_offset), .rs2(rs2),
    .wen(wen), .rd(rd), .rd_data_use_execute(rd_data_use_execute),
    .mem_valid(mem_valid), .mem_rdwt(mem_rdwt),
    .is_br(is_br)
  );


  // STEP rf Read Write
  wire [`REG_LEN-1:0] rs1_data;
  wire [`REG_LEN-1:0] rs2_data;
  wire [`REG_LEN-1:0] rd_data;
  rf_1 rf_instance(
    .clk(clk), .rst(rst),
    .rs1(rs1), .rs1_data(rs1_data),
    .rs2(rs2), .rs2_data(rs2_data),
    .wen(wen), .rd(rd), .rd_data(rd_data)
  );


  // STEP Execute
  wire [`REG_LEN-1      :0] rd_data_execute;
  wire [`MEMD_SIZE_LOG-1:0] mem_addr;
  wire [`REG_LEN-1      :0] mem_data;
  wire [`MEMI_SIZE_LOG-1:0] next_pc_branch;
  execute_1 execute_instance(
    .opcode(opcode), .rs1_imm(rs1_imm), .rs1_br_offset(rs1_br_offset),
    .rs1_data(rs1_data), .rs2_data(rs2_data),
    .rd_data_execute(rd_data_execute),
    .mem_addr(mem_addr), .mem_data(mem_data),
    .pc(pc), .next_pc_branch(next_pc_branch)
  );


  // STEP Memory Read/Write
  wire [`REG_LEN-1:0] rd_data_memory;
  memd_1 memd_instance(
    .clk(clk), .rst(rst),
    .req_valid(mem_valid), .req_rdwt(mem_rdwt),
    .req_addr(mem_addr), .req_data(mem_data),
    .resp_data(rd_data_memory)
  );


  // STEP Writeback
  assign rd_data = rd_data_use_execute? rd_data_execute:rd_data_memory;
  assign next_pc = is_br? next_pc_branch:(pc+1);


endmodule


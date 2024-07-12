
`include "param.v"


module imm(
  input  wire [`INST_LEN-1: 0] inst,
  output wire [`REG_LEN-1 : 0] IMM_I,
  output wire [`REG_LEN-1 : 0] IMM_S,
  output wire [`REG_LEN-1 : 0] IMM_B,
  output wire [`REG_LEN-1 : 0] IMM_U,
  output wire [`REG_LEN-1 : 0] IMM_J
);

  assign IMM_I = { {21{inst[31]}}, inst[30:25], inst[24:21], inst[20] };
  assign IMM_S = { {21{inst[31]}}, inst[30:25], inst[11:8], inst[7] };
  assign IMM_B = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
  assign IMM_U = { inst[31], inst[30:20], inst[19:12], 12'b0 };
  assign IMM_J = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0 };

endmodule


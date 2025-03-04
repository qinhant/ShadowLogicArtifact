`define ALU_OP_WIDTH 4

`define ALU_OP_ADD  `ALU_OP_WIDTH'd0
`define ALU_OP_SLL  `ALU_OP_WIDTH'd1
`define ALU_OP_XOR  `ALU_OP_WIDTH'd4
`define ALU_OP_OR   `ALU_OP_WIDTH'd6
`define ALU_OP_AND  `ALU_OP_WIDTH'd7
`define ALU_OP_SRL  `ALU_OP_WIDTH'd5
`define ALU_OP_SEQ  `ALU_OP_WIDTH'd8
`define ALU_OP_SNE  `ALU_OP_WIDTH'd9
`define ALU_OP_SUB  `ALU_OP_WIDTH'd10
`define ALU_OP_SRA  `ALU_OP_WIDTH'd11
`define ALU_OP_SLT  `ALU_OP_WIDTH'd12
`define ALU_OP_SGE  `ALU_OP_WIDTH'd13
`define ALU_OP_SLTU `ALU_OP_WIDTH'd14
`define ALU_OP_SGEU `ALU_OP_WIDTH'd15


// STEP: Arch States
`define REG_LEN       4
`define REG_LEN_LOG   2
`define RF_SIZE       4
`define RF_SIZE_LOG   2
`define MEMI_SIZE     8
`define MEMI_SIZE_LOG 3
`define MEMD_SIZE     4
`define MEMD_SIZE_LOG 2




// STEP: Inst
`define INST_SIZE     6
`define INST_SIZE_LOG 3
`define INST_OP_LI  0
`define INST_OP_ADD 1
`define INST_OP_MUL 2
`define INST_OP_LD  3
`define INST_OP_ST  4
`define INST_OP_BR  5
`define INST_LEN (`INST_SIZE_LOG + `REG_LEN + 2*`RF_SIZE_LOG)
`define OPCODE [`INST_LEN-1:`INST_LEN-`INST_SIZE_LOG]
`define RS1    [`INST_LEN-`INST_SIZE_LOG-1:`INST_LEN-`INST_SIZE_LOG-`REG_LEN]
`define RS2    [2*`RF_SIZE_LOG-1:`RF_SIZE_LOG]
`define RD     [`RF_SIZE_LOG-1:0]




// STEP: Init state
`define INIT_VALUE_ZERO 0
`define INIT_VALUE_CUSTOMIZED 1
`define INIT_VALUE `INIT_VALUE_CUSTOMIZED


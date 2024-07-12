
// STEP: Arch States
`define REG_LEN       32
`define RF_SIZE       32
`define RF_SIZE_LOG   5
`define MEMI_SIZE     16
`define MEMI_SIZE_LOG 4
`define MEMD_SIZE     4
`define MEMD_SIZE_LOG 2






// STEP: Inst
`define INST_LEN 32

// STEP.1: opcode
`define OP [6:0]

`define OP_LUI     7'b0110111
`define OP_AUIPC   7'b0010111

`define OP_JAL     7'b1101111
`define OP_JALR    7'b1100111
`define OP_BRANCH  7'b1100011

`define OP_LOAD    7'b0000011
`define OP_STORE   7'b0100011

`define OP_ALU_IMM 7'b0010011
`define OP_ALU     7'b0110011






// STEP.2: FUNCT7
`define FUNCT7 [31:25]

`define FUNCT7_SHIFT_LOGIC 7'b0000000
`define FUNCT7_SHIFT_ARITH 7'b0100000

`define FUNCT7_ADD 7'b0000000
`define FUNCT7_SUB 7'b0100000

`define FUNCT7_ZERO 7'b0000000

`define FUNCT7_MUL_DIV 7'b0000001






// STEP.3: FUNCT3
`define FUNCT3 [14:12]

// STEP.3.1
`define FUNCT3_ZERO  3'h0


// STEP.3.2: Branch
`define FUNCT3_BEQ  3'h0
`define FUNCT3_BNE  3'h1
`define FUNCT3_BLT  3'h4
`define FUNCT3_BGE  3'h5
`define FUNCT3_BLTU 3'h6
`define FUNCT3_BGEU 3'h7


// STEP.3.3: Memory
`define FUNCT3_MEM_W  3'h2


// STEP.3.4: Arithmetic
`define FUNCT3_ADD_SUB 3'h0
`define FUNCT3_SLL     3'h1
`define FUNCT3_SLT     3'h2
`define FUNCT3_SLTU    3'h3
`define FUNCT3_XOR     3'h4
`define FUNCT3_SRA_SRL 3'h5
`define FUNCT3_OR      3'h6
`define FUNCT3_AND     3'h7


// STEP.3.5: MUL
`define FUNCT3_MUL    3'h0
`define FUNCT3_MULH   3'h1
`define FUNCT3_MULHSU 3'h2
`define FUNCT3_MULHU  3'h3






// STEP.4
`define RS1   [19:15]
`define RS2   [24:20]
`define RD    [11:7]
`define SHAMT [4:0]
`define MUL_H [63:32]
`define MUL_L [31: 0]






// STEP: Init state
// `define COSTOMIZE_MEMI
// `define COSTOMIZE_MEMD
// `define COSTOMIZE_RF


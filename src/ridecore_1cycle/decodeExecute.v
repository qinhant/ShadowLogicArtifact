
`include "param.v"
`include "imm.v"


module  decodeExecute(
  input      [`REG_LEN-1:0] pc,
  input      [`INST_LEN-1:0] inst,

  output reg [`REG_LEN-1:0] next_pc,

  output     [`RF_SIZE_LOG-1:0] rs1,
  input      [`REG_LEN-1    :0] rs1_data,
  output     [`RF_SIZE_LOG-1:0] rs2,
  input      [`REG_LEN-1    :0] rs2_data,
  output reg                    wen,
  output     [`RF_SIZE_LOG-1:0] rd,
  output reg [`REG_LEN-1    :0] rd_data,

  output reg                mem_valid,
  output reg                mem_rdwt,
  output reg [`REG_LEN-1:0] mem_addr,
  output reg [`REG_LEN-1:0] mem_data_write,
  input      [`REG_LEN-1:0] mem_data_read,

  output reg                valid_inst
);
  reg  muldiv_valid;
  reg  br_valid;
  wire [`REG_LEN-1:0] imm_I;
  wire [`REG_LEN-1:0] imm_S;
  wire [`REG_LEN-1:0] imm_B;
  wire [`REG_LEN-1:0] imm_U;
  wire [`REG_LEN-1:0] imm_J;
  imm imm_instance(
    .inst(inst),
    .IMM_I(imm_I), .IMM_S(imm_S), .IMM_B(imm_B), .IMM_U(imm_U), .IMM_J(imm_J)
  );

  assign rs1 = inst`RS1;
  assign rs2 = inst`RS2;
  assign rd  = inst`RD;

  reg [2*`REG_LEN-1:0] mul_temp;
  always @(*) begin
    next_pc    = pc + 4;
    wen        = 0;
    mem_valid  = 0;
    valid_inst = 0;
    muldiv_valid = 0;
    br_valid = 0;

    // Though not necessary, initalize them to remove warnings
    rd_data        = 0;
    mem_rdwt       = 0;
    mem_addr       = 0;
    mem_data_write = 0;
    mul_temp       = 0;

    case (inst`OP)
      `OP_LUI: begin
        wen        = 1;
        rd_data    = imm_U;
        valid_inst = 1;
      end
      



      `OP_AUIPC: begin
        wen        = 1;
        rd_data    = pc + imm_U;
        valid_inst = 1;
      end
      



      `OP_JAL: begin
        next_pc    = pc + imm_J;
        wen        = 1;
        rd_data    = pc + 4;
        valid_inst = 1;
        br_valid <= 1;
      end
      



      `OP_JALR: begin
        if (inst`FUNCT3==`FUNCT3_ZERO) begin
          next_pc    = rs1_data + imm_I;
          next_pc    = {next_pc[`REG_LEN-1:1], 1'b0};
          wen        = 1;
          rd_data    = pc + 4;
          valid_inst = 1;
          br_valid <= 1;
        end
      end
      



      `OP_BRANCH: begin
        if (inst`FUNCT3==`FUNCT3_BEQ) begin
          if (rs1_data==rs2_data) next_pc = pc + imm_B;
          valid_inst = 1;
          br_valid <= 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_BNE) begin
          if (rs1_data!=rs2_data) next_pc = pc + imm_B;
          valid_inst = 1;
          br_valid <= 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_BLT) begin
          if ($signed(rs1_data)< $signed(rs2_data)) next_pc = pc + imm_B;
          valid_inst = 1;
          br_valid <= 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_BGE) begin
          if ($signed(rs1_data)>=$signed(rs2_data)) next_pc = pc + imm_B;
          valid_inst = 1;
          br_valid <= 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_BLTU) begin
          if (rs1_data<rs2_data) next_pc = pc + imm_B;
          valid_inst = 1;
          br_valid <= 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_BGEU) begin
          if (rs1_data>=rs2_data) next_pc = pc + imm_B;
          valid_inst = 1;
          br_valid <= 1;
        end
      end
      



      `OP_LOAD: begin
        if (inst`FUNCT3==`FUNCT3_MEM_W) begin
          mem_valid  = 1;
          mem_rdwt   = 1;
          mem_addr   = rs1_data + imm_I;
          wen        = 1;
          rd_data    = mem_data_read;
          valid_inst = 1;
        end
      end
      



      `OP_STORE: begin
        if (inst`FUNCT3==`FUNCT3_MEM_W) begin
          mem_valid      = 1;
          mem_rdwt       = 0;
          mem_addr       = rs1_data + imm_S;
          mem_data_write = rs2_data;
          valid_inst     = 1;
        end
      end



      
      `OP_ALU_IMM: begin
        if (inst`FUNCT3==`FUNCT3_ADD_SUB) begin
          wen        = 1;
          rd_data    = rs1_data + imm_I;
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_SLT) begin
          wen        = 1;
          rd_data    = {31'h0, $signed(rs1_data) < $signed(imm_I)};
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_SLTU) begin
          wen        = 1;
          rd_data    = {31'h0, rs1_data < imm_I};
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_XOR) begin
          wen        = 1;
          rd_data    = rs1_data ^ imm_I;
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_OR) begin
          wen        = 1;
          rd_data    = rs1_data | imm_I;
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_AND) begin
          wen        = 1;
          rd_data    = rs1_data & imm_I;
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_SLL && inst`FUNCT7==`FUNCT7_SHIFT_LOGIC) begin
          wen        = 1;
          rd_data    = rs1_data << imm_I`SHAMT;
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_SRA_SRL && inst`FUNCT7==`FUNCT7_SHIFT_LOGIC) begin
          wen        = 1;
          rd_data    = rs1_data >> imm_I`SHAMT;
          valid_inst = 1;
        end
        
        if (inst`FUNCT3==`FUNCT3_SRA_SRL && inst`FUNCT7==`FUNCT7_SHIFT_ARITH) begin
          wen        = 1;
          rd_data    = $signed(rs1_data) >>> imm_I`SHAMT;
          valid_inst = 1;
        end
      end
      



      `OP_ALU: begin
        if (inst`FUNCT3==`FUNCT3_ADD_SUB && inst`FUNCT7==`FUNCT7_ADD) begin
          wen        = 1;
          rd_data    = rs1_data + rs2_data;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_ADD_SUB && inst`FUNCT7==`FUNCT7_SUB) begin
          wen        = 1;
          rd_data    = rs1_data - rs2_data;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_SLL && inst`FUNCT7==`FUNCT7_ZERO) begin
          wen        = 1;
          rd_data    = rs1_data << rs2_data`SHAMT;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_SLT && inst`FUNCT7==`FUNCT7_ZERO) begin
          wen        = 1;
          rd_data    = {31'h0, $signed(rs1_data) < $signed(rs2_data)};
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_SLTU && inst`FUNCT7==`FUNCT7_ZERO) begin
          wen        = 1;
          rd_data    = {31'h0, rs1_data < rs2_data};
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_XOR && inst`FUNCT7==`FUNCT7_ZERO) begin
          wen        = 1;
          rd_data    = rs1_data ^ rs2_data;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_SRA_SRL && inst`FUNCT7==`FUNCT7_SHIFT_LOGIC) begin
          wen        = 1;
          rd_data    = rs1_data >> rs2_data`SHAMT;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_SRA_SRL && inst`FUNCT7==`FUNCT7_SHIFT_ARITH) begin
          wen        = 1;
          rd_data    = $signed(rs1_data) >>> rs2_data`SHAMT;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_OR && inst`FUNCT7==`FUNCT7_ZERO) begin
          wen        = 1;
          rd_data    = rs1_data | rs2_data;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_AND && inst`FUNCT7==`FUNCT7_ZERO) begin
          wen        = 1;
          rd_data    = rs1_data & rs2_data;
          valid_inst = 1;
        end

        if (inst`FUNCT3==`FUNCT3_MUL && inst`FUNCT7==`FUNCT7_MUL_DIV) begin
          wen        = 1;
          mul_temp   = $signed(rs1_data) * $signed(rs2_data);
          rd_data    = mul_temp`MUL_L;
          valid_inst = 1;
          muldiv_valid = 1;
        end

        if (inst`FUNCT3==`FUNCT3_MULH && inst`FUNCT7==`FUNCT7_MUL_DIV) begin
          wen        = 1;
          mul_temp   = $signed(rs1_data) * $signed(rs2_data);
          rd_data    = mul_temp`MUL_H;
          valid_inst = 1;
          muldiv_valid = 1;
        end

        if (inst`FUNCT3==`FUNCT3_MULHSU && inst`FUNCT7==`FUNCT7_MUL_DIV) begin
          wen        = 1;
          mul_temp   = $signed(rs1_data) * $signed({1'b0, rs2_data});
          rd_data    = mul_temp`MUL_H;
          valid_inst = 1;
          muldiv_valid = 1;
        end

        if (inst`FUNCT3==`FUNCT3_MULHU && inst`FUNCT7==`FUNCT7_MUL_DIV) begin
          wen        = 1;
          mul_temp   = $signed({1'b0, rs1_data}) * $signed({1'b0, rs2_data});
          rd_data    = mul_temp`MUL_H;
          valid_inst = 1;
          muldiv_valid = 1;
        end
      end



      default: begin end
    endcase
  end

endmodule


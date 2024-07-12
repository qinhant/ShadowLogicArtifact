`include "constants.vh"
`default_nettype none
// 8KB Instruction Memory (32bit*4way)
module imem(
	    input wire 			 clk,
	    input wire [8:0] 		 addr,
	    output reg [`INSN_LEN*4-1:0] data
	    );
   reg [`INSN_LEN*4-1:0] 		 mem[0:`IMEM_SIZE-1];
   always @ (posedge clk) begin
      data <= mem[addr];
   end
endmodule // imem

module imem_ld(
	       input wire 		    clk,
          input wire           reset_x,
	       input wire [8:0] 	    addr,
	       output reg [4*`INSN_LEN-1:0] rdata,
	       input wire [4*`INSN_LEN-1:0] wdata,
	       input wire we
	       );
   reg [`INSN_LEN*4-1:0] 		 mem[0:`IMEM_SIZE-1];
   always @ (posedge clk) begin
      if (!reset_x) begin
`ifdef CONCRETE_IMEM
         // 0: pc <- R1 + 0;
         // 1: R0 <= 0;
         // 2: R0 <= 0;
         // mem[0] <= {32'h0,
         //            12'h0, 5'h0, `FUNCT3_ADD_SUB, 5'h0, `OP_ALU_IMM,
         //            12'h0, 5'h0, `FUNCT3_ADD_SUB, 5'h0, `OP_ALU_IMM,
         //            12'h0, 5'h1, `FUNCT3_ZERO, 5'h0, `OP_JALR};
         
         // 0: R1 <= 1;
         // 1: R2 <= R1 + R2;
         // mem[0] <= {32'h0,
         //            32'h0,
         //            `FUNCT7_ADD, 5'h1, 5'h2, `FUNCT3_ADD_SUB, 5'h2, `OP_ALU,
         //            12'h1, 5'h1, `FUNCT3_ADD_SUB, 5'h1, `OP_ALU_IMM};

         // 0: R2 <- ld R0
         // 1: R1 <- R1 + 1
         // 2: R1 <- R1 * R1
         // 3: R1 <- R1 * R1
         // 4: if (R1==R1) PC <- PC + 2
         // 5: R2 <- R2 * R2
         // mem[0] <= {`RV32_FUNCT7_MUL_DIV, 5'h1, 5'h1, `RV32_FUNCT3_MUL, 5'h1, `RV32_OP,
         //            `RV32_FUNCT7_MUL_DIV, 5'h1, 5'h1, `RV32_FUNCT3_MUL, 5'h1, `RV32_OP,
         //            12'h1, 5'h1, `RV32_FUNCT3_ADD_SUB, 5'h1, `RV32_OP_IMM,
         //            12'h0, 5'h0, 3'h0, 5'h2, `RV32_LOAD};
         // mem[1] <= {32'h00000000,
         //            32'h00000000,
         //            `RV32_FUNCT7_MUL_DIV, 5'h2, 5'h2, `RV32_FUNCT3_MUL, 5'h2, `RV32_OP,
         //            7'h0, 5'h1, 5'h1, `RV32_FUNCT3_BEQ, 5'h8, `RV32_BRANCH};
         // mem[0] <= {`RV32_FUNCT7_MUL_DIV, 5'h1, 5'h1, `RV32_FUNCT3_MUL, 5'h1, `RV32_OP,
         //            `RV32_FUNCT7_MUL_DIV, 5'h1, 5'h1, `RV32_FUNCT3_MUL, 5'h1, `RV32_OP,
         //            12'h1, 5'h1, `RV32_FUNCT3_ADD_SUB, 5'h1, `RV32_OP_IMM,
         //            12'h0, 5'h0, 3'h0, 5'h2, `RV32_LOAD};
         // mem[1] <= {32'h00000000,
         //            32'h00000000,
         //            12'h0, 5'h2, 3'h0, 5'h3, `RV32_LOAD,
         //            7'h0, 5'h1, 5'h1, `RV32_FUNCT3_BEQ, 5'h8, `RV32_BRANCH};
      
         mem[0] <= {12'h0, 5'h3, 3'h0, 5'h4, `RV32_LOAD,
                    12'h0, 5'h2, 3'h0, 5'h3, `RV32_LOAD,
                    7'h0, 5'h1, 5'h0, `RV32_FUNCT3_BEQ, 5'h0, `RV32_BRANCH,
                    `RV32_FUNCT7_MUL_DIV, 5'h1, 5'h1, `RV32_FUNCT3_MUL, 5'h1, `RV32_OP};
         mem[1] <= {32'h00000000,
                    32'h00000000,
                    32'h00000000,
                    32'h00000000};

         // mem[0] <= {7'h0, 5'h3, 5'h11, `RV32_FUNCT3_BEQ, 5'h4, `RV32_BRANCH,
         //            12'h0, 5'h18, 3'h0, 5'h3, `RV32_LOAD,
         //            7'h0, 5'h4, 5'h6, `RV32_FUNCT3_BEQ, 5'h0, `RV32_BRANCH,
         //            12'h8, 5'h0, 3'h0, 5'h4, `RV32_LOAD};
         // mem[1] <= {32'h00000000,
         //            32'h00000000,
         //            32'h00000000,
         //            12'h0, 5'h3, 3'h0, 5'h13, `RV32_LOAD};
`else
for (int i = 0; i < `IMEM_SIZE; i = i + 1) begin
   mem[i] <= {32'h0, 32'h0, 32'h0, 32'h0};
end
`endif
      end else begin
         rdata <= `IMEM_SIZE_LOG > 0 ?mem[addr[`IMEM_SIZE_LOG-1:0]]: mem[0];
         // if (we) begin
   	   //    mem[addr[`IMEM_SIZE_LOG-1:0]] <= wdata;
         // end
      end
   end
`ifdef EQUIV_CLASS_ABSTRACT
wire [6:0] op_1 = mem[0][102:96];
wire [6:0] op_2 = mem[0][70:64];
wire [6:0] op_3 = mem[0][38:32];
wire [6:0] op_4 = mem[0][6:0];
wire [6:0] op_5 = mem[1][102:96];
wire [6:0] op_6 = mem[1][70:64];
wire [6:0] op_7 = mem[1][38:32];
wire [6:0] op_8 = mem[1][6:0];

wire [2:0] func3_1 = mem[0][110:108];
wire [2:0] func3_2 = mem[0][78:76];
wire [2:0] func3_3 = mem[0][46:44];
wire [2:0] func3_4 = mem[0][14:12];
wire [2:0] func3_5 = mem[1][110:108];
wire [2:0] func3_6 = mem[1][78:76];
wire [2:0] func3_7 = mem[1][46:44];
wire [2:0] func3_8 = mem[1][14:12];

wire [6:0] funct7_1 = mem[0][127:121];
wire [6:0] funct7_2 = mem[0][95:89];
wire [6:0] funct7_3 = mem[0][63:57];
wire [6:0] funct7_4 = mem[0][31:25];
wire [6:0] funct7_5 = mem[1][127:121];
wire [6:0] funct7_6 = mem[1][95:89];
wire [6:0] funct7_7 = mem[1][63:57];
wire [6:0] funct7_8 = mem[1][31:25];

wire [4:0] rs1_1 = mem[0][115:111];
wire [4:0] rs1_2 = mem[0][83:79];
wire [4:0] rs1_3 = mem[0][51:47];
wire [4:0] rs1_4 = mem[0][19:15];
wire [4:0] rs1_5 = mem[1][115:111];
wire [4:0] rs1_6 = mem[1][83:79];
wire [4:0] rs1_7 = mem[1][51:47];
wire [4:0] rs1_8 = mem[1][19:15];

wire [4:0] rs2_1 = mem[0][120:116];
wire [4:0] rs2_2 = mem[0][88:84];
wire [4:0] rs2_3 = mem[0][56:52];
wire [4:0] rs2_4 = mem[0][24:20];
wire [4:0] rs2_5 = mem[1][120:116];
wire [4:0] rs2_6 = mem[1][88:84];
wire [4:0] rs2_7 = mem[1][56:52];
wire [4:0] rs2_8 = mem[1][24:20];

wire [4:0] rd_1 = mem[0][107:103];
wire [4:0] rd_2 = mem[0][75:71];
wire [4:0] rd_3 = mem[0][43:39];
wire [4:0] rd_4 = mem[0][11:7];
wire [4:0] rd_5 = mem[1][107:103];
wire [4:0] rd_6 = mem[1][75:71];
wire [4:0] rd_7 = mem[1][43:39];
wire [4:0] rd_8 = mem[1][11:7];

// // There must be a load
// assume property (op_1==`RV32_LOAD||op_2==`RV32_LOAD||op_3==`RV32_LOAD||op_4==`RV32_LOAD
//                 ||op_5==`RV32_LOAD||op_6==`RV32_LOAD||op_7==`RV32_LOAD||op_8==`RV32_LOAD);


assume property (op_1==`RV32_LUI && rd_1<24
               || op_1==`RV32_AUIPC && rd_1<24
               || op_1==`RV32_JAL && rd_1<24
               || op_1==`RV32_JALR && rd_1<24 && rs1_1<24 && func3_1==0 
               || op_1==`RV32_BRANCH && rs1_1<24 && rs2_1<24 && func3_1==0
               || op_1==`RV32_LOAD && rd_1<24 && rs1_1<24 && func3_1==0
               || op_1==`RV32_STORE && rs1_1<24 && rs2_1<24 && func3_1==0
               || op_1==`RV32_OP_IMM && rd_1<24 && rs1_1<24 && func3_1==0
               || op_1==`RV32_OP && rd_1<24 && rs1_1<24 && rs2_1<24 && func3_1==0 && funct7_1==0
               || op_1==`RV32_OP && rd_1<24 && rs1_1<24 && rs2_1<24 && func3_1==0 && funct7_1==1
               || op_1==0);
assume property (op_2==`RV32_LUI && rd_2<24
               || op_2==`RV32_AUIPC && rd_2<24
               || op_2==`RV32_JAL && rd_2<24
               || op_2==`RV32_JALR && rd_2<24 && rs1_2<24 && func3_2==0
               || op_2==`RV32_BRANCH && rs1_2<24 && rs2_2<24 && func3_2==0
               || op_2==`RV32_LOAD && rd_2<24 && rs1_2<24 && func3_2==0
               || op_2==`RV32_STORE && rs1_2<24 && rs2_2<24 && func3_2==0
               || op_2==`RV32_OP_IMM && rd_2<24 && rs1_2<24 && func3_2==0
               || op_2==`RV32_OP && rd_2<24 && rs1_2<24 && rs2_2<24 && func3_2==0 && funct7_2==0
               || op_2==`RV32_OP && rd_2<24 && rs1_2<24 && rs2_2<24 && func3_2==0 && funct7_2==1
               || op_2==0);
assume property (op_3==`RV32_LUI && rd_3<24
               || op_3==`RV32_AUIPC && rd_3<24
               || op_3==`RV32_JAL && rd_3<24
               || op_3==`RV32_JALR && rd_3<24 && rs1_3<24 && func3_3==0 
               || op_3==`RV32_BRANCH && rs1_3<24 && rs2_3<24 && func3_3==0
               || op_3==`RV32_LOAD && rd_3<24 && rs1_3<24 && func3_3==0
               || op_3==`RV32_STORE && rs1_3<24 && rs2_3<24 && func3_3==0
               || op_3==`RV32_OP_IMM && rd_3<24 && rs1_3<24 && func3_3==0
               || op_3==`RV32_OP && rd_3<24 && rs1_3<24 && rs2_3<24 && func3_3==0 && funct7_3==0
               || op_3==`RV32_OP && rd_3<24 && rs1_3<24 && rs2_3<24 && func3_3==0 && funct7_3==1
               || op_3==0);
assume property (op_4==`RV32_LUI && rd_4<24
               || op_4==`RV32_AUIPC && rd_4<24
               || op_4==`RV32_JAL && rd_4<24
               || op_4==`RV32_JALR && rd_4<24 && rs1_4<24 && func3_4==0 
               || op_4==`RV32_BRANCH && rs1_4<24 && rs2_4<24 && func3_4==0
               || op_4==`RV32_LOAD && rd_4<24 && rs1_4<24 && func3_4==0
               || op_4==`RV32_STORE && rs1_4<24 && rs2_4<24 && func3_4==0
               || op_4==`RV32_OP_IMM && rd_4<24 && rs1_4<24 && func3_4==0
               || op_4==`RV32_OP && rd_4<24 && rs1_4<24 && rs2_4<24 && func3_4==0 && funct7_4==0
               || op_4==`RV32_OP && rd_4<24 && rs1_4<24 && rs2_4<24 && func3_4==0 && funct7_4==1
               || op_4==0);
assume property (op_5==`RV32_LUI && rd_5<24
               || op_5==`RV32_AUIPC && rd_5<24
               || op_5==`RV32_JAL && rd_5<24
               || op_5==`RV32_JALR && rd_5<24 && rs1_5<24 && func3_5==0 
               || op_5==`RV32_BRANCH && rs1_5<24 && rs2_5<24 && func3_5==0
               || op_5==`RV32_LOAD && rd_5<24 && rs1_5<24 && func3_5==0
               || op_5==`RV32_STORE && rs1_5<24 && rs2_5<24 && func3_5==0
               || op_5==`RV32_OP_IMM && rd_5<24 && rs1_5<24 && func3_5==0
               || op_5==`RV32_OP && rd_5<24 && rs1_5<24 && rs2_5<24 && func3_5==0 && funct7_5==0
               || op_5==`RV32_OP && rd_5<24 && rs1_5<24 && rs2_5<24 && func3_5==0 && funct7_5==1
               || op_5==0);
assume property (op_6==`RV32_LUI && rd_6<24
               || op_6==`RV32_AUIPC && rd_6<24
               || op_6==`RV32_JAL && rd_6<24
               || op_6==`RV32_JALR && rd_6<24 && rs1_6<24 && func3_6==0 
               || op_6==`RV32_BRANCH && rs1_6<24 && rs2_6<24 && func3_6==0
               || op_6==`RV32_LOAD && rd_6<24 && rs1_6<24 && func3_6==0
               || op_6==`RV32_STORE && rs1_6<24 && rs2_6<24 && func3_6==0
               || op_6==`RV32_OP_IMM && rd_6<24 && rs1_6<24 && func3_6==0
               || op_6==`RV32_OP && rd_6<24 && rs1_6<24 && rs2_6<24 && func3_6==0 && funct7_6==0
               || op_6==`RV32_OP && rd_6<24 && rs1_6<24 && rs2_6<24 && func3_6==0 && funct7_6==1
               || op_6==0);
assume property (op_7==`RV32_LUI && rd_7<24
               || op_7==`RV32_AUIPC && rd_7<24
               || op_7==`RV32_JAL && rd_7<24
               || op_7==`RV32_JALR && rd_7<24 && rs1_7<24 && func3_7==0 
               || op_7==`RV32_BRANCH && rs1_7<24 && rs2_7<24 && func3_7==0
               || op_7==`RV32_LOAD && rd_7<24 && rs1_7<24 && func3_7==0
               || op_7==`RV32_STORE && rs1_7<24 && rs2_7<24 && func3_7==0
               || op_7==`RV32_OP_IMM && rd_7<24 && rs1_7<24 && func3_7==0
               || op_7==`RV32_OP && rd_7<24 && rs1_7<24 && rs2_7<24 && func3_7==0 && funct7_7==0
               || op_7==`RV32_OP && rd_7<24 && rs1_7<24 && rs2_7<24 && func3_7==0 && funct7_7==1
               || op_7==0);
assume property (op_8==`RV32_LUI && rd_8<24
               || op_8==`RV32_AUIPC && rd_8<24
               || op_8==`RV32_JAL && rd_8<24
               || op_8==`RV32_JALR && rd_8<24 && rs1_8<24 && func3_8==0 
               || op_8==`RV32_BRANCH && rs1_8<24 && rs2_8<24 && func3_8==0
               || op_8==`RV32_LOAD && rd_8<24 && rs1_8<24 && func3_8==0
               || op_8==`RV32_STORE && rs1_8<24 && rs2_8<24 && func3_8==0
               || op_8==`RV32_OP_IMM && rd_8<24 && rs1_8<24 && func3_8==0
               || op_8==`RV32_OP && rd_8<24 && rs1_8<24 && rs2_8<24 && func3_8==0 && funct7_8==0
               || op_8==`RV32_OP && rd_8<24 && rs1_8<24 && rs2_8<24 && func3_8==0 && funct7_8==1
               || op_8==0);
`endif
endmodule
`default_nettype wire

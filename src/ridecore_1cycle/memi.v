
`include "param.v"


module memi(
  input clk,
  input rst,

  input  [`MEMI_SIZE_LOG-1:0] req_addr,
  output [`INST_LEN-1     :0] resp_data
);

  reg [`INST_LEN-1:0] array [`MEMI_SIZE-1:0];

  // STEP Read
  assign resp_data = array[req_addr];

  always @(posedge clk) begin
    // STEP Init
    if (rst) begin
      integer i;
      for (i=0; i<`MEMI_SIZE; i=i+1) array[i] <= 0;

`ifdef COSTOMIZE_MEMI
      // 0: R1 <= 1;
      // 1: R2 <= R1 + R2;
      // array[0] <= {12'h1, 5'h1, `FUNCT3_ADD_SUB, 5'h1, `OP_ALU_IMM};
      // array[1] <= {`FUNCT7_ADD, 5'h1, 5'h2, `FUNCT3_ADD_SUB, 5'h2, `OP_ALU};
      // array[2] <= 0;
      // array[3] <= 0;
      
      // 0: pc <- R1 + 0;
      // 1: R0 <= 0;
      // 2: R0 <= 0;
      array[0] <= {12'h0, 5'h1, `FUNCT3_ZERO, 5'h0, `OP_JALR};
      array[1] <= {12'h0, 5'h0, `FUNCT3_ADD_SUB, 5'h0, `OP_ALU_IMM};
      array[2] <= {12'h0, 5'h0, `FUNCT3_ADD_SUB, 5'h0, `OP_ALU_IMM};
`endif
    end
  end

endmodule


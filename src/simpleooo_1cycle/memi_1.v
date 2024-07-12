

`include "src/simpleooo_1cycle/param.v"

module memi_1(
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
      if (`INIT_VALUE==`INIT_VALUE_ZERO) begin
        integer i;
        for (i=0; i<`MEMI_SIZE; i=i+1) array[i] <= 0;
      end

      else if (`INIT_VALUE==`INIT_VALUE_CUSTOMIZED) begin
        array[0] <= {`INST_SIZE_LOG'd`INST_OP_LI , `REG_LEN'd1, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
        array[1] <= {`INST_SIZE_LOG'd`INST_OP_ADD, `REG_LEN'd0, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
        array[2] <= {`INST_SIZE_LOG'd`INST_OP_ADD, `REG_LEN'd0, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
        array[3] <= {`INST_SIZE_LOG'd`INST_OP_ADD, `REG_LEN'd0, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
        array[4] <= {`INST_SIZE_LOG'd`INST_OP_ADD, `REG_LEN'd0, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
        array[5] <= {`INST_SIZE_LOG'd`INST_OP_ADD, `REG_LEN'd0, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
        array[6] <= {`INST_SIZE_LOG'd`INST_OP_ADD, `REG_LEN'd0, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
        array[7] <= {`INST_SIZE_LOG'd`INST_OP_ADD, `REG_LEN'd0, `RF_SIZE_LOG'd0, `RF_SIZE_LOG'd0};
      end
    end
  end


endmodule


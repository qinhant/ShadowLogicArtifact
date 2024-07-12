
`include "param.v"

`include "rf.v"
`include "memi.v"
`include "memd.v"

`include "decodeExecute.v"


module ridecore_1cycle(
  input clk,
  input rst
);

  // STEP PC
  reg  [`REG_LEN-1:0] pc;
  wire [`REG_LEN-1:0] next_pc;
  always @(posedge clk) begin
    if (rst) pc <= 0;
    else     pc <= next_pc;
  end
  
  reg  [`REG_LEN-1:0] last_committed_pc;
  always @(posedge clk) begin
    if (rst) last_committed_pc <= 0;
    else     last_committed_pc <= pc;
  end


  // STEP Fetch
  wire [`INST_LEN-1:0] inst;
  memi memi_instance(
    .clk(clk), .rst(rst),
    .req_addr(pc[`MEMI_SIZE_LOG+1:2]), .resp_data(inst)
  );


  // STEP rf Read Write
  wire [`RF_SIZE_LOG-1:0] rs1;
  wire [`REG_LEN-1    :0] rs1_data;
  wire [`RF_SIZE_LOG-1:0] rs2;
  wire [`REG_LEN-1    :0] rs2_data;
  wire                    wen;
  wire [`RF_SIZE_LOG-1:0] rd;
  wire [`REG_LEN-1    :0] rd_data;
  rf rf_instance(
    .clk(clk), .rst(rst),
    .rs1(rs1), .rs1_data(rs1_data),
    .rs2(rs2), .rs2_data(rs2_data),
    .wen(wen), .rd(rd), .rd_data(rd_data)
  );


  // STEP Memory Read Write
  wire                mem_valid;
  wire                mem_rdwt;
  wire [`REG_LEN-1:0] mem_addr;
  wire [`REG_LEN-1:0] mem_data_write;
  wire [`REG_LEN-1:0] mem_data_read;
  memd memd_instance(
    .clk(clk), .rst(rst),
    .req_valid(mem_valid), .req_rdwt(mem_rdwt), .req_addr(mem_addr[`MEMD_SIZE_LOG+1:2]),
    .req_data(mem_data_write),
    .resp_data(mem_data_read)
  );


  // STEP Decode and Execute
  wire valid_inst;
  decodeExecute decodeExecute_instance(
    .pc(pc),
    .inst(inst),

    .next_pc(next_pc),

    .rs1(rs1), .rs1_data(rs1_data),
    .rs2(rs2), .rs2_data(rs2_data),
    .wen(wen), .rd(rd), .rd_data(rd_data),

    .mem_valid(mem_valid), .mem_rdwt(mem_rdwt), .mem_addr(mem_addr),
    .mem_data_write(mem_data_write),
    .mem_data_read(mem_data_read),

    .valid_inst(valid_inst)
  );

endmodule


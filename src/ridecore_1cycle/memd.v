
`include "param.v"


module memd(
  input clk,
  input rst,

  input                       req_valid,
  input                       req_rdwt,
  input  [`MEMD_SIZE_LOG-1:0] req_addr,
  input  [`REG_LEN-1      :0] req_data,

  output [`REG_LEN-1      :0] resp_data
);

  reg [`REG_LEN-1:0] array [`MEMD_SIZE-1:0];

  // STEP Read
  assign resp_data = array[req_addr];

  always @(posedge clk) begin
    // STEP Init
    if (rst) begin
      integer i;
      for (i=0; i<`MEMD_SIZE; i=i+1) array[i] <= 0;

`ifdef COSTOMIZE_MEMD
      array[0] <= 0;
      array[1] <= 0;
      array[2] <= 0;
      array[3] <= 0;
`endif
    end

    // STEP Write
    else if (req_valid && req_rdwt==0) begin
      array[req_addr] <= req_data;
    end
  end

endmodule


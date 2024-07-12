
`include "ridecore_1cycle.v"
`include "src/ridecore/topsim.v"


module veri_correctness(
  input clk,
  input rst

);

  // STEP: instantiate ooo and ISA
  reg stall_ooo, stall_ISA;
  topsim          ooo(.clk(stall_ooo? 0 : clk), .reset_x(~rst));
  ridecore_1cycle ISA(.clk(stall_ISA? 0 : clk), .rst(rst));


  // STEP: synchronized simulation
  reg  [31:0] total_ooo, total_ISA;
  wire [31:0] total_ooo_next, total_ISA_next;
  assign total_ooo_next = total_ooo + ((stall_ooo | ooo.pipe.prmiss)? 0 : ooo.pipe.comnum);
  assign total_ISA_next = total_ISA + (stall_ISA? 0 : 1);
  always @(posedge clk) begin
    if (rst) begin
      stall_ooo <= 0;
      stall_ISA <= 0;
      total_ooo <= 0;
      total_ISA <= 0;
    end else begin
      if (total_ooo_next==total_ISA_next) begin
        stall_ooo <= 0;
        stall_ISA <= 0;
      end
      if (total_ooo_next<total_ISA_next) begin
        stall_ooo <= 0;
        stall_ISA <= 1;
      end
      if (total_ooo_next>total_ISA_next) begin
        stall_ooo <= 1;
        stall_ISA <= 0;
      end

      total_ooo    <= total_ooo_next;
      total_ISA <= total_ISA_next;
    end
  end


  // STEP: same initial state
  reg init;
  always @(posedge clk) begin
    if (rst)
      init <= 1;
    else
      init <= 0;
  end

  wire same_state =
    ooo.pipe.rob.last_committed_pc[`MEMI_SIZE_LOG+1:0]==ISA.last_committed_pc[`MEMI_SIZE_LOG+1:0]
 && ooo.pipe.aregfile.regfile.mem[ 0]==ISA.rf_instance.array[ 0]
 && ooo.pipe.aregfile.regfile.mem[ 1]==ISA.rf_instance.array[ 1]
 && ooo.pipe.aregfile.regfile.mem[ 2]==ISA.rf_instance.array[ 2]
 && ooo.pipe.aregfile.regfile.mem[ 3]==ISA.rf_instance.array[ 3]
 && ooo.pipe.aregfile.regfile.mem[ 4]==ISA.rf_instance.array[ 4]
 && ooo.pipe.aregfile.regfile.mem[ 5]==ISA.rf_instance.array[ 5]
 && ooo.pipe.aregfile.regfile.mem[ 6]==ISA.rf_instance.array[ 6]
 && ooo.pipe.aregfile.regfile.mem[ 7]==ISA.rf_instance.array[ 7]
 && ooo.pipe.aregfile.regfile.mem[ 8]==ISA.rf_instance.array[ 8]
 && ooo.pipe.aregfile.regfile.mem[ 9]==ISA.rf_instance.array[ 9]
 && ooo.pipe.aregfile.regfile.mem[10]==ISA.rf_instance.array[10]
 && ooo.pipe.aregfile.regfile.mem[11]==ISA.rf_instance.array[11]
 && ooo.pipe.aregfile.regfile.mem[12]==ISA.rf_instance.array[12]
 && ooo.pipe.aregfile.regfile.mem[13]==ISA.rf_instance.array[13]
 && ooo.pipe.aregfile.regfile.mem[14]==ISA.rf_instance.array[14]
 && ooo.pipe.aregfile.regfile.mem[15]==ISA.rf_instance.array[15]
 && ooo.pipe.aregfile.regfile.mem[16]==ISA.rf_instance.array[16]
 && ooo.pipe.aregfile.regfile.mem[17]==ISA.rf_instance.array[17]
 && ooo.pipe.aregfile.regfile.mem[18]==ISA.rf_instance.array[18]
 && ooo.pipe.aregfile.regfile.mem[19]==ISA.rf_instance.array[19]
 && ooo.pipe.aregfile.regfile.mem[20]==ISA.rf_instance.array[20]
 && ooo.pipe.aregfile.regfile.mem[21]==ISA.rf_instance.array[21]
 && ooo.pipe.aregfile.regfile.mem[22]==ISA.rf_instance.array[22]
 && ooo.pipe.aregfile.regfile.mem[23]==ISA.rf_instance.array[23]
 && ooo.pipe.aregfile.regfile.mem[24]==ISA.rf_instance.array[24]
 && ooo.pipe.aregfile.regfile.mem[25]==ISA.rf_instance.array[25]
 && ooo.pipe.aregfile.regfile.mem[26]==ISA.rf_instance.array[26]
 && ooo.pipe.aregfile.regfile.mem[27]==ISA.rf_instance.array[27]
 && ooo.pipe.aregfile.regfile.mem[28]==ISA.rf_instance.array[28]
 && ooo.pipe.aregfile.regfile.mem[29]==ISA.rf_instance.array[29]
 && ooo.pipe.aregfile.regfile.mem[30]==ISA.rf_instance.array[30]
 && ooo.pipe.aregfile.regfile.mem[31]==ISA.rf_instance.array[31]
  ;
  wire same_init_state = init? same_state : 1;

  wire same_memi =
    ooo.instmemory.mem[0]=={ISA.memi_instance.array[ 3],ISA.memi_instance.array[ 2],
                            ISA.memi_instance.array[ 1],ISA.memi_instance.array[ 0]}
 && ooo.instmemory.mem[1]=={ISA.memi_instance.array[ 7],ISA.memi_instance.array[ 6],
                            ISA.memi_instance.array[ 5],ISA.memi_instance.array[ 4]}
 && ooo.instmemory.mem[2]=={ISA.memi_instance.array[11],ISA.memi_instance.array[10],
                            ISA.memi_instance.array[ 9],ISA.memi_instance.array[ 8]}
 && ooo.instmemory.mem[3]=={ISA.memi_instance.array[15],ISA.memi_instance.array[14],
                            ISA.memi_instance.array[13],ISA.memi_instance.array[12]}
  ;
  wire same_init_memi = init? same_memi : 1;

  wire same_memd =
    ooo.datamemory.mem[0]==ISA.memd_instance.array[0]
 && ooo.datamemory.mem[1]==ISA.memd_instance.array[1]
 && ooo.datamemory.mem[2]==ISA.memd_instance.array[2]
 && ooo.datamemory.mem[3]==ISA.memd_instance.array[3]
 && ooo.datamemory.mem[4]==ISA.memd_instance.array[4]
 && ooo.datamemory.mem[5]==ISA.memd_instance.array[5]
 && ooo.datamemory.mem[6]==ISA.memd_instance.array[6]
 && ooo.datamemory.mem[7]==ISA.memd_instance.array[7]
  ;
  wire same_init_memd = init? same_memd : 1;


  // STEP: same state forever
  wire incorrect = (total_ooo==total_ISA) && !same_state;


  // STEP: valid instruction
  wire valid_inst = ISA.valid_inst;

endmodule


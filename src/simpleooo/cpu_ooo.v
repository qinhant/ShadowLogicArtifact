

`include "src/simpleooo/param.v"

`include "src/simpleooo/decode.v"
`include "src/simpleooo/execute.v"

`include "src/simpleooo/param.v"
`include "src/simpleooo/rf.v"
`include "src/simpleooo/memi.v"


module cpu_ooo(
  input clk,
  input rst
);

  // STEP: PC
  reg  [`MEMI_SIZE_LOG-1:0] F_pc;
  wire [`MEMI_SIZE_LOG-1:0] F_next_pc;
  always @(posedge clk) begin
    if (rst) F_pc <= 0;
    else     F_pc <= F_next_pc;
  end




  // STEP: Fetch
  wire [`INST_LEN-1:0] F_inst;
  memi memi_instance(
    .clk(clk), .rst(rst),
    .req_addr(F_pc), .resp_data(F_inst)
  );




  // STEP: Decode
  wire [`INST_SIZE_LOG-1:0] F_opcode;
  wire                      F_rs1_used;
  wire [`REG_LEN-1      :0] F_rs1_imm;
  wire [`RF_SIZE_LOG-1  :0] F_rs1;
  wire [`MEMI_SIZE_LOG-1:0] F_rs1_br_offset;
  wire                      F_rs2_used;
  wire [`RF_SIZE_LOG-1  :0] F_rs2;

  wire                    F_wen;
  wire [`RF_SIZE_LOG-1:0] F_rd;
  wire                    F_rd_data_use_execute;

  wire F_mem_valid;
  wire F_mem_rdwt;

  wire F_is_br;

`ifdef USE_DEFENSE_STT
  wire F_IsAccessInstr;
  wire F_IsTxInstr;
`endif

  decode decode_instance(
    .inst(F_inst),
    .opcode(F_opcode), .rs1_used(F_rs1_used), .rs1_imm(F_rs1_imm), .rs1(F_rs1),
    .rs1_br_offset(F_rs1_br_offset), .rs2_used(F_rs2_used), .rs2(F_rs2),
    .wen(F_wen), .rd(F_rd), .rd_data_use_execute(F_rd_data_use_execute),
    .mem_valid(F_mem_valid), .mem_rdwt(F_mem_rdwt),
    .is_br(F_is_br)
  );
`ifdef USE_DEFENSE_STT
  assign F_IsAccessInstr = (F_opcode==`INST_OP_LD && F_isSpec);
`ifdef STT_CHEAT_DELAY_ALL
  assign F_IsTxInstr = 1'b1;
`else
  assign F_IsTxInstr = F_opcode==`INST_OP_LD;
`endif
`endif




  // STEP: Whether the current fetched inst is under speculation
`ifdef USE_DEFENSE_STT
  `define TEMP_USE_IS_SPEC
`elsif USE_DEFENSE_PARTIAL_DOM
  `define TEMP_USE_IS_SPEC
`elsif PARTIAL_STT_USE_SPEC
  `define TEMP_USE_IS_SPEC
`endif

`ifdef STT_CHEAT_ALL_SPEC
  `define TEMP_CHEAT_ALL_SPEC
`elsif PARTIAL_DOM_CHEAT_ALL_SPEC
  `define TEMP_CHEAT_ALL_SPEC
`endif

`ifdef TEMP_USE_IS_SPEC
  reg                      F_isSpec;
  reg  [`ROB_SIZE_LOG-1:0] F_isSpec_ROBlink;

`ifdef TEMP_CHEAT_ALL_SPEC
  always @(posedge clk)
    if (rst)
      F_isSpec <= 1'b1;
`else
  always @(posedge clk) begin
    if (rst)
      F_isSpec <= 1'b0;
    else if (C_squash && C_valid)
      F_isSpec <= 1'b0;
    else if (!ROB_full && F_is_br) begin
      F_isSpec <= 1'b1;
      F_isSpec_ROBlink <= ROB_tail;
    end
    else if (C_valid && C_is_br && (F_isSpec_ROBlink==ROB_head))
      F_isSpec <= 1'b0;
  end
`endif
`endif




  // STEP: rf Read Write
  wire [`REG_LEN-1:0] F_rs1_data_rf;
  wire [`REG_LEN-1:0] F_rs2_data_rf;
  rf rf_instance(
    .clk(clk), .rst(rst),
    .rs1(F_rs1), .rs1_data(F_rs1_data_rf),
    .rs2(F_rs2), .rs2_data(F_rs2_data_rf),
    .wen(C_valid && C_wen), .rd(C_rd), .rd_data(C_rd_data)
  );




  // STEP: PC Prediction
  reg  br_hist;

  wire                      F_taken;
  wire [`MEMI_SIZE_LOG-1:0] F_next_pc;

  always @(posedge clk) begin
    if (rst)                     br_hist <= 1'b0;
    else if (C_valid && C_is_br) br_hist <= C_taken;
  end

  assign F_taken =
    (`BR_PREDICT==`BR_PREDICT_NOT_TAKEN)?
      1'b0 :
    (`BR_PREDICT==`BR_PREDICT_BHB)?
      br_hist :
    (`BR_PREDICT==`BR_PREDICT_FORWARD_DATA_THEN_NOT_TAKEN)?
      (F_rs2_stall? 1'b0 : F_rs2_data==0) :
    // (`BR_PREDICT==`BR_PREDICT_FORWARD_DATA_THEN_BHB)?
      (F_rs2_stall? br_hist : F_rs2_data==0);

  assign F_next_pc = (C_valid && C_squash)? C_next_pc :
                     ROB_full?              F_pc :
                     (F_is_br && F_taken)?  F_pc+F_rs1_br_offset :
                                            F_pc+1;




  // STEP: Rename Table
  reg  [`RF_SIZE-1     :0] renameTB_valid;
  reg  [`ROB_SIZE_LOG-1:0] renameTB_ROBlink [`RF_SIZE-1:0];
`ifdef USE_DEFENSE_STT
  // NOTE: we make sure srcIsTainted == srcIsTainted && valid
  //       and IsAccessInstr == IsAccessInstr && valid
  reg  [`RF_SIZE-1     :0] renameTB_srcIsTainted;
`ifndef STT_CHEAT_NO_UNTAINT
  reg  [`ROB_SIZE_LOG-1:0] renameTB_srcYRoT [`RF_SIZE-1:0];
`endif
  reg  [`RF_SIZE-1     :0] renameTB_IsAccessInstr;
`endif

  wire                F_rs1_stall;
  wire [`REG_LEN-1:0] F_rs1_data;
  wire                F_rs2_stall;
  wire [`REG_LEN-1:0] F_rs2_data;
`ifdef USE_DEFENSE_STT
  wire                     F_srcIsTainted;
`ifndef STT_CHEAT_NO_UNTAINT
  wire [`ROB_SIZE_LOG-1:0] F_srcYRoT;
`endif
`endif


  // STEP.: update rename table entries
  wire renameTB_clearEntry, renameTB_addEntry, renameTB_clearAddConflict;
  assign renameTB_clearEntry = C_valid && C_wen && (renameTB_ROBlink[C_rd]==ROB_head);
  assign renameTB_addEntry   = !ROB_full && F_wen;
  assign renameTB_clearAddConflict = renameTB_addEntry && renameTB_clearEntry && F_rd==C_rd;
  always @(posedge clk) begin
    if (rst)        begin 
      for (i=0; i<`RF_SIZE; i=i+1) begin
        renameTB_valid[i]         <= 1'b0;
`ifdef USE_DEFENSE_STT
        renameTB_srcIsTainted[i]  <= 1'b0;
        renameTB_IsAccessInstr[i] <= 1'b0;
`endif
      end
    end

    else if (C_squash && C_valid)
      for (i=0; i<`RF_SIZE; i=i+1) begin
        renameTB_valid[i]         <= 1'b0;
`ifdef USE_DEFENSE_STT
        renameTB_srcIsTainted[i]  <= 1'b0;
        renameTB_IsAccessInstr[i] <= 1'b0;
`endif
      end

    else begin
      // TODO: make visible point earlier
`ifdef USE_DEFENSE_STT
`ifndef STT_CHEAT_NO_UNTAINT
      if (C_valid)
        for (i=0; i<`RF_SIZE; i=i+1)
          if (renameTB_srcYRoT[i]==ROB_head)
            renameTB_srcIsTainted[i] <= 1'b0;
`endif
`endif

      if (renameTB_clearEntry && !renameTB_clearAddConflict) begin
        renameTB_valid        [C_rd] <= 1'b0;
`ifdef USE_DEFENSE_STT
`ifdef STT_CHEAT_NO_UNTAINT
        renameTB_srcIsTainted [C_rd] <= 1'b0;
`endif
        renameTB_IsAccessInstr[C_rd] <= 1'b0;
`endif
      end

      if (renameTB_addEntry) begin
        renameTB_valid[F_rd]         <= 1'b1;
`ifdef USE_DEFENSE_STT
        renameTB_srcIsTainted[F_rd]  <= F_srcIsTainted;
`ifndef STT_CHEAT_NO_UNTAINT
        renameTB_srcYRoT[F_rd]       <= F_srcYRoT;
`endif
        renameTB_IsAccessInstr[F_rd] <= F_IsAccessInstr;
`endif
      end
    end
  end

  always @(posedge clk) begin
    if (!ROB_full && F_wen) renameTB_ROBlink[F_rd] <= ROB_tail;
  end


  // STEP.: use renameTB to read data from either reg or ROB or stall
`ifdef USE_DEFENSE_PARTIAL_STT
  assign F_rs1_stall =
    F_rs1_used
    && renameTB_valid[F_rs1]
    && (!(ROB_state[renameTB_ROBlink[F_rs1]]==`FINISHED)
        || ROB_op[renameTB_ROBlink[F_rs1]]==`INST_OP_LD
`ifdef PARTIAL_STT_USE_SPEC
           && ROB_isSpec[renameTB_ROBlink[F_rs1]]
`endif
           && !(renameTB_ROBlink[F_rs1]==ROB_head));
  assign F_rs2_stall =
    F_rs2_used
    && renameTB_valid[F_rs2]
    && (!(ROB_state[renameTB_ROBlink[F_rs2]]==`FINISHED)
        || ROB_op[renameTB_ROBlink[F_rs2]]==`INST_OP_LD
`ifdef PARTIAL_STT_USE_SPEC
           && ROB_isSpec[renameTB_ROBlink[F_rs2]]
`endif
           && !(renameTB_ROBlink[F_rs2]==ROB_head));

`else
  assign F_rs1_stall =
    F_rs1_used && renameTB_valid[F_rs1] &&
    !(ROB_state[renameTB_ROBlink[F_rs1]]==`FINISHED);
  assign F_rs2_stall =
    F_rs2_used && renameTB_valid[F_rs2] &&
    !(ROB_state[renameTB_ROBlink[F_rs2]]==`FINISHED);
`endif

  assign F_rs1_data = {`REG_LEN{F_rs1_used&&!F_rs1_stall}} & 
                      (renameTB_valid[F_rs1]?
                        ROB_rd_data[renameTB_ROBlink[F_rs1]]:
                        F_rs1_data_rf);
  assign F_rs2_data = {`REG_LEN{F_rs2_used&&!F_rs2_stall}} & 
                      (renameTB_valid[F_rs2]?
                        ROB_rd_data[renameTB_ROBlink[F_rs2]]:
                        F_rs2_data_rf);


  // STEP.: use renameTB to compute STT signals
`ifdef USE_DEFENSE_STT

  // STEP..1: let the event of commit instruction happens first
  wire [`RF_SIZE-1:0] renameTB_srcIsTainted_forwarded;
  wire [`RF_SIZE-1:0] renameTB_IsAccessInstr_forwarded;

  // STEP..1.1: srcIsTainted
`ifdef STT_CHEAT_NO_UNTAINT
  assign renameTB_srcIsTainted_forwarded =
    renameTB_srcIsTainted
    & ~({`RF_SIZE'b0, renameTB_clearEntry}[`RF_SIZE-1:0] << C_rd);
`else
  genvar j;
  generate
  for(j=0;j<`RF_SIZE;j=j+1)
    assign renameTB_srcIsTainted_forwarded[j] =
      renameTB_srcIsTainted[j]
      && !(C_valid && renameTB_srcYRoT[j]==ROB_head);
  endgenerate
`endif

  // STEP..1.2: srcIsTainted
  assign renameTB_IsAccessInstr_forwarded =
    renameTB_IsAccessInstr
    & ~({`RF_SIZE'b0, renameTB_clearEntry}[`RF_SIZE-1:0] << C_rd);

  // STEP..2: compute the taint of this instruction
  wire F_rs1_dstIsTainted, F_rs2_dstIsTainted;
  assign F_rs1_dstIsTainted = renameTB_IsAccessInstr_forwarded[F_rs1] || renameTB_srcIsTainted_forwarded[F_rs1];
  assign F_rs2_dstIsTainted = renameTB_IsAccessInstr_forwarded[F_rs2] || renameTB_srcIsTainted_forwarded[F_rs2];
  assign F_srcIsTainted = F_rs1_used && F_rs1_dstIsTainted
                       || F_rs2_used && F_rs2_dstIsTainted;


  // STEP..3: compute the YRoT of this instruction
`ifndef STT_CHEAT_NO_UNTAINT
  wire [`ROB_SIZE_LOG-1:0] F_rs1_dstYRoT, F_rs2_dstYRoT;
  wire F_rs1_isYounger;
  assign F_rs1_dstYRoT = renameTB_IsAccessInstr_forwarded[F_rs1]? renameTB_ROBlink[F_rs1]:
                                                                  renameTB_srcYRoT[F_rs1];
  assign F_rs2_dstYRoT = renameTB_IsAccessInstr_forwarded[F_rs2]? renameTB_ROBlink[F_rs2]:
                                                                  renameTB_srcYRoT[F_rs2];
  assign F_rs1_isYounger =
    (F_rs1_dstIsTainted && F_rs2_dstIsTainted)?
      ((ROB_tail - F_rs1_dstYRoT) < (ROB_tail - F_rs2_dstYRoT)):
    (F_rs1_dstIsTainted && !F_rs2_dstIsTainted)?
      1'b1:
      1'b0;
  assign F_srcYRoT =
    (F_rs1_used && F_rs2_used)?
      (F_rs1_isYounger? F_rs1_dstYRoT:F_rs2_dstYRoT):
    (F_rs1_used && !F_rs2_used)?
      F_rs1_dstYRoT:
      F_rs2_dstYRoT;
`endif
`endif




  // STEP: ROB
  reg  [`ROB_STATE_LEN-1:0] ROB_state [`ROB_SIZE-1:0];

  reg  [`MEMI_SIZE_LOG-1:0] ROB_pc [`ROB_SIZE-1:0];
  reg  [`INST_SIZE_LOG-1:0] ROB_op [`ROB_SIZE-1:0];

  reg  [`RF_SIZE_LOG-1  :0] ROB_rs1           [`ROB_SIZE-1:0];
  reg  [`ROB_SIZE-1     :0] ROB_rs1_stall;
  reg  [`REG_LEN-1      :0] ROB_rs1_imm       [`ROB_SIZE-1:0];
  reg  [`REG_LEN-1      :0] ROB_rs1_data      [`ROB_SIZE-1:0];
  reg  [`ROB_SIZE_LOG-1 :0] ROB_rs1_ROBlink   [`ROB_SIZE-1:0];
  reg  [`MEMI_SIZE_LOG-1:0] ROB_rs1_br_offset [`ROB_SIZE-1:0];
  reg  [`RF_SIZE_LOG-1  :0] ROB_rs2           [`ROB_SIZE-1:0];
  reg  [`ROB_SIZE-1     :0] ROB_rs2_stall;
  reg  [`REG_LEN-1      :0] ROB_rs2_data      [`ROB_SIZE-1:0];
  reg  [`ROB_SIZE_LOG-1 :0] ROB_rs2_ROBlink   [`ROB_SIZE-1:0];
  reg  [`ROB_SIZE-1     :0] ROB_rd_data_use_execute;

  reg  [`ROB_SIZE-1     :0] ROB_wen;
  reg  [`RF_SIZE_LOG-1  :0] ROB_rd      [`ROB_SIZE-1:0];
  reg  [`REG_LEN-1      :0] ROB_rd_data [`ROB_SIZE-1:0];

  reg  [`ROB_SIZE-1     :0] ROB_mem_valid;
  reg  [`ROB_SIZE-1     :0] ROB_mem_rdwt;
  reg  [`MEMD_SIZE_LOG-1:0] ROB_mem_addr[`ROB_SIZE-1:0];
  reg  [`REG_LEN-1      :0] ROB_mem_data[`ROB_SIZE-1:0];

  reg  [`ROB_SIZE-1     :0] ROB_is_br;
  reg  [`ROB_SIZE-1     :0] ROB_predicted_taken;
  reg  [`ROB_SIZE-1     :0] ROB_taken;
  reg  [`MEMI_SIZE_LOG-1:0] ROB_next_pc [`ROB_SIZE-1:0];

`ifdef USE_DEFENSE_STT
  reg  [`ROB_SIZE-1    :0] ROB_IsTxInstr;
  reg  [`ROB_SIZE-1    :0] ROB_srcIsTainted;
`ifndef STT_CHEAT_NO_UNTAINT
  reg  [`ROB_SIZE_LOG-1:0] ROB_srcYRoT [`ROB_SIZE-1:0];
`endif
`endif

`ifdef USE_DEFENSE_PARTIAL_DOM
  reg  [`ROB_SIZE-1:0] ROB_isSpec;
`endif

`ifdef PARTIAL_STT_USE_SPEC
  reg  [`ROB_SIZE-1:0] ROB_isSpec;
`endif

  reg  [`ROB_SIZE_LOG-1:0] ROB_head;
  reg  [`ROB_SIZE_LOG-1:0] ROB_tail;

  wire ROB_full;
  wire ROB_empty;

`ifdef USE_CACHE
  reg [`MEMD_SIZE_LOG-1:0] cached_addr;
`endif

  integer i, k;
  always@(posedge clk) begin
    if (rst) begin
      for (i=0; i<`ROB_SIZE; i=i+1) begin
        ROB_state[i] <= `IDLE;
      end
      ROB_head <= 0;
      ROB_tail <= 0;
`ifdef USE_CACHE
      cached_addr <= 0;
`endif
    end

    // STEP.1: squash
    else if (C_valid && C_squash) begin
      for (i=0; i<`ROB_SIZE; i=i+1) begin
        ROB_state[i] <= `IDLE;
        ROB_rd_data[i] <= 0;
      end
      ROB_head <= 0;
      ROB_tail <= 0;
    end

    else begin
      // STEP.2: push
      if (!ROB_full) begin
        ROB_state[ROB_tail] <= `STALLED;

        ROB_pc[ROB_tail] <= F_pc;
        ROB_op[ROB_tail] <= F_opcode;

        ROB_rs1                [ROB_tail] <= F_rs1;
        ROB_rs1_stall          [ROB_tail] <= F_rs1_stall;
        ROB_rs1_imm            [ROB_tail] <= F_rs1_imm;
        ROB_rs1_data           [ROB_tail] <= F_rs1_data;
        ROB_rs1_br_offset      [ROB_tail] <= F_rs1_br_offset;
        ROB_rs1_ROBlink        [ROB_tail] <= renameTB_ROBlink[F_rs1];
        ROB_rs2                [ROB_tail] <= F_rs2;
        ROB_rs2_stall          [ROB_tail] <= F_rs2_stall;
        ROB_rs2_data           [ROB_tail] <= F_rs2_data;
        ROB_rs2_ROBlink        [ROB_tail] <= renameTB_ROBlink[F_rs2];
        ROB_rd_data_use_execute[ROB_tail] <= F_rd_data_use_execute;

        ROB_wen                [ROB_tail] <= F_wen;
        ROB_rd                 [ROB_tail] <= F_rd;

        ROB_mem_valid[ROB_tail] <= F_mem_valid;
        ROB_mem_rdwt [ROB_tail] <= F_mem_rdwt;

        ROB_is_br          [ROB_tail] <= F_is_br;
        ROB_predicted_taken[ROB_tail] <= F_taken;

`ifdef USE_DEFENSE_STT
        ROB_IsTxInstr   [ROB_tail] <= F_IsTxInstr;
        ROB_srcIsTainted[ROB_tail] <= F_srcIsTainted;
`ifndef STT_CHEAT_NO_UNTAINT
        ROB_srcYRoT     [ROB_tail] <= F_srcYRoT;
`endif
`endif

`ifdef USE_DEFENSE_PARTIAL_DOM
        ROB_isSpec[ROB_tail] <= F_isSpec;
`endif

`ifdef PARTIAL_STT_USE_SPEC
        ROB_isSpec[ROB_tail] <= F_isSpec;
`endif

        ROB_tail <= ROB_tail + 1;
      end


      // STEP.3: issue
      // TODO: detect st-ld hazard and stall
      for (i=0; i<`ROB_SIZE; i=i+1) begin
        if (ROB_state[i]==`STALLED &&
            !ROB_rs1_stall[i] && !ROB_rs2_stall[i])
`ifdef USE_DEFENSE_STT
`ifdef STT_CHEAT_NO_UNTAINT
          if (!(ROB_IsTxInstr[i] && ROB_srcIsTainted[i]
                && !(ROB_head==i[`ROB_SIZE_LOG-1:0])))
`else
          if (!(ROB_IsTxInstr[i] && ROB_srcIsTainted[i]))
`endif
`endif
`ifdef USE_DEFENSE_PARTIAL_DOM
`ifndef PARTIAL_DOM_USE_MISS_ONLY
            if (!(ROB_isSpec[i] && ROB_op[i]==`INST_OP_LD
                  && !(ROB_head==i[`ROB_SIZE_LOG-1:0])))
`endif
`endif
              ROB_state [i] <= `READY;
      end


      // STEP.4: execute
      for (i=0; i<`ROB_SIZE; i=i+1) begin
        if (ROB_state[i]==`READY && ROB_exe_this_cycle[i]) begin
          ROB_rd_data [i] <= ROB_rd_data_wire;
          ROB_mem_addr[i] <= ROB_mem_addr_wire;
          ROB_mem_data[i] <= ROB_mem_data_wire;
          ROB_taken   [i] <= ROB_taken_wire;
          ROB_next_pc [i] <= ROB_next_pc_wire;

`ifdef USE_CACHE
          if (ROB_op[i]==`INST_OP_LD && ROB_mem_addr_wire!=cached_addr)
            ROB_state [i] <= `EXECUTING_1;
          else
            ROB_state [i] <= `FINISHED;
`else
          ROB_state [i] <= `FINISHED;
`endif
        end

`ifdef USE_CACHE
        if (ROB_state[i]==`EXECUTING_1) begin
`ifdef PARTIAL_DOM_USE_MISS_ONLY
          if (!(ROB_isSpec[i] && ROB_op[i]==`INST_OP_LD
                && !(ROB_head==i[`ROB_SIZE_LOG-1:0])))
`endif
            ROB_state [i] <= `EXECUTING_0;
        end

        if (ROB_state[i]==`EXECUTING_0) begin
          ROB_state [i] <= `FINISHED;
          if (ROB_op[i]==`INST_OP_LD)
            cached_addr <= ROB_mem_addr[i];
        end
`endif
      end


      // STEP.5: forward
      for (i=0; i<`ROB_SIZE; i=i+1) begin
`ifdef USE_DEFENSE_PARTIAL_STT
`ifdef PARTIAL_STT_USE_SPEC
        if (!(ROB_op[i]==`INST_OP_LD && ROB_isSpec[i])) begin
`else
        if (!(ROB_op[i]==`INST_OP_LD)) begin
`endif
`endif
          if (ROB_state[i]==`FINISHED) begin
            for (k=0; k<`ROB_SIZE; k=k+1) begin
              if (ROB_state[k]==`STALLED && ROB_rs1_stall[k] &&
                  ROB_rs1_ROBlink[k]==i[`ROB_SIZE_LOG-1:0]) begin
                ROB_rs1_stall[k] <= 1'b0;
                ROB_rs1_data[k] <= ROB_rd_data[i];
              end

              if (ROB_state[k]==`STALLED && ROB_rs2_stall[k] &&
                  ROB_rs2_ROBlink[k]==i[`ROB_SIZE_LOG-1:0]) begin
                ROB_rs2_stall[k] <= 1'b0;
                ROB_rs2_data[k] <= ROB_rd_data[i];
              end
            end
          end
`ifdef USE_DEFENSE_PARTIAL_STT
        end
`endif
      end


      // STEP.6: pop
      if (C_valid) begin
`ifdef USE_DEFENSE_PARTIAL_STT
        if (ROB_op[ROB_head]==`INST_OP_LD) begin
          for (k=0; k<`ROB_SIZE; k=k+1) begin
            if (ROB_state[k]==`STALLED && ROB_rs1_stall[k] &&
                ROB_rs1_ROBlink[k]==ROB_head) begin
              ROB_rs1_stall[k] <= 1'b0;
              ROB_rs1_data[k] <= ROB_rd_data[ROB_head];
            end

            if (ROB_state[k]==`STALLED && ROB_rs2_stall[k] &&
                ROB_rs2_ROBlink[k]==ROB_head) begin
              ROB_rs2_stall[k] <= 1'b0;
              ROB_rs2_data[k] <= ROB_rd_data[ROB_head];
            end
          end
        end
`endif

`ifdef USE_DEFENSE_STT
`ifndef STT_CHEAT_NO_UNTAINT
        for (k=0; k<`ROB_SIZE; k=k+1)
          if (ROB_state[k]==`STALLED && ROB_srcYRoT[k]==ROB_head)
            ROB_srcIsTainted[k] <= 1'b0;
`endif
`endif

        ROB_state[ROB_head] <= `IDLE;
        ROB_rd_data[ROB_head] <= 0;
        ROB_head <= ROB_head + 1;
      end
    end
  end

  assign ROB_full  = ROB_state[ROB_tail] != `IDLE;
  assign ROB_empty = ROB_state[ROB_head] == `IDLE;




  // STEP: Execute + Memory Read
  // STEP.X: arbitor to choose an entry in ROB
  reg [`ROB_SIZE-1:0] ROB_exe_this_cycle;
  always @(*) begin
    ROB_exe_this_cycle = 0;
    for (i=`ROB_SIZE-1; i >= 0; i=i-1)
`ifdef PARTIAL_DOM_USE_PRIORITY
      if (ROB_state[ROB_head+i[`ROB_SIZE_LOG-1:0]]==`READY)
        ROB_exe_this_cycle = (1 << (ROB_head+i[`ROB_SIZE_LOG-1:0]));
`else
      if (ROB_state[i]==`READY)
        ROB_exe_this_cycle = (1 << i);
`endif
  end


  // STEP.X: choose an input to alu
  reg [`MEMI_SIZE_LOG-1:0] ROB_pc_wire;
  reg [`INST_SIZE_LOG-1:0] ROB_op_wire;
  reg [`REG_LEN-1      :0] ROB_rs1_imm_wire;
  reg [`REG_LEN-1      :0] ROB_rs1_data_wire;
  reg [`MEMI_SIZE_LOG-1:0] ROB_rs1_br_offset_wire;
  reg [`REG_LEN-1      :0] ROB_rs2_data_wire;
  reg                      ROB_rd_data_use_execute_wire;
  reg                      ROB_is_br_wire;
  always @(*) begin
    ROB_pc_wire                  = 0;
    ROB_op_wire                  = 0;
    ROB_rs1_imm_wire             = 0;
    ROB_rs1_data_wire            = 0;
    ROB_rs1_br_offset_wire       = 0;
    ROB_rs2_data_wire            = 0;
    ROB_rd_data_use_execute_wire = 0;
    ROB_is_br_wire               = 0;
    for (i=0; i < `ROB_SIZE; i=i+1) begin
      ROB_pc_wire                  = ROB_pc_wire                  | {`MEMI_SIZE_LOG{ROB_exe_this_cycle[i]}} & ROB_pc[i];
      ROB_op_wire                  = ROB_op_wire                  | {`INST_SIZE_LOG{ROB_exe_this_cycle[i]}} & ROB_op[i];
      ROB_rs1_imm_wire             = ROB_rs1_imm_wire             | {`REG_LEN      {ROB_exe_this_cycle[i]}} & ROB_rs1_imm[i];
      ROB_rs1_data_wire            = ROB_rs1_data_wire            | {`REG_LEN      {ROB_exe_this_cycle[i]}} & ROB_rs1_data[i];
      ROB_rs1_br_offset_wire       = ROB_rs1_br_offset_wire       | {`MEMI_SIZE_LOG{ROB_exe_this_cycle[i]}} & ROB_rs1_br_offset[i];
      ROB_rs2_data_wire            = ROB_rs2_data_wire            | {`REG_LEN      {ROB_exe_this_cycle[i]}} & ROB_rs2_data[i];
      ROB_rd_data_use_execute_wire = ROB_rd_data_use_execute_wire |                 ROB_exe_this_cycle[i]   & ROB_rd_data_use_execute[i];
      ROB_is_br_wire               = ROB_is_br_wire               |                 ROB_exe_this_cycle[i]   & ROB_is_br[i];
    end
  end


  // STEP.X: output from alu
  wire [`REG_LEN-1      :0] ROB_rd_data_wire;
  wire [`MEMD_SIZE_LOG-1:0] ROB_mem_addr_wire;
  wire [`REG_LEN-1      :0] ROB_mem_data_wire;
  wire                      ROB_taken_wire;
  wire [`MEMI_SIZE_LOG-1:0] ROB_next_pc_wire;
  wire [`MEMD_SIZE_LOG-1:0] mem_read_addr = ROB_op_wire == `INST_OP_LD ? ROB_rs1_data_wire[`MEMD_SIZE_LOG-1:0] : 0;
  execute execute_instance(
    .pc(ROB_pc_wire),
    .op(ROB_op_wire),

    .rs1_imm(ROB_rs1_imm_wire),
    .rs1_br_offset(ROB_rs1_br_offset_wire),
    .rs1_data(ROB_rs1_data_wire),
    .rs2_data(ROB_rs2_data_wire),
    .rd_data_memory(memd[mem_read_addr]),
    .rd_data_use_execute(ROB_rd_data_use_execute_wire),

    .rd_data(ROB_rd_data_wire),
    
    // .memd(memd),
    .mem_addr(ROB_mem_addr_wire),
    .mem_data(ROB_mem_data_wire),

    .is_br(ROB_is_br_wire),
    .taken(ROB_taken_wire),
    .next_pc(ROB_next_pc_wire)
  );


  // STEP.X: observation of memory trace
  wire [`MEMD_SIZE_LOG-1:0] ld_addr;
if (`OBSV==`OBSV_COMITTED_ADDR)
  assign ld_addr = (C_valid && C_mem_rdwt && C_mem_valid && !C_squash) ? C_mem_addr : 0;
else if (`OBSV==`OBSV_EVERY_ADDR)
`ifdef PARTIAL_DOM_USE_MISS_ONLY
  assign ld_addr = cached_addr;
`else
  assign ld_addr = (|(ROB_exe_this_cycle & ROB_mem_rdwt & ROB_mem_valid)) ? ROB_mem_addr_wire : 0;
`endif




  // STEP: Memory Write
  // TODO: add write
  reg [`REG_LEN-1:0] memd [`MEMD_SIZE-1:0];

  always @(posedge clk) begin
    if (rst)
      if (`INIT_VALUE==`INIT_VALUE_ZERO)
        for (i=0; i<`MEMD_SIZE; i=i+1)
          memd[i] <= 0;
      else if (`INIT_VALUE==`INIT_VALUE_CUSTOMIZED) begin
          memd[0] <= 0;
          memd[1] <= 1;
          memd[2] <= 0;
          memd[3] <= 0;
      end
    // else if (C_valid && C_mem_valid && C_mem_rdwt==0)
    //   memd[C_mem_addr] <= C_mem_data;
  end




  // STEP: Commit
  wire                      C_valid;

  wire                      C_mem_valid;
  wire                      C_mem_rdwt;
  wire [`MEMD_SIZE_LOG-1:0] C_mem_addr;
  wire [`REG_LEN-1      :0] C_mem_data;

  wire                      C_is_br;
  wire                      C_taken;
  wire                      C_squash;
  wire [`MEMI_SIZE_LOG-1:0] C_next_pc;

  wire                      C_wen;
  wire [`RF_SIZE_LOG-1  :0] C_rd;
  wire [`REG_LEN-1      :0] C_rd_data;

  assign C_valid = ROB_state[ROB_head]==`FINISHED;

  assign C_mem_valid = ROB_mem_valid[ROB_head];
  assign C_mem_rdwt  = ROB_mem_rdwt [ROB_head];
  assign C_mem_addr  = ROB_mem_addr [ROB_head];
  assign C_mem_data  = ROB_mem_data [ROB_head];

  assign C_is_br   = ROB_is_br  [ROB_head];
  assign C_taken   = ROB_taken  [ROB_head];
  assign C_squash  = C_is_br &&
                     (ROB_predicted_taken[ROB_head] != ROB_taken[ROB_head]);
  assign C_next_pc = ROB_next_pc[ROB_head];

  assign C_wen     = ROB_wen    [ROB_head];
  assign C_rd      = ROB_rd     [ROB_head];
  assign C_rd_data = ROB_rd_data[ROB_head];


endmodule


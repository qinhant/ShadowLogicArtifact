analyze -sva +define+CONTRACT=1 ./src/boom/two_copy_top.sv ./src/boom/TestHarness.v ./src/boom/SmallBoom.v ./src/boom/BOOM_mem.v ./src/boom/plusarg_reader.v ./src/boom/ClockDividerN.sv ./src/boom/EICG_wrapper.v ./src/boom/IOCell.v ./src/boom/SimDRAM.v ./src/boom/SimJTAG.v ./src/boom/SimSerial.v ./src/boom/SimUART.v 

elaborate -top top -bbox_a 32768 -bbox_mul 256

clock clk
reset rst -non_resettable_regs 0 -init_state src/boom/BOOM.init

# Contract assumption is never violated
assume {invalid_program==0}

# Assume always in machine mode
assume {copy1.core.csr.reg_mstatus_prv==2'b11 && copy2.core.csr.reg_mstatus_prv==2'b11}

# Abstract Icache data array
abstract -init_value {copy1.frontend.icache.dataArrayWay_0.dataArrayWay_0_ext.mem_0_0.ram}
abstract -init_value {copy2.frontend.icache.dataArrayWay_0.dataArrayWay_0_ext.mem_0_0.ram}
assume {copy1.frontend.icache.dataArrayWay_0.dataArrayWay_0_ext.mem_0_0.ram==copy2.frontend.icache.dataArrayWay_0.dataArrayWay_0_ext.mem_0_0.ram && copy1.frontend.icache.dataArrayWay_1.dataArrayWay_0_ext.mem_0_0.ram==copy2.frontend.icache.dataArrayWay_1.dataArrayWay_0_ext.mem_0_0.ram}
# Constrain Icache tag array
abstract -register_value {copy1.frontend.icache.tag_array.tag_array_0_ext.mem_0_0.ram[0] copy1.frontend.icache.tag_array.tag_array_0_ext.mem_0_0.ram[1]} -expression {25'h200}
abstract -register_value {copy1.frontend.icache.tag_array.tag_array_0_ext.mem_0_1.ram[0] copy1.frontend.icache.tag_array.tag_array_0_ext.mem_0_1.ram[1]} -expression {25'h0}
abstract -register_value {copy2.frontend.icache.tag_array.tag_array_0_ext.mem_0_0.ram[0] copy2.frontend.icache.tag_array.tag_array_0_ext.mem_0_0.ram[1]} -expression {25'h200}
abstract -register_value {copy2.frontend.icache.tag_array.tag_array_0_ext.mem_0_1.ram[0] copy2.frontend.icache.tag_array.tag_array_0_ext.mem_0_1.ram[1]} -expression {25'h0}

# All cache lines must always be valid
abstract -register_value {copy1.frontend.icache.vb_array copy2.frontend.icache.vb_array} -expression {4'b1111}

# Abstract Dcache data array, only abstract one way
abstract -init_value {copy1.dcache.data.array_0_0.array_0_0_ext.mem_0_0.ram copy2.dcache.data.array_0_0.array_0_0_ext.mem_0_0.ram}
assume {init -> copy1.dcache.data.array_0_0.array_0_0_ext.mem_0_0.ram!=copy2.dcache.data.array_0_0.array_0_0_ext.mem_0_0.ram}
# Constrain Dcache tag array, tag array is 2-bit coherence bits + 25-bit tag bits
# abstract -init_value {copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram}
# assume {init -> copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram==copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram && copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram==copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram}
abstract -register_value {copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram[0] copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram[1]} -expression {27'h6200009}
abstract -register_value {copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram[0] copy1.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram[1]} -expression {27'h6200000}
abstract -register_value {copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram[0] copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_0.ram[1]} -expression {27'h6200009}
abstract -register_value {copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram[0] copy2.dcache.meta_0.tag_array.tag_array_ext.mem_0_1.ram[1]} -expression {27'h6200000}

# Dache must always hit
assume {copy1.dcache.s2_valid_REG -> copy1.dcache.s2_hit_0 && copy2.dcache.s2_valid_REG -> copy2.dcache.s2_hit_0}

# Assume there's no exception caused by address misalignment
# assume {!copy1.core.mem_units_0.maddrcalc.misaligned && !copy2.core.mem_units_0.maddrcalc.misaligned}

# Assume there's no exception caused by illegal address
# assume {!copy1.lsu.ae_ld_0 && !copy1.lsu.ae_st_0 && !copy2.lsu.ae_ld_0 && !copy2.lsu.ae_st_0}

# Assume there's no branch
# assume {!copy1.core.rob.io_enq_uops_0_is_br && !copy2.core.rob.io_enq_uops_0_is_br && !copy1.core.rob.io_enq_uops_0_is_jalr && !copy2.core.rob.io_enq_uops_0_is_jalr}

assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}

set_prove_orchestration off
set_engine_mode {Ht}
set_prove_time_limit 7d

prove -all

save -jdb my_jdb_ct_2copy_boom -capture_setup -capture_session_data

exit


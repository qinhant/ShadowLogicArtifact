analyze -sva +define+TWO_COPY_CT ./src/ridecore/alloc_issue_ino.v ./src/ridecore/exunit_branch.v ./src/ridecore/prioenc.v ./src/ridecore/search_be.v ./src/ridecore/alu_ops.vh ./src/ridecore/exunit_ldst.v ./src/ridecore/ram_sync_nolatch.v ./src/ridecore/src_manager.v ./src/ridecore/alu.v ./src/ridecore/exunit_mul.v ./src/ridecore/ram_sync.v ./src/ridecore/srcopr_manager.v ./src/ridecore/arf.v ./src/ridecore/gshare.v ./src/ridecore/reorderbuf.v ./src/ridecore/srcsel.v ./src/ridecore/brimm_gen.v ./src/ridecore/imem_outa.v ./src/ridecore/rrf_freelistmanager.v ./src/ridecore/storebuf.v ./src/ridecore/btb.v ./src/ridecore/imem.v ./src/ridecore/rrf.v ./src/ridecore/system.v ./src/ridecore/constants.vh ./src/ridecore/imm_gen.v ./src/ridecore/rs_alu.v ./src/ridecore/tag_generator.v ./src/ridecore/decoder.v ./src/ridecore/mpft.v ./src/ridecore/rs_branch.v ./src/ridecore/topsim.v ./src/ridecore/define.v ./src/ridecore/multiplier.v ./src/ridecore/rs_ldst.v ./src/ridecore/top.v ./src/ridecore/dmem.v ./src/ridecore/oldest_finder.v ./src/ridecore/rs_mul.v ./src/ridecore/two_copy_top_ct.sv ./src/ridecore/dualport_ram.v ./src/ridecore/pipeline_if.v ./src/ridecore/rs_reqgen.v ./src/ridecore/uart.v ./src/ridecore/exunit_alu.v ./src/ridecore/pipeline.v ./src/ridecore/rv32_opcodes.vh


elaborate -top two_copy_top_ct -bbox_mul 256 -bbox_a 1024
clock clk -both_edges
reset rst -non_resettable_regs 0


# Avoid memory address overflow
assume {copy1.dmem_addr < `DMEM_SIZE}
assume {copy2.dmem_addr < `DMEM_SIZE}


assume {@(posedge clk) invalid_program==0 && $next(invalid_program)==0}


abstract -init_value {copy1.instmemory.mem copy2.instmemory.mem}
assume {copy1.instmemory.mem == copy2.instmemory.mem}

# Let the secret be different in two copies
abstract -init_value {copy1.datamemory.mem[0] copy2.datamemory.mem[0]}

assert {@(posedge clk) !(deviation_found && finish_1 && finish_2 && !stall_1 && !stall_2 && !$next(stall_1) && !$next(stall_2))}

set_prove_orchestration off
set_engine_mode {Ht}
set_prove_time_limit 7d

prove -all

save -jdb my_jdb_ct_2copy_ridecore -capture_setup -capture_session_data

exit


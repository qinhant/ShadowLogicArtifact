analyze -sva src/sodor2/sodor_1_stage.sv src/sodor2/sodor_2_stage.sv src/sodor2/four_copy_top_sandbox.sv src/sodor2/param.vh

elaborate -top top -bbox_mul 256 -bbox_a 1024 -bbox_m plusarg_reader -bbox_m GenericDigitalInIOCell -bbox_m GenericDigitalOutIOCell -bbox_m ClockDividerN -bbox_m EICG_wrapper
clock clk
reset rst -non_resettable_regs 0

assume {(copy1.core_io_imem_req_bits_addr >> 2) < `IMEM_SIZE}
assume {copy1.core_io_dmem_req_valid -> (mem_addr_1>>2 < `MEM_SIZE && mem_addr_1>>2 >= `IMEM_SIZE)}
assume {(copy2.core_io_imem_req_bits_addr >> 2) < `IMEM_SIZE}
assume {copy2.core_io_dmem_req_valid -> (mem_addr_2>>2 < `MEM_SIZE && mem_addr_2>>2 >= `IMEM_SIZE)}

abstract -init_value {copy1.memory.mem_0 copy1.memory.mem_1 copy1.memory.mem_2 copy1.memory.mem_3}
abstract -init_value {copy2.memory.mem_0 copy2.memory.mem_1 copy2.memory.mem_2 copy2.memory.mem_3}
abstract -init_value {ISA1.memory.mem_0 ISA1.memory.mem_1 ISA1.memory.mem_2 ISA1.memory.mem_3}
abstract -init_value {ISA2.memory.mem_0 ISA2.memory.mem_1 ISA2.memory.mem_2 ISA2.memory.mem_3}

# Assume same program
assume {copy1.memory.mem_0[0:`IMEM_SIZE]==copy2.memory.mem_0[0:`IMEM_SIZE]}
assume {copy1.memory.mem_1[0:`IMEM_SIZE]==copy2.memory.mem_1[0:`IMEM_SIZE]}
assume {copy1.memory.mem_2[0:`IMEM_SIZE]==copy2.memory.mem_2[0:`IMEM_SIZE]}
assume {copy1.memory.mem_3[0:`IMEM_SIZE]==copy2.memory.mem_3[0:`IMEM_SIZE]}
assume {init -> (ISA1.memory.mem_0==copy1.memory.mem_0 && ISA1.memory.mem_1==copy1.memory.mem_1 && ISA1.memory.mem_2==copy1.memory.mem_2 && ISA1.memory.mem_3==copy1.memory.mem_3)}
assume {init -> (ISA2.memory.mem_0==copy2.memory.mem_0 && ISA2.memory.mem_1==copy2.memory.mem_1 && ISA2.memory.mem_2==copy2.memory.mem_2 && ISA2.memory.mem_3==copy2.memory.mem_3)}

# Legal instructions
assume {copy1.core.d.regfile_exe_rs1_data_MPORT_addr < `RF_SIZE && copy1.core.d.regfile_exe_rs2_data_MPORT_addr < `RF_SIZE}
assume {copy2.core.d.regfile_exe_rs1_data_MPORT_addr < `RF_SIZE && copy2.core.d.regfile_exe_rs2_data_MPORT_addr < `RF_SIZE}
assume {copy1.core.d.regfile_MPORT_1_addr < `RF_SIZE}
assume {copy2.core.d.regfile_MPORT_1_addr < `RF_SIZE}
assume {!copy1.core.c.illegal && !copy2.core.c.illegal}
assume {!copy1.core.c.io_dat_inst_misaligned && !copy2.core.c.io_dat_inst_misaligned}
assume {!copy1.core.c.io_dat_data_misaligned && !copy2.core.c.io_dat_data_misaligned}
assume {!ISA1.core.c.io_dat_inst_misaligned && !ISA2.core.c.io_dat_inst_misaligned}
assume {!ISA1.core.c.data_misaligned && !ISA2.core.c.data_misaligned}

assume {copy1.core.c.cs0_4==0 && copy2.core.c.cs0_4==0}
assume {copy1.core.d.io_ctl_wb_sel!=3 && copy2.core.d.io_ctl_wb_sel!=3}


set_prove_orchestration off
set_engine_mode {AM}
set_prove_time_limit 7d
prove -all

save -jdb my_jdb_sandbox_4copy_sodor2 -capture_setup -capture_session_data

exit


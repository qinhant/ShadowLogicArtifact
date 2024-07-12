
import math


def gen_verify(
  batchName=0,
  # micro-arch size
  RF_SIZE=4, MEMI_SIZE=16, MEMD_SIZE=4, ROB_SIZE=4,
  # micro-arch scheme
  BR_PREDICT=0, USE_CACHE=0,
  USE_DEFENSE_PARTIAL_STT=0, PARTIAL_STT_USE_SPEC=0,
  USE_DEFENSE_STT=0,
  STT_CHEAT_ALL_SPEC=0, STT_CHEAT_DELAY_ALL=0, STT_CHEAT_NO_UNTAINT=0,
  USE_DEFENSE_PARTIAL_DOM=0,
  PARTIAL_DOM_CHEAT_ALL_SPEC=0,
  PARTIAL_DOM_USE_MISS_ONLY=0, PARTIAL_DOM_USE_PRIORITY=0,
  # verification type
  OBSV=1, THREAT="ct", COPY=2, OPT_ABS_REG=0, OPT_ABS_MEMPUB=0,
  # Customize jaspergold engine
  # "Mp Hp N AM" for proof
  # "Ht" for bounded check
  CUSTOM_ENGINE=0,
  # Customize jaspergold time limite
  # "0s" for no limit, "7d", "24h"
  TIME_LIMIT=0):

  # PART: computed arguments
  RF_SIZE_LOG   = int(math.log2(RF_SIZE))
  MEMI_SIZE_LOG = int(math.log2(MEMI_SIZE))
  MEMD_SIZE_LOG = int(math.log2(MEMD_SIZE))
  ROB_SIZE_LOG  = int(math.log2(ROB_SIZE))


  # PART: experiment name and file names
  assert(BR_PREDICT==0)
  assert(OBSV==1)
  if PARTIAL_DOM_USE_MISS_ONLY==1:
    assert(USE_CACHE==1)
  if (COPY==3):
    assert(THREAT=="sandbox")
  
  if      USE_DEFENSE_PARTIAL_STT==1:
    temp_defense = "_PSTT"
    if PARTIAL_STT_USE_SPEC==1:
      temp_defense += "_USESPEC"
  elif    USE_DEFENSE_STT==1:
    temp_defense = "_STT"
    if STT_CHEAT_ALL_SPEC==1:
      temp_defense += "_ALLSPEC"
    if STT_CHEAT_DELAY_ALL==1:
      temp_defense += "_DELAYALL"
    if STT_CHEAT_NO_UNTAINT==1:
      temp_defense += "_NOUNTAINT"
  elif    USE_DEFENSE_PARTIAL_DOM==1:
    temp_defense = "_PDOM"
    if PARTIAL_DOM_CHEAT_ALL_SPEC==1:
      temp_defense += "_ALLSPEC"
    if PARTIAL_DOM_USE_MISS_ONLY==1:
      temp_defense += "_MISSONLY"
    if PARTIAL_DOM_USE_PRIORITY==1:
      temp_defense += "_PRIORITY"
  else:
    temp_defense = ""
  
  if   OPT_ABS_REG==1 and OPT_ABS_MEMPUB==1:
    temp_opt = "_OPTRegMem"
  elif OPT_ABS_REG==1 and OPT_ABS_MEMPUB==0:
    temp_opt = "_OPTReg"
  elif OPT_ABS_REG==0 and OPT_ABS_MEMPUB==1:
    temp_opt = "_OPTMem"
  else:
    temp_opt = ""


  # PART: name
  if batchName==0:
    batchName = ""
  else:
    batchName += "/"
  exp_name = "%s_%dcopy_RF%d_MEMI%d_MEMD%d_ROB%d_CACHE%d%s%s" \
             % (THREAT, COPY, \
                RF_SIZE, MEMI_SIZE, MEMD_SIZE, ROB_SIZE, USE_CACHE, \
                temp_defense, temp_opt)
  tcl_name = "results/%sveri_%s.tcl" % (batchName, exp_name)
  jg_run_data = "results/%smy_jdb_%s" % (batchName, exp_name)
  jg_run_folder = "results/%smy_proj_%s" % (batchName, exp_name)
  terminal_log = "results/%sterminal_%s.log"  % (batchName, exp_name)
  cmd = "{ time jg -batch -proj %s %s ; } > %s 2>&1" \
        % (jg_run_folder, tcl_name, terminal_log)

  # PART: tcl content
  tcl = ""


  # PART.1: Overide the macros in .v
  tcl += "analyze" \
       + " +define"

  tcl += "+RF_SIZE=%d+RF_SIZE_LOG=%d" % (RF_SIZE, RF_SIZE_LOG) \
       + "+MEMI_SIZE=%d+MEMI_SIZE_LOG=%d" % (MEMI_SIZE, MEMI_SIZE_LOG) \
       + "+MEMD_SIZE=%d+MEMD_SIZE_LOG=%d" % (MEMD_SIZE, MEMD_SIZE_LOG) \
       + "+ROB_SIZE=%d+ROB_SIZE_LOG=%d" % (ROB_SIZE, ROB_SIZE_LOG)

  if      USE_DEFENSE_PARTIAL_STT==1:
    temp_defense = "+USE_DEFENSE_PARTIAL_STT="
    if PARTIAL_STT_USE_SPEC==1:
      temp_defense += "+PARTIAL_STT_USE_SPEC="
  elif    USE_DEFENSE_STT==1:
    temp_defense = "+USE_DEFENSE_STT="
    if STT_CHEAT_ALL_SPEC==1:
      temp_defense += "+STT_CHEAT_ALL_SPEC="
    if STT_CHEAT_DELAY_ALL==1:
      temp_defense += "+STT_CHEAT_DELAY_ALL="
    if STT_CHEAT_NO_UNTAINT==1:
      temp_defense += "+STT_CHEAT_NO_UNTAINT="
  elif    USE_DEFENSE_PARTIAL_DOM==1:
    temp_defense = "+USE_DEFENSE_PARTIAL_DOM="
    if PARTIAL_DOM_CHEAT_ALL_SPEC==1:
      temp_defense += "+PARTIAL_DOM_CHEAT_ALL_SPEC="
    if PARTIAL_DOM_USE_MISS_ONLY==1:
      temp_defense += "+PARTIAL_DOM_USE_MISS_ONLY="
    if PARTIAL_DOM_USE_PRIORITY==1:
      temp_defense += "+PARTIAL_DOM_USE_PRIORITY="
  else:
    temp_defense = ""
  
  if USE_CACHE==1:
    temp_cache = "+USE_CACHE="
  else:
    temp_cache = ""

  tcl += "+BR_PREDICT=%d" % BR_PREDICT \
       + temp_defense \
       + temp_cache \
       + "+OBSV=%d" % OBSV \
       + "+INIT_VALUE=0"

  if      COPY==2:
    temp_copy = "two"
    temp_threat = "_" + THREAT
  elif    COPY==3:
    temp_copy = "three"
    temp_threat = ""
  else: # COPY==4:
    temp_copy = "four"
    temp_threat = ""
  tcl += " -sva " \
       + "./src/simpleooo/%s_copy_top%s.v" % (temp_copy, temp_threat)

  tcl += "\n"
  tcl += "\n"


  # PART.2: default jasper gold commands
  tcl += "elaborate -top top -bbox_mul 256\n"
  tcl += "clock clk\n"
  tcl += "reset rst -non_resettable_regs 0\n"
  tcl += "\n"


  # PART.3: Same, Arbitrary Program Assumption
  if      COPY==2:
    tcl += "abstract -init_value {copy1.memi_instance.array}\n"
    tcl += "abstract -init_value {copy2.memi_instance.array}\n"
    tcl += "assume {copy1.memi_instance.array == copy2.memi_instance.array}\n"
  elif    COPY==3:
    tcl += "abstract -init_value {isa1.memi_instance.array}\n"
    tcl += "abstract -init_value {ooo1.memi_instance.array}\n"
    tcl += "abstract -init_value {ooo2.memi_instance.array}\n"
    tcl += "assume {isa1.memi_instance.array == ooo1.memi_instance.array}\n"
    tcl += "assume {ooo1.memi_instance.array == ooo2.memi_instance.array}\n"
  else: # COPY==4:
    tcl += "abstract -init_value {isa1.memi_instance.array}\n"
    tcl += "abstract -init_value {isa2.memi_instance.array}\n"
    tcl += "abstract -init_value {ooo1.memi_instance.array}\n"
    tcl += "abstract -init_value {ooo2.memi_instance.array}\n"
    tcl += "assume {isa1.memi_instance.array == isa2.memi_instance.array}\n"
    tcl += "assume {isa1.memi_instance.array == ooo1.memi_instance.array}\n"
    tcl += "assume {ooo1.memi_instance.array == ooo2.memi_instance.array}\n"

  tcl += "\n"


  # PART.4: Valid Program Assumption
  if      THREAT=="ct":
    if      COPY==2:
      tcl += "assume {invalid_program==0}\n"
    else: # COPY==4:
      tcl += "assume {isa1.is_br -> (isa1.rs2_data==isa2.rs2_data)}\n"
      tcl += "assume {(isa1.mem_valid && isa1.mem_rdwt) -> (isa1.mem_addr==isa2.mem_addr)}\n"
  else: # THREAT=="sandbox":
    if      COPY==2:
      tcl += "assume {invalid_program==0}\n"
    elif    COPY==3:
      tcl += "assume {(isa1.mem_valid && isa1.mem_rdwt) -> !(isa1.mem_addr==1)}\n"
    else: # COPY==4:
      tcl += "assume {(isa1.mem_valid && isa1.mem_rdwt) -> (isa1.rd_data_memory==isa2.rd_data_memory)}\n"
  tcl += "\n"


  # PART.5: Abstract initial secret, public memory
  if OPT_ABS_MEMPUB==1:
    if      COPY==2:
      tcl += "abstract -init_value {copy1.memd}\n"
      tcl += "abstract -init_value {copy2.memd}\n"
      for i in ([0] + list(range(2, MEMD_SIZE))):
        tcl += "assume {init -> copy1.memd[%d] == copy2.memd[%d]}\n" % (i, i)
    elif    COPY==3:
      tcl += "abstract -init_value {isa1.memd_instance.array}\n"
      tcl += "abstract -init_value {ooo1.memd}\n"
      tcl += "abstract -init_value {ooo2.memd}\n"
      for i in ([0] + list(range(2, MEMD_SIZE))):
        tcl += "assume {init -> isa1.memd_instance.array[%d] == ooo1.memd[%d]}\n" % (i, i)
        tcl += "assume {init -> ooo1.memd[%d] == ooo2.memd[%d]}\n" % (i, i)
    else: # COPY==4:
      tcl += "abstract -init_value {ooo1.memd}\n"
      tcl += "abstract -init_value {ooo2.memd}\n"
      tcl += "abstract -init_value {isa1.memd_instance.array}\n"
      tcl += "abstract -init_value {isa2.memd_instance.array}\n"
      tcl += "assume {init -> ooo1.memd[1] == isa1.memd_instance.array[1]}\n"
      tcl += "assume {init -> ooo2.memd[1] == isa2.memd_instance.array[1]}\n"
      for i in ([0] + list(range(2, MEMD_SIZE))):
        tcl += "assume {init -> isa1.memd_instance.array[%d] == isa2.memd_instance.array[%d]}\n" % (i, i)
        tcl += "assume {init -> isa1.memd_instance.array[%d] == ooo1.memd[%d]}\n" % (i, i)
        tcl += "assume {init -> ooo1.memd[%d] == ooo2.memd[%d]}\n" % (i, i)
    tcl += "\n"

  else:
    if      COPY==2:
      tcl += "abstract -init_value {copy1.memd[1]}\n"
      tcl += "abstract -init_value {copy2.memd[1]}\n"
    elif    COPY==3:
      tcl += "abstract -init_value {ooo1.memd[1]}\n"
      tcl += "abstract -init_value {ooo2.memd[1]}\n"
    else: # COPY==4:
      tcl += "abstract -init_value {ooo1.memd[1]}\n"
      tcl += "abstract -init_value {ooo2.memd[1]}\n"
      tcl += "abstract -init_value {isa1.memd_instance.array[1]}\n"
      tcl += "abstract -init_value {isa2.memd_instance.array[1]}\n"
      tcl += "assume {init -> ooo1.memd[1] == isa1.memd_instance.array[1]}\n"
      tcl += "assume {init -> ooo2.memd[1] == isa2.memd_instance.array[1]}\n"
    tcl += "\n"


  # PART.6: Abstract initial register
  if OPT_ABS_REG==1:
    if      COPY==2:
      tcl += "abstract -init_value {copy1.rf_instance.array}\n"
      tcl += "abstract -init_value {copy2.rf_instance.array}\n"
      tcl += "assume {init -> copy1.rf_instance.array == copy2.rf_instance.array}\n"
    elif    COPY==3:
      tcl += "abstract -init_value {isa1.rf_instance.array}\n"
      tcl += "abstract -init_value {ooo1.rf_instance.array}\n"
      tcl += "abstract -init_value {ooo2.rf_instance.array}\n"
      tcl += "assume {init -> isa1.rf_instance.array == ooo1.rf_instance.array}\n"
      tcl += "assume {init -> ooo1.rf_instance.array == ooo2.rf_instance.array}\n"
    else: # COPY==4:
      tcl += "abstract -init_value {isa1.rf_instance.array}\n"
      tcl += "abstract -init_value {isa2.rf_instance.array}\n"
      tcl += "abstract -init_value {ooo1.rf_instance.array}\n"
      tcl += "abstract -init_value {ooo2.rf_instance.array}\n"
      tcl += "assume {init -> isa1.rf_instance.array == isa2.rf_instance.array}\n"
      tcl += "assume {init -> isa1.rf_instance.array == ooo1.rf_instance.array}\n"
      tcl += "assume {init -> ooo1.rf_instance.array == ooo2.rf_instance.array}\n"
    tcl += "\n"


  # PART.6: Abstract initial cache state
  if USE_CACHE==1:
    if      COPY==2:
      tcl += "abstract -init_value {copy1.cached_addr}\n"
      tcl += "abstract -init_value {copy2.cached_addr}\n"
      tcl += "assume {init -> copy1.cached_addr == copy2.cached_addr}\n"
    else: # COPY==3/4:
      tcl += "abstract -init_value {ooo1.cached_addr}\n"
      tcl += "abstract -init_value {ooo2.cached_addr}\n"
      tcl += "assume {init -> ooo1.cached_addr == ooo2.cached_addr}\n"


  
  # PART.7: Property (depending on the observation)
  if      COPY==2:
    tcl += "assert {!((commit_deviation || addr_deviation) && finish_1 && finish_2 && !stall_1 && !stall_2)}\n"
  elif    COPY==3:
    tcl += "assert {ooo1.ld_addr == ooo2.ld_addr && ooo1.C_valid == ooo2.C_valid}\n"
  else: # COPY==4:
    tcl += "assert {ooo1.ld_addr == ooo2.ld_addr && ooo1.C_valid == ooo2.C_valid}\n"
  tcl += "\n"


  # PART.8: prove engine
  if CUSTOM_ENGINE!=0:
    tcl += "set_prove_orchestration off\n"
    tcl += "set_engine_mode {%s}\n" % CUSTOM_ENGINE
    tcl += "\n"
  

  # PART.9: prove time limit
  if TIME_LIMIT!=0:
    tcl += "set_prove_time_limit %s\n" % TIME_LIMIT
    tcl += "\n"


  # PART.10: Run and save work folder
  tcl += "prove -all\n"
  tcl += "save -jdb %s -capture_setup -capture_session_data\n" % jg_run_data
  tcl += "get_design_info\n"
  tcl += "exit\n"
  tcl += "\n"


  return exp_name, tcl_name, tcl, cmd, terminal_log


def write_file(file, content):
  with open(file, "w") as f:
    f.write(content)




if __name__ == "__main__":

  _, tcl_name, tcl, _, _ = gen_verify(THREAT="sandbox", COPY=2)
  print(tcl)
  write_file(tcl_name, tcl)

  _, tcl_name, tcl, _, _ = gen_verify(THREAT="sandbox", COPY=3)
  print(tcl)
  write_file(tcl_name, tcl)

  _, tcl_name, tcl, _, _ = gen_verify(THREAT="sandbox", COPY=4)
  print(tcl)
  write_file(tcl_name, tcl)

  _, tcl_name, tcl, _, _ = gen_verify(THREAT="ct", COPY=2)
  print(tcl)
  write_file(tcl_name, tcl)
  
  _, tcl_name, tcl, _, _ = gen_verify(THREAT="ct", COPY=4)
  print(tcl)
  write_file(tcl_name, tcl)


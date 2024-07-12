
import sys, os

sys.path.append(os.getcwd())
from verification.gen_verify import gen_verify, write_file
from scripts.experiment_helper.saveConfig import saveConfig
from scripts.dask.runCmdList import runCmdList

from param import batchName




expName_list = []
logName_list = []
cmd_list = []




## PART1: Sodor
expName_list += ["sandbox_2copy_sodor2", "ct_2copy_sodor2", "sandbox_4copy_sodor2", "ct_4copy_sodor2"]
logName_list += [ \
  "terminal_sandbox_2copy_sodor2.log", \
  "terminal_ct_2copy_sodor2.log",      \
  "terminal_sandbox_4copy_sodor2.log", \
  "terminal_ct_4copy_sodor2.log"       \
]
cmd_list += [ \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_sandbox_2copy_sodor2 verification/verify_2_copy_sandbox_sodor2.tcl ; } > terminal_sandbox_2copy_sodor2.log 2>&1", \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_ct_2copy_sodor2      verification/verify_2_copy_ct_sodor2.tcl      ; } > terminal_ct_2copy_sodor2.log      2>&1", \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_sandbox_4copy_sodor2 verification/verify_4_copy_sandbox_sodor2.tcl ; } > terminal_sandbox_4copy_sodor2.log 2>&1", \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_ct_4copy_sodor2      verification/verify_4_copy_ct_sodor2.tcl      ; } > terminal_ct_4copy_sodor2.log      2>&1"  \
]




## PART2: SimpleOOO
COPY_list = [2, 4]

## NOTE: Following two sets of 6 micr-arch settings are
#        - NoDefense
#        - NoFwd_futuristic
#        - NoFwd_spectre
#        - Delay_futuristic
#        - Delay_spectre
#        - DoM_spectre
ROB_SIZE_list                   = [4, 4, 4, 4, 4, 8,   4, 4, 4, 4, 4, 4]
USE_CACHE_list                  = [0, 0, 0, 0, 0, 1,   0, 0, 0, 0, 0, 1]

USE_DEFENSE_PARTIAL_STT_list    = [0, 1, 1, 0, 0, 0,   0, 1, 1, 0, 0, 0]
PARTIAL_STT_USE_SPEC_list       = [0, 0, 1, 0, 0, 0,   0, 0, 1, 0, 0, 0]

USE_DEFENSE_PARTIAL_DOM_list    = [0, 0, 0, 1, 1, 1,   0, 0, 0, 1, 1, 1]
PARTIAL_DOM_CHEAT_ALL_SPEC_list = [0, 0, 0, 1, 0, 0,   0, 0, 0, 1, 0, 0]
PARTIAL_DOM_USE_MISS_ONLY_list  = [0, 0, 0, 0, 0, 1,   0, 0, 0, 0, 0, 1]

THREAT_list = ["sandbox", "sandbox", "sandbox", "sandbox", "sandbox", "sandbox", \
               "ct"     , "ct"     , "ct"     , "ct",      "ct"     , "ct"]
CUSTOM_ENGINE_list = ["Ht", "AM", "AM", "AM", "AM", "Ht", \
                      "Ht", "Ht", "Ht", "AM", "AM", "Ht"]

for COPY in COPY_list:
  for (ROB_SIZE, USE_CACHE, \
       USE_DEFENSE_PARTIAL_STT, PARTIAL_STT_USE_SPEC, \
       USE_DEFENSE_PARTIAL_DOM, PARTIAL_DOM_CHEAT_ALL_SPEC, \
       PARTIAL_DOM_USE_MISS_ONLY, \
       THREAT, CUSTOM_ENGINE) in \
      zip(ROB_SIZE_list, USE_CACHE_list, \
          USE_DEFENSE_PARTIAL_STT_list, PARTIAL_STT_USE_SPEC_list, \
          USE_DEFENSE_PARTIAL_DOM_list, PARTIAL_DOM_CHEAT_ALL_SPEC_list, \
          PARTIAL_DOM_USE_MISS_ONLY_list, \
          THREAT_list, CUSTOM_ENGINE_list):
    expName, tclName, tcl, cmd, logName = gen_verify(
      RF_SIZE=4, MEMI_SIZE=16, MEMD_SIZE=4, ROB_SIZE=ROB_SIZE,
      USE_CACHE=USE_CACHE,
      USE_DEFENSE_PARTIAL_STT=USE_DEFENSE_PARTIAL_STT,
      PARTIAL_STT_USE_SPEC=PARTIAL_STT_USE_SPEC,
      USE_DEFENSE_PARTIAL_DOM=USE_DEFENSE_PARTIAL_DOM,
      PARTIAL_DOM_CHEAT_ALL_SPEC=PARTIAL_DOM_CHEAT_ALL_SPEC,
      PARTIAL_DOM_USE_MISS_ONLY=PARTIAL_DOM_USE_MISS_ONLY,
      THREAT=THREAT, COPY=COPY,
      OPT_ABS_MEMPUB=1,
      CUSTOM_ENGINE=CUSTOM_ENGINE,
      TIME_LIMIT="7d"
    )
    write_file(tclName, tcl)

    expName_list.append(expName)
    logName_list.append(logName)
    cmd_list.append("cd %s && " % os.getcwd() + cmd)



## PART3: Ridecore
expName_list += ["sandbox_2copy_ridecore", "ct_2copy_ridecore", "sandbox_4copy_ridecore", "ct_4copy_ridecore"]
logName_list += [ \
  "terminal_sandbox_2copy_ridecore.log", \
  "terminal_ct_2copy_ridecore.log",      \
  "terminal_sandbox_4copy_ridecore.log", \
  "terminal_ct_4copy_ridecore.log"       \
]
cmd_list += [ \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_sandbox_2copy_ridecore verification/verify_2_copy_sandbox_ridecore.tcl ; } > terminal_sandbox_2copy_ridecore.log 2>&1", \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_ct_2copy_ridecore      verification/verify_2_copy_ct_ridecore.tcl      ; } > terminal_ct_2copy_ridecore.log      2>&1", \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_sandbox_4copy_ridecore verification/verify_4_copy_sandbox_ridecore.tcl ; } > terminal_sandbox_4copy_ridecore.log 2>&1", \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_ct_4copy_ridecore      verification/verify_4_copy_ct_ridecore.tcl      ; } > terminal_ct_4copy_ridecore.log      2>&1"  \
]



## PART3: Ridecore
expName_list += ["sandbox_2copy_boom", "ct_2copy_boom"]
logName_list += [ \
  "terminal_sandbox_2copy_boom.log", \
  "terminal_ct_2copy_boom.log"       \
]
cmd_list += [ \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_sandbox_2copy_boom verification/verify_2_copy_sandbox_boom.tcl ; } > terminal_sandbox_2copy_boom.log 2>&1", \
  "cd %s && " % os.getcwd() + "{ time jg -batch -proj my_proj_ct_2copy_boom      verification/verify_2_copy_ct_boom.tcl      ; } > terminal_ct_2copy_boom.log      2>&1"  \
]



## PART4: Run all tests
saveConfig(batchName, expName_list, logName_list)
print("[cmd_list]:", cmd_list)
runCmdList(cmd_list)


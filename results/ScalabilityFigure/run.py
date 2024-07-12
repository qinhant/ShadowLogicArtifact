
import sys, os

sys.path.append(os.getcwd())
from verification.gen_verify import gen_verify, write_file
from scripts.experiment_helper.saveConfig import saveConfig
from scripts.dask.runCmdList import runCmdList

from param import batchName




USE_DEFENSE_PARTIAL_STT_list = [        1,     0]
USE_DEFENSE_PARTIAL_DOM_list = [        0,     1]
THREAT_list                  = ["sandbox",  "ct"]

RF_SIZE_list   = [ 2,  4,  8, 16,    4,  4,  4,    4,  4,  4]
MEMI_SIZE_list = [16, 16, 16, 16,   16, 16, 16,   16, 16, 16]
MEMD_SIZE_list = [ 4,  4,  4,  4,    2,  8, 16,    4,  4,  4]
ROB_SIZE_list  = [ 4,  4,  4,  4,    4,  4,  4,    2,  8, 16]




expName_list = []
logName_list = []
cmd_list = []

for (USE_DEFENSE_PARTIAL_STT, USE_DEFENSE_PARTIAL_DOM, THREAT) in \
    zip(USE_DEFENSE_PARTIAL_STT_list, USE_DEFENSE_PARTIAL_DOM_list, THREAT_list):
  for (RF_SIZE, MEMI_SIZE, MEMD_SIZE, ROB_SIZE) in \
      zip(RF_SIZE_list, MEMI_SIZE_list, MEMD_SIZE_list, ROB_SIZE_list):
    expName, tclName, tcl, cmd, logName = gen_verify(
      RF_SIZE=RF_SIZE, MEMI_SIZE=MEMI_SIZE,
      MEMD_SIZE=MEMD_SIZE, ROB_SIZE=ROB_SIZE,
      USE_DEFENSE_PARTIAL_STT=USE_DEFENSE_PARTIAL_STT,
      USE_DEFENSE_PARTIAL_DOM=USE_DEFENSE_PARTIAL_DOM,
      THREAT=THREAT, COPY=2,
      OPT_ABS_MEMPUB=1,
      CUSTOM_ENGINE="Mp",
      TIME_LIMIT="7d"
    )
    write_file(tclName, tcl)

    expName_list.append(expName)
    logName_list.append(logName)
    cmd_list.append("cd %s && " % os.getcwd() + cmd)


## Run all tests
saveConfig(batchName, expName_list, logName_list)
print("[cmd_list]:", cmd_list)
runCmdList(cmd_list)


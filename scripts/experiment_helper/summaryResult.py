
import sys, os
import json
import numpy as np

sys.path.append(os.getcwd())
from scripts.experiment_helper.getResult import getResult


def summaryResult(batchName, shape, num_engine=4):

  def getIssecureTime(fileName, num_engine):
    isSecure = -1
    try:
      with open(fileName) as f:
        lines = f.readlines()
        for i in range(len(lines)-1, -1, -1):
          words = lines[i].split()

          if len(words) >= 4 and \
             words[0] == "-" and words[1] == "proven" and \
             words[2] == ":" and words[3] == "1":
            isSecure = 1

          if len(words) >= 4 and \
             words[0] == "-" and words[1] == "cex" and \
             words[2] == ":" and words[3] == "1":
            isSecure = 0


          if len(words) >= 4 and \
             words[0] == "Total" and words[1] == "time" and \
             words[2] == "in" and words[3] == "state":
            words = lines[i+4].split()
            # return isSecure, int(float(words[1]) / num_engine)
            return isSecure, float(words[1]) / num_engine
    except:
      return -1, -1
    return -1, -1


  # STEP1: Get expName_list
  expName_list = np.reshape(getResult(batchName)["expName_list"], (-1)).tolist()
  logName_list = np.reshape(getResult(batchName)["logName_list"], (-1)).tolist()


  # STEP2: Collect
  isSecure_list = []
  time_list = []
  for logName in logName_list:
    isSecure, time = getIssecureTime(logName, num_engine)
    isSecure_list.append(isSecure)
    time_list.append(time)
  result = {}
  result["expName_list"]  = np.reshape(expName_list , shape).tolist()
  result["logName_list"]  = np.reshape(logName_list , shape).tolist()
  result["isSecure_list"] = np.reshape(isSecure_list, shape).tolist()
  result["time_list"]     = np.reshape(time_list    , shape).tolist()


  # STEP3: Write to Buffer
  with open("results/%s/summary.json" % batchName, "w") as f:
    json.dump(result, f)


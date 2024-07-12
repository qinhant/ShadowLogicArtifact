
import json


def saveConfig(batchName, expName_list, logName_list):
  config = {"expName_list": expName_list, "logName_list": logName_list}
  with open("results/%s/summary.json" % batchName, "w") as f:
    json.dump(config, f)



import json


def getResult(batchName):
  with open("results/%s/summary.json" % batchName,'r') as f:
    result = json.load(
      f,
      object_hook=lambda d: \
        {int(k) if k.lstrip('-').isdigit() else k: v for k, v in d.items()}
    )
  return result



import sys, os
import numpy as np

sys.path.append(os.getcwd())
from scripts.experiment_helper.getResult import getResult

from param import batchName




result = getResult(batchName)
expName_list  = np.array(result["expName_list"])
isSecure_list = np.array(result["isSecure_list"])
time_list     = np.array(result["time_list"])
np.set_printoptions(formatter={'float': '{: 0.1f}'.format})


print("****** Experiment Name ******")
print(expName_list[:])
print("\n")

print("****** Is Secure ******")
print(isSecure_list[:])
print("\n")

print("****** Time ******")
print(time_list[:])


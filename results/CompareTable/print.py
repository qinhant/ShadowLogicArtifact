
import sys, os
import numpy as np

sys.path.append(os.getcwd())
from scripts.experiment_helper.getResult import getResult

from param import batchName, shape




result = getResult(batchName)
expName_list  = np.array(result["expName_list"])
isSecure_list = np.array(result["isSecure_list"])
time_list     = np.array(result["time_list"])
np.set_printoptions(formatter={'float': '{: 0.1f}'.format})

print("****** Formate ******")
print("expName_list")
print("isSecure_list")
print("time_list")
print("\n\n")

print("****** Sodor ******")
print(expName_list[0:4])
print(isSecure_list[0:4])
print(time_list[0:4])
print("\n\n")

print("****** SimpleOOO - 2copy - Sandbox ******")
print(expName_list[4:10])
print(isSecure_list[4:10])
print(time_list[4:10])
print("\n\n")

print("****** SimpleOOO - 2copy - ConstantTime ******")
print(expName_list[10:16])
print(isSecure_list[10:16])
print(time_list[10:16])
print("\n\n")

print("****** SimpleOOO - 4copy - Sandbox ******")
print(expName_list[16:22])
print(isSecure_list[16:22])
print(time_list[16:22])
print("\n\n")

print("****** SimpleOOO - 4copy - ConstantTime ******")
print(expName_list[22:28])
print(isSecure_list[22:28])
print(time_list[22:28])
print("\n\n")

print("****** Ridecore ******")
print(expName_list[28:32])
print(isSecure_list[28:32])
print(time_list[28:32])
print("\n\n")

print("****** Boom ******")
print(expName_list[32:34])
print(isSecure_list[32:34])
print(time_list[32:34])



import sys, os
import time

sys.path.append(os.getcwd())
from scripts.dask.param import SCHEDULER_PORT
from dask.distributed import Client


def runCmdList(shellcmd_list, use_dask=True):

  if use_dask:
    # STEP1 connect to the local cluster
    client = Client(address="127.0.0.1:%d" % SCHEDULER_PORT)


    # STEP2 mark start time
    startTime = time.time()


    # STEP3 run them
    futureList = []
    for shellcmd in shellcmd_list:
      futureList.append(client.submit(os.system, shellcmd))

    for i, future in enumerate(futureList):
      future.result()
      print("----------> Finish %d/%d Simu, After %f minutes" % \
        (i+1, len(shellcmd_list), (time.time() - startTime)/60))

  else:
    for shellcmd in shellcmd_list:
      os.system("( %s &)" % shellcmd)




if __name__ == "__main__":

  runCmdList([
    "echo haha_1 > haha_1.txt",
    "echo haha_2 > haha_2.txt",
    "echo haha_3 > haha_3.txt",
    "echo haha_4 > haha_4.txt"
  ])

  runCmdList([
    "echo haha_5 > haha_5.txt",
    "echo haha_6 > haha_6.txt",
    "echo haha_7 > haha_7.txt",
    "echo haha_8 > haha_8.txt"
  ], use_dask=False)


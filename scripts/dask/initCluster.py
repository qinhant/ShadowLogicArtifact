
import sys, os
import time

sys.path.append(os.getcwd())
from scripts.dask.param import SCHEDULER_PORT
from dask.distributed import LocalCluster


def initClient(parallelism):
  cluster = LocalCluster(
    scheduler_port=SCHEDULER_PORT,
    threads_per_worker=1,
    n_workers=parallelism
  )
  time.sleep(1)
  print(cluster)




if __name__ == "__main__":

  if len(sys.argv) <= 1:
    print("1 arguments needed!")
    print("Usage: " + sys.argv[0] + " parallelism")
    exit()
  
  parallelism = int(sys.argv[1])
  initClient(parallelism)
  while True:
    time.sleep(100)


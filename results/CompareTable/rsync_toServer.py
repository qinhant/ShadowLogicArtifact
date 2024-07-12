
import os, sys
sys.path.append(os.getcwd())

from scripts.rsync import rsync, SERVER_PATH
from param import batchName, FILELIST




if __name__ == "__main__":
  rsync(".", f"{SERVER_PATH}/{batchName}", FILELIST)


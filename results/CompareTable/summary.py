
import sys, os

sys.path.append(os.getcwd())
from scripts.experiment_helper.summaryResult import summaryResult

from param import batchName, shape, num_engine




summaryResult(batchName, shape, num_engine)


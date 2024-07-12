

shape = [34]
batchName = "CompareTable"
num_engine = 1

FILELIST = [
  "results/%s" % batchName,
  
  "scripts/experiment_helper",
  "scripts/dask",

  "src/sodor2",

  "src/simpleooo_1cycle",
  "src/simpleooo",
  
  "src/ridecore_1cycle",
  "src/ridecore",

  "src/boom",

  "verification",
]


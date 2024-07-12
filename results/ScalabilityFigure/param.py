

shape = [2, 10]
batchName = "ScalabilityFigure"
num_engine = 1

FILELIST = [
    "results/%s" % batchName,
    "scripts/experiment_helper",
    "scripts/dask",

    "src/simpleooo",
    "verification/gen_verify.py",
]


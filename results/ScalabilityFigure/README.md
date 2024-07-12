


## launch the cluster on the server

```
(python3 -u scripts/dask/initCluster.py 6 > & initCluster.log &)
```



## Run Dask batch experiments

```
( python3 -u results/ScalabilityFigure/run.py > & run.log & )
```

You can run other experiments with the same cluster.



## Check the results

```
python3 results/ScalabilityFigure/summary.py
python3 results/ScalabilityFigure/print.py
```

You can do this many times until you see all experiments are finished.



## Plot the results for Figure 2

Based on the printed result, update the array `time` in file `results/ScalabilityFigure/plot.py`. Then run:
```
python3 results/ScalabilityFigure/plot.py
```

You will get a reproduced Figure 2 at `results/ScalabilityFigure/performance.pdf`.






## Kill the cluster on the server

```
ps -ef | grep initCluster.py
kill xxx
```





## launch the cluster on the server

```
(python3 -u scripts/dask/initCluster.py 6 > & initCluster.log &)
```



## Run Dask batch experiments

```
( python3 -u results/CompareTable/run.py > & run.log & )
```

You can run other experiments with the same cluster.



## Check the results

```
python3 results/CompareTable/summary.py
python3 results/CompareTable/print.py
```

You can do this many times until you see all experiments are finished.






## Kill the cluster on the server

```
ps -ef | grep initCluster.py
kill xxx
```


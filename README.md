# H2O Parallel Grid Search Benchmark

A benchmark to demonstrate potential speed-up gained by building `n` models in parallel during Grid Search, instead of sequential build (one model built at a time on the whole H2O Cluster). Parallel model building for Grid search is available since [H2O version 3.28.0.1](https://www.h2o.ai/download/#h2o).

Building multiple models in parallel is useful in many uses cases, especially in:
1. Large variance in hyperparameters, resulting in models with large training time variance. Less time-consuming models are trained alongside the more resource-heavy models, resulting in better resource utilization,
1. Many "quick-to-train" models trained in parallel. Instantiating model training and actions take after a model is built introduce a certain overhead. This also leads to a better resource utilization.

Building multiple models in parallel during Grid search comes at a cost of higher memory consumption. The memory consumption grows in a linear way with the number of models trained in parallel. There is a new parameter introduced named `parallelism`, exposed in R, Python and Flow. By default, this parameter is set to `parallelism = 1`, unless it is overridden by the user. The number given represents number of models built in parallel. Therefore, `parallelism = 1` results in sequential model building, as there is only one model built at a time. Setting this value to anything `> 1` increases the level of parallelism. Things to consider when setting level of parallelism manually:

```R
airlines_small_sequential_duration <- run_grid_search_bench(training_data = airlines_small,
                                                      features = airlines_small_features,
                                                      response = airlines_small_response,
                                                      parallelism = 1, # 1 implicates sequential grid search - one model at a time
                                                      grid_name = "airlines_small_sequential")
```

1. Context switching - every algorithm may spawn multiple threads on each node of the H2O cluster. Training too many models at once might result in high context switching overhead.
1. Memory consumption - Every model requires certain amount of `RAM` allocated during training phase. Increasing the number of models increases the memory consumption in a linear way.

There is one **special mode** of parallel grid search named, which uses H2O's heuristics to determine the number of models built at once. It is invoked by putting zero as a parameter to the parallelism level: `parallelism = 0`. Currently, there is no contract guaranteed - the way the heuristics work might change in future. At the time this is written, H2O does a simple heuristics of running twice as many model builds in parallel as there are CPUs available. H2O assumes all nodes have equal resources and memory is scaled accordingly by the user.

## Grid search parameters

### Constant values
- Algorithms used: Gradient Boosting Machines (GBM, decision trees - runs on CPU)
- Number of trees: 1000
- Seed: 42


### Hyperspace 

The hyperspace is walked in it's whole, by a cartesian walker. Total number of models built is `216`. It is a reduced version of default hyperparameters used by H2O AutoML Project, selected with respect to value variance maximization.

```
max_depth_opts <- c(3, 9,17)
min_rows_opts <- c(30, 100)
learn_rate_opts <- c(0.1, 0.5, 0.8)
sample_rate_opts <- c(0.50, 0.80, 1.00)
col_sample_rate_opts <- c(0.4, 1.0)
col_sample_rate_per_tree_opts <- c(0.4, 1.0)
min_split_improvement_opts <- c(1e-5)
```


## Benchmark results

### Environment

**One** cluster of **five** nodes running on Amazon EC2. Computation-optimized instance.

| Parameter       | Value               |
|:----------------|:--------------------|
| Instance type   | c5.4xlarge          |
| vCPUs           | 16                  |
| RAM (Gb)        | 32                  |
| Placement group | Low latency cluster |

Absolute times are heavily dependent on cluster parameters. H2O Gradient Boosting Machines is used as a single point of reference, as it runs on CPU only. Training multiple models in parallel requires enough memory to be available.

For single.node benchmarks, only one node running on Amazon EC2 was used. As there is no cluster to spread the dataset into, an instance with significantly higher memory for the same amount of cores has been used. This is especially important for the largest dataset, as there will be 32 models trained on one machine.

| Parameter       | Value               |
|:----------------|:--------------------|
| Instance type   | r5a.4xlarge         |
| vCPUs           | 16                  |
| RAM (Gb)        | 128                 |
| Placement group | Low latency cluster |

### Environment setup

H2O `3.28.0.1` was used to perform the benchmark, running on Ubuntu 18.04 LTS. The following "script" has been used to install all the necessary dependencies.

```sh
sudo apt update && \
sudo apt install unzip -y && \
sudo apt install openjdk-8-jdk -y && \
wget http://h2o-release.s3.amazonaws.com/h2o/rel-yu/1/h2o-3.28.0.1.zip && \
unzip h2o-3.28.0.1.zip && \
sudo apt install r-base -y && \
sudo apt install libcurl4-openssl-dev -y
```

In order to be able to execute the R script with the benchmark, `H2O-R library` must be installed. In order to install `H2O R client`, please follow the instructions for the given version available at [h2o.ai downloads](http://h2o-release.s3.amazonaws.com/h2o/rel-yu/1/index.html) website.

When `h2o.init()` is invoked in R, it automatically spawns an instance. However, to ensure proper clustering and easier management, instances of H2O were spawned separately using `nohup java -XmxXXXg -jar h2o.jar &`. For the benchmark, it is crucial to set maximum heap size using the `-Xmx` command to the maximum that is available on the machine where H2O is running, so that H2O is able to fully utilize the memory.

## Measurements (5 nodes)


| Dataset         | Dataset size | Parallelism   | Features                                              | Response     | Response type | Duration                       |
|:----------------|:-------------|:--------------|:------------------------------------------------------|:-------------|:--------------|:-------------------------------|
| Airlines Small  | 2 MB         | SEQUENTIAL    | "Origin", "Dest", "Distance"                          | IsDepDelayed | BINOMIAL      | 133.11378 minutes              |
| Airlines Small  | 2 MB         | PARALLEL-AUTO | "Origin", "Dest", "Distance"                          | IsDepDelayed | BINOMIAL      | 19.88512 minutes (6.9x faster) |
| Airlines Medium | 607,8 MB     | SEQUENTIAL    | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 281.98812 mins                 |
| Airlines Medium | 607,8 MB     | PARALLEL-AUTO | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 74.95446 minutes (3.8x faster) |
| Airlines Large  | 2.2 GB       | SEQUENTIAL    | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 6.880764 hours                 |
| Airlines Large  | 2.2 GB       | PARALLEL-AUTO | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 3.337788 hours (2.06x faster)  |

## Measurements (single node)


| Dataset         | Dataset size | Parallelism   | Features                                              | Response     | Response type | Duration                        |
|:----------------|:-------------|:--------------|:------------------------------------------------------|:-------------|:--------------|:--------------------------------|
| Airlines Small* | 2 MB         | SEQUENTIAL    | "Origin", "Dest", "Distance"                          | IsDepDelayed | BINOMIAL      | 24.81697 minutes                |
| Airlines Small* | 2 MB         | PARALLEL-AUTO | "Origin", "Dest", "Distance"                          | IsDepDelayed | BINOMIAL      | 6.259788 minutes (3.96x faster) |
| Airlines Medium | 607,8 MB     | SEQUENTIAL    | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 6.668322                        |
| Airlines Medium | 607,8 MB     | PARALLEL-AUTO | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 5.404298 (1.23x faster)         |
| Airlines Large  | 2.2 GB       | SEQUENTIAL    | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 21.26976                        |
| Airlines Large  | 2.2 GB       | PARALLEL-AUTO | "Origin", "Dest", "Distance", "FlightNum", "Diverted" | IsDepDelayed | BINOMIAL      | 18.1456 hours (1.2x faster)     |

\*The spee-up in `Airlines Small` benchmark shows there is a large overhead in performing the distributed computing on a tiny dataset.

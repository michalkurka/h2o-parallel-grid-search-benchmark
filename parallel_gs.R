library(h2o)
run_grid_search_bench <- function(training_data, features, response, parallelism, grid_name){
# Constants
ntrees = c(1000)
algorithms_used = "gbm" # GBM is used as a single point of reference

# Space to search
max_depth_opts <- c(3, 9,17)
min_rows_opts <- c(30, 100)
learn_rate_opts <- c(0.1, 0.5, 0.8)
sample_rate_opts <- c(0.50, 0.80, 1.00)
col_sample_rate_opts <- c(0.4, 1.0)
col_sample_rate_per_tree_opts <- c(0.4, 1.0)
min_split_improvement_opts <- c(1e-5)

# Everything else is left to the default settings
hyper_parameters = list(ntrees = ntrees,
                        learn_rate = learn_rate_opts,
                        max_depth = max_depth_opts,
                        min_rows = min_rows_opts,
                        sample_rate = sample_rate_opts,
                        col_sample_rate = col_sample_rate_opts,
                        col_sample_rate_per_tree = col_sample_rate_per_tree_opts,
                        min_split_improvement = min_split_improvement_opts)

start_time = Sys.time()
grid <- h2o.grid(algorithm = algorithms_used,
                          grid_id=grid_name,
                          x=features,
                          y=response,
                          seed=42,
                          training_frame= training_data, 
                          hyper_params = hyper_parameters,
                          parallelism = parallelism)
end_time = Sys.time()

return(end_time - start_time)
}

# Connects to a local H2O cluster by default, change if required
h2o.init(ip = "localhost", strict_version_check = FALSE)




#█████╗ ██╗██████╗ ██╗     ██╗███╗   ██╗███████╗███████╗    ███████╗███╗   ███╗ █████╗ ██╗     ██╗     
#██╔══██╗██║██╔══██╗██║     ██║████╗  ██║██╔════╝██╔════╝    ██╔════╝████╗ ████║██╔══██╗██║     ██║     
#███████║██║██████╔╝██║     ██║██╔██╗ ██║█████╗  ███████╗    ███████╗██╔████╔██║███████║██║     ██║     
#██╔══██║██║██╔══██╗██║     ██║██║╚██╗██║██╔══╝  ╚════██║    ╚════██║██║╚██╔╝██║██╔══██║██║     ██║     
#██║  ██║██║██║  ██║███████╗██║██║ ╚████║███████╗███████║    ███████║██║ ╚═╝ ██║██║  ██║███████╗███████╗
#╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝    ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝

h2o.removeAll() # Ensure the whole cluster is empty both in terms of models and frames
airlines_small <- h2o.importFile("https://0xdata-public.s3.amazonaws.com/parallel-gs-benchmark/airlines_small.csv")
airlines_small_features <- c("Origin", "Dest", "Distance")
airlines_small_response <- c("IsDepDelayed")

# Airlines small - sequential grid search 

airlines_small_sequential_duration <- run_grid_search_bench(training_data = airlines_small,
                                                      features = airlines_small_features,
                                                      response = airlines_small_response,
                                                      parallelism = 1, # 1 implicates sequential grid search - one model at a time
                                                      grid_name = "airlines_small_sequential")
print("Airlines Small (Sequential) duration:")
print(airlines_small_sequential_duration)

# Airlines small - parallel grid search
airlines_small_parallel_duration <- run_grid_search_bench(training_data = airlines_small,
                                                    features = airlines_small_features,
                                                    response = airlines_small_response,
                                                    parallelism = 0, # 0 implicates automatic level of parallelism determined by H2O
                                                    grid_name = "airlines_small_parallel")
print("Airlines Small (Parallel) duration:")
print(airlines_small_parallel_duration)


#█████╗ ██╗██████╗ ██╗     ██╗███╗   ██╗███████╗███████╗    ███╗   ███╗███████╗██████╗ ██╗██╗   ██╗███╗   ███╗
#██╔══██╗██║██╔══██╗██║     ██║████╗  ██║██╔════╝██╔════╝    ████╗ ████║██╔════╝██╔══██╗██║██║   ██║████╗ ████║
#███████║██║██████╔╝██║     ██║██╔██╗ ██║█████╗  ███████╗    ██╔████╔██║█████╗  ██║  ██║██║██║   ██║██╔████╔██║
#██╔══██║██║██╔══██╗██║     ██║██║╚██╗██║██╔══╝  ╚════██║    ██║╚██╔╝██║██╔══╝  ██║  ██║██║██║   ██║██║╚██╔╝██║
#██║  ██║██║██║  ██║███████╗██║██║ ╚████║███████╗███████║    ██║ ╚═╝ ██║███████╗██████╔╝██║╚██████╔╝██║ ╚═╝ ██║
#╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝    ╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝ ╚═════╝ ╚═╝     ╚═╝


h2o.removeAll() # Ensure the whole cluster is empty both in terms of models and frames
airlines_medium <- h2o.importFile("https://0xdata-public.s3.amazonaws.com/parallel-gs-benchmark/airlines_medium.csv")
airlines_medium_features <- c("Origin", "Dest", "Distance", "FlightNum", "Diverted")
airlines_medium_response <- c("IsDepDelayed")

# Airlines medium - sequential grid search 

airlines_medium_sequential_duration <- run_grid_search_bench(training_data = airlines_medium,
                      features = airlines_medium_features,
                      response = airlines_medium_response,
                      parallelism = 1, # 1 implicates sequential grid search - one model at a time
                      grid_name = "airlines_medium_sequential")
print("Airlines Medium (Sequential) duration:")
print(airlines_medium_sequential_duration)

# Airlines medium - parallel grid search
airlines_medium_parallel_duration <- run_grid_search_bench(training_data = airlines_medium,
                                                      features = airlines_medium_features,
                                                      response = airlines_medium_response,
                                                      parallelism = 0, # 0 implicates automatic level of parallelism determined by H2O
                                                      grid_name = "airlines_medium_parallel")
print("Airlines Medium (Parallel) duration:")
print(airlines_medium_parallel_duration)



#█████╗ ██╗██████╗ ██╗     ██╗███╗   ██╗███████╗███████╗    ██╗      █████╗ ██████╗  ██████╗ ███████╗
#██╔══██╗██║██╔══██╗██║     ██║████╗  ██║██╔════╝██╔════╝    ██║     ██╔══██╗██╔══██╗██╔════╝ ██╔════╝
#███████║██║██████╔╝██║     ██║██╔██╗ ██║█████╗  ███████╗    ██║     ███████║██████╔╝██║  ███╗█████╗  
#██╔══██║██║██╔══██╗██║     ██║██║╚██╗██║██╔══╝  ╚════██║    ██║     ██╔══██║██╔══██╗██║   ██║██╔══╝  
#██║  ██║██║██║  ██║███████╗██║██║ ╚████║███████╗███████║    ███████╗██║  ██║██║  ██║╚██████╔╝███████╗
#╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

h2o.removeAll() # Ensure the whole cluster is empty both in terms of models and frames
airlines_large <- h2o.importFile("https://0xdata-public.s3.amazonaws.com/parallel-gs-benchmark/airlines_large.csv")
airlines_large_features <- c("Origin", "Dest", "Distance", "FlightNum", "Diverted")
airlines_large_response <- c("IsDepDelayed")

# Airlines large - sequential grid search 

airlines_large_sequential_duration <- run_grid_search_bench(training_data = airlines_large,
                                                             features = airlines_large_features,
                                                             response = airlines_large_response,
                                                             parallelism = 1, # 1 implicates sequential grid search - one model at a time
                                                             grid_name = "airlines_large_sequential")
print("Airlines Large (Sequential) duration:")
print(airlines_large_sequential_duration)

# Airlines large - parallel grid search
airlines_large_parallel_duration <- run_grid_search_bench(training_data = airlines_large,
                                                           features = airlines_large_features,
                                                           response = airlines_large_response,
                                                           parallelism = 0, # 0 implicates automatic level of parallelism determined by H2O
                                                           grid_name = "airlines_large_parallel")
print("Airlines Large (Parallel) duration:")
print(airlines_large_parallel_duration)


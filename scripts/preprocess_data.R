source("R/faers_prepare.R")

n_quarters <- as.integer(Sys.getenv("FAERS_N_QUARTERS", "8"))
raw_dir <- Sys.getenv("FAERS_RAW_DIR", "data/raw")
processed_dir <- Sys.getenv("FAERS_PROCESSED_DIR", "data/processed")

prepare_processed_data(raw_dir = raw_dir, processed_dir = processed_dir, n_quarters = n_quarters)

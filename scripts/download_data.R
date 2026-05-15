source("R/faers_download.R")

n_quarters <- as.integer(Sys.getenv("FAERS_N_QUARTERS", "8"))
raw_dir <- Sys.getenv("FAERS_RAW_DIR", "data/raw")

download_latest_faers(n = n_quarters, raw_dir = raw_dir, min_year = 2012)

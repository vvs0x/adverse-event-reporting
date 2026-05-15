if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required.", call. = FALSE)
}
suppressPackageStartupMessages(library(data.table))

source_if_needed <- function(path) {
  if (file.exists(path)) {
    source(path, local = .GlobalEnv)
  }
}

source_if_needed("R/faers_read.R")

to_number <- function(x) {
  suppressWarnings(as.numeric(x))
}

age_to_years <- function(age, age_cod) {
  age <- to_number(age)
  code <- toupper(trimws(ifelse(is.na(age_cod), "", age_cod)))
  factor <- rep(NA_real_, length(age))
  factor[code == "YR"] <- 1
  factor[code == "DEC"] <- 10
  factor[code == "MON"] <- 1 / 12
  factor[code == "WK"] <- 7 / 365.25
  factor[code == "DY"] <- 1 / 365.25
  factor[code == "HR"] <- 1 / (365.25 * 24)
  age * factor
}

duration_to_days <- function(dur, dur_cod) {
  dur <- to_number(dur)
  code <- toupper(trimws(ifelse(is.na(dur_cod), "", dur_cod)))
  factor <- rep(NA_real_, length(dur))
  factor[code == "YR"] <- 365.25
  factor[code == "MON"] <- 30.44
  factor[code == "WK"] <- 7
  factor[code %in% c("DAY", "DY")] <- 1
  factor[code == "HR"] <- 1 / 24
  factor[code == "MIN"] <- 1 / (24 * 60)
  factor[code == "SEC"] <- 1 / (24 * 60 * 60)
  dur * factor
}

normalize_drug_name <- function(x) {
  x <- toupper(trimws(ifelse(is.na(x), "", x)))
  x <- gsub("\\s+", " ", x)
  x
}

latest_outcome_per_report <- function(outcome) {
  if (!nrow(outcome)) {
    return(outcome)
  }
  data.table::setDT(outcome)
  outcome[, row_id := seq_len(.N)]
  out <- outcome[order(primaryid, year, quarter, row_id)]
  out <- out[, .SD[.N], by = primaryid]
  out[, row_id := NULL]
  out
}

prepare_processed_data <- function(raw_dir = "data/raw", processed_dir = "data/processed", n_quarters = 8) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Package 'data.table' is required.", call. = FALSE)
  }

  quarters <- latest_available_quarters(raw_dir = raw_dir, n = n_quarters)
  if (!length(quarters)) {
    stop("No FAERS TXT files found. Run scripts/download_data.R first.", call. = FALSE)
  }

  entities <- names(entity_specs())
  written <- character()
  for (entity in entities) {
    message("Combining ", entity)
    dt <- combine_faers_entity(entity, path = raw_dir, quarters = quarters)
    data.table::setDT(dt)

    if (entity == "demographic" && all(c("age", "age_cod") %in% names(dt))) {
      dt[, age_years := age_to_years(age, age_cod)]
    }
    if (entity == "therapy" && all(c("dur", "dur_cod") %in% names(dt))) {
      dt[, therapy_days := duration_to_days(dur, dur_cod)]
    }
    if (entity == "drug" && "drugname" %in% names(dt)) {
      dt[, drugname_norm := normalize_drug_name(drugname)]
    }

    written <- c(written, write_processed_table(dt, entity, processed_dir))
  }

  drug <- read_processed_table("drug", processed_dir)
  drug_lookup <- drug[
    !is.na(drugname_norm) & drugname_norm != "",
    .(reports = data.table::uniqueN(primaryid), records = .N),
    by = .(drugname_norm)
  ][order(-reports, drugname_norm)]
  drug_lookup[, label := paste0(drugname_norm, " (", reports, " reports)")]
  written <- c(written, write_processed_table(drug_lookup, "drug_lookup", processed_dir))

  metadata <- data.frame(
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    quarters = paste(quarters, collapse = ", "),
    storage = if (requireNamespace("nanoparquet", quietly = TRUE)) "parquet" else "rds",
    stringsAsFactors = FALSE
  )
  written <- c(written, write_processed_table(metadata, "metadata", processed_dir))
  invisible(written)
}

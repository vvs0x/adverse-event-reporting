if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required.", call. = FALSE)
}
suppressPackageStartupMessages(library(data.table))

entity_specs <- function() {
  list(
    drug = list(label = "Drug", prefix = "DRUG", seq = "drug_seq"),
    demographic = list(label = "Demographic", prefix = "DEMO", seq = NULL),
    therapy = list(label = "Therapy", prefix = "THER", seq = "dsg_drug_seq"),
    indication = list(label = "Indication", prefix = "INDI", seq = "indi_drug_seq"),
    reaction = list(label = "Reaction", prefix = "REAC", seq = NULL),
    outcome = list(label = "Outcome", prefix = "OUTC", seq = NULL),
    report_sources = list(label = "Report_Sources", prefix = "RPSR", seq = NULL)
  )
}

normalize_entity <- function(entity) {
  key <- tolower(gsub("[^A-Za-z0-9]+", "_", entity))
  aliases <- c(
    drugs = "drug",
    demo = "demographic",
    demographics = "demographic",
    ther = "therapy",
    therapies = "therapy",
    indi = "indication",
    indications = "indication",
    reac = "reaction",
    reactions = "reaction",
    outc = "outcome",
    outcomes = "outcome",
    rpsr = "report_sources",
    report_source = "report_sources",
    reportsources = "report_sources"
  )
  if (key %in% names(aliases)) {
    key <- aliases[[key]]
  }
  if (!key %in% names(entity_specs())) {
    stop("Unknown entity: ", entity, call. = FALSE)
  }
  key
}

faers_entities <- function() {
  vapply(entity_specs(), function(x) x$label, character(1))
}

standardize_faers_names <- function(x) {
  names(x) <- tolower(names(x))
  names(x) <- gsub("[^a-z0-9]+", "_", names(x))
  names(x) <- gsub("^_|_$", "", names(x))

  rename_if_present <- function(old, new) {
    if (old %in% names(x) && !new %in% names(x)) {
      data.table::setnames(x, old, new)
    }
  }

  rename_if_present("gnbr_cod", "sex")
  rename_if_present("gndr_cod", "sex")
  rename_if_present("i_f_code", "i_f_cod")
  rename_if_present("init_fda_date", "init_fda_dt")
  x
}

extract_quarter_from_file <- function(path) {
  base <- basename(path)
  hit <- regmatches(base, regexpr("[0-9]{2}Q[1-4]", base, ignore.case = TRUE))
  if (!length(hit) || hit == "") {
    return(NULL)
  }
  yy <- as.integer(substr(hit, 1, 2))
  year <- if (yy >= 90) 1900 + yy else 2000 + yy
  quarter <- as.integer(substr(hit, 4, 4))
  list(year = year, quarter = quarter, key = sprintf("%dQ%d", year, quarter))
}

find_entity_files <- function(entity, path = "data/raw") {
  key <- normalize_entity(entity)
  prefix <- entity_specs()[[key]]$prefix
  all_files <- list.files(path, pattern = "\\.txt$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  pattern <- paste0("^", prefix, "[0-9]{2}Q[1-4]\\.txt$")
  files <- all_files[grepl(pattern, basename(all_files), ignore.case = TRUE)]
  files[order(files)]
}

read_faers_entity <- function(entity, path = "data/raw", years = NULL, quarters = NULL) {
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Package 'data.table' is required.", call. = FALSE)
  }

  files <- find_entity_files(entity, path)
  if (!length(files)) {
    stop("No files found for entity '", entity, "' under ", path, call. = FALSE)
  }

  meta <- lapply(files, extract_quarter_from_file)
  keep <- !vapply(meta, is.null, logical(1))
  files <- files[keep]
  meta <- meta[keep]

  if (!is.null(years)) {
    keep <- vapply(meta, function(m) m$year %in% years, logical(1))
    files <- files[keep]
    meta <- meta[keep]
  }

  if (!is.null(quarters)) {
    quarter_keys <- toupper(quarters)
    keep <- vapply(meta, function(m) toupper(m$key) %in% quarter_keys, logical(1))
    files <- files[keep]
    meta <- meta[keep]
  }

  out <- vector("list", length(files))
  for (i in seq_along(files)) {
    dt <- data.table::fread(
      files[i],
      sep = "$",
      quote = "",
      na.strings = c("", "NA"),
      fill = TRUE,
      colClasses = "character",
      showProgress = FALSE
    )
    dt <- standardize_faers_names(dt)
    dt[, year := meta[[i]]$year]
    dt[, quarter := meta[[i]]$quarter]
    dt[, quarter_key := meta[[i]]$key]
    out[[i]] <- dt
  }
  names(out) <- vapply(meta, function(m) m$key, character(1))
  out
}

combine_faers_entity <- function(entity, path = "data/raw", years = NULL, quarters = NULL) {
  parts <- read_faers_entity(entity, path = path, years = years, quarters = quarters)
  data.table::rbindlist(parts, use.names = TRUE, fill = TRUE)
}

write_processed_table <- function(x, name, processed_dir = "data/processed") {
  dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
  if (requireNamespace("nanoparquet", quietly = TRUE)) {
    file <- file.path(processed_dir, paste0(name, ".parquet"))
    nanoparquet::write_parquet(x, file)
  } else {
    file <- file.path(processed_dir, paste0(name, ".rds"))
    saveRDS(x, file, compress = "xz")
  }
  file
}

read_processed_table <- function(name, processed_dir = "data/processed") {
  parquet <- file.path(processed_dir, paste0(name, ".parquet"))
  rds <- file.path(processed_dir, paste0(name, ".rds"))
  if (file.exists(parquet)) {
    if (!requireNamespace("nanoparquet", quietly = TRUE)) {
      stop("Install 'nanoparquet' to read ", parquet, call. = FALSE)
    }
    return(data.table::as.data.table(nanoparquet::read_parquet(parquet)))
  }
  if (file.exists(rds)) {
    return(data.table::as.data.table(readRDS(rds)))
  }
  stop("Processed table not found: ", name, call. = FALSE)
}

latest_available_quarters <- function(raw_dir = "data/raw", n = 8) {
  files <- list.files(raw_dir, pattern = "\\.txt$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  meta <- lapply(files, extract_quarter_from_file)
  meta <- meta[!vapply(meta, is.null, logical(1))]
  keys <- unique(vapply(meta, function(m) m$key, character(1)))
  if (!length(keys)) {
    return(character())
  }
  ord <- order(as.integer(substr(keys, 1, 4)), as.integer(substr(keys, 6, 6)), decreasing = TRUE)
  rev(keys[ord][seq_len(min(n, length(keys)))])
}

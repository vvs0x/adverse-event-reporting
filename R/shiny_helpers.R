if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required.", call. = FALSE)
}
suppressPackageStartupMessages(library(data.table))

source("R/faers_read.R")
source("R/faers_prepare.R")

outcome_labels <- c(
  DE = "Death",
  LT = "Life-threatening",
  HO = "Hospitalization",
  DS = "Disability",
  CA = "Congenital anomaly",
  RI = "Required intervention",
  OT = "Other serious"
)

role_labels <- c(
  PS = "Primary suspect",
  SS = "Secondary suspect",
  C = "Concomitant",
  I = "Interacting"
)

sex_labels <- c(
  M = "Male",
  F = "Female",
  UNK = "Unknown"
)

load_app_data <- function(processed_dir = "data/processed") {
  list(
    drug = read_processed_table("drug", processed_dir),
    demographic = read_processed_table("demographic", processed_dir),
    therapy = read_processed_table("therapy", processed_dir),
    indication = read_processed_table("indication", processed_dir),
    reaction = read_processed_table("reaction", processed_dir),
    outcome = read_processed_table("outcome", processed_dir),
    report_sources = read_processed_table("report_sources", processed_dir),
    drug_lookup = read_processed_table("drug_lookup", processed_dir),
    metadata = tryCatch(read_processed_table("metadata", processed_dir), error = function(e) NULL)
  )
}

reports_for_drug <- function(data, selected_drug) {
  drug <- data$drug
  selected_ids <- unique(drug[drugname_norm == selected_drug, primaryid])
  drug[primaryid %in% selected_ids]
}

build_drug_case_table <- function(data, selected_drug) {
  drug_seq <- reports_for_drug(data, selected_drug)
  if (!nrow(drug_seq)) {
    return(data.table::data.table())
  }

  selected_ids <- unique(drug_seq$primaryid)
  demo <- data$demographic[primaryid %in% selected_ids]
  outc <- latest_outcome_per_report(data$outcome[primaryid %in% selected_ids])
  therapy <- data.table::copy(data$therapy[primaryid %in% selected_ids])
  indication <- data.table::copy(data$indication[primaryid %in% selected_ids])

  demo_cols <- intersect(
    c("primaryid", "age", "age_cod", "age_years", "age_grp", "sex", "reporter_country", "occr_country", "occp_cod"),
    names(demo)
  )
  demo <- demo[, ..demo_cols]

  data.table::setnames(therapy, "dsg_drug_seq", "drug_seq", skip_absent = TRUE)
  data.table::setnames(indication, "indi_drug_seq", "drug_seq", skip_absent = TRUE)

  joined <- merge(drug_seq, demo, by = "primaryid", all.x = TRUE, suffixes = c("_drug", "_demo"))
  if (nrow(outc)) {
    joined <- merge(joined, outc[, .(primaryid, outc_cod)], by = "primaryid", all.x = TRUE)
  } else {
    joined[, outc_cod := NA_character_]
  }
  if (nrow(therapy)) {
    joined <- merge(joined, therapy[, .(primaryid, drug_seq, dur, dur_cod, therapy_days, start_dt, end_dt)],
      by = c("primaryid", "drug_seq"), all.x = TRUE
    )
  } else {
    joined[, `:=`(dur = NA_character_, dur_cod = NA_character_, therapy_days = NA_real_, start_dt = NA_character_, end_dt = NA_character_)]
  }
  if (nrow(indication)) {
    joined <- merge(joined, indication[, .(primaryid, drug_seq, indi_pt)], by = c("primaryid", "drug_seq"), all.x = TRUE)
  } else {
    joined[, indi_pt := NA_character_]
  }
  joined
}

filter_cases <- function(case_table, age_range = c(0, 120), sex_filter = "All", roles = c("PS", "SS", "C", "I")) {
  out <- data.table::copy(case_table)
  if ("age_years" %in% names(out)) {
    out <- out[is.na(age_years) | (age_years >= age_range[1] & age_years <= age_range[2])]
  }
  if (!identical(sex_filter, "All") && "sex" %in% names(out)) {
    out <- out[sex == sex_filter]
  }
  if (length(roles) && "role_cod" %in% names(out)) {
    out <- out[role_cod %in% roles]
  }
  out
}

top_reactions <- function(data, case_table, n = 10) {
  ids <- unique(case_table$primaryid)
  head(data$reaction[primaryid %in% ids & !is.na(pt) & pt != "", .N, by = pt][order(-N)], n)
}

top_indications <- function(case_table, n = 10) {
  head(case_table[!is.na(indi_pt) & indi_pt != "", .N, by = indi_pt][order(-N)], n)
}

reports_by_quarter_role <- function(case_table) {
  case_table[, .(reports = data.table::uniqueN(primaryid)), by = .(quarter_key, role_cod)][order(quarter_key, role_cod)]
}

co_occurring_by_role <- function(case_table, selected_drug, n = 8) {
  case_table[
    drugname_norm != selected_drug & !is.na(drugname_norm) & drugname_norm != "",
    .(reports = data.table::uniqueN(primaryid)),
    by = .(role_cod, drugname_norm)
  ][order(role_cod, -reports)][, head(.SD, n), by = role_cod]
}

outcome_distribution <- function(case_table) {
  closed <- case_table[!is.na(end_dt) & end_dt != ""]
  closed[!is.na(outc_cod) & outc_cod != "", .N, by = outc_cod][
    order(-N)
  ][, outcome := ifelse(outc_cod %in% names(outcome_labels), outcome_labels[outc_cod], outc_cod)]
}

age_group_distribution <- function(case_table) {
  if ("age_grp" %in% names(case_table)) {
    out <- case_table[!is.na(age_grp) & age_grp != "", .(reports = data.table::uniqueN(primaryid)), by = age_grp]
    if (nrow(out)) {
      return(out[order(-reports)])
    }
  }
  case_table[, age_bucket := cut(age_years, breaks = c(0, 18, 40, 65, 120), include.lowest = TRUE, right = FALSE)]
  case_table[!is.na(age_bucket), .(reports = data.table::uniqueN(primaryid)), by = age_bucket][order(age_bucket)]
}

country_distribution <- function(case_table, n = 10) {
  country_col <- if ("occr_country" %in% names(case_table)) "occr_country" else "reporter_country"
  out <- case_table[
    !is.na(get(country_col)) & get(country_col) != "",
    .(reports = data.table::uniqueN(primaryid)),
    by = .(country = get(country_col))
  ][order(-reports)]
  head(out, n)
}

missing_value_summary <- function(case_table) {
  cols <- intersect(c("age_years", "sex", "outc_cod", "therapy_days", "indi_pt", "role_cod"), names(case_table))
  data.table::data.table(
    field = cols,
    missing = vapply(cols, function(col) sum(is.na(case_table[[col]]) | case_table[[col]] == ""), integer(1)),
    rows = nrow(case_table)
  )
}

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
  PS = "Primary suspect (PS)",
  SS = "Secondary suspect (SS)",
  C = "Concomitant (C)",
  I = "Interacting (I)"
)

sex_labels <- c(
  M = "Male",
  F = "Female",
  UNK = "Unknown"
)

age_group_labels <- c(
  N = "Neonate",
  I = "Infant",
  C = "Child",
  T = "Adolescent",
  A = "Adult",
  E = "Elderly"
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

selected_drug_rows <- function(data, selected_drug) {
  data$drug[drugname_norm == selected_drug]
}

filter_report_set <- function(data, selected_drug, age_range = c(0, 120), sex_filter = "All", roles = c("PS", "SS", "C", "I")) {
  drug_rows <- selected_drug_rows(data, selected_drug)
  if (!nrow(drug_rows) || !length(roles)) {
    return(list(
      ids = character(),
      role_ids = character(),
      selected_drug = drug_rows[0],
      all_drugs = data$drug[0],
      demographic = data$demographic[0],
      unknown_age_excluded = 0L
    ))
  }

  role_rows <- drug_rows[role_cod %in% roles]
  role_ids <- unique(role_rows$primaryid)
  demo <- data$demographic[primaryid %in% role_ids]
  unknown_age_reports <- data.table::uniqueN(demo[is.na(age_years), primaryid])

  age_filter_active <- !identical(as.numeric(age_range), c(0, 120))
  if ("age_years" %in% names(demo) && age_filter_active) {
    demo <- demo[!is.na(age_years) & age_years >= age_range[1] & age_years <= age_range[2]]
  }
  if (!identical(sex_filter, "All") && "sex" %in% names(demo)) {
    demo <- demo[!is.na(sex) & sex == sex_filter]
  }

  ids <- intersect(role_ids, unique(demo$primaryid))
  list(
    ids = ids,
    role_ids = role_ids,
    selected_drug = role_rows[primaryid %in% ids],
    all_drugs = data$drug[primaryid %in% ids],
    demographic = demo[primaryid %in% ids],
    unknown_age_reports = unknown_age_reports,
    unknown_age_excluded = if (age_filter_active) unknown_age_reports else 0L,
    age_filter_active = age_filter_active
  )
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

top_reactions_for_reports <- function(data, report_set, n = 10) {
  head(data$reaction[primaryid %in% report_set$ids & !is.na(pt) & pt != "", .N, by = pt][order(-N)], n)
}

top_indications <- function(case_table, n = 10) {
  head(case_table[!is.na(indi_pt) & indi_pt != "", .N, by = indi_pt][order(-N)], n)
}

top_indications_for_reports <- function(data, report_set, n = 10) {
  indication <- data$indication[primaryid %in% report_set$ids & !is.na(indi_pt) & indi_pt != ""]
  head(indication[, .(records = .N, reports = data.table::uniqueN(primaryid)), by = indi_pt][order(-reports, -records)], n)
}

reports_by_quarter_role <- function(case_table) {
  case_table[, .(reports = data.table::uniqueN(primaryid)), by = .(quarter_key, role_cod)][order(quarter_key, role_cod)]
}

reports_by_quarter_role_for_selected_drug <- function(report_set) {
  report_set$selected_drug[, .(reports = data.table::uniqueN(primaryid)), by = .(quarter_key, role_cod)][order(quarter_key, role_cod)]
}

co_occurring_by_role <- function(case_table, selected_drug, n = 8) {
  case_table[
    drugname_norm != selected_drug & !is.na(drugname_norm) & drugname_norm != "",
    .(reports = data.table::uniqueN(primaryid)),
    by = .(role_cod, drugname_norm)
  ][order(role_cod, -reports)][, head(.SD, n), by = role_cod]
}

selected_drug_role_summary <- function(report_set) {
  out <- report_set$selected_drug[, .(reports = data.table::uniqueN(primaryid)), by = role_cod][order(-reports)]
  if (!nrow(out)) {
    return(data.table::data.table(role_cod = character(), reports = integer(), role = character()))
  }
  out[, role := ifelse(role_cod %in% names(role_labels), role_labels[role_cod], role_cod)]
  out
}

co_occurring_by_role_for_reports <- function(report_set, selected_drug, n = 5) {
  summary <- selected_drug_role_summary(report_set)
  if (!nrow(summary)) {
    return(data.table::data.table(role = character(), drugname = character(), reports = integer()))
  }
  most_common_role <- summary[1, role_cod]
  other_roles <- setdiff(names(role_labels), most_common_role)
  out <- report_set$all_drugs[
    drugname_norm != selected_drug & role_cod %in% other_roles & !is.na(drugname_norm) & drugname_norm != "",
    .(reports = data.table::uniqueN(primaryid)),
    by = .(role_cod, drugname_norm)
  ][order(role_cod, -reports)]
  out <- out[, head(.SD, n), by = role_cod]
  out[, role := ifelse(role_cod %in% names(role_labels), role_labels[role_cod], role_cod)]
  out[, .(role, drugname = drugname_norm, reports)]
}

outcome_distribution <- function(case_table) {
  closed <- case_table[!is.na(end_dt) & end_dt != ""]
  closed[!is.na(outc_cod) & outc_cod != "", .N, by = outc_cod][
    order(-N)
  ][, outcome := ifelse(outc_cod %in% names(outcome_labels), outcome_labels[outc_cod], outc_cod)]
}

outcome_distribution_for_reports <- function(data, report_set) {
  therapy <- data$therapy[primaryid %in% report_set$ids & !is.na(end_dt) & end_dt != ""]
  completed_ids <- unique(therapy$primaryid)
  outc <- latest_outcome_per_report(data$outcome[primaryid %in% completed_ids])
  out <- outc[!is.na(outc_cod) & outc_cod != "", .(reports = data.table::uniqueN(primaryid)), by = outc_cod][order(-reports)]
  out[, outcome := ifelse(outc_cod %in% names(outcome_labels), outcome_labels[outc_cod], outc_cod)]
  out
}

therapy_distribution_for_reports <- function(data, report_set) {
  data$therapy[primaryid %in% report_set$ids & !is.na(therapy_days) & therapy_days >= 0 & therapy_days <= 3650]
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

age_group_distribution_for_reports <- function(report_set) {
  demo <- report_set$demographic
  if ("age_grp" %in% names(demo)) {
    out <- demo[!is.na(age_grp) & age_grp != "", .(reports = data.table::uniqueN(primaryid)), by = age_grp]
    if (nrow(out)) {
      out[, age_group := ifelse(age_grp %in% names(age_group_labels), age_group_labels[age_grp], age_grp)]
      return(out[order(-reports), .(age_group, reports)])
    }
  }
  demo[, age_group := cut(age_years, breaks = c(0, 18, 40, 65, 120), include.lowest = TRUE, right = FALSE)]
  demo[!is.na(age_group), .(reports = data.table::uniqueN(primaryid)), by = age_group][order(age_group)]
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

country_distribution_for_reports <- function(report_set, n = 10) {
  demo <- report_set$demographic
  country_col <- if ("occr_country" %in% names(demo)) "occr_country" else "reporter_country"
  out <- demo[
    !is.na(get(country_col)) & get(country_col) != "",
    .(reports = data.table::uniqueN(primaryid)),
    by = .(country = get(country_col))
  ][order(-reports)]
  head(out, n)
}

missing_value_summary <- function(data, report_set) {
  ids <- report_set$ids
  demo <- data$demographic[primaryid %in% ids]
  outc <- latest_outcome_per_report(data$outcome[primaryid %in% ids])
  therapy <- data$therapy[primaryid %in% ids]
  indication <- data$indication[primaryid %in% ids]
  data.table::data.table(
    field = c(
      "age excluded before filter",
      "sex",
      "latest outcome",
      "therapy duration",
      "indication",
      "selected drug role"
    ),
    missing = c(
      report_set$unknown_age_excluded,
      data.table::uniqueN(demo[is.na(sex) | sex == "", primaryid]),
      length(setdiff(ids, outc[!is.na(outc_cod) & outc_cod != "", primaryid])),
      length(setdiff(ids, therapy[!is.na(therapy_days), primaryid])),
      length(setdiff(ids, indication[!is.na(indi_pt) & indi_pt != "", primaryid])),
      length(setdiff(ids, report_set$selected_drug[!is.na(role_cod) & role_cod != "", primaryid]))
    ),
    reports = length(ids)
  )
}

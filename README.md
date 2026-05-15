# FAERS Adverse Event Reporting

R/Shiny university project for exploring FDA FAERS adverse event reports.

The assignment text is documented in `docs/assignment_full_extracted.md`. The FAERS ASCII data dictionary is documented in `docs/ASC_NTS_full_extracted.md`.

## Folder Structure

- `R/`: reusable R functions for downloading, reading, preprocessing, and Shiny summaries.
- `scripts/`: command-line scripts for data acquisition and preprocessing.
- `app.R`: Shiny application.
- `data/raw/`: downloaded and unzipped FAERS ASCII quarterly files. Data is not committed.
- `data/processed/`: combined app-ready tables. Data is not committed.
- `docs/`: assignment and FAERS data dictionary references.

## Setup

Install the required packages:

```r
install.packages(c("shiny", "data.table", "ggplot2", "rvest", "stringr", "xml2"))
```

Optional but recommended for the assignment's fast processed format requirement:

```r
install.packages("nanoparquet")
```

If `nanoparquet` is installed, processed files are written as parquet. Otherwise the scripts fall back to compressed RDS files so the project still runs.

## Data Workflow

Download and unzip the latest 8 FAERS quarters:

```sh
Rscript scripts/download_data.R
```

The FDA files can be slow. The script uses a 10-minute timeout and removes incomplete zip files before retrying. If your connection is slower, increase it:

```sh
FAERS_DOWNLOAD_TIMEOUT=1800 Rscript scripts/download_data.R
```

Combine the seven FAERS entities and write processed files:

```sh
Rscript scripts/preprocess_data.R
```

Run the Shiny app:

```r
shiny::runApp()
```

The default period is the latest 8 quarters found on the FDA quarterly FAERS page. To change this:

```sh
FAERS_N_QUARTERS=4 Rscript scripts/download_data.R
FAERS_N_QUARTERS=4 Rscript scripts/preprocess_data.R
```

## App Functionality

The app lets the user:

- Select a drug from the processed FAERS data.
- Filter by age range, sex, and drug role (`PS`, `SS`, `C`, `I`).
- View reports by quarter and role.
- View frequent co-occurring substances in the other role categories.
- View therapy length distribution.
- View top indications and top reactions.
- View outcome distribution for completed therapies.
- View two extra statistics: age group distribution and country distribution.
- Inspect missing values created by joining the FAERS tables.

## Presentation Notes

A simple 10-minute structure:

1. Explain FAERS: reports are split into seven `$`-delimited quarterly ASCII files.
2. Show acquisition: the script scrapes FDA links, downloads recent quarters, unzips them, and keeps generic folder names.
3. Show preprocessing: each entity is read with one generic function and combined with `year`, `quarter`, and `quarter_key`.
4. Show app workflow: choose a drug, filter cases, and interpret required outputs.
5. Discuss the two extra statistics: age groups and countries help identify who is affected and where reports come from.
6. Mention limitations: FAERS is spontaneous reporting data, so counts are not incidence rates and do not prove causality.

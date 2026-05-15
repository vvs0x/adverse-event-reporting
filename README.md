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
install.packages(c("shiny", "data.table", "ggplot2", "rvest", "stringr", "xml2", "nanoparquet"))
```

`nanoparquet` is used for the assignment's fast processed parquet format. If it is not installed, preprocessing falls back to compressed RDS files, but existing parquet files require `nanoparquet` to read.

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

- Select a drug from the 500 most frequently reported drugs in the processed FAERS data.
- Filter by age range, sex, and drug role (`PS`, `SS`, `C`, `I`).
- View reports by quarter and selected drug role.
- View the selected drug's role summary and common other drugs in the same reports.
- View therapy length distribution, with an optional display-only zoom to typical values.
- View top reported indications and reactions.
- View serious outcome distribution for reports with completed therapies.
- View demographics: age groups and event or reporter countries.
- Inspect data completeness and missing values.

## Presentation Notes

A simple 10-minute presentation structure:

1. Explain FAERS briefly: spontaneous adverse event reports split across seven quarterly ASCII files.
2. Show the data workflow: download from FDA, unzip into generic quarter folders, read all seven entities, and save processed parquet files.
3. Explain the app workflow: choose a drug, optionally filter by age, sex, and selected drug role.
4. Demonstrate one common drug, for example `DUPIXENT` or `ASPIRIN`, across the Reports, Therapy, Medical terms, Outcomes, Demographics, and Data quality tabs.
5. Point out the two added statistics: age group distribution and country distribution.
6. Mention the key limitation: FAERS counts are report counts, not incidence rates, risk estimates, or proof of causality.

The data files do not need to be submitted. Submit the R code, README, and documentation files required by the course.

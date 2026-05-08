# ==============================================================================
# AUFGABE 1: DATENAKQUISE UND ORGANISATION (WOCHE 1)
# ==============================================================================

# --- 1. Benötigte Pakete installieren und laden ---
if (!require("pacman")) install.packages("pacman")
pacman::p_load(rvest, stringr, dplyr, fs)

# --- 2. Verzeichnisstruktur definieren ---
# Stelle sicher, dass du in deinem Projekt-Hauptverzeichnis bist
base_path <- getwd()
raw_data_path <- file.path(base_path, "data", "raw")
processed_data_path <- file.path(base_path, "data", "processed")

# Erstelle Ordner, falls sie nicht existieren
dir.create(raw_data_path, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_data_path, recursive = TRUE, showWarnings = FALSE)

# --- 3. Daten von der FDA-Website herunterladen ---
cat("Starte Download der FAERS-Daten...\n")
faers_url <- "https://fis.fda.gov/extensions/FPD-QDE-FAERS/FPD-QDE-FAERS.html"

page <- read_html(faers_url)

# Extrahiere alle Download-Links für ASCII-ZIP-Dateien
links <- page %>%
  html_elements("a") %>%
  html_attr("href")

# Filtere relevante Dateien ab 2012
zip_files_to_download <- links[str_which(links, "ascii\\.zip$")] %>%
  str_subset("/\\d{4}/") # Stellt sicher, dass wir nur Jahresverzeichnisse matchen

# Lade Dateien herunter, wenn sie noch nicht existieren
for (f_link in zip_files_to_download) {
  # Extrahiere das Jahr aus dem Link, um ältere Daten zu überspringen
  year_in_link <- as.numeric(str_extract(f_link, "/(\\d{4})/"))
  if (!is.na(year_in_link) && year_in_link >= 2012) {
    file_name <- basename(f_link)
    dest_path <- file.path(raw_data_path, file_name)
    
    if (!file.exists(dest_path)) {
      cat("Lade herunter:", file_name, "\n")
      download.file(
        url = paste0("https://fis.fda.gov", f_link),
        destfile = dest_path,
        mode = "wb"
      )
    } else {
      cat("Datei bereits vorhanden:", file_name, "\n")
    }
  }
}

# --- 4. Dateien entpacken und organisieren ---
cat("Entpacke und organisiere Dateien...\n")
zip_files_local <- list.files(raw_data_path, pattern = "\\.zip$", full.names = TRUE)

# Erstelle einen generischen Zielordner
generic_unzip_path <- file.path(raw_data_path, "faers_ascii_all")
dir.create(generic_unzip_path, recursive = TRUE, showWarnings = FALSE)

for (z_file in zip_files_local) {
  # Entpacke in einen temporären Ordner
  temp_unzip_dir <- file.path(raw_data_path, "temp_unzip")
  unzip(z_file, exdir = temp_unzip_dir)
  
  # Finde den erzeugten Unterordner (z.B. ascii_2023q1)
  extracted_folder <- list.dirs(temp_unzip_dir, recursive = FALSE)
  
  if (length(extracted_folder) > 0) {
    # Kopiere den Inhalt in den generischen Ordner
    file_copy(
      list.files(extracted_folder, full.names = TRUE),
      generic_unzip_path,
      overwrite = TRUE
    )
  }
  
  # Aufräumen
  unlink(temp_unzip_dir, recursive = TRUE)
}

cat("Aufgabe 1 abgeschlossen. Rohdaten befinden sich in:", generic_unzip_path, "\n")

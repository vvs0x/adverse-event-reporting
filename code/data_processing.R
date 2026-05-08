# ==============================================================================
# AUFGABE 2: DATEN EINLESEN UND ZUSAMMENFÜHREN (WOCHE 2)
# ==============================================================================

# --- 1. Benötigte Pakete laden ---
if (!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, feather, dplyr)

# Pfad zu den entpackten Rohdaten (aus Aufgabe 1)
raw_data_path <- file.path(getwd(), "data", "raw", "faers_ascii_all")
processed_data_path <- file.path(getwd(), "data", "processed")

# --- 2. Einlesefunktion für FAERS-Entitäten ---
# Diese Funktion liest alle Dateien einer Entität (z.B. DRUG, DEMO) für einen Zeitraum ein
read_faers_entity <- function(entity_name, base_path, start_year = 2012) {
  # Finde alle relevanten TXT-Dateien für diese Entität
  pattern <- paste0("^", entity_name, "_\\d{4}Q[1-4]\\.txt$")
  files <- list.files(base_path, pattern = pattern, full.names = TRUE)
  
  # Filtere nach Jahr
  files <- files[str_detect(files, as.character(start_year))]
  
  if (length(files) == 0) {
    warning(paste("Keine Dateien für Entität", entity_name, "gefunden."))
    return(NULL)
  }
  
  # Lese alle Dateien ein und füge eine Spalte für Jahr/Quartal hinzu
  dt_list <- lapply(files, function(f) {
    dt <- fread(f, sep = "$", fill = TRUE, na.strings = "", stringsAsFactors = FALSE)
    # Extrahiere Jahr und Quartal aus dem Dateinamen
    dt$year_quarter <- str_extract(basename(f), "\\d{4}Q[1-4]")
    return(dt)
  })
  
  # Verbinde alle Quartale zu einem großen DataTable
  final_dt <- rbindlist(dt_list, fill = TRUE, use.names = TRUE)
  return(final_dt)
}

# --- 3. Daten für die letzten 2 Jahre einlesen und speichern ---
# Wir nehmen an, die aktuellsten Daten sind 2024/2025.
# Passe die Jahreszahlen bei Bedarf an.
current_year <- 2024
previous_year <- 2023

cat("Lese DRUG-Daten ein...\n")
drug_data <- read_faers_entity("DRUG", raw_data_path, previous_year)

cat("Lese DEMO-Daten ein...\n")
demo_data <- read_faers_entity("DEMO", raw_data_path, previous_year)

cat("Lese REAC-Daten ein...\n")
reac_data <- read_faers_entity("REAC", raw_data_path, previous_year)

cat("Lese OUTC-Daten ein...\n")
outc_data <- read_faers_entity("OUTC", raw_data_path, previous_year)

cat("Lese THER-Daten ein...\n")
ther_data <- read_faers_entity("THER", raw_data_path, previous_year)

cat("Lese INDI-Daten ein...\n")
indi_data <- read_faers_entity("INDI", raw_data_path, previous_year)


# --- 4. Speichern im schnellen Feather-Format ---
# Dies ist ideal für die Shiny App, da das Laden sehr schnell ist.
cat("Speichere aufbereitete Daten im Feather-Format...\n")

write_feather(drug_data, file.path(processed_data_path, "drug.feather"))
write_feather(demo_data, file.path(processed_data_path, "demo.feather"))
write_feather(reac_data, file.path(processed_data_path, "reac.feather"))
write_feather(outc_data, file.path(processed_data_path, "outc.feather"))
write_feather(ther_data, file.path(processed_data_path, "ther.feather"))
write_feather(indi_data, file.path(processed_data_path, "indi.feather"))

cat("Aufgabe 2 abgeschlossen. Verarbeitete Daten wurden in", processed_data_path, "gespeichert.\n")

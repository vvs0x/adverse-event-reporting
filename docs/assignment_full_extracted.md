# Praktikum 3 - Adverse Event Reporting

<!-- Vollständige Markdown-Transkription aus DSPM2_Praktikum3.pdf. Seitenumbrüche und offensichtliche PDF-Zeilenumbrüche wurden geglättet; Inhalt und Struktur bleiben nah am Original. -->

## Woche 1: Daten herunterladen

### 1. Planung

**a)** Verschaffen Sie sich eine Übersicht über die FAERS Daten, z.B. durch Lesen des Dokuments ASC_NTS.DOC (auf Moodle oder Teams) der FDA (2016) oder aufrufen der Links Latest Quaterly Data Files oder Public Dashboard. Lernen Sie daraus, wie die Daten erhoben werden und wie Sie strukturiert sind.

**b)** Organisieren Sie die Dateiverwaltung. Legen Sie ein Dateiverzeichnis an, auf welches alle Gruppenmitglieder zugreifen können (und niemand anderes). Die Grundstruktur könnte Ordner für folgende Inhalte beinhalten:

- Organistaion der Rohdaten
- Organisation der aufbereiteten Daten
- Programmiercode, verwaltet mit Git
- Dokumentation

Legen Sie eine README Datei an, in welcher die Dateiverwaltung beschrieben wird.

### 2. Digitale Datenakquise

**a)** Schreiben Sie in R eine Prozedur, um die Daten direkt von der folgenden Webseite <https://fis.fda.gov/extensions/FPD-QDE-FAERS/FPD-QDE-FAERS.html> auf ihrem Notebook zu speichern, diese zu entpacken und zu organisieren, so dass Sie in der zweiten Woche die Daten einlesen können. Berücksichtigen Sie ausschliesslich Daten ab dem Jahr 2012 und neuer. Folgende R-Funktionen sind nützlich:

```r
library(rvest)
html_elements("a") # searches for HTML-kinks <a href = ...>
html_attr("href") # extracts values of attribute 'href'
download.file() # download file
str_which() # needed to find the desired files
```

**b)** Entpacken Sie von R aus die heruntergeladenen Dateien und legen Sie die Daten ab. Führen Sie anschliessend von R aus Dateimanipulationen wie Umbenennungen oder Dateiverschiebungen aus, so dass die Verzeichnisse generische Namen (z.B. `faers_ascii_2021Q3/`) und Strukturen haben. Orientieren Sie sich dabei an der Verzeichnisstrukur der Daten des aktuellsten Quartals.

```r
unzip()
dir.create()
list.files(path, pattern)
file.copy() # useful for files and folders
file.rename() # useful for files and folders
```

---

## Woche 2: Daten zusammenführen, Planung der Shiny App

### 1. Daten einlesen und zusammenführen

**a)** Lesen Sie die in Woche 1 heruntergeladenen und entpackten Dateien in R ein. Schreiben Sie dazu eine Einlesefunktion, welche mittels den Argumenten `entity`, `path` und `years` sämtliche Dateien einer vorgegebenen Entität (`Drug`, `Demographic`, `Therapy`, `Indication`, `Reaction`, `Outcome` und `Report_Sources`) und Datumsbereich einliest. Die Funktion soll eine Liste mit einem `data.table` pro Quartal generieren. Verwenden Sie für das Einlesen der Daten die Funktion `fread()` oder entsprechende Funktionen für feather oder parquet. Ziel ist es, dass mit dem Code ohne wesentliche Änderungen auch Daten weiterer Quartale eingelesen werden könnten.

**b)** Führen Sie für die letzten 2 Jahre (wenn mehr möglich ist, ist dies natürlich auch in Ordung) jede Entität (`Drug`, ...) die in (a) eingelesenen Daten zu einem `data.table` zusammen, inklusive Spalten für das jeweilige Jahr und Quartal. Berücksichtigen Sie beim Zusammenführen der Daten, dass über die Jahre neue Variablen hinzugefügt bzw. wegglassen wurden und dass Variablen teilweise umbenannt wurden. Ab dem 3. Quartal 2014 wurde die Datenstruktur geändert (siehe <https://fis.fda.gov/content/Exports/SummaryofChanges2014Q3QDE.pdf>).

**c)** Speichern Sie die aufbereiteten in einem Format, welches ihnen erlaubt die Daten möglichst rasch einzulesen. Zwei Speicherformate eignen sich dazu speziell: feather (R-Paket: `feather`) und parquet (R-Paket: `nanoparquet`).

**d)** Schreiben Sie eine Funktion die für ein bestimmtes Medikament (`drugname`) alle Tabellen (ausser `Reaction` und `Report_Sources`) vereinigt, wobei von der `Outcome` Tabelle jeweils nur der letzte Eintrag pro `primaryid` verwendet werden soll. Achten Sie darauf, dass die gesamten Sequenzen in der das ausgewählte Medikament vorkommt berücksichtigt wird, d.h. es wird in der zusammengestellten Tabelle einträge von anderen Medikamenten geben. Starten Sie mit der reduzierten `Drug` Tabelle (Auswahl eines Medikamentents plus Erweiterung auf die vollständigen Sequenzen), vereinigen Sie diese mit der `Demographic` und `Outcome` Tabelle. Anschliessend vereinigen Sie diese Tabelle mit der `Therapy` und `Indication` Tabelle. Überlegen Sie sich zudem, wie sie die Top 10 Reaktion dazu erhalten. Dies gilt wiederum für die gesamten Sequenzen in welchen das Medikament vorkommt.

Berücksichtigen Sie beim Zusammenführen der Daten, dass die Entitäten `Therapie`, `Indication`, `Reaction` und `Report_Sources` nicht für jede Meldung (`primarykey`) einen Record umfasst.

### 2. Planung der App

**a)** In Woche 3 soll eine Shiny App erstellt werden, mit welcher sich die Anwenderin für ein bestimmtes Arztneimittel eine Übersicht über mögliche Reaktionen und unerwünschten Ereignissen erzeugen kann.

**b)** In der App soll die Nutzerin zuerst aus einer Liste das interessierende Medikament auswählen können. Sie können wahlweise alle Medikamente zur Auswahl anbieten, oder Sie können die Liste zwecks Performanz einschränken, z.B. auf die häufigsten Medikamente oder Medikamente für vergleichbare Anwendungen. Anschliessend kann der Nutzer die Analyse durch folgende Filter einschränken: Altersbereich, Geschlecht sowie die Rolle des Medikaments im Fall (`ROLE_COD`). Auf Basis der gefilterten Sequenzen werden automatisch die folgenden Auswertungen berechnet und angezeigt: Histogramm zur Verteilung der Therapielänge, Top-Indikationen sowie Top-Reaktionen.

Beim Start der Shiny-App sollten einmal die Daten jeder Tabelle mind. der letzten zwei Jahre eingelesen werden. Für die Auswahl sollten Sie die im Abschnitt 1d) implementierte Funktion verwenden wobei diese allenfalls zu erweitern ist oder weitere Funktionen dazu kommen.

Abschliessend soll die App dem Nutzer mindestens die folgenden Statistiken anzeigen:

- Anzahl Meldungen zum Medikament nach Quartal und Rolle (`ROLE_COD`-Werte (`PS`, `SS`, `C`, `I`))
- Neben dem häufigsten `ROLE_COD` des Medikaments auch die Substanzen, die in den übrigen drei `ROLE_COD`-Kategorien am häufigsten gemeinsam auftreten.
- Histogramm zur Verteilung der Therapielänge
- Top 10 (oder top 75%) Indikationen
- Top 10 (oder top 75%) Reaktionen
- Balkendiagramm zur Verteilung des Outcomes (unter Ausschluss von Therapien, die nicht abgeschlossen sind)

Ergänzen Sie diese Basisstatistiken mit mindestens zwei weiteren Statistiken, die Sie als interessant werten. Geben Sie womöglich auch die Anzahl fehlender Werte an, die sich durch das Zusammenführen der Daten ergeben.

Für die Planung dieser Arbeit sollen folgende Schritte gemacht werden:

- Diskutieren Sie in Ihrer Gruppe, welche Jahre (mindestens 2 Jahre) und welche Medikamente (alle die in den zwei Jahren vorkommen sollte möglich sein) berücksicht werden sollen. Beachten Sie bei der Einschränkung der Medikamente, dass auch alle Medikamente berücksichtigt werden müssen die in mindestens einer der dazugehörigen Sequenzen vorkommen.
- Bestimmen Sie die 2 weiteren Statistiken, die Sie dem Nutzer anbieten wollen.
- Bestimmen Sie eine Arbeitsaufteilung.
- Suchen Sie für die selektive Eingabe des Medikaments, der Medikamentensequenzen, des Alters und des Geschlechts nach passenden Shiny Input Widgets.
- Skizzieren Sie von Hand, wie die App aussehen soll.
- Stellen Sie gegen Ende des Morgens dem Dozenten Ihren Plan mündlich vor (ca. 5 min).

---

## Woche 3: Shiny App

### 1. Shiny App programmieren

Setzen Sie in der Vorwoche geplante Shiny App in R um. Zusätzlich zur Basisfunktionalität soll in der App eine kurze Benutzeranleitung ersichtlich sein. Beginnen Sie die Programmierung mit einem moderaten Umfang an Daten.

### 2. Präsentation vorbereiten

In Woche 4 soll die programmierte Shiny App präsentiert werden. In dieser Präsentation soll erklärt werden, wie ihre App aufgebaut und zu bedienen ist. Zeigen Sie an ein bis zwei Beispielen wie die App genutzt werden kann und welchen Output die Benutzerin erhält und gehen Sie insbesondere auf die von Ihnen selbst erstellten Statistiken ein. Sie müssen keine zusätzlichen Präsentationsunterlagen (z.B. Folien) oder einen Bericht erstellen.

Nutzen Sie hier die Zeit, um diese Präsentation vorzubereiten.

---

## Woche 4: Präsentation (Donnerstag, 21. Mai ab 9 Uhr im TN O1.46)

In der letzten Woche des Semesters stellen Sie die Resultate ihre Arbeit vor. Auf dem Teams Kanal des Moduls finden Sie die Exceldatei `Zeitplan_Praesentation_Ergebnisse_Praktikum3.xlsx` in der Sie ein Zeitfenster für ihre Präsentation auswählen können. Sie müssen an diesem Morgen nur während der Präsentation anwesend sein.

Sie haben maximal 10 Minuten Zeit die Funktionalität ihrer Shiny App zu demonstrieren (Hilfmittel: eigenes Notbook + Beamer des Unterrichtsraum). Im Anschluss an die Präsentation werden die Dozierenden Fragen zur App sowie der Umsetzung der einzelnen Teilaufgaben stellen, d.h. auch zur Datenakquisition und Aufbereitung (5-10 Minunten). Sie sollten daher wärend der Präsentation Zugriff auf den in den Teilaufgaben entwickleten R-Code haben, diesen via Beamer darstellen und allfällige Fragen dazu beantworten können.

Neben der fachlichen Korrektheit ihrer Antworten wird auch ihr sprachlicher Kommunikationstil (sprachliche Klar- und Korrektheit) beurteilt. Dazu gehört auch die Beurteilung von ihren Antworten auf Fragen von technischen Laien (Personnen die weder R noch Shiny kennen, z.B. eine Auftraggeberin oder ein Journalist).

Der R-Code zu allen Teilaufgaben also von der Datenakquise bis zur Shiny App muss via Moodle bis 21. Mai um 8 Uhr abgegeben werden. Die Daten müssen Sie nicht abgegeben.

---

## Dokumente

FDA. 2016. „"ASC_NTS.DOC" FILE FOR THE QUARTERLY DATA EXTRACT (QDE) FROM THE FDA ADVERSE EVENT REPORTING SYSTEM (FAERS)“. U.S. FOOD AND DRUG ADMINISTRATION (FDA).

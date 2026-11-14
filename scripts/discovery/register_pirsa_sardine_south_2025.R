candidate_id <- "PIRSA:SA_SARDINE_2025"
candidate_unit_id <- "pirsa_southern_australia_sardine"
review_date <- "2026-11-09"
write_mode <- "--write" %in% commandArgs(trailingOnly = TRUE)

register_path <- "discovery/candidates.csv"
units_path <- "discovery/inventory_units.csv"
progress_path <- "discovery/inventory_progress.csv"

if (!file.exists(register_path) || !file.exists(units_path) ||
    !file.exists(progress_path)) {
  stop("Run this script from the SAIO repository root.", call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
units <- read.csv(units_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
progress_table <- read.csv(progress_path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")

if (sum(register$candidate_id == candidate_id, na.rm = TRUE) > 1L ||
    (candidate_id %in% register$candidate_id &&
      any(register$candidate_unit_id[register$candidate_id == candidate_id] !=
        candidate_unit_id, na.rm = TRUE)) ||
    (candidate_unit_id %in% register$candidate_unit_id &&
      !candidate_id %in% register$candidate_id)) {
  stop("A conflicting South Australian Sardine candidate is registered.",
    call. = FALSE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = "PIRSA / SARDI",
  official_stock_id = "",
  scientific_name = "Sardinops sagax",
  stock_name = "Australian Sardine - Southern Australia stock",
  assessment_area = "Southern Australia stock; South Australian Sardine Fishery assessment area",
  inventory_assessment_year = "2025",
  inventory_url = "https://pir.sa.gov.au/fishing-and-aquaculture/commercial-fishing/commercial-fisheries/sardine-fishery",
  retrieved_on = review_date,
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2025 assessment describes annual commercial catch and age-composition",
    "inputs. Exact numerical vectors and likelihood sample sizes were not found",
    "in a separate machine-readable source and are not transcribed from the report."
  ),
  survey_age_evidence = paste(
    "The assessment uses DEPM spawning-biomass observations as an aggregate",
    "abundance input, not an age-specific survey index. Numeric values are not",
    "transcribed from the report."
  ),
  weights_evidence = paste(
    "The report describes fixed growth and length-weight relationships. A",
    "machine-readable age-weight vector was not located."
  ),
  maturity_evidence = paste(
    "The report describes a fixed age-based maturity relationship. Numeric",
    "parameters and derived vectors are not transcribed."
  ),
  mortality_evidence = paste(
    "The report describes estimated baseline and event-specific mortality.",
    "Numeric estimates are not transcribed."
  ),
  timing_evidence = paste(
    "The assessment is annual; a fractional within-year timing for the DEPM",
    "input was not found."
  ),
  output_evidence = paste(
    "The report provides spawning-biomass and total-biomass summaries and other",
    "model outputs, but numeric output values are not transcribed or cached."
  ),
  detailed_source_url = paste(
    "https://pir.sa.gov.au/__data/assets/pdf_file/0011/496793/Stock-assessment-of-Australian-Sardine-Sardinops-sagax-off-South-Australia-2025.pdf",
    "https://pir.sa.gov.au/__data/assets/pdf_file/0008/491381/20251128-Sardine-Spawning-Biomass-2025-FINAL-V2.pdf",
    sep = "; "
  ),
  review_date = review_date,
  decision_reason = paste(
    "The latest detailed official report located describes an age-structured",
    "SardEst assessment for the Southern Australia stock and identifies catch,",
    "age-composition, DEPM, biological and output data. Eligibility remains",
    "unresolved because the sources restrict electronic storage without",
    "permission and no separately licensed machine-readable source was found."
  ),
  notes = paste(
    "Targeted source-led screen; this is not a comprehensive Australian inventory.",
    "The official reports' copyright notices restrict electronic storage without",
    "permission. Direct PDF retrieval previously returned an automated browser",
    "challenge. No source files, checksums, canonical stock, or assessment records",
    "were created. This Southern Australia unit is distinct from the NOAA/DFO Pacific",
    "Sardine northern subpopulation."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

unit <- data.frame(
  unit_key = paste0("candidate:", candidate_unit_id),
  matched_stock_id = "",
  candidate_unit_id = candidate_unit_id,
  match_status = "new",
  eligibility = "unresolved",
  screening_status = "screened",
  import_status = "not_started",
  organizations = "PIRSA / SARDI",
  source_regions = "Southern Australia; targeted assessment-source screen, not a comprehensive inventory",
  candidate_ids = candidate_id,
  inventory_entries = 1L,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

progress <- data.frame(
  organization = "PIRSA / SARDI",
  source_region = "Southern Australia; targeted assessment-source screen, not a comprehensive inventory",
  inventory_rows = 1L,
  matched = 0L,
  new = 1L,
  ambiguous = 0L,
  identity_unreviewed = 0L,
  eligible = 0L,
  excluded = 0L,
  eligible_new = 0L,
  eligibility_unresolved = 1L,
  screening_not_started = 0L,
  screening_in_progress = 0L,
  screening_complete = 1L,
  matched_units = 0L,
  crosswalked_candidate_units = 1L,
  identity_unlinked_rows = 0L,
  eligible_new_units = 0L,
  ineligible_new_units = 0L,
  unresolved_new_units = 1L,
  mixed_new_units = 0L,
  other_candidate_units = 0L,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(identical(names(candidate), names(register)),
  identical(names(unit), names(units)),
  identical(names(progress), names(progress_table)),
  !any(stocks$scientific_name == candidate$scientific_name &
    grepl("Southern Australia|South Australia",
      paste(stocks$area, stocks$region, stocks$authority_stock_id),
      ignore.case = TRUE)))

append_row <- function(row, path) {
  size <- file.info(path)$size
  if (size > 0) {
    con <- file(path, open = "rb")

    seek(con, where = size - 1, origin = "start")
    last_byte <- readBin(con, what = "raw", n = 1L)
    close(con)
    if (!identical(last_byte, as.raw(10L))) {
      cat("\r\n", file = path, append = TRUE)
    }
  }
  write.table(row, path, sep = ",", row.names = FALSE, col.names = FALSE,
    append = TRUE, quote = TRUE, qmethod = "double", na = "")
}

cat("Candidate:", candidate_id, "-", candidate$stock_name, "\n")
cat("Assessment year:", candidate$inventory_assessment_year, "\n")
cat("Screening:", candidate$screening_status, "; eligibility:",
  candidate$eligibility, "; import:", candidate$import_status, "\n")
cat("No canonical assessment data or local source files will be written.\n")

if (write_mode) {
  if (!candidate_id %in% register$candidate_id) {
    append_row(candidate, register_path)
  }
  if (!candidate_unit_id %in% units$candidate_unit_id) {
    append_row(unit, units_path)
  }
  if (!any(progress_table$organization == progress$organization &
      progress_table$source_region == progress$source_region)) {
    append_row(progress, progress_path)
  }
  cat("Registered or completed the unresolved source-led candidate.\n")
}
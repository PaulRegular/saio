root <- "."
args <- commandArgs(trailingOnly = TRUE)
write_mode <- "--write" %in% args

candidate_id <- "QDAF:EAST_COAST_SEA_MULLET_2026"
stock_id <- "australia_east_coast_sea_mullet"
source_path <- file.path(root, "source_cache/australia_east_coast_sea_mullet_2024/sea_mullet_assessment_data_2024.pdf")
expected_hash <- "59069D68DCE3E2F19AD9393210F073A3D12632B9C93ACE0A61B39529EF37AE21"
source_url <- "https://era.dpi.qld.gov.au/id/eprint/16056/1/2026_sea_mullet_stock_assessment.pdf"

sha256_file <- function(path) {
  if ("sha256sum" %in% getNamespaceExports("tools")) {
    return(toupper(unname(tools::sha256sum(path))))
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Install openssl to verify the cached assessment PDF.", call. = FALSE)
  }
  toupper(as.character(openssl::sha256(readBin(path, "raw", n = file.info(path)$size))))
}

if (!file.exists(source_path) || sha256_file(source_path) != expected_hash) {
  stop("The cached Queensland–NSW assessment PDF is missing or has changed.", call. = FALSE)
}

read_csv <- function(path) utils::read.csv(path, stringsAsFactors = FALSE,
  check.names = FALSE, na.strings = c("", "NA"))
read_fields <- function(path) names(utils::read.csv(path, nrows = 0L,
  check.names = FALSE))
append_row <- function(path, row) {
  fields <- read_fields(path)
  if (!all(fields %in% names(row))) {
    stop("The row does not contain all fields for ", path, call. = FALSE)
  }
  utils::write.table(row[fields], path, sep = ",", row.names = FALSE,
    col.names = FALSE, quote = TRUE, qmethod = "double", na = "", append = TRUE)
}

candidate <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = stock_id,
  organization = "Fisheries Queensland / NSW DPIRD",
  official_stock_id = "Eastern Australia biological stock",
  scientific_name = "Mugil cephalus",
  stock_name = "Sea mullet - Eastern Australia",
  assessment_area = "Queensland and New South Wales east coast waters",
  inventory_assessment_year = 2026L,
  inventory_url = "https://era.dpi.qld.gov.au/id/eprint/16056/",
  retrieved_on = "2026-11-08",
  matched_stock_id = "",
  match_status = "new",
  screening_status = "screened",
  eligibility = "unresolved",
  import_status = "not_started",
  catch_age_evidence = paste(
    "The 2026 assessment fits annual catches and sex-specific age compositions for four fleets.",
    "The report gives only one exact aggregate catch total (2024) and shows age compositions in figures, not numerical vectors; fleet-specific catch series are not tabulated."
  ),
  survey_age_evidence = paste(
    "Four standardized annual catch-rate indices are used; the assessment does not report an age-specific abundance survey index.",
    "Numerical CPUE vectors are not tabulated."
  ),
  weights_evidence = "Age and length biological relationships are described and plotted, but the report does not provide complete numerical age-specific weight surfaces.",
  maturity_evidence = "Biological relationships are described and plotted; a complete numerical age-specific maturity schedule is not supplied in the report.",
  mortality_evidence = "Natural mortality is common across ages, sexes and years; the ensemble uses 0.28, 0.33 and 0.37 per year.",
  timing_evidence = "The model is annual; fractional-year timing for catch-rate indices is not reported.",
  output_evidence = paste(
    "Table 1 reports the beginning-of-2025 spawning-biomass ratio with a 95% credible interval, probability by status category, and a 2020-2024 harvest-rate summary.",
    "No numerical annual N-at-age or F-at-age arrays are reported."
  ),
  detailed_source_url = paste(
    source_url,
    "https://www.dpi.qld.gov.au/services/fisheries/monitor/stock/species/sea-mullet",
    sep = "; "
  ),
  review_date = "2026-11-08",
  decision_reason = paste(
    "The latest official assessment for the shared current eastern Australian unit provides a numeric catch summary, model assumptions and comparable status outputs, so it is selected for partial source curation.",
    "Age-input eligibility remains unresolved because the numerical likelihood inputs and complete age-specific biological arrays are not published."
  ),
  notes = "One shared Queensland–NSW biological stock; do not count the state components as separate units.",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

candidate_path <- file.path(root, "discovery/candidates.csv")
units_path <- file.path(root, "discovery/inventory_units.csv")
progress_path <- file.path(root, "discovery/inventory_progress.csv")
stocks <- read_csv(file.path(root, "database/stocks.csv"))
candidates <- read_csv(candidate_path)
units <- read_csv(units_path)
progress <- read_csv(progress_path)

if (stock_id %in% stocks$stock_id || "Mugil cephalus" %in% stocks$scientific_name) {
  stop("A current sea mullet stock record already exists; review before writing.", call. = FALSE)
}

unit <- data.frame(
  unit_key = paste0("candidate:", stock_id),
  matched_stock_id = "",
  candidate_unit_id = stock_id,
  match_status = "new",
  eligibility = "unresolved",
  screening_status = "screened",
  import_status = "not_started",
  organizations = "Fisheries Queensland / NSW DPIRD",
  source_regions = "Eastern Australia",
  candidate_ids = candidate_id,
  inventory_entries = 1L,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

progress_row <- data.frame(
  organization = "Fisheries Queensland / NSW DPIRD",
  source_region = "Eastern Australia; targeted assessment-report screen, not a comprehensive inventory",
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

registered_candidate <- candidates[candidates$candidate_id %in% candidate_id, , drop = FALSE]
registered_unit <- units[units$candidate_unit_id %in% stock_id, , drop = FALSE]
registered_progress <- progress[progress$organization %in% progress_row$organization &
  progress$source_region %in% progress_row$source_region, , drop = FALSE]
if (nrow(registered_candidate) > 1L || nrow(registered_unit) > 1L ||
    nrow(registered_progress) > 1L ||
    (nrow(registered_candidate) == 1L &&
      registered_candidate$candidate_unit_id != stock_id) ||
    (nrow(registered_unit) == 1L &&
      registered_unit$candidate_ids != candidate_id) ||
    (nrow(registered_progress) == 1L &&
      any(as.character(unlist(registered_progress[names(progress_row)], use.names = FALSE)) !=
        as.character(unlist(progress_row, use.names = FALSE))))) {
  stop("The screened register state differs from this source review.", call. = FALSE)
}

cat("Eastern Australian sea mullet: 2026 production assessment verified; one new shared stock unit; age-input eligibility unresolved.\n")
if (!write_mode) {
  cat("Dry run only. Re-run with --write to add the screened candidate and unit crosswalk.\n")
} else {
  if (nrow(registered_candidate) == 0L) append_row(candidate_path, candidate)
  if (nrow(registered_unit) == 0L) append_row(units_path, unit)
  if (nrow(registered_progress) == 0L) append_row(progress_path, progress_row)
  cat("Screened sea mullet candidate, unit crosswalk and targeted inventory status are recorded.\n")
}

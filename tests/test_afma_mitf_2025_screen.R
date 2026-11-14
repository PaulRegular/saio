source("tests/helper_inventory.R")

register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
progress <- read.csv("discovery/inventory_progress.csv", stringsAsFactors = FALSE)
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE)
candidate <- register[register$candidate_id == "AFMA:MITF", , drop = FALSE]
manifest <- read.csv("provenance/afma_mitf_2025_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

check_inventory_accounting(register, progress, units)

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "afma_mitf_patagonian_toothfish",
  candidate$official_stock_id == "MITF",
  candidate$scientific_name == "Dissostichus eleginoides",
  candidate$inventory_assessment_year == 2025L,
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  grepl("conditional age-at-length", candidate$catch_age_evidence, fixed = TRUE),
  grepl("not public", candidate$decision_reason, fixed = TRUE),
  nrow(progress[progress$organization == "AFMA" &
    progress$source_region == candidate$assessment_area, , drop = FALSE]) == 1L,
  nrow(units[units$candidate_ids == "AFMA:MITF", , drop = FALSE]) == 1L,
  nrow(manifest) == 2L,
  manifest$retrieved_on == "2026-11-06",
  nchar(manifest$sha256) == 64L,
  file.exists("source_reviews/afma_mitf_2025.md")
)

cached <- file.path("source_cache", manifest$local_file)
if (all(file.exists(cached))) {
  stopifnot(toupper(unname(tools::sha256sum(cached))) == toupper(manifest$sha256))
}

cat("AFMA Macquarie Island toothfish 2025 screen checks passed.\n")
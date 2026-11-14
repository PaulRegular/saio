source("R/read_database.R")
source("tests/helper_inventory.R")

assessment_id <- "ccsbt_sbt_2026"
x <- read_assessment(assessment_id)
outputs <- x$outputs
candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidates[candidates$candidate_id == "CCSBT:SBT", , drop = FALSE]
manifest <- read.csv("provenance/ccsbt_sbt_2026_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
progress <- read.csv("discovery/inventory_progress.csv", stringsAsFactors = FALSE)
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE)
check_inventory_accounting(register, progress, units)
ccsbt_progress <- progress[progress$organization == "CCSBT", , drop = FALSE]
ccsbt_unit <- units[units$candidate_unit_id == "ccsbt_sbt", , drop = FALSE]

stopifnot(
  x$stocks$stock_id == "ccsbt_sbt",
  x$stocks$authority == "CCSBT",
  x$stocks$authority_stock_id == "SBT",
  x$stocks$scientific_name == "Thunnus maccoyii",
  x$stocks$ocean == "Southern Ocean",
  x$assessment$assessment_year == 2026L,
  x$assessment$terminal_year == 2025L,
  x$assessment$estimate_terminal_year == 2026L,
  x$assessment$is_current,
  x$assessment$is_applied,
  x$assessment$model_family == "R-RTMB annual age-structured assessment",
  all(x$assessment[c("assumptions_status", "inputs_status", "outputs_status")] == "partial"),
  nrow(x$inputs) == 0L,
  nrow(x$assumptions) == 8L,
  nrow(outputs) == 10L,
  setequal(outputs$measure, c(
    "relative_total_reproductive_output",
    "probability_relative_TRO_below_0.2",
    "relative_biomass_age_10_plus",
    "F_ratio_to_FMSY",
    "TRO_ratio_to_TRO_MSY",
    "MSY",
    "probability_TRO2035_above_0.2_TRO0",
    "probability_TRO2035_above_0.3_TRO0",
    "mean_catch_2026_2035"
  )),
  all(is.na(outputs$se) | outputs$se == ""),
  !any(outputs$measure %in% c("SSB", "numbers_at_age",
    "fishing_mortality_at_age", "natural_mortality_at_age")),
  outputs$value[outputs$measure == "relative_total_reproductive_output" &
    outputs$year == 2026L] == 0.281,
  outputs$lwr[outputs$measure == "relative_total_reproductive_output" &
    outputs$year == 2026L] == 0.209,
  outputs$upr[outputs$measure == "relative_total_reproductive_output" &
    outputs$year == 2026L] == 0.373,
  outputs$value[outputs$measure == "MSY"] == 32529,
  candidate$match_status == "new",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  ccsbt_progress$inventory_rows == 1L,
  ccsbt_progress$eligibility_unresolved == 1L,
  ccsbt_unit$unit_key == "candidate:ccsbt_sbt",
  ccsbt_unit$inventory_entries == 1L,
  grepl("longline fleets use length compositions", candidate$catch_age_evidence, fixed = TRUE),
  grepl("not found", candidate$output_evidence, fixed = TRUE),
  nrow(manifest) == 3L,
  all(manifest$retrieved_on == "2026-11-06"),
  all(nchar(manifest$sha256) == 64L),
  any(grepl("ESC31_20", manifest$source_url, fixed = TRUE)),
  file.exists("source_reviews/ccsbt_sbt_2026.md")
)

cached_files <- file.path("source_cache", manifest$local_file)
if (all(file.exists(cached_files))) {
  actual <- toupper(unname(tools::sha256sum(cached_files)))
  stopifnot(identical(actual, toupper(manifest$sha256)))
}

cat("CCSBT SBT 2026 source data checks passed.\n")

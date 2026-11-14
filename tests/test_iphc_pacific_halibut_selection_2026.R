candidate_id <- "NOAA:11082"
stock_id <- "iphc_pacific_halibut"

candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- read.csv("discovery/selected_unworked_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
unit <- candidates[!is.na(candidates$candidate_unit_id) &
  candidates$candidate_unit_id == stock_id, , drop = FALSE]
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
selection <- selected[selected$candidate_id == candidate_id, , drop = FALSE]

stopifnot(
  nrow(unit) == 2L,
  setequal(unit$candidate_id, c("NOAA:11082", "DFO:Pacific:Pacific Halibut")),
  all(unit$eligibility == "eligible"),
  all(unit$import_status == "partial"),
  all(unit$match_status == "matched"),
  all(unit$matched_stock_id == stock_id),
  nrow(candidate) == 1L,
  candidate$official_stock_id == "11082",
  candidate$scientific_name == "Hippoglossus stenolepis",
  nrow(selection) == 1L,
  selection$priority == 2L,
  selection$organization == "IPHC",
  selection$assessment_area == "IPHC Convention Area",
  selection$inventory_assessment_year == 2026L,
  selection$curation_status == "source_curated_partial",
  grepl("31 October 2025", selection$selection_basis, fixed = TRUE),
  sum(stocks$stock_id == stock_id) == 1L,
  sum(assessments$stock_id == stock_id) == 1L,
  assessments$assessment_year[assessments$stock_id == stock_id] == 2025L,
  file.exists("provenance/discovery_iphc_pacific_halibut/sources.csv")
)

cat("IPHC Pacific halibut source-curation register passed.\n")

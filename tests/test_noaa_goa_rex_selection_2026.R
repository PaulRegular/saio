candidate_id <- "NOAA:10058"
stock_id <- "noaa_goa_rex_sole"

candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- read.csv("discovery/selected_unworked_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stock <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidates[candidates$candidate_id == candidate_id, , drop = FALSE]
selection <- selected[selected$candidate_id == candidate_id, , drop = FALSE]
aliases <- candidates[!is.na(candidates$candidate_unit_id) &
  candidates$candidate_unit_id == stock_id, , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  candidate$match_status == "matched",
  candidate$matched_stock_id == stock_id,
  candidate$candidate_unit_id == stock_id,
  nrow(aliases) == 3L,
  setequal(aliases$candidate_id, c("NOAA:10058", "NOAA:15410", "NOAA:15411")),
  all(aliases$import_status == "partial"),
  all(aliases$matched_stock_id == stock_id),
  all(aliases$match_status == "matched"),
  nrow(selection) == 1L,
  selection$curation_status == "source_curated_partial",
  selection$inventory_assessment_year == 2026L,
  grepl("Table 30", selection$selection_basis, fixed = TRUE),
  grepl("Appendix E", selection$selection_basis, fixed = TRUE),
  sum(stock$stock_id == stock_id) == 1L,
  sum(assessments$assessment_id == paste0(stock_id, "_2026")) == 1L,
  assessments$inputs_status[assessments$assessment_id == paste0(stock_id, "_2026")] == "partial",
  assessments$outputs_status[assessments$assessment_id == paste0(stock_id, "_2026")] == "partial",
  file.exists("discovery/source_reviews/noaa_goa_rex_sole_2026.md"),
  file.exists("provenance/discovery_noaa_goa_rex_2026/sources.csv")
)

cat("NOAA GOA rex sole source-curation status passed.\n")

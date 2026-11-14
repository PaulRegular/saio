candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate[candidate$candidate_id == "NOAA:10331", , drop = FALSE]
inventory <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
inventory <- inventory[inventory$candidate_ids == "NOAA:10331", , drop = FALSE]
batch <- read.csv("discovery/selected_batch_41_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_red_grouper_gom_2025.md",
  warn = FALSE), collapse = " ")

stopifnot(
  nrow(candidate) == 1L,
  candidate$official_stock_id == "10331",
  candidate$scientific_name == "Epinephelus morio",
  candidate$assessment_area == "Gulf of Mexico",
  candidate$match_status == "new",
  candidate$eligibility == "eligible",
  candidate$import_status == "not_started",
  nrow(inventory) == 1L,
  inventory$eligibility == "eligible",
  inventory$import_status == "not_started",
  nrow(batch) == 1L,
  batch$candidate_id == "NOAA:10331",
  batch$curation_status == "selected_for_partial_source_curation",
  sum(stocks$authority_stock_id == "10331", na.rm = TRUE) == 0L,
  sum(stocks$authority_stock_id == "10332", na.rm = TRUE) == 1L,
  !any(assessments$assessment_id == "noaa_red_grouper_gom_sedar88_2025"),
  grepl("figure-only", review, fixed = TRUE),
  grepl("not age-specific", review, fixed = TRUE),
  grepl("eligibility does not mean that all model inputs are recoverable", review,
    fixed = TRUE)
)

cat("NOAA Gulf red grouper SEDAR 88 selection checks passed.\n")

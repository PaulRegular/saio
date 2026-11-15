source("scripts/discovery/candidate_reports.R", local = TRUE)

candidate <- read.csv("database/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate[candidate$candidate_id == "NOAA:10331", , drop = FALSE]
inventory <- candidate_units()
inventory <- inventory[inventory$candidate_ids == "NOAA:10331", , drop = FALSE]
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
review <- paste(readLines("source_reviews/noaa_red_grouper_gom.md",
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
  sum(stocks$authority_stock_id == "10331", na.rm = TRUE) == 0L,
  sum(stocks$authority_stock_id == "10332", na.rm = TRUE) == 1L,
  !any(assessments$assessment_id == "noaa_red_grouper_gom_sedar88_2025"),
  grepl("figure-only", review, fixed = TRUE),
  grepl("not age-specific", review, fixed = TRUE),
  grepl("eligibility does not mean that all model inputs are recoverable", review,
    fixed = TRUE)
)

cat("NOAA Gulf red grouper SEDAR 88 selection checks passed.\n")

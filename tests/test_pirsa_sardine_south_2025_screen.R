register <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
progress <- read.csv("discovery/inventory_progress.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE, colClasses = "character")
candidate_id <- "PIRSA:SA_SARDINE_2025"
candidate_unit_id <- "pirsa_southern_australia_sardine"
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == candidate_unit_id, , drop = FALSE]
org_progress <- progress[progress$organization == "PIRSA / SARDI", , drop = FALSE]
review <- paste(readLines(
  "discovery/source_reviews/pirsa_southern_australian_sardine_2025.md",
  warn = FALSE), collapse = "\n")

stopifnot(nrow(candidate) == 1L,
  is.na(candidate$official_stock_id) || candidate$official_stock_id == "",
  candidate$scientific_name == "Sardinops sagax",
  candidate$inventory_assessment_year == "2025",
  candidate$match_status == "new",
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status == "not_started",
  nrow(unit) == 1L,
  unit$unit_key == paste0("candidate:", candidate_unit_id),
  unit$inventory_entries == "1",
  nrow(org_progress) == 1L,
  org_progress$screening_complete == "1",
  org_progress$eligibility_unresolved == "1",
  !any(stocks$scientific_name == "Sardinops sagax"),
  !any(assessments$assessment_id == candidate_unit_id),
  grepl("copyright notices restrict electronic storage", review, fixed = TRUE),
  grepl("No canonical stock, assessment", review, fixed = TRUE),
  grepl("age-composition", candidate$catch_age_evidence, fixed = TRUE),
  grepl("DEPM", candidate$survey_age_evidence, fixed = TRUE))

cat("South Australian Sardine is screened without unsupported canonical data.\n")

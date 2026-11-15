source("scripts/discovery/candidate_reports.R", local = TRUE)

register <- read.csv("database/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
row <- register[register$candidate_id == "DFO:Pacific:Silvergray Rockfish - Coastwide", , drop = FALSE]
units <- candidate_units()
unit <- units[which(units$candidate_unit_id == "dfo_silvergray_rockfish_coastwide"), , drop = FALSE]
review <- paste(readLines("source_reviews/dfo_silvergray_rockfish_coastwide.md",
  warn = FALSE), collapse = "\n")
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == "dfo_silvergray_rockfish_coastwide",
  row$inventory_assessment_year == "2025",
  row$match_status == "new",
  row$screening_status == "screened",
  row$eligibility == "unresolved",
  row$import_status == "not_started",
  nrow(unit) == 1L,
  unit$screening_status == "screened",
  unit$eligibility == "unresolved",
  unit$import_status == "not_started",
  !any(grepl("silvergray", stocks$common_name, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl("silvergray", assessments$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  grepl("2026/038", review, fixed = TRUE),
  grepl("1996 through 2025", review, fixed = TRUE),
  grepl("age-input eligibility remains unresolved", review, ignore.case = TRUE),
  grepl("do not fall back", review, ignore.case = TRUE)
)

cat("DFO Silvergray current-unit identity, source screen, and unresolved age-input checks passed.\n")
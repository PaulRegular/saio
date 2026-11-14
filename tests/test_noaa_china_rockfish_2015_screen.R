root <- "."
source(file.path(root, "tests/helper_inventory.R"))
register <- read.csv(file.path(root, "discovery/candidates.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
ids <- c("NOAA:14410", "NOAA:14430", "NOAA:14429")
units_expected <- c("noaa_china_rockfish_northern_pacific_coast",
  "noaa_china_rockfish_central_pacific_coast", "noaa_china_rockfish_southern_pacific_coast")
candidate <- register[match(ids, register$candidate_id), , drop = FALSE]
units <- read.csv(file.path(root, "discovery/inventory_units.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
progress <- read.csv(file.path(root, "discovery/inventory_progress.csv"),
  stringsAsFactors = FALSE, check.names = FALSE)
unit <- units[units$matched_stock_id %in% units_expected | units$candidate_unit_id %in% units_expected, , drop = FALSE]
review <- paste(readLines(file.path(root, "discovery/source_reviews/noaa_china_rockfish_us_pacific_2015.md"),
  warn = FALSE), collapse = " ")
stocks <- read.csv(file.path(root, "database/stocks.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv(file.path(root, "database/assessments.csv"),
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stock_ids <- units_expected
assessment_ids <- paste0(stock_ids, "_2015")

stopifnot(nrow(candidate) == 3L, !anyDuplicated(candidate$candidate_unit_id),
  setequal(candidate$candidate_unit_id, units_expected),
  all(candidate$match_status == "matched"), all(candidate$screening_status == "screened"),
  all(candidate$eligibility == "eligible"), all(candidate$import_status == "partial"),
  all(candidate$matched_stock_id == units_expected),
  all(grepl("Partial source import", candidate$notes, fixed = TRUE)),
  grepl("three independent Stock Synthesis models", review, fixed = TRUE),
  grepl("2019 Stock SMART label refers to a catch-only projection", review, fixed = TRUE),
  grepl("source_cache/discovery_noaa_china_rockfish_2019", review, fixed = TRUE),
  nrow(unit) == 3L, all(unit$inventory_entries == 1L),
  all(unit$match_status == "matched"), all(unit$import_status == "partial"),
  setequal(unit$matched_stock_id, units_expected),
  nrow(stocks[stocks$stock_id %in% stock_ids, ]) == 3L,
  nrow(assessments[assessments$assessment_id %in% assessment_ids, ]) == 3L)

check_inventory_accounting(register, progress, units)
cat("NOAA China rockfish 2015 area identity, import status, and source review checks passed.\n")

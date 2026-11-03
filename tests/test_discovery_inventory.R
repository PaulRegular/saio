source("tests/helper_inventory.R")
read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
register <- read_table("discovery/candidates.csv")
stocks <- read_table("database/stocks.csv")
progress <- read_table("discovery/inventory_progress.csv")
units <- read_table("discovery/inventory_units.csv")
selected <- read_table("discovery/selected_batch_01_2026.csv")

# Source-list membership is distinct from current stock and import status.
stopifnot(nrow(register) > 0L, !anyNA(register$candidate_id),
  !anyDuplicated(register$candidate_id), !any(register$candidate_id == "candidate_id"),
  all(register$organization %in% c("NOAA", "ICES", "DFO")),
  all(register$match_status %in% c("unreviewed", "matched", "new", "ambiguous")),
  all(register$screening_status %in% c("not_started", "in_progress", "screened")),
  all(register$eligibility %in% c("unresolved", "eligible", "ineligible")),
  all(register$import_status %in% c("not_started", "in_progress", "partial", "imported", "blocked")),
  all(is.na(register$matched_stock_id) | register$matched_stock_id %in% stocks$stock_id))
check_inventory_accounting(register, progress, units)
incorrect_progress <- progress
incorrect_progress$new[1L] <- incorrect_progress$new[1L] + 1L
incorrect_units <- units
incorrect_units$candidate_ids[1L] <- "absent:inventory-entry"
stopifnot(inherits(tryCatch(check_inventory_accounting(register, incorrect_progress, units),
    error = identity), "error"),
  inherits(tryCatch(check_inventory_accounting(register, progress, incorrect_units),
    error = identity), "error"))

eligible <- register$eligibility == "eligible"
for (field in c("catch_age_evidence", "survey_age_evidence", "weights_evidence",
  "maturity_evidence", "mortality_evidence", "timing_evidence", "output_evidence",
  "detailed_source_url", "review_date")) {
  stopifnot(!any(is.na(register[[field]][eligible]) | !nzchar(register[[field]][eligible])))
}
ices_matches <- register[register$organization == "ICES" & register$match_status == "matched", ]
stock_rows <- match(ices_matches$matched_stock_id, stocks$stock_id)
stopifnot(all(tolower(ices_matches$official_stock_id) == tolower(stocks$authority_stock_id[stock_rows])))

# Joint assessments and selected imports must keep their cross-inventory identities.
lookup <- function(id) register[match(id, register$candidate_id), , drop = FALSE]
hake <- register[register$matched_stock_id %in% "joint_hake_coastal", , drop = FALSE]
stopifnot(all(c("NOAA", "DFO") %in% hake$organization),
  lookup("NOAA:10523")$matched_stock_id == "joint_hake_coastal",
  lookup("DFO:Pacific:Pacific Hake - Offshore")$matched_stock_id == "joint_hake_coastal",
  !anyDuplicated(selected$candidate_unit_id), !anyDuplicated(selected$candidate_id),
  all(selected$candidate_id %in% register$candidate_id))
selected_rows <- register[match(selected$candidate_id, register$candidate_id), , drop = FALSE]
stopifnot(identical(selected$candidate_unit_id, selected_rows$candidate_unit_id),
  all(selected_rows$eligibility == "eligible"),
  all(selected_rows$import_status %in% c("partial", "imported")),
  all(selected$curation_status == "partial_source_import"))

cat("Current discovery identities, source evidence, unit deduplication and summary accounting passed.\n")

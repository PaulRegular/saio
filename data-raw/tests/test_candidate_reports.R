source("data-raw/scripts/shared/candidate_reports.R", local = TRUE)

register <- data.frame(
  candidate_id = c("NOAA:A", "DFO:Atlantic:A", "ICES:B", "DFO:Atlantic:C"),
  candidate_unit_id = c("a", "a", "b", NA),
  matched_stock_id = c("stock_a", "stock_a", NA, NA),
  organization = c("NOAA", "DFO", "ICES", "DFO"),
  match_status = c("matched", "matched", "new", "ambiguous"),
  eligibility = c("eligible", "eligible", "eligible", "unresolved"),
  screening_status = rep("screened", 4L),
  import_status = c("partial", "partial", "not_started", "not_started")
)
region <- c("NOAA region", "Atlantic", "ICES region", "Atlantic")
units <- candidate_units(register, region)
progress <- candidate_progress(register, region)
stopifnot(
  setequal(units$unit_key, c("stock:stock_a", "candidate:b")),
  units$inventory_entries[units$unit_key == "stock:stock_a"] == 2L,
  units$import_status[units$unit_key == "stock:stock_a"] == "partial",
  units$import_status[units$unit_key == "candidate:b"] == "not_started",
  sum(progress$inventory_rows) == nrow(register),
  sum(progress$identity_unlinked_rows) == 1L,
  sum(progress$eligible_new_units) == 1L
)

current <- read_candidate_register()
stopifnot(
  sum(candidate_progress(current)$inventory_rows) == nrow(current),
  !anyDuplicated(candidate_units(current)$unit_key)
)
cat("Candidate reports count inventory entries and group aliases by stock unit.\n")

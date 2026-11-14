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
  !anyNA(register$organization), all(nzchar(register$organization)),
  all(register$match_status %in% c("unreviewed", "matched", "new", "ambiguous")),
  all(register$screening_status %in% c("not_started", "in_progress", "screened")),
  all(register$eligibility %in% c("unresolved", "eligible", "ineligible")),
  all(register$import_status %in% c("not_started", "in_progress", "partial", "imported", "blocked")),
  all(is.na(register$matched_stock_id) | register$matched_stock_id %in% stocks$stock_id))
regional_rows <- register[register$organization %in%
  c("Fisheries New Zealand", "AFMA"), , drop = FALSE]
nz_rows <- regional_rows[regional_rows$organization == "Fisheries New Zealand", , drop = FALSE]
afma_rows <- regional_rows[regional_rows$organization == "AFMA", , drop = FALSE]
afma_unmatched <- afma_rows[afma_rows$match_status == "new", , drop = FALSE]
stopifnot(nrow(regional_rows) == 29L,
  nrow(nz_rows) == 21L,
  all(nz_rows$match_status == "matched"),
  all(nz_rows$matched_stock_id %in% stocks$stock_id),
  nrow(afma_rows) == 8L,
  sum(afma_rows$match_status == "matched") == 7L,
  nrow(afma_unmatched) == 1L,
  afma_unmatched$candidate_id == "AFMA:SESSF_Eastern_School_Whiting",
  afma_unmatched$eligibility == "unresolved",
  afma_unmatched$import_status == "partial",
  all(afma_rows$matched_stock_id[afma_rows$match_status == "matched"] %in% stocks$stock_id))
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

nafo <- register[register$organization == "NAFO", , drop = FALSE]
stopifnot(nrow(nafo) == 27L, !anyDuplicated(nafo$candidate_id),
  !anyNA(nafo$official_stock_id), all(nzchar(nafo$official_stock_id)),
  all(nafo$screening_status == "screened"),
  all(nafo$inventory_url == "https://www.nafo.int/Science/Science-Advice/Stock-advice"),
  all(nafo$retrieved_on == "2026-11-04"), all(nafo$review_date == "2026-11-04"),
  any(nafo$eligibility == "eligible"), any(nafo$eligibility == "ineligible"),
  all(c("NAFO") %in% progress$organization))
for (id in c("NAFO:cod.3M", "NAFO:cod.3NO", "NAFO:redfish.3M",
  "NAFO:american_plaice.3LNO")) {
  stopifnot(lookup(id)$eligibility == "eligible")
}
for (id in c("NAFO:american_plaice.3M", "NAFO:redfish.3LN",
  "NAFO:redfish.3O", "NAFO:yellowtail_flounder.3LNO",
  "NAFO:witch_flounder.3NO", "NAFO:capelin.3NO",
  "NAFO:thorny_skate.3LNOPs", "NAFO:white_hake.3NO3Ps",
  "NAFO:greenland_halibut.1A-Uummannaq", "NAFO:wolffish.SA1")) {
  stopifnot(lookup(id)$eligibility == "ineligible")
}
stopifnot(lookup("NAFO:greenland_halibut.SA2-3KLMNO")$matched_stock_id ==
    "dfo_greenland_halibut_2_3klmno",
  lookup("NAFO:greenland_halibut.SA2-3KLMNO")$match_status == "matched",
  lookup("NAFO:redfish.SA1")$match_status == "ambiguous")
crosswalks <- c(
  "NAFO:redfish.3LN" = "DFO:Newfoundland and Labrador:Redfish - NAFO 3LN",
  "NAFO:redfish.3O" = "DFO:Newfoundland and Labrador:Redfish - NAFO 3O",
  "NAFO:yellowtail_flounder.3LNO" = "DFO:Newfoundland and Labrador:Yellowtail Flounder - NAFO 3LNO",
  "NAFO:witch_flounder.3NO" = "DFO:Newfoundland and Labrador:Witch Flounder - NAFO 3NO",
  "NAFO:thorny_skate.3LNOPs" = "DFO:Newfoundland and Labrador:Thorny Skate - NAFO 3LNO",
  "NAFO:white_hake.3NO3Ps" = "DFO:Newfoundland and Labrador:White Hake - NAFO 3NOPs",
  "NAFO:greenland_halibut.SA0-1-offshore" = "DFO:Arctic:Greenland Halibut - NAFO 0A and 0B"
)
for (nafo_id in names(crosswalks)) {
  stopifnot(lookup(nafo_id)$candidate_unit_id ==
      lookup(unname(crosswalks[[nafo_id]]))$candidate_unit_id)
}
prior_units <- unique(register$candidate_unit_id[register$organization != "NAFO" &
  !is.na(register$candidate_unit_id) & nzchar(register$candidate_unit_id)])
nafo_units <- unique(nafo$candidate_unit_id[!is.na(nafo$candidate_unit_id) &
  nzchar(nafo$candidate_unit_id)])
stopifnot(length(nafo_units) == 27L,
  length(intersect(nafo_units, prior_units)) == 8L,
  length(setdiff(nafo_units, prior_units)) == 19L)
redfish3ln_unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == "nafo_redfish_3ln", ]
stopifnot(nrow(redfish3ln_unit) == 1L,
  grepl("DFO", redfish3ln_unit$organizations, fixed = TRUE),
  grepl("NAFO", redfish3ln_unit$organizations, fixed = TRUE))
hoki <- lookup("MPI:HOK1")
hoki_selection <- read_table("discovery/selected_batch_02_2026.csv")
hoki_selection <- hoki_selection[hoki_selection$candidate_id == "MPI:HOK1", , drop = FALSE]
stopifnot(hoki$candidate_unit_id == "nz_hoki_hok1",
  hoki$official_stock_id == "HOK 1",
  grepl("numbers-at-age", hoki$catch_age_evidence, fixed = TRUE),
  hoki$import_status %in% c("not_started", "partial"),
  nrow(hoki_selection) == 1L,
  hoki_selection$candidate_id == "MPI:HOK1",
  hoki_selection$curation_status %in% c("selected_for_source_curation", "source_curated_partial"))
cat("New Zealand HOK 1 screening and selection passed.\n")

cat("NAFO inventory coverage, screening decisions and DFO crosswalks passed.\n")

cat("Current discovery identities, source evidence, unit deduplication and summary accounting passed.\n")



hak7 <- lookup("MPI:HAK7:WCSI")
hak7_unit <- units[units$candidate_ids == "MPI:HAK7:WCSI", , drop = FALSE]
nz_progress <- progress[progress$organization == "Fisheries New Zealand", , drop = FALSE]
nz_rows <- register[register$organization == "Fisheries New Zealand", , drop = FALSE]
nz_eligible_new_units <- unique(nz_rows$candidate_unit_id[
  nz_rows$match_status == "new" & nz_rows$eligibility == "eligible"])
stopifnot(nrow(hak7) == 1L,
  hak7$matched_stock_id == "mpi_hake_hak7_wcsi",
  hak7$import_status == "partial",
  nrow(hak7_unit) == 1L,
  hak7_unit$unit_key == "stock:mpi_hake_hak7_wcsi",
  hak7_unit$import_status == "partial",
  grepl("not part of the fitted run", hak7$notes, fixed = TRUE),
  nz_progress$inventory_rows == nrow(nz_rows),
  nz_progress$eligible_new == sum(nz_rows$match_status == "new" &
    nz_rows$eligibility == "eligible"),
  nz_progress$eligible_new_units == length(nz_eligible_new_units))

source("scripts/discovery/candidate_reports.R", local = TRUE)

assessment_id <- "mpi_bluenose_nz_2021"
read_table <- function(path) read.csv(path, stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)

candidate_id <- "MPI:BNS_NZ"
candidate <- read_table("discovery/candidates.csv")
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
manifest <- read_table("provenance/mpi_bluenose_nz_2021_sources.csv")
units <- candidate_units()
progress <- candidate_progress()

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "mpi_bluenose_nz",
  candidate$official_stock_id == "BNS (New Zealand-wide assessment unit)",
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  grepl("not catch numbers-at-age", candidate$catch_age_evidence, fixed = TRUE),
  grepl("no research-survey", candidate$survey_age_evidence, fixed = TRUE),
  grepl("sex-specific empirical", candidate$weights_evidence, fixed = TRUE),
  grepl("Table 5", candidate$output_evidence, fixed = TRUE),
  grepl("official 2021 assessment", candidate$decision_reason, fixed = TRUE),
  nrow(manifest) == 2L,
  all(manifest$retrieved_on == "2026-11-06"),
  identical(toupper(unname(tools::sha256sum(file.path("source_cache", manifest$local_file)))),
    toupper(manifest$sha256)),
  sum(units$unit_key == "stock:mpi_bluenose_nz", na.rm = TRUE) == 1L,
  units$import_status[units$unit_key == "stock:mpi_bluenose_nz"] == "partial",
  progress$inventory_rows[progress$organization == "Fisheries New Zealand"] == 18L,
  progress$eligible_new[progress$organization == "Fisheries New Zealand"] == 0L
)

cat("New Zealand bluenose selection and source provenance checks passed.\n")

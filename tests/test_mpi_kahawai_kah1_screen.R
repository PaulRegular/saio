source("scripts/discovery/candidate_reports.R", local = TRUE)

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
kah <- candidate[candidate$candidate_id == "MPI:KAH1", , drop = FALSE]
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
units <- candidate_units()
unit <- units[units$unit_key == "stock:mpi_kahawai_kah1", , drop = FALSE]
manifest <- read.csv("provenance/mpi_kahawai_kah1_2021_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("source_reviews/mpi_kahawai_kah1.md"),
  collapse = "\n")
progress <- candidate_progress()
nz <- progress[progress$organization == "Fisheries New Zealand", , drop = FALSE]

stopifnot(
  nrow(kah) == 1L,
  kah$candidate_unit_id == "nz_kahawai_kah1",
  kah$official_stock_id == "KAH 1",
  kah$scientific_name == "Arripis trutta",
  kah$match_status == "matched",
  kah$eligibility == "eligible",
  kah$import_status == "partial",
  grepl("not catch numbers-at-age", kah$catch_age_evidence, fixed = TRUE),
  grepl("aggregate rather than age-specific", kah$survey_age_evidence, fixed = TRUE),
  "mpi_kahawai_kah1" %in% stocks$stock_id,
  nrow(unit) == 1L,
  unit$match_status == "matched",
  unit$eligibility == "eligible",
  unit$inventory_entries == 1L,
  nrow(manifest) == 2L,
  manifest$sha256[match("source_cache/mpi_kahawai_kah1_2021/FAR2022-54.pdf", manifest$local_file)] == "D3A6DC8BB710AC13CD520BB7D188A15850302C9EB334DA3AC59C0F575EE02DEA",
  nrow(nz) == 1L,
  nz$inventory_rows == sum(candidate$organization == "Fisheries New Zealand"),
  nz$eligible_new_units == 0L,
  grepl("CASAL assessment using data through", review, fixed = TRUE),
  grepl("not catch numbers-at-age", review, fixed = TRUE)
)
cat("KAH 1 source screening checks passed.\n")
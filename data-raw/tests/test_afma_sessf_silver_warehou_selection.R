source("data-raw/scripts/shared/candidate_reports.R", local = TRUE)

source("data-raw/tests/helper_inventory.R")

candidates <- read.csv("database/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
progress <- candidate_progress()
units <- candidate_units()
manifest <- read.csv("data-raw/provenance/afma_sessf_silver_warehou_2021/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)

candidate <- candidates[candidates$candidate_id == "AFMA:SESSF_SILVER_WAREHOU", , drop = FALSE]

check_inventory_accounting(candidates, progress, units)

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "afma_sessf_silver_warehou",
  candidate$organization == "AFMA",
  candidate$official_stock_id == "Silver warehou (SESSF)",
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  candidate$inventory_assessment_year == 2021L,
  nrow(manifest) == 2L,
  all(manifest$retrieved_on == "2026-11-06"),
  all(vapply(seq_len(nrow(manifest)), function(i) {
    path <- file.path("source_cache", manifest$local_file[i])
    file.exists(path) && identical(
      toupper(unname(tools::sha256sum(path))),
      toupper(manifest$sha256[i])
    )
  }, logical(1))),
  file.exists("data-raw/source_reviews/afma_sessf_silver_warehou.md")
)

cat("AFMA SESSF silver warehou candidate-selection checks passed.\n")

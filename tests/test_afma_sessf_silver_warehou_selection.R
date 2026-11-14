source("tests/helper_inventory.R")

candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
selected <- read.csv("discovery/selected_batch_08_2026.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
progress <- read.csv("discovery/inventory_progress.csv", stringsAsFactors = FALSE)
units <- read.csv("discovery/inventory_units.csv", stringsAsFactors = FALSE)
manifest <- read.csv("provenance/afma_sessf_silver_warehou_2021_sources.csv",
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
  nrow(selected) == 1L,
  selected$candidate_id == candidate$candidate_id,
  selected$curation_status == "source_curated_partial",
  nrow(manifest) == 2L,
  all(manifest$retrieved_on == "2026-11-06"),
  all(vapply(seq_len(nrow(manifest)), function(i) {
    path <- file.path("source_cache", manifest$local_file[i])
    file.exists(path) && identical(
      toupper(unname(tools::sha256sum(path))),
      toupper(manifest$sha256[i])
    )
  }, logical(1))),
  file.exists("discovery/source_reviews/afma_sessf_silver_warehou_2021.md")
)

cat("AFMA SESSF silver warehou candidate-selection checks passed.\n")

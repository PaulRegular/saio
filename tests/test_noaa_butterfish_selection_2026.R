candidate_id <- "NOAA:10187"
stock_id <- "noaa_butterfish_gom_cape_hatteras"

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- candidate[candidate$candidate_id == candidate_id, , drop = FALSE]
selected <- read.csv("discovery/selected_batch_22_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
manifest <- read.csv("provenance/discovery_noaa_butterfish_2024/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- paste(readLines("discovery/source_reviews/noaa_butterfish_2024.md", warn = FALSE),
  collapse = " ")

cache_options <- c("source_cache/discovery_noaa_butterfish_2024",
  file.path("..", "..", "discovery_noaa_butterfish_2024"))
cache_root <- cache_options[dir.exists(cache_options)][1L]
source_paths <- file.path(cache_root, manifest$file)
cache_available <- all(file.exists(source_paths))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == stock_id,
  candidate$matched_stock_id == stock_id,
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  candidate$review_date == "2026-11-09",
  nrow(selected) == 1L,
  selected$candidate_id == candidate_id,
  selected$curation_status == "source_curated_partial",
  grepl("1,198 source input rows, 21 assumptions and 105 output rows", selected$selection_basis, fixed = TRUE),
  sum(stocks$stock_id == stock_id) == 1L,
  sum(assessments$assessment_id == paste0(stock_id, "_2024")) == 1L,
  assessments$inputs_status[assessments$assessment_id == paste0(stock_id, "_2024")] == "partial",
  grepl("still identifies the 2024 assessment", review, fixed = TRUE),
  grepl("Remaining source gaps", review, fixed = TRUE),
  grepl("partially imported from the official support tables", candidate$notes, fixed = TRUE),
  !grepl("tinyAM", review, ignore.case = TRUE)
)
if (cache_available) {
  stopifnot(identical(toupper(unname(tools::sha256sum(source_paths))), manifest$sha256))
}

cat("NOAA butterfish selection, import, and cache checks passed.\n")

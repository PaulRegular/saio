candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:BCO5")
selection <- read.csv("discovery/selected_batch_21_2026.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
manifest <- read.csv("provenance/mpi_blue_cod_bco5_sources.csv", stringsAsFactors = FALSE,
  check.names = FALSE)
review <- readLines("source_reviews/mpi_blue_cod_bco5.md", warn = FALSE)
review_text <- paste(review, collapse = " ")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "mpi_blue_cod_bco5",
  candidate$organization == "Fisheries New Zealand",
  candidate$official_stock_id == "BCO 5",
  candidate$scientific_name == "Parapercis colias",
  candidate$inventory_assessment_year == 2019L,
  candidate$match_status == "matched",
  candidate$matched_stock_id == "mpi_blue_cod_bco5",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$import_status == "partial",
  grepl("did not publish direct catch numbers-at-age", candidate$catch_age_evidence, fixed = TRUE),
  grepl("2010, 2014, and 2018", candidate$survey_age_evidence, fixed = TRUE),
  grepl("0.17", candidate$mortality_evidence, fixed = TRUE),
  grepl("derived approximate 2019 SSB", candidate$output_evidence, fixed = TRUE),
  nrow(selection) == 1L,
  selection$candidate_id == "MPI:BCO5",
  selection$curation_status == "source_curated_partial",
  nrow(manifest) == 5L,
  !anyDuplicated(manifest$local_file),
  all(manifest$status == "cached"),
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  grepl("2024 assessment attempt", review_text, fixed = TRUE),
  grepl("2019 age-based assessment", review_text, fixed = TRUE),
  grepl("not a direct catch-numbers-at-age series", review_text, fixed = TRUE),
  grepl("35.7%", review_text, fixed = TRUE),
  !grepl("tinyAM", review_text, ignore.case = TRUE)
)

cache_files <- manifest$local_file
if (all(file.exists(cache_files))) {
  stopifnot(identical(toupper(unname(tools::sha256sum(cache_files))), manifest$sha256))
}

cat("BCO 5 candidate screening and source provenance checks passed.\n")

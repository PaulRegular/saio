candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:SBW6I")
manifest <- read.csv("provenance/mpi_sbw_sbw6i_2024_sources.csv",
  stringsAsFactors = FALSE)
review <- readLines("source_reviews/mpi_sbw_sbw6i_2024.md", warn = FALSE)
review_text <- paste(review, collapse = " ")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "nz_southern_blue_whiting_sbw6i",
  candidate$organization == "Fisheries New Zealand",
  candidate$official_stock_id == "SBW 6I",
  candidate$scientific_name == "Micromesistius australis",
  candidate$inventory_assessment_year == 2024L,
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status %in% c("not_started", "partial"),
  is.na(candidate$matched_stock_id) || candidate$matched_stock_id == "mpi_sbw_sbw6i",
  grepl("1979-2022", candidate$catch_age_evidence, fixed = TRUE),
  grepl("not age-specific abundance indices", candidate$survey_age_evidence, fixed = TRUE),
  grepl("Tables 8-10", candidate$output_evidence, fixed = TRUE),
  nrow(manifest) == 6L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  grepl("model year 2022", review_text, fixed = TRUE),
  grepl("FAR 2026/38", review_text, fixed = TRUE),
  grepl("not imported as approximate readings from plots", review_text, fixed = TRUE),
  !grepl("tinyAM", review_text, ignore.case = TRUE)
)

cache_files <- file.path("source_cache", manifest$local_file)
if (all(file.exists(cache_files))) {
  stopifnot(identical(toupper(unname(tools::sha256sum(cache_files))), manifest$sha256))
}

cat("SBW 6I screening and source provenance checks passed.\n")

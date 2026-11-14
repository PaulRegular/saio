candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "MPI:LIN56+LIN6B")
selection <- read.csv("discovery/selected_batch_06_2026.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
selection <- subset(selection, candidate_id == "MPI:LIN56+LIN6B")
manifest <- read.csv("provenance/mpi_ling_lin56_2024_sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
review <- readLines("discovery/source_reviews/mpi_ling_lin56_lin6b_2024.md",
  warn = FALSE)
review_text <- paste(review, collapse = " ")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "mpi_ling_lin56_lin6b",
  candidate$organization == "Fisheries New Zealand",
  candidate$official_stock_id == "LIN 5&6 and LIN 6B",
  candidate$scientific_name == "Genypterus blacodes",
  candidate$inventory_assessment_year == 2024L,
  candidate$match_status == "matched",
  candidate$screening_status == "screened",
  candidate$eligibility == "unresolved",
  candidate$import_status == "partial",
  nrow(selection) == 1L,
  selection$curation_status == "source_curated_partial",
  nrow(manifest) == 6L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  grepl("1972-2023", review_text, fixed = TRUE),
  grepl("does not tabulate", review_text, ignore.case = TRUE),
  grepl("2024/84 Tables 8-11", review_text, fixed = TRUE),
  grepl("FAR 2024/74 Tables 11 and 17", review_text, fixed = TRUE),
  grepl("not imported as inputs to the selected 2024 run", review_text, fixed = TRUE),
  !grepl("tinyAM", review_text, ignore.case = TRUE)
)

cache_files <- file.path("source_cache", manifest$local_file)
if (all(file.exists(cache_files))) {
  stopifnot(identical(toupper(unname(tools::sha256sum(cache_files))),
    toupper(manifest$sha256)))
}

cat("Sub-Antarctic ling candidate and provenance checks passed.\n")

read_matching_rows <- function(path, id) {
  connection <- file(path, open = "r")
  on.exit(close(connection))
  header <- readLines(connection, n = 1L, warn = FALSE)
  prefix <- paste0('"', id, '",')
  rows <- character()
  repeat {
    chunk <- readLines(connection, n = 100000L, warn = FALSE)
    if (!length(chunk)) break
    rows <- c(rows, chunk[startsWith(chunk, prefix)])
  }
  if (!length(rows)) return(read.csv(text = header, check.names = FALSE))
  read.csv(text = paste(c(header, rows), collapse = "\n"),
    stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
}

candidate <- read_matching_rows("discovery/candidates.csv", "MPI:SNA8")
manifest <- read.csv("provenance/mpi_snapper_sna8_2024_sources.csv",
  stringsAsFactors = FALSE)
review <- readLines("discovery/source_reviews/mpi_snapper_sna8_2024.md",
  warn = FALSE)

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == "nz_snapper_sna8",
  candidate$organization == "Fisheries New Zealand",
  candidate$official_stock_id == "SNA 8",
  candidate$scientific_name == "Chrysophrys auratus",
  candidate$inventory_assessment_year == 2024L,
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$matched_stock_id == "mpi_snapper_sna8",
  candidate$import_status == "partial",
  grepl("model catch histories are imported", candidate$catch_age_evidence, fixed = TRUE),
  grepl("model ages 2-5 across nine survey years", candidate$survey_age_evidence, fixed = TRUE),
  grepl("Table 10 Base_Frec outputs are imported", candidate$output_evidence, fixed = TRUE),
  nrow(manifest) == 3L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  grepl("2025 Fisheries Assessment Plenary", paste(review, collapse = " "), fixed = TRUE),
  grepl("Composition proportions are distinct from catch numbers-at-age",
    paste(review, collapse = " "), fixed = TRUE),
  !grepl("tinyAM", paste(review, collapse = " "), ignore.case = TRUE)
)

cache_files <- file.path("source_cache", manifest$local_file)
if (all(file.exists(cache_files))) {
  stopifnot(identical(toupper(unname(tools::sha256sum(cache_files))), manifest$sha256))
}

cat("SNA 8 candidate screening and source provenance checks passed.\n")

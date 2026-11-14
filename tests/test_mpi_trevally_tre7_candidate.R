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
           stringsAsFactors = FALSE, na.strings = c("", "NA"),
           check.names = FALSE)
}

candidate <- read_matching_rows("discovery/candidates.csv", "MPI:TRE7")
stock <- read_matching_rows("database/stocks.csv", "mpi_trevally_tre7")
assessment <- read_matching_rows("database/assessments.csv", "mpi_trevally_tre7_2026")
manifest <- read.csv("provenance/mpi_trevally_tre7_2026_sources.csv",
                     stringsAsFactors = FALSE)
review <- readLines("discovery/source_reviews/mpi_trevally_tre7_2026.md")

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_id == "MPI:TRE7",
  candidate$organization == "Fisheries New Zealand",
  candidate$official_stock_id == "TRE 7",
  candidate$inventory_assessment_year == 2026L,
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$matched_stock_id == "mpi_trevally_tre7",
  candidate$match_status == "matched",
  candidate$import_status == "partial",
  nrow(stock) == 1L,
  nrow(assessment) == 1L,
  nrow(manifest) == 2L,
  all(grepl("^[A-F0-9]{64}$", manifest$sha256)),
  all(file.exists(manifest$local_file)),
  grepl("northern NMB and KMNTB", paste(review, collapse = " "), fixed = TRUE),
  grepl("TwoRegion", paste(review, collapse = " "), fixed = TRUE),
  !grepl("tinyAM", paste(review, collapse = " "), ignore.case = TRUE)
)

cat("TRE 7 candidate source checks passed.\n")

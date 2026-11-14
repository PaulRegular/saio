candidates <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
ids <- c("MPI:TAR:EASTERN", "MPI:TAR:WESTERN", "MPI:SKI3+SKI7")
screened <- candidates[match(ids, candidates$candidate_id), , drop = FALSE]

manifest <- read.csv("provenance/mpi_tarakihi_gemfish_2026_sources.csv",
  stringsAsFactors = FALSE)

stopifnot(
  nrow(screened) == 3L,
  !anyNA(screened$candidate_id),
  !anyDuplicated(screened$candidate_id),
  identical(screened$candidate_unit_id,
    c("nz_tarakihi_eastern", "nz_tarakihi_western", "nz_gemfish_ski3_ski7")),
  all(screened$organization == "Fisheries New Zealand"),
  identical(screened$inventory_assessment_year, c(2026L, 2026L, 2025L)),
  all(screened$match_status == "matched"),
  all(screened$screening_status == "screened"),
  identical(screened$eligibility, c("eligible", "eligible", "unresolved")),
  identical(screened$import_status, c("partial", "partial", "partial")),
  screened$matched_stock_id[1L] == "mpi_tarakihi_eastern",
  screened$matched_stock_id[2L] == "mpi_tarakihi_western",
  screened$scientific_name[1L] == screened$scientific_name[2L],
  screened$assessment_area[1L] != screened$assessment_area[2L],
  grepl("MCMC", screened$output_evidence[3L], fixed = TRUE),
  grepl("2020-21", screened$catch_age_evidence[3L], fixed = TRUE),
  grepl("2023-24", screened$catch_age_evidence[3L], fixed = TRUE),
  nrow(manifest) == 3L,
  all(grepl("^[[:xdigit:]]{64}$", manifest$sha256)),
  all(grepl("^https://fs\\.fish\\.govt\\.nz/", manifest$source_url)),
  setequal(basename(manifest$local_file), c(
    "FAR-2026-44-eastern-tarakihi-2026.pdf",
    "FAR-2026-23-western-tarakihi-2026.pdf",
    "FAR-2026-39-southern-gemfish-SKI3-SKI7.pdf"
  ))
)

cat("Tarakihi and southern gemfish candidate screening and source provenance passed.\n")

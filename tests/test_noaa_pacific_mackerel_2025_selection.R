candidate_id <- "NOAA:10163"
stock_id <- "noaa_pacific_mackerel_pacific_coast"
cache <- "source_cache/discovery_noaa_pacific_mackerel_2025"

candidate <- read.csv("discovery/candidates.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
candidate <- subset(candidate, candidate_id == "NOAA:10163")
selected <- read.csv("discovery/selected_batch_23_2026.csv",
  stringsAsFactors = FALSE, na.strings = c("", "NA"), check.names = FALSE)
stocks <- read.csv("database/stocks.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
assessments <- read.csv("database/assessments.csv", stringsAsFactors = FALSE,
  na.strings = c("", "NA"), check.names = FALSE)
manifest <- read.csv("provenance/discovery_noaa_pacific_mackerel_2025/sources.csv",
  stringsAsFactors = FALSE, check.names = FALSE)
source_paths <- file.path(cache, manifest$file)
archive_files <- utils::unzip(file.path(cache, "pacific_mackerel_2023_model_files.zip"),
  list = TRUE)$Name

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == stock_id,
  candidate$scientific_name == "Scomber japonicus",
  candidate$screening_status == "screened",
  candidate$eligibility == "eligible",
  candidate$matched_stock_id == stock_id,
  candidate$import_status == "partial",
  candidate$review_date == "2026-11-09",
  nrow(selected) == 1L,
  selected$candidate_id == candidate_id,
  selected$inventory_assessment_year == 2025L,
  selected$curation_status == "imported",
  grepl("2025 catch-only update", selected$selection_basis, fixed = TRUE),
  grepl("2023 benchmark archive", selected$selection_basis, fixed = TRUE),
  grepl("catch time series only", selected$selection_basis, fixed = TRUE),
  sum(stocks$stock_id == stock_id) == 1L,
  all(c("noaa_pacific_mackerel_2023", "noaa_pacific_mackerel_2025") %in%
    assessments$assessment_id),
  nrow(manifest) == 3L,
  all(c("pfmc_2025_catch_only_assessment", "pfmc_2023_benchmark_assessment",
    "pfmc_2023_model_files") %in% manifest$source_id),
  all(!is.na(manifest$pinned_revision) & nzchar(manifest$pinned_revision)),
  all(file.exists(source_paths)),
  identical(toupper(unname(tools::sha256sum(source_paths))),
    toupper(manifest$sha256)),
  all(c("pmack2023.dat", "pmack2023.ctl", "wtatage.ss", "Report.sso") %in%
    archive_files)
)

cat("NOAA Pacific mackerel selection and source cache passed.\n")

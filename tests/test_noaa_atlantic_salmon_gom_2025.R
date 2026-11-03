root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:10498', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review_path <- file.path(root, 'discovery', 'source_reviews',
  'noaa_atlantic_salmon_gom_2025.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = '\n')
cache <- file.path(root, 'source_cache', 'discovery_noaa_atlantic_salmon_2025')
database <- file.path(cache, 'USASAC_database_2026-05.zip')
database_hash <- if (.Platform$OS.type == 'windows') {
  result <- system2('certutil.exe', c('-hashfile', normalizePath(database), 'SHA256'), stdout = TRUE)
  tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', result, value = TRUE)))
} else {
  result <- system2('sha256sum', shQuote(database), stdout = TRUE)
  sub('[[:space:]].*$', '', result[1L])
}

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary
latest <- metadata[metadata$stock_id == 10498, , drop = FALSE]
latest <- latest[order(-as.numeric(latest$assessment_year),
  -as.numeric(latest$assessment_id), na.last = TRUE), , drop = FALSE][1L, , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_atlantic_salmon_gom',
  candidate$scientific_name == 'Salmo salar',
  candidate$assessment_area == 'Gulf of Maine',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  latest$assessment_year == 2024L,
  latest$last_data_year == 2023L,
  latest$assessment_model == 'Index Method',
  latest$review_result == 'Full acceptance',
  file.exists(database),
  identical(database_hash, 'a372d61fde09ec43c428d31ffcd2fdaca614b66609e4242a9f81dd29b68552be'),
  !any(stocks$scientific_name == 'Salmo salar', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_atlantic_salmon_gom', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_atlantic_salmon_gom', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_atlantic_salmon_gom', na.rm = TRUE),
  grepl('Report 37', review, fixed = TRUE),
  grepl('sea age', review, fixed = TRUE),
  grepl('catch-at-age', review, fixed = TRUE),
  grepl('SHA-256', review, fixed = TRUE),
  grepl('HTTP 403', review, fixed = TRUE)
)
cat('NOAA Gulf of Maine Atlantic salmon source-screening checks passed.\n')

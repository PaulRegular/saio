root <- "."
read_table <- function(name) read.csv(file.path(root, name), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
canonical_paths <- c(stocks = 'database/stocks.csv',
  assessments = 'database/assessments.csv', inputs = 'database/inputs.csv',
  outputs = 'database/outputs.csv')
canonical_before <- lapply(canonical_paths, read_table)

source(file.path(root, 'scripts', 'database',
  '531_screen_noaa_seak_coho_indicators_2024.R'))

register <- read_table('discovery/candidates.csv')
ids <- c('NOAA:10959', 'NOAA:10960', 'NOAA:10961')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
expected_units <- c('noaa_coho_berners_river',
  'noaa_coho_ford_arm_lake_discontinued', 'noaa_coho_hugh_smith_lake')
cache <- file.path(root, 'source_cache', 'discovery_noaa_seak_coho_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
expected_files <- c('southeast_alaska_coho_status_2024.pdf',
  'seak_coho_operational_plan_2022-2024.pdf')
expected_sizes <- c(718214L, 1428928L)
expected_hashes <- c(
  '8AC2384CCF2FE5AB5A7D12075FA84E574D6E26289036D1E226CDEE0F1A28C376',
  '38B1ED0379600E0E5DC7DD23E56C2059952BD917510B5B645FC9675D22CA7F51')

stopifnot(nrow(rows) == 3L, !anyNA(rows$candidate_id),
  identical(rows$candidate_unit_id, expected_units),
  all(rows$match_status == 'new'), all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'), all(rows$import_status == 'not_started'),
  rows$review_date[1] == '2026-11-02',
  grepl('through 2024', rows$catch_age_evidence[1], fixed = TRUE),
  grepl('eliminated in 2016', rows$notes[2], fixed = TRUE),
  grepl('through 2024', rows$output_evidence[3], fixed = TRUE),
  identical(canonical_before, lapply(canonical_paths, read_table)),
  nrow(manifest) == 2L, identical(manifest$file, expected_files),
  identical(as.numeric(manifest$bytes), as.numeric(expected_sizes)),
  identical(manifest$sha256, expected_hashes),
  all(manifest$retrieved_on == '2026-11-02'),
  all(nzchar(manifest$source_url)), all(nzchar(manifest$pinned_revision)),
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == expected_sizes),
  identical(rawToChar(readBin(file.path(cache, expected_files[1]), 'raw', n = 5L)), '%PDF-'),
  identical(rawToChar(readBin(file.path(cache, expected_files[2]), 'raw', n = 5L)), '%PDF-'),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'noaa_southeast_alaska_coho_2024.md')),
  !anyDuplicated(rows$candidate_unit_id))

progress <- read_table('discovery/inventory_progress.csv')
units <- read_table('discovery/inventory_units.csv')
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
afsc <- noaa[noaa$source_region == 'AFSC', , drop = FALSE]
stopifnot(sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L, sum(noaa$screening_not_started) == 0L,
  nrow(afsc) == 1L, afsc$inventory_rows == 89L, afsc$new == 73L,
  afsc$identity_unreviewed == 2L, afsc$excluded == 67L,
  afsc$eligibility_unresolved == 4L, afsc$screening_complete == 89L,
  afsc$screening_not_started == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

cat('NOAA Southeast Alaska coho indicator source-screening checks passed.\n')

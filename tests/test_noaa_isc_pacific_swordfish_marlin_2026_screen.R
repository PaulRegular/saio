root <- "."
read_table <- function(name) read.csv(file.path(root, name), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
canonical_paths <- c(stocks = 'database/stocks.csv',
  assessments = 'database/assessments.csv', inputs = 'database/inputs.csv',
  outputs = 'database/outputs.csv')
canonical_before <- lapply(canonical_paths, read_table)

source(file.path(root, 'scripts', 'database',
  '530_screen_noaa_isc_pacific_swordfish_marlin_2026.R'))

register <- read_table('discovery/candidates.csv')
ids <- c('NOAA:11642', 'NOAA:11643', 'NOAA:11692', 'NOAA:11706')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
expected_units <- c('noaa_wcnpo_swordfish', 'noaa_eastern_pacific_swordfish',
  'isc_wcnpo_striped_marlin', 'isc_pacific_blue_marlin')
cache <- file.path(root, 'source_cache', 'discovery_noaa_pacific_billfish_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
expected_files <- c('isc14_np_swordfish_2014.pdf',
  'isc23_north_pacific_swordfish_2023.pdf',
  'isc23_wcnpo_striped_marlin_2023.pdf',
  'isc26_pacific_blue_marlin_2026.pdf')
expected_sizes <- c(2530574L, 3578167L, 5299577L, 7769730L)
expected_hashes <- c(
  '67692B148D49AAAD827CE768AED2CB5CBDB205D7A1DE0DF520FC8CF4A81CD803',
  '83B051E6AF8640BE86F8086EC4E1A7C708DBB0815B7E225B2C10D8CA11156696',
  '1425EBB5C8D3651740F1A3F4C70E9FA6B8A2DCCCF147D8F15E18A694492211DA',
  '79BC5CA1466206D91861BDAAC384B2F9806FEF544B10231A89F46C83B3606158')

stopifnot(nrow(rows) == 4L, !anyNA(rows$candidate_id),
  identical(rows$candidate_unit_id, expected_units),
  all(rows$match_status == 'new'), all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'), all(rows$import_status == 'not_started'),
  all(rows$review_date == '2026-11-02'),
  grepl('Stock Synthesis', rows$catch_age_evidence[1], fixed = TRUE),
  grepl('surplus-production', rows$catch_age_evidence[2], fixed = TRUE),
  grepl('2026 through 2024', rows$notes[4], fixed = TRUE),
  grepl('annual N-at-age', rows$output_evidence[1], fixed = TRUE),
  identical(canonical_before, lapply(canonical_paths, read_table)),
  nrow(manifest) == 4L, identical(manifest$file, expected_files),
  identical(as.numeric(manifest$bytes), as.numeric(expected_sizes)),
  identical(manifest$sha256, expected_hashes),
  all(manifest$retrieved_on == '2026-11-02'),
  all(nzchar(manifest$source_url)), all(nzchar(manifest$pinned_revision)),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == expected_sizes),
  all(vapply(file.path(cache, manifest$file), function(path) {
    identical(rawToChar(readBin(path, 'raw', n = 5L)), '%PDF-')
  }, logical(1L))),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'noaa_isc_pacific_billfish_swordfish_2026.md')),
  !anyDuplicated(rows$candidate_unit_id))

progress <- read_table('discovery/inventory_progress.csv')
units <- read_table('discovery/inventory_units.csv')
stopifnot(sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

cat('NOAA Pacific swordfish and marlin source-screening checks passed.\n')

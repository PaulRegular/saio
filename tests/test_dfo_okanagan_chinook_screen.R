register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE)
id <- 'DFO:Pacific:Chinook salmon - Okanagan'
row <- register[register$candidate_id == id, , drop = FALSE]
review_path <- 'discovery/source_reviews/dfo_okanagan_chinook_2023.md'

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'dfo_okanagan_chinook',
  row$scientific_name == 'Oncorhynchus tshawytscha',
  row$inventory_assessment_year == 2023,
  row$match_status == 'new', is.na(row$matched_stock_id),
  row$screening_status == 'screened', row$eligibility == 'ineligible',
  row$import_status == 'not_started', row$review_date == '2026-10-30',
  !row$candidate_unit_id %in% register$candidate_unit_id[
    register$candidate_id != id & !is.na(register$candidate_unit_id)],
  !any(stocks$stock_id == row$candidate_unit_id),
  all(vapply(row[c('catch_age_evidence', 'survey_age_evidence', 'weights_evidence',
    'maturity_evidence', 'mortality_evidence', 'timing_evidence',
    'output_evidence', 'detailed_source_url', 'decision_reason')],
    function(x) !is.na(x) && nzchar(x), logical(1L))),
  grepl('age estimates have not been collected sufficiently', row$survey_age_evidence, fixed = TRUE),
  grepl('recruitment is unavailable', row$decision_reason, fixed = TRUE),
  file.exists(review_path)
)

review <- paste(readLines(review_path, warn = FALSE), collapse = '\n')
stopifnot(
  grepl('assessment year 2023', review, fixed = TRUE),
  grepl('does not report a fishery catch-at-age input', review, fixed = TRUE),
  grepl('does not report N-at-age or F-at-age', review, fixed = TRUE),
  grepl('NOAA Stock SMART', review, fixed = TRUE)
)

cache <- 'source_cache/discovery_dfo_okanagan_chinook_2023'
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- file.path(cache, manifest$file)
  stopifnot(nrow(manifest) == 2L, all(file.exists(files)),
    all(file.info(files)$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
    any(grepl('41276371.pdf', manifest$source_url, fixed = TRUE)),
    any(grepl('40959429.pdf', manifest$source_url, fixed = TRUE)))
}

noaa_aggregate <- register[register$candidate_id == 'NOAA:17337', , drop = FALSE]
stopifnot(nrow(noaa_aggregate) == 1L,
  noaa_aggregate$screening_status == 'not_started',
  is.na(noaa_aggregate$candidate_unit_id) || !nzchar(noaa_aggregate$candidate_unit_id))

cat('DFO Okanagan Chinook unit and source-screening checks passed.\n')

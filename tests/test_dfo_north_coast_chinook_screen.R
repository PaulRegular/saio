register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE)
id <- 'DFO:Pacific:Chinook Salmon - North Coast'
row <- register[register$candidate_id == id, , drop = FALSE]
review_path <- 'discovery/source_reviews/dfo_north_coast_chinook_inventory.md'

stopifnot(
  nrow(row) == 1L,
  is.na(row$candidate_unit_id),
  row$scientific_name == 'Oncorhynchus tshawytscha',
  is.na(row$inventory_assessment_year),
  row$match_status == 'ambiguous', is.na(row$matched_stock_id),
  row$screening_status == 'screened', row$eligibility == 'unresolved',
  row$import_status == 'not_started', row$review_date == '2026-10-30',
  !any(stocks$stock_id == 'dfo_north_coast_chinook'),
  all(vapply(row[c('catch_age_evidence', 'survey_age_evidence', 'weights_evidence',
    'maturity_evidence', 'mortality_evidence', 'timing_evidence',
    'output_evidence', 'detailed_source_url', 'decision_reason')],
    function(x) !is.na(x) && nzchar(x), logical(1L))),
  grepl('Skeena-Nass', row$decision_reason, fixed = TRUE),
  grepl('Central Coast ISBM', row$decision_reason, fixed = TRUE),
  grepl('age-structured eligibility unresolved', row$decision_reason, fixed = TRUE),
  file.exists(review_path)
)

review <- paste(readLines(review_path, warn = FALSE), collapse = '\n')
stopifnot(
  grepl('early scan', review, fixed = TRUE),
  grepl('not calibrated for Chinook', review, fixed = TRUE),
  grepl('Eligibility therefore remains unresolved', review, fixed = TRUE)
)

cache <- 'source_cache/discovery_dfo_north_coast_chinook_2026'
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- file.path(cache, manifest$file)
  stopifnot(nrow(manifest) == 2L, all(file.exists(files)),
    all(file.info(files)$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
    any(grepl('41248077.pdf', manifest$source_url, fixed = TRUE)),
    any(grepl('smon-summ-somm-eng.html', manifest$source_url, fixed = TRUE)))
}

cat('DFO North Coast Chinook identity and source-screening checks passed.\n')

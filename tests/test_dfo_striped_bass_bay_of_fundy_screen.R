register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE)
id <- 'DFO:Maritimes:Striped Bass - Bay of Fundy'
row <- register[register$candidate_id == id, , drop = FALSE]
review_path <- 'discovery/source_reviews/dfo_striped_bass_bay_of_fundy.md'

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'dfo_striped_bass_bay_of_fundy_du',
  row$scientific_name == 'Morone saxatilis',
  grepl('Designatable Unit', row$assessment_area, fixed = TRUE),
  is.na(row$inventory_assessment_year),
  row$match_status == 'new', is.na(row$matched_stock_id),
  row$screening_status == 'screened', row$eligibility == 'ineligible',
  row$import_status == 'not_started', row$review_date == '2026-10-30',
  !any(stocks$stock_id == row$candidate_unit_id),
  all(vapply(row[c('catch_age_evidence', 'survey_age_evidence', 'weights_evidence',
    'maturity_evidence', 'mortality_evidence', 'timing_evidence',
    'output_evidence', 'detailed_source_url', 'decision_reason')],
    function(x) !is.na(x) && nzchar(x), logical(1L))),
  grepl('Uncertain', row$decision_reason, fixed = TRUE),
  grepl('not a current production', row$decision_reason, fixed = TRUE),
  file.exists(review_path)
)

review <- paste(readLines(review_path, warn = FALSE), collapse = '\n')
stopifnot(
  grepl('Shubenacadie, Annapolis, and Saint John rivers', review, fixed = TRUE),
  grepl('distinct from the', review, fixed = TRUE),
  grepl('not a current production stock assessment', review, fixed = TRUE),
  grepl('Screen this distinct DU', review, fixed = TRUE)
)

survey <- paste(readLines(
  'source_cache/discovery_dfo_sustainability/survey_2024.html',
  warn = FALSE), collapse = '\n')
stopifnot(grepl('<td>Striped Bass - Bay of Fundy</td>', survey, fixed = TRUE),
  grepl('<td>Uncertain</td>', survey, fixed = TRUE))

cache <- 'source_cache/discovery_dfo_striped_bass_bay_of_fundy'
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- file.path(cache, manifest$file)
  signatures <- lapply(files, function(path) readBin(path, 'raw', n = 5L))
  stopifnot(nrow(manifest) == 2L, all(file.exists(files)),
    all(file.info(files)$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
    all(vapply(signatures, function(x) substr(rawToChar(x), 1L, 5L) == '%PDF-', logical(1L))),
    any(grepl('364418.pdf', manifest$source_url, fixed = TRUE)),
    any(grepl('359709.pdf', manifest$source_url, fixed = TRUE)))
}

cat('DFO Bay of Fundy Striped Bass identity and source-screening checks passed.\n')

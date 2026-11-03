register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE)
row <- register[register$candidate_id == 'DFO:Pacific:Chinook Salmon - Yukon', , drop = FALSE]
review_path <- 'discovery/source_reviews/dfo_yukon_chinook_2024.md'

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'dfo_yukon_chinook_smu',
  row$scientific_name == 'Oncorhynchus tshawytscha',
  row$assessment_area == 'Yukon Chinook SMU, Canadian Yukon River; nine Conservation Units; excludes the Porcupine Chinook SMU',
  row$inventory_assessment_year == 2024,
  row$match_status == 'new', is.na(row$matched_stock_id),
  row$screening_status == 'screened', row$eligibility == 'unresolved',
  row$import_status == 'not_started', row$review_date == '2026-10-30',
  !row$candidate_unit_id %in% register$candidate_unit_id[register$candidate_id != row$candidate_id & !is.na(register$candidate_unit_id)],
  !any(stocks$stock_id == row$candidate_unit_id),
  all(vapply(row[c('catch_age_evidence', 'survey_age_evidence', 'weights_evidence',
    'maturity_evidence', 'mortality_evidence', 'timing_evidence',
    'output_evidence', 'detailed_source_url', 'decision_reason')],
    function(x) !is.na(x) && nzchar(x), logical(1L))),
  grepl('Porcupine', row$decision_reason, fixed = TRUE),
  grepl('returns by age', row$output_evidence, ignore.case = TRUE),
  grepl('in press', row$decision_reason, fixed = TRUE),
  file.exists(review_path)
)

review <- paste(readLines(review_path, warn = FALSE), collapse = '\n')
stopifnot(
  grepl('frozen production-run release', review, fixed = TRUE),
  grepl('no en-route adult migration mortality', review, fixed = TRUE),
  grepl('complete, run-matched numeric N/F/M-at-age tables', review, fixed = TRUE)
)

cache <- 'source_cache/discovery_dfo_yukon_chinook_2024_2026'
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- file.path(cache, manifest$file)
  stopifnot(nrow(manifest) >= 20L, all(file.exists(files)),
    all(file.info(files)$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
    all(!is.na(manifest$source_url) & nzchar(manifest$source_url)),
    any(grepl('41320517.pdf', manifest$source_url, fixed = TRUE)),
    any(grepl('8bf845e838a3ea56ba071cb3286e5cf210c3b393', manifest$pinned_revision, fixed = TRUE)),
    any(grepl('dba18480b9a538ac8aec31df5903ccdb26448b88', manifest$pinned_revision, fixed = TRUE)))
}

cat('DFO Yukon Chinook unit and source-screening checks passed.\n')
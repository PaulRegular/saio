register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE)
id <- 'DFO:Pacific:Coho salmon - Interior Fraser'
row <- register[register$candidate_id == id, , drop = FALSE]
review_path <- 'discovery/source_reviews/dfo_interior_fraser_coho_2022.md'

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'dfo_coho_interior_fraser',
  row$scientific_name == 'Oncorhynchus kisutch',
  row$assessment_area == paste(
    'Fraser River watershed upstream of Hells Gate; one SMU, five Conservation',
    'Units, and eleven subpopulations'
  ),
  row$inventory_assessment_year == 2022,
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
  grepl('assessment is for return year 2022', row$decision_reason, fixed = TRUE),
  grepl('does not use age-specific catch/index likelihoods', row$decision_reason, fixed = TRUE),
  grepl('Ineligible for the age-disaggregated', row$decision_reason, fixed = TRUE),
  file.exists(review_path)
)

review <- paste(readLines(review_path, warn = FALSE), collapse = '\n')
stopifnot(
  grepl('five Conservation Units and eleven subpopulations', review, fixed = TRUE),
  grepl('not an age-structured', review, fixed = TRUE),
  grepl('Age proportions are used in the stock-recruit', review, fixed = TRUE)
)

cache <- 'source_cache/discovery_dfo_interior_fraser_coho_2022'
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  files <- file.path(cache, manifest$file)
  signature <- readBin(files, 'raw', n = 5L)
  stopifnot(nrow(manifest) == 1L, all(file.exists(files)),
    all(file.info(files)$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
    rawToChar(signature) == '%PDF-',
    grepl('4130276x.pdf', manifest$source_url, fixed = TRUE))
}

cat('DFO Interior Fraser Coho identity and source-screening checks passed.\n')

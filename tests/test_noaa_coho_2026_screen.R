register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stock_ids <- c(10581:10593, 10596:10600)
rows <- match(paste0('NOAA:', stock_ids), register$candidate_id)
coho <- register[rows, , drop = FALSE]

stopifnot(nrow(coho) == 18L, !anyNA(rows), !anyDuplicated(rows),
  identical(coho$candidate_unit_id, paste0('noaa_coho_', stock_ids)),
  all(coho$scientific_name == 'Oncorhynchus kisutch'),
  all(coho$match_status == 'new'), all(coho$screening_status == 'screened'),
  all(coho$eligibility == 'ineligible'), all(coho$import_status == 'not_started'),
  all(grepl('age-3', coho$survey_age_evidence, ignore.case = TRUE)),
  all(grepl('multi-age', coho$decision_reason, ignore.case = TRUE)),
  all(grepl('2026', coho$detailed_source_url, fixed = TRUE)),
  file.exists('discovery/source_reviews/noaa_coho_2026.md'))

review <- readLines('discovery/source_reviews/noaa_coho_2026.md',
  warn = FALSE)
stopifnot(any(grepl('only age-3 fish', review, fixed = TRUE)),
  any(grepl('password-protected NWIFC area', review, fixed = TRUE)),
  any(grepl('Composition Input Data level 3', review, fixed = TRUE)))

stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv('database/assessments.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv('database/inputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv('database/outputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(as.character(stock_ids) %in% stocks$authority_stock_id),
  !any(grepl('noaa_coho_', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_coho_', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_coho_', outputs$assessment_id, fixed = TRUE)))

units <- read.csv('discovery/inventory_units.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
coho_units <- units[units$candidate_unit_id %in% paste0('noaa_coho_', stock_ids), , drop = FALSE]
stopifnot(nrow(coho_units) == 18L, all(coho_units$eligibility == 'ineligible'),
  sum(register$organization == 'NOAA') == 432L,
  sum(register$organization == 'NOAA' & register$screening_status == 'screened') == 305L)

cat('NOAA coho candidate identity and multi-age eligibility screen passed.\n')

register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stock_ids <- c(10516L, 10517L)
rows <- match(paste0('NOAA:', stock_ids), register$candidate_id)
red_hake <- register[rows, , drop = FALSE]

stopifnot(nrow(red_hake) == 2L, !anyNA(rows), !anyDuplicated(rows),
  identical(red_hake$candidate_unit_id, paste0('noaa_red_hake_', stock_ids)),
  identical(red_hake$assessment_area, c('Gulf of Maine / Northern Georges Bank',
    'Southern Georges Bank / Mid-Atlantic')),
  all(red_hake$scientific_name == 'Urophycis chuss'),
  all(red_hake$match_status == 'new'),
  all(red_hake$screening_status == 'screened'),
  all(red_hake$eligibility == 'ineligible'),
  all(red_hake$import_status == 'not_started'),
  all(grepl('fileId=9037', red_hake$detailed_source_url, fixed = TRUE)),
  all(grepl('fileId=9038', red_hake$detailed_source_url, fixed = TRUE)),
  all(grepl('age', red_hake$catch_age_evidence, ignore.case = TRUE)),
  all(grepl('swept-area', red_hake$output_evidence, fixed = TRUE)),
  all(grepl('not estimate annual N-at-age', red_hake$decision_reason, fixed = TRUE)))

review <- readLines('discovery/source_reviews/noaa_red_hake_2023.md',
  warn = FALSE)
review <- paste(review, collapse = ' ')
stopifnot(grepl('N-at-age', review, fixed = TRUE),
  grepl('length frequencies', review, fixed = TRUE),
  grepl('Earlier AIM/index assessments', review, fixed = TRUE))

stocks <- read.csv('database/stocks.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv('database/assessments.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv('database/inputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv('database/outputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(as.character(stock_ids) %in% stocks$authority_stock_id),
  !any(grepl('noaa_red_hake_', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_red_hake_', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_red_hake_', outputs$assessment_id, fixed = TRUE)))

units <- read.csv('discovery/inventory_units.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
red_hake_units <- units[units$candidate_unit_id %in% paste0('noaa_red_hake_', stock_ids), , drop = FALSE]
stopifnot(nrow(red_hake_units) == 2L,
  all(red_hake_units$eligibility == 'ineligible'),
  sum(register$organization == 'NOAA') == 432L,
  sum(register$organization == 'NOAA' & register$screening_status == 'screened') == 305L)

cat('NOAA red hake candidate identity and multi-age eligibility screen passed.\n')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:11694', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'wcpfc_wcpo_yellowfin', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_wcpfc_yellowfin_2026.md'), warn = FALSE), collapse = ' ')

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'wcpfc_wcpo_yellowfin',
  candidate$match_status == 'matched',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'partial',
  candidate$review_date == '2026-11-13',
  grepl('1,873 age-at-length observations', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not catch-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('aggregate relative-abundance indices', candidate$survey_age_evidence, fixed = TRUE),
  grepl('SC22 deferred advice review to SC23', candidate$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$matched_stock_id == 'wcpfc_wcpo_yellowfin',
  unit$match_status == 'matched',
  unit$eligibility == 'eligible',
  unit$screening_status == 'screened',
  unit$import_status == 'partial',
  grepl('latest detailed run is diagnostic', review, fixed = TRUE),
  grepl('does not provide catch-at-age', review, fixed = TRUE),
  !grepl('This is a discovery screen only', review, fixed = TRUE),
  !grepl('no canonical database records were added', review, ignore.case = TRUE)
)

cat('NOAA 11694 WCPO yellowfin source-review checks passed.\n')

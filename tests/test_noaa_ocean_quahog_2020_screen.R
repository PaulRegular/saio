root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10788', , drop = FALSE]
unit <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- unit[!is.na(unit$candidate_unit_id) &
  unit$candidate_unit_id == 'noaa_ocean_quahog_atlantic', , drop = FALSE]
review <- readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_ocean_quahog_2020.md'), warn = FALSE)

stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_ocean_quahog_atlantic',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  grepl('catch numbers-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('No age-specific index', row$survey_age_evidence, fixed = TRUE),
  grepl('draft working paper', row$decision_reason, fixed = TRUE),
  nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$screening_status == 'screened', unit$eligibility == 'ineligible',
  any(grepl('age data were scarce', review, fixed = TRUE)),
  any(grepl('3,651 thousand tonnes in 2019', review, fixed = TRUE)),
  any(grepl('canonical numerical assessment data were added', review,
    fixed = TRUE)))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$authority_stock_id == '10788', na.rm = TRUE),
  !any(grepl('noaa_ocean_quahog_2020', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_ocean_quahog_2020', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_ocean_quahog_2020', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L)

cat('NOAA ocean quahog inventory screen passed.\n')

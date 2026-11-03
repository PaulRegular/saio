source('scripts/database/460_screen_noaa_iattc_bigeye_2026.R')
root <- "."
candidate <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- candidate[candidate$candidate_id == 'NOAA:11685', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'iattc_eastern_pacific_bigeye',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('catch-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('aggregate', row$survey_age_evidence, fixed = TRUE),
  grepl('SAC-17-03_BET-assessment-EN.pdf', row$detailed_source_url, fixed = TRUE),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'noaa_iattc_bigeye_eastern_pacific_2026.md')),
  !any(stocks$authority_stock_id == '11685', na.rm = TRUE),
  !any(assessments$assessment_id == 'iattc_eastern_pacific_bigeye', na.rm = TRUE),
  !any(inputs$assessment_id == 'iattc_eastern_pacific_bigeye', na.rm = TRUE),
  !any(outputs$assessment_id == 'iattc_eastern_pacific_bigeye', na.rm = TRUE))
cat('NOAA:11685 IATTC bigeye source-screening checks passed.\n')
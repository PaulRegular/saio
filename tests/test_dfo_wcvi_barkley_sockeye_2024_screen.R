source('scripts/database/465_screen_dfo_wcvi_barkley_sockeye_2024.R')
source('scripts/database/195_summarize_discovery.R')
source('scripts/database/196_summarize_inventory_units.R')
root <- "."
candidate <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- candidate[candidate$candidate_id == 'DFO:Pacific:WCVI Barkley Sockeye Salmon', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'), stringsAsFactors = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'), stringsAsFactors = FALSE)
stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'dfo_wcvi_barkley_sockeye_smu',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('age and stock composition', row$catch_age_evidence, fixed = TRUE),
  grepl('does not report an age-specific marine abundance', row$survey_age_evidence, fixed = TRUE),
  grepl('does not establish the complete', row$decision_reason, fixed = TRUE),
  grepl('archived-page interstitial', row$notes, fixed = TRUE),
  file.exists(file.path(root, 'discovery', 'source_reviews', 'dfo_wcvi_barkley_sockeye_2024.md')),
  !any(stocks$scientific_name == 'Oncorhynchus nerka', na.rm = TRUE),
  !any(assessments$assessment_id == 'dfo_wcvi_barkley_sockeye_smu', na.rm = TRUE),
  !any(inputs$assessment_id == 'dfo_wcvi_barkley_sockeye_smu', na.rm = TRUE),
  !any(outputs$assessment_id == 'dfo_wcvi_barkley_sockeye_smu', na.rm = TRUE),
  sum(progress$inventory_rows) == 905L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  sum(progress$screening_in_progress) == 0L,
  sum(progress$screening_in_progress[progress$organization == 'DFO']) == 0L,
  sum(progress$excluded[progress$organization == 'DFO']) == 147L,
  sum(progress$screening_complete[progress$organization == 'DFO']) == 199L,
  nrow(units) == 736L)
cat('DFO Barkley Sockeye source-screening checks passed.\n')

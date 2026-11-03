root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/369_screen_noaa_pacific_bluefin_2024.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:11687', , drop = FALSE]
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_isc_pacific_bluefin', , drop = FALSE]

stopifnot(
  nrow(row) == 1L,
  row$scientific_name == 'Thunnus orientalis',
  row$inventory_assessment_year == 2024,
  row$candidate_unit_id == 'noaa_isc_pacific_bluefin',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('does not fit observed catch-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('annual standardized fishery CPUE', row$survey_age_evidence, fixed = TRUE),
  grepl('age-group-specific VAST indices', row$survey_age_evidence, fixed = TRUE),
  grepl('1.6 year-1', row$mortality_evidence, fixed = TRUE),
  grepl('0.2 at age 3', row$maturity_evidence, fixed = TRUE),
  grepl('annual fishery CPUE', row$timing_evidence, fixed = TRUE),
  !grepl('fractional survey timing for tinyAM is not applicable',
    row$timing_evidence, fixed = TRUE),
  grepl('age-specific fishing-mortality', row$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  !any(stocks$scientific_name == 'Thunnus orientalis', na.rm = TRUE),
  !any(assessments$stock_id == 'noaa_isc_pacific_bluefin'),
  !any(inputs$assessment_id == 'noaa_isc_pacific_bluefin'),
  !any(outputs$assessment_id == 'noaa_isc_pacific_bluefin'),
  file.exists(file.path(root,
    'discovery/source_reviews/noaa_pacific_bluefin_2024.md'))
)

cat('NOAA Pacific bluefin 2024 assessment identity and age-input screen checks passed.\n')

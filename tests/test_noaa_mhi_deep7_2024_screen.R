root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/370_screen_noaa_mhi_deep7_2024.R'))
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
progress <- read.csv(file.path(root, 'discovery/inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:11827', , drop = FALSE]
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_mhi_deep7_complex', , drop = FALSE]
pifsc <- progress[progress$organization == 'NOAA' &
  progress$source_region == 'PIFSC', , drop = FALSE]

stopifnot(
  nrow(row) == 1L,
  row$stock_name == 'Main Hawaiian Islands Deep 7 Bottomfish Multi-species Complex',
  row$inventory_assessment_year == 2024,
  row$candidate_unit_id == 'noaa_mhi_deep7_complex',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('does not fit catch-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('no observed catch-at-age or age-composition likelihood', row$catch_age_evidence, fixed = TRUE),
  grepl('BFISH relative biomass index', row$survey_age_evidence, fixed = TRUE),
  grepl('not age-specific', row$survey_age_evidence, fixed = TRUE),
  grepl('weight-composition', row$weights_evidence, fixed = TRUE),
  grepl('fixed life-history', row$mortality_evidence, fixed = TRUE),
  grepl('July-June fishing years', row$timing_evidence, fixed = TRUE),
  grepl('reports annual exploitable biomass', row$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  nrow(pifsc) == 1L,
  pifsc$inventory_rows == 45L,
  pifsc$new == 44L,
  pifsc$ambiguous == 1L,
  pifsc$identity_unreviewed == 0L,
  pifsc$excluded == 43L,
  pifsc$screening_complete == 45L,
  pifsc$screening_not_started == 0L,
  !any(grepl('Deep 7', stocks$common_name, ignore.case = TRUE), na.rm = TRUE),
  !any(assessments$stock_id == 'noaa_mhi_deep7_complex'),
  !any(inputs$assessment_id == 'noaa_mhi_deep7_complex'),
  !any(outputs$assessment_id == 'noaa_mhi_deep7_complex'),
  file.exists(file.path(root, 'discovery/source_reviews/noaa_mhi_deep7_2024.md'))
)

cat('NOAA Deep 7 2024 assessment identity and age-input screen checks passed.\n')

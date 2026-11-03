root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/371_screen_noaa_american_samoa_2026.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
progress <- read.csv(file.path(root, 'discovery/inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

current_ids <- c('NOAA:11997', 'NOAA:11998', 'NOAA:12003', 'NOAA:12005')
legacy_species_ids <- c('NOAA:11999', 'NOAA:12007', 'NOAA:12011', 'NOAA:12013',
  'NOAA:12215')
current <- register[match(current_ids, register$candidate_id), , drop = FALSE]
legacy_species <- register[match(legacy_species_ids, register$candidate_id), , drop = FALSE]
complex <- register[register$candidate_id == 'NOAA:11695', , drop = FALSE]
pifsc <- progress[progress$organization == 'NOAA' &
  progress$source_region == 'PIFSC', , drop = FALSE]
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]

stopifnot(
  nrow(current) == 4L,
  all(current$screening_status == 'screened'),
  all(current$eligibility == 'ineligible'),
  all(current$match_status == 'new'),
  all(current$inventory_assessment_year == 2023L),
  all(grepl('2026', current$notes, fixed = TRUE)),
  all(grepl('no catch-at-age or age-composition likelihood',
    current$catch_age_evidence, fixed = TRUE)),
  all(grepl('aggregate boat-based creel CPUE', current$survey_age_evidence, fixed = TRUE)),
  all(grepl('through 2025', current$output_evidence, fixed = TRUE)),
  !anyDuplicated(current$candidate_unit_id),
  nrow(legacy_species) == 5L,
  all(legacy_species$screening_status == 'screened'),
  all(legacy_species$eligibility == 'ineligible'),
  all(grepl('did not refit this species',
    legacy_species$decision_reason, fixed = TRUE)),
  nrow(complex) == 1L,
  complex$match_status == 'ambiguous',
  complex$screening_status == 'screened',
  complex$eligibility == 'ineligible',
  grepl('21164', complex$detailed_source_url, fixed = TRUE),
  !grepl('37789', complex$detailed_source_url, fixed = TRUE),
  is.na(complex$candidate_unit_id) || !nzchar(complex$candidate_unit_id),
  grepl('one-to-many', complex$decision_reason, fixed = TRUE),
  nrow(pifsc) == 1L,
  pifsc$inventory_rows == 45L,
  pifsc$new == 44L,
  pifsc$ambiguous == 1L,
  pifsc$identity_unreviewed == 0L,
  pifsc$excluded == 43L,
  pifsc$screening_complete == 45L,
  pifsc$screening_not_started == 0L,
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L,
  sum(noaa$ambiguous) == 14L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  all(current$candidate_unit_id %in% units$candidate_unit_id),
  !any(grepl('American Samoa', assessments$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('American Samoa', inputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('American Samoa', outputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  file.exists(file.path(root, 'discovery/source_reviews/noaa_american_samoa_bottomfish_2026.md'))
)

cat('American Samoa 2026 unit reconciliation and age-input eligibility checks passed.\n')

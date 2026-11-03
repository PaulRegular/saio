root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/372_screen_noaa_marianas_bottomfish_2025.R'))
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

ids <- c('NOAA:11696', 'NOAA:11731')
marianas <- register[match(ids, register$candidate_id), , drop = FALSE]
pifsc <- progress[progress$organization == 'NOAA' &
  progress$source_region == 'PIFSC', , drop = FALSE]
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]

stopifnot(
  nrow(marianas) == 2L,
  all(marianas$screening_status == 'screened'),
  all(marianas$eligibility == 'ineligible'),
  all(marianas$match_status == 'new'),
  identical(marianas$candidate_unit_id,
    c('noaa_guam_bottomfish_complex', 'noaa_cnmi_bottomfish_complex')),
  grepl('1982-2023', marianas$catch_age_evidence[1], fixed = TRUE),
  grepl('2000-2023', marianas$catch_age_evidence[2], fixed = TRUE),
  all(grepl('aggregate catch', marianas$catch_age_evidence, fixed = TRUE)),
  all(grepl('no age-specific index', marianas$survey_age_evidence, fixed = TRUE)),
  all(grepl('No numeric N-at-age or F-at-age', marianas$output_evidence, fixed = TRUE)),
  grepl('through 2029', marianas$output_evidence[1], fixed = TRUE),
  grepl('2026-2030', marianas$output_evidence[2], fixed = TRUE),
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
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  all(marianas$candidate_unit_id %in% units$candidate_unit_id),
  !any(grepl('Guam|Northern Mariana|CNMI', assessments$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('Guam|Northern Mariana|CNMI', inputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('Guam|Northern Mariana|CNMI', outputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  file.exists(file.path(root, 'discovery/source_reviews/noaa_marianas_bottomfish_2024_2025.md'))
)

cat('NOAA Guam 2024 and CNMI 2025 current-unit screens passed.\n')

root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/373_screen_noaa_mhi_reef_fish_2016.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
progress <- read.csv(file.path(root, 'discovery/inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

ids <- paste0('NOAA:', c(12452L, 14617L:14623L))
mhi <- register[match(ids, register$candidate_id), , drop = FALSE]
pifsc <- progress[progress$organization == 'NOAA' &
  progress$source_region == 'PIFSC', , drop = FALSE]
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
sources <- read.csv(file.path(root, 'source_cache/discovery_noaa_mhi_reef_fish_2016/sources.csv'),
  stringsAsFactors = FALSE)

stopifnot(
  nrow(mhi) == 8L,
  all(mhi$match_status == 'new'),
  all(mhi$screening_status == 'screened'),
  all(mhi$eligibility == 'ineligible'),
  all(mhi$import_status == 'not_started'),
  identical(mhi$candidate_unit_id, c(
    'noaa_mhi_giant_trevally', 'noaa_mhi_twosaddle_goatfish',
    'noaa_mhi_kumu_goatfish', 'noaa_mhi_spectacled_parrotfish',
    'noaa_mhi_bullethead_parrotfish', 'noaa_mhi_regal_parrotfish',
    'noaa_mhi_palenose_parrotfish', 'noaa_mhi_redlip_parrotfish')),
  all(grepl('does not document catch-at-age', mhi$catch_age_evidence, fixed = TRUE)),
  all(grepl('no age-specific abundance index', mhi$survey_age_evidence, fixed = TRUE)),
  all(grepl('size', mhi$survey_age_evidence, fixed = TRUE)),
  all(grepl('N-at-age or F-at-age', mhi$output_evidence, fixed = TRUE)),
  all(mhi$candidate_unit_id %in% units$candidate_unit_id),
  !any(mhi$scientific_name %in% stocks$scientific_name),
  !any(grepl('Main Hawaiian Islands', assessments$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('Main Hawaiian Islands', inputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('Main Hawaiian Islands', outputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  nrow(pifsc) == 1L,
  pifsc$inventory_rows == 45L,
  pifsc$new == 44L,
  pifsc$ambiguous == 1L,
  pifsc$identity_unreviewed == 0L,
  pifsc$excluded == 43L,
  pifsc$screening_complete == 45L,
  pifsc$screening_not_started == 0L,
  sum(noaa$new) == 388L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(sources) == 2L,
  grepl('HTTP 403', sources$notes[1], fixed = TRUE),
  grepl('d5dfb6b7c1c7ef19', sources$notes[1], fixed = TRUE),
  file.exists(file.path(root, 'discovery/source_reviews/noaa_mhi_reef_fish_2016.md'))
)

cat('NOAA Main Hawaiian Islands 2016 age-input screens passed.\n')

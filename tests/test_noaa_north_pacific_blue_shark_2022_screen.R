root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/374_screen_noaa_north_pacific_blue_shark_2022.R'))
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
sources <- read.csv(file.path(root, 'source_cache/discovery_noaa_north_pacific_blue_shark_2022/sources.csv'),
  stringsAsFactors = FALSE)

bsh <- register[register$candidate_id == 'NOAA:11686', , drop = FALSE]
pifsc <- progress[progress$organization == 'NOAA' &
  progress$source_region == 'PIFSC', , drop = FALSE]
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]

stopifnot(
  nrow(bsh) == 1L,
  bsh$candidate_unit_id == 'noaa_blue_shark_north_pacific',
  bsh$scientific_name == 'Prionace glauca',
  bsh$stock_name == 'Blue shark - North Pacific',
  bsh$match_status == 'new',
  bsh$screening_status == 'screened',
  bsh$eligibility == 'ineligible',
  bsh$import_status == 'not_started',
  grepl('1971-2020', bsh$catch_age_evidence, fixed = TRUE),
  grepl('1976-2020', bsh$survey_age_evidence, fixed = TRUE),
  grepl('1979-2020', bsh$survey_age_evidence, fixed = TRUE),
  grepl('not age-specific indices', bsh$survey_age_evidence, fixed = TRUE),
  grepl('age-0 recruitment', bsh$output_evidence, fixed = TRUE),
  grepl('N-at-age and F-at-age', bsh$output_evidence, fixed = TRUE),
  bsh$candidate_unit_id %in% units$candidate_unit_id,
  !any(stocks$scientific_name == 'Prionace glauca' &
    grepl('North Pacific', paste(stocks$area, stocks$region), ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('North Pacific blue shark', assessments$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('North Pacific blue shark', inputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  !any(grepl('North Pacific blue shark', outputs$assessment_id, ignore.case = TRUE), na.rm = TRUE),
  nrow(pifsc) == 1L,
  pifsc$inventory_rows == 45L,
  pifsc$new == 44L,
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
  all(nzchar(sources$file)),
  all(file.exists(file.path(root, 'source_cache/discovery_noaa_north_pacific_blue_shark_2022', sources$file))),
  sources$sha256[1] == '7FE2A05C0DC52DA5AE466AE8046BB62AE839206ECBE941AAFFF2DA7431DAD0FA',
  sources$sha256[2] == '767B0605A3D9A518C80EB73673531D8AF58EF9542F18FD5DC5857FCBAF65A47E',
  file.exists(file.path(root, 'discovery/source_reviews/noaa_north_pacific_blue_shark_2022.md'))
)

cat('NOAA North Pacific blue shark 2022 age-input screen checks passed.\n')

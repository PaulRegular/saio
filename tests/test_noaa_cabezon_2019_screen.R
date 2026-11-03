root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/474_screen_noaa_cabezon_2019.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
lookup <- function(candidate_id) {
  row <- register[register$candidate_id == candidate_id, , drop = FALSE]
  stopifnot(nrow(row) == 1L)
  row
}
historical <- lookup('NOAA:10299')
ors <- lookup('NOAA:12193')
washington <- lookup('NOAA:14803')
ncs <- lookup('NOAA:15050')
scs <- lookup('NOAA:15051')
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
progress <- read.csv(file.path(root, 'discovery/inventory_progress.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
nw <- noaa[noaa$source_region == 'NWFSC / SWFSC', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

stopifnot(
  historical$inventory_assessment_year == 2009,
  historical$match_status == 'ambiguous',
  historical$screening_status == 'screened',
  historical$eligibility == 'ineligible',
  is.na(historical$candidate_unit_id),
  grepl('one-to-many', historical$decision_reason, fixed = TRUE),
  ors$candidate_unit_id == 'noaa_cabezon_oregon_2019',
  ors$inventory_assessment_year == 2019,
  ors$match_status == 'new',
  ors$screening_status == 'screened',
  ors$eligibility == 'eligible',
  grepl('2,328 fish', ors$catch_age_evidence, fixed = TRUE),
  grepl('364 fish', ors$catch_age_evidence, fixed = TRUE),
  grepl('aggregate logbook', ors$survey_age_evidence, fixed = TRUE),
  grepl('not a complete observed catch-at-age', ors$catch_age_evidence, fixed = TRUE),
  washington$candidate_unit_id == 'noaa_cabezon_washington_2019',
  washington$eligibility == 'ineligible',
  grepl('SSS analysis', washington$decision_reason, fixed = TRUE),
  ncs$candidate_unit_id == 'noaa_cabezon_northern_california_2019',
  ncs$eligibility == 'ineligible',
  grepl('do not represent catch age', ncs$catch_age_evidence, fixed = TRUE),
  scs$candidate_unit_id == 'noaa_cabezon_southern_california_2019',
  scs$eligibility == 'ineligible',
  grepl('no conditional age-at-length', scs$catch_age_evidence, fixed = TRUE),
  sum(units$candidate_unit_id %in% c(
    'noaa_cabezon_oregon_2019', 'noaa_cabezon_washington_2019',
    'noaa_cabezon_northern_california_2019', 'noaa_cabezon_southern_california_2019')) == 4L,
  sum(noaa$new) == 388L,
  sum(noaa$ambiguous) == 14L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$eligible) == 89L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(nw) == 1L,
  nw$new == 130L,
  nw$eligible == 37L,
  nw$excluded == 53L,
  nw$screening_complete == 138L,
  !any(stocks$scientific_name == 'Scorpaenichthys marmoratus', na.rm = TRUE),
  !any(assessments$stock_id %in% c('noaa_cabezon_oregon_2019',
    'noaa_cabezon_washington_2019', 'noaa_cabezon_northern_california_2019',
    'noaa_cabezon_southern_california_2019')),
  !any(inputs$assessment_id %in% c('noaa_cabezon_oregon_2019',
    'noaa_cabezon_washington_2019', 'noaa_cabezon_northern_california_2019',
    'noaa_cabezon_southern_california_2019')),
  !any(outputs$assessment_id %in% c('noaa_cabezon_oregon_2019',
    'noaa_cabezon_washington_2019', 'noaa_cabezon_northern_california_2019',
    'noaa_cabezon_southern_california_2019'))
)

cat('NOAA 2019 cabezon current-unit crosswalk, age-input screen, source provenance, and no-import checks passed.\n')

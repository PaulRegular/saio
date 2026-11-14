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
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
ors_stock <- stocks[stocks$stock_id == 'noaa_cabezon_oregon', , drop = FALSE]
ors_assessment <- assessments[assessments$assessment_id == 'noaa_cabezon_oregon_2019', , drop = FALSE]
ors_inputs <- inputs[inputs$assessment_id == 'noaa_cabezon_oregon_2019', , drop = FALSE]
ors_outputs <- outputs[outputs$assessment_id == 'noaa_cabezon_oregon_2019', , drop = FALSE]

stopifnot(
  historical$inventory_assessment_year == 2009,
  historical$match_status == 'ambiguous',
  historical$screening_status == 'screened',
  historical$eligibility == 'ineligible',
  is.na(historical$candidate_unit_id),
  grepl('one-to-many', historical$decision_reason, fixed = TRUE),
  ors$candidate_unit_id == 'noaa_cabezon_oregon_2019',
  ors$inventory_assessment_year == 2019,
  ors$matched_stock_id == 'noaa_cabezon_oregon',
  ors$match_status == 'new',
  ors$screening_status == 'screened',
  ors$eligibility == 'eligible',
  ors$import_status == 'partial',
  grepl('no observed catch-numbers-at-age', ors$catch_age_evidence, fixed = TRUE),
  grepl('not an age-specific abundance index', ors$survey_age_evidence, fixed = TRUE),
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
  nrow(ors_stock) == 1L,
  ors_stock$authority_stock_id == '12193',
  ors_stock$ocean == 'Northeast Pacific',
  nrow(ors_assessment) == 1L,
  ors_assessment$assessment_year == 2019L,
  ors_assessment$terminal_year == 2018L,
  ors_assessment$inputs_status == 'partial',
  nrow(ors_inputs) == 20260L,
  nrow(ors_outputs) == 24795L,
  !any(ors_inputs$type == 'catch' & ors_inputs$measure == 'numbers_at_age'),
  any(ors_inputs$measure == 'conditional_frequency_at_age'),
  any(ors_outputs$measure == 'catch_numbers_at_age'),
  all(ors_outputs$source_type %in% c('native_model', 'official_table')),
  any(ors_outputs$measure == 'SSB' & ors_outputs$year == 2019L &
    ors_outputs$scenario == 'assessment forecast' & ors_outputs$value == 177 &
    ors_outputs$lwr == 128 & ors_outputs$upr == 226),
  file.exists('discovery/source_reviews/noaa_cabezon_2019.md'),
  !any(assessments$stock_id %in% c('noaa_cabezon_washington_2019',
    'noaa_cabezon_northern_california_2019',
    'noaa_cabezon_southern_california_2019')),
  !any(inputs$assessment_id %in% c('noaa_cabezon_washington_2019',
    'noaa_cabezon_northern_california_2019',
    'noaa_cabezon_southern_california_2019')),
  !any(outputs$assessment_id %in% c('noaa_cabezon_washington_2019',
    'noaa_cabezon_northern_california_2019',
    'noaa_cabezon_southern_california_2019'))
)

cat('NOAA 2019 cabezon current-unit crosswalk, source screen, and imported-data checks passed.\n')

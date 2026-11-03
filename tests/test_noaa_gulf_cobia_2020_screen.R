root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/478_screen_noaa_gom_cobia_2020.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10390', , drop = FALSE]
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
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_gulf_cobia_2020.md'), warn = FALSE), collapse = ' ')

stopifnot(nrow(candidate) == 1L,
  candidate$candidate_id == 'NOAA:10390',
  candidate$candidate_unit_id == 'noaa_cobia_gulf_mexico_2020',
  candidate$scientific_name == 'Rachycentron canadum',
  candidate$inventory_assessment_year == '2020',
  candidate$match_status == 'new', candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible', candidate$import_status == 'not_started',
  grepl('conditional age-at-length', candidate$catch_age_evidence, fixed = TRUE),
  grepl('no separate age-specific survey index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('M = 0.38', candidate$mortality_evidence, fixed = TRUE),
  grepl('Table 15', candidate$output_evidence, fixed = TRUE),
  grepl('age-input reconstruction caveat', review, fixed = TRUE),
  grepl('age proportions are plotted', review, fixed = TRUE),
  sum(stocks$stock_id == 'noaa_cobia_gulf_mexico_2020', na.rm = TRUE) == 0L,
  sum(assessments$assessment_id == 'noaa_cobia_gulf_mexico_2020', na.rm = TRUE) == 0L,
  sum(inputs$assessment_id == 'noaa_cobia_gulf_mexico_2020', na.rm = TRUE) == 0L,
  sum(outputs$assessment_id == 'noaa_cobia_gulf_mexico_2020', na.rm = TRUE) == 0L,
  sum(units$candidate_unit_id == 'noaa_cobia_gulf_mexico_2020', na.rm = TRUE) == 1L)

cat('NOAA Gulf cobia 2020 source, screening, and no-import checks passed.\n')

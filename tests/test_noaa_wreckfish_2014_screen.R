root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database/481_screen_noaa_wreckfish_2014.R'),
  local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10369', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_south_atlantic_wreckfish', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_wreckfish_south_atlantic_2014.md'), warn = FALSE),
  collapse = ' ')

stopifnot(nrow(candidate) == 1L,
  candidate$official_stock_id == '10369',
  candidate$scientific_name == 'Polyprion americanus',
  candidate$assessment_area == 'Southern Atlantic Coast',
  candidate$inventory_assessment_year == '2014',
  candidate$candidate_unit_id == 'noaa_south_atlantic_wreckfish',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('catch-at-length', candidate$catch_age_evidence, fixed = TRUE),
  grepl('1991-2012', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age-specific', candidate$survey_age_evidence, fixed = TRUE),
  grepl('under development', candidate$notes, fixed = TRUE),
  nrow(unit) == 1L, unit$match_status == 'new',
  unit$screening_status == 'screened', unit$eligibility == 'unresolved',
  unit$inventory_entries == 1L,
  grepl('not a final production output', review, fixed = TRUE),
  grepl('representativeness', review, fixed = TRUE),
  !any(stocks$scientific_name == 'Polyprion americanus', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_south_atlantic_wreckfish', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_south_atlantic_wreckfish', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_south_atlantic_wreckfish', na.rm = TRUE))

cat('NOAA wreckfish identity, unresolved age-input screen, provenance, and no-import checks passed.\n')

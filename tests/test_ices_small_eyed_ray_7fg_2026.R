root <- '.'
candidate_id <- 'ICES:rje.27.7fg'
unit_id <- 'ices_small_eyed_ray_7fg'
cache <- file.path(root, 'source_cache', 'discovery_ices_small_eyed_ray_7fg_2026')

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_small_eyed_ray_7fg_2026.md'), warn = FALSE), collapse = '\n')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$official_stock_id == 'rje.27.7fg',
  candidate$scientific_name == 'Raja microocellata',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('no age-specific catch', candidate$catch_age_evidence, fixed = TRUE),
  grepl('aggregate biomass index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('N-, F-, or M-at-age', candidate$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$candidate_unit_id == unit_id,
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  nrow(manifest) == 3L,
  all(file.exists(file.path(cache, manifest$file))),
  grepl('Category 3', review, fixed = TRUE),
  grepl('124 tonnes', review, fixed = TRUE),
  grepl('N-at-age, F-at-age, or M-at-age', review, fixed = TRUE),
  grepl('7.d–7.e unit', review, fixed = TRUE),
  !any(stocks$authority_stock_id == 'rje.27.7fg', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE)
)

cat('ICES small-eyed ray identity, current aggregate assessment, and no-import checks passed.\n')

old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts', 'database', '396_screen_ices_small_eyed_ray_7fg_2026.R'))
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

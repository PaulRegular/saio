root <- '.'
candidate_id <- 'ICES:rju.27.7de'
unit_id <- 'ices_undulate_ray_7de'

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_undulate_ray_7de_2024.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$organization == 'ICES',
  candidate$official_stock_id == 'rju.27.7de',
  candidate$scientific_name == 'Raja undulata',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('aggregate SPiCT', candidate$catch_age_evidence, fixed = TRUE),
  grepl('aggregate survey biomass indices', candidate$survey_age_evidence, fixed = TRUE),
  grepl('2024 category 2', candidate$decision_reason, fixed = TRUE),
  nrow(unit) == 1L,
  unit$candidate_unit_id == unit_id,
  unit$match_status == 'new',
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == 'rju.27.7de', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE),
  grepl('aggregate relative biomass', review, fixed = TRUE),
  grepl('Q1SWECOS', review, fixed = TRUE),
  grepl('2026 SID row is an inventory entry', review, fixed = TRUE),
  grepl('No canonical', review, fixed = TRUE),
  file.exists(file.path(root, 'scripts', 'database',
    '380_screen_ices_undulate_ray_7de_2024.R'))
)

cat('ICES undulate ray identity, aggregate-model screen, and no-import checks passed.\n')

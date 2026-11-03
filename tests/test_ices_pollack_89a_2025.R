root <- '.'
candidate_id <- 'ICES:pol.27.89a'
unit_id <- 'ices_pollack_89a'

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
  'ices_pollack_89a_2025.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$organization == 'ICES',
  candidate$official_stock_id == 'pol.27.89a',
  candidate$scientific_name == 'Pollachius pollachius',
  as.character(candidate$inventory_assessment_year) == '2025',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('not catch-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('aggregate biomass index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('category 3.2', candidate$decision_reason, fixed = TRUE),
  nrow(unit) == 1L,
  unit$candidate_unit_id == unit_id,
  unit$match_status == 'new',
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == 'pol.27.89a', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE),
  grepl('B_index', review, fixed = TRUE),
  grepl('kilograms per hour', review, fixed = TRUE),
  grepl('not treated as spawning-stock biomass', review, fixed = TRUE),
  grepl('No tinyAM', review, fixed = TRUE),
  grepl('translation was attempted', review, fixed = TRUE),
  file.exists(file.path(root, 'scripts', 'database',
    '379_screen_ices_pollack_89a_2025.R'))
)

cat('ICES pollack identity, aggregate-index screen, and no-import checks passed.\n')

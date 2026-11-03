root <- '.'
candidate_id <- 'ICES:ghl.27.1-2'
unit_id <- 'ices_greenland_halibut_1_2'

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
  'ices_greenland_halibut_1_2_2026.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$organization == 'ICES',
  candidate$official_stock_id == 'ghl.27.1-2',
  candidate$scientific_name == 'Reinhardtius hippoglossoides',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$match_status == 'new',
  is.na(candidate$matched_stock_id),
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('not a commercial catch-at-age likelihood', candidate$catch_age_evidence, fixed = TRUE),
  grepl('2015-2021', candidate$catch_age_evidence, fixed = TRUE),
  grepl('2001-2023', candidate$survey_age_evidence, fixed = TRUE),
  grepl('0.12 for females and 0.16', candidate$mortality_evidence, fixed = TRUE),
  grepl('age-2 recruitment', candidate$output_evidence, fixed = TRUE),
  grepl('exact link', candidate$mortality_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$candidate_unit_id == unit_id,
  unit$match_status == 'new',
  unit$eligibility == 'unresolved',
  unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == 'ghl.27.1-2', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE),
  grepl('2024 model version', review, fixed = TRUE),
  grepl('not verified as the exact run bundle', review, fixed = TRUE),
  grepl('eligibility unresolved', review, fixed = TRUE),
  file.exists(file.path(root, 'scripts', 'database',
    '377_screen_ices_greenland_halibut_1_2_2026.R'))
)

cat('ICES Greenland halibut in subareas 1 and 2 identity, evidence, unresolved eligibility, and no-import checks passed.\n')

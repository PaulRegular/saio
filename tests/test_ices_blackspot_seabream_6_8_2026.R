root <- '.'
candidate_id <- 'ICES:sbr.27.6-8'
unit_id <- 'ices_blackspot_seabream_6_8'

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
  'ices_blackspot_seabream_6_8_2026.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$organization == 'ICES',
  candidate$official_stock_id == 'sbr.27.6-8',
  candidate$scientific_name == 'Pagellus bogaraveo',
  as.character(candidate$inventory_assessment_year) == '2026',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  grepl('landings, catches, and discards only', candidate$catch_age_evidence, fixed = TRUE),
  grepl('category 6', candidate$output_evidence),
  grepl('current record is therefore', candidate$decision_reason, fixed = TRUE),
  nrow(unit) == 1L,
  unit$candidate_unit_id == unit_id,
  unit$match_status == 'new',
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == 'sbr.27.6-8', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE),
  grepl('2026 advice is category 6', review, fixed = TRUE),
  grepl('aggregate landings, catches, and discards', review, fixed = TRUE),
  file.exists(file.path(root, 'scripts', 'database',
    '378_screen_ices_blackspot_seabream_6_8_2026.R'))
)

cat('ICES blackspot seabream identity, aggregate-only screen, and no-import checks passed.\n')

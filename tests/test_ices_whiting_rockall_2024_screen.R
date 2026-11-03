root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/367_screen_ices_whiting_rockall_2024.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'ICES:whg.27.6b', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'ices_whiting_rockall_6b', , drop = FALSE]

stopifnot(
  nrow(row) == 1L,
  row$official_stock_id == 'whg.27.6b',
  row$scientific_name == 'Merlangius merlangus',
  row$inventory_assessment_year == 2024,
  row$candidate_unit_id == 'ices_whiting_rockall_6b',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('Category 6.2', row$catch_age_evidence, fixed = TRUE),
  grepl('1975-2023', row$catch_age_evidence, fixed = TRUE),
  grepl('landings only', row$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == 'whg.27.6b', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_whiting_rockall_6b'),
  !any(inputs$assessment_id == 'ices_whiting_rockall_6b'),
  !any(outputs$assessment_id == 'ices_whiting_rockall_6b'),
  file.exists(file.path(root, 'discovery/source_reviews/ices_whiting_rockall_2024.md'))
)

cat('ICES Rockall whiting 2024 current-method and age-input screen checks passed.\n')

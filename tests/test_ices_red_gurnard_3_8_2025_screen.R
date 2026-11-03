root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/368_screen_ices_red_gurnard_2025.R'))
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
row <- register[register$candidate_id == 'ICES:gur.27.3-8', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'ices_red_gurnard_3_8', , drop = FALSE]

stopifnot(
  nrow(row) == 1L,
  row$official_stock_id == 'gur.27.3-8',
  row$scientific_name == 'Chelidonichthys cuculus',
  row$inventory_assessment_year == 2025,
  row$candidate_unit_id == 'ices_red_gurnard_3_8',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('survey trends-based assessment', row$catch_age_evidence, fixed = TRUE),
  grepl('aggregate biomass indices', row$survey_age_evidence, fixed = TRUE),
  grepl('uncertainty', row$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == 'gur.27.3-8', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_red_gurnard_3_8'),
  !any(inputs$assessment_id == 'ices_red_gurnard_3_8'),
  !any(outputs$assessment_id == 'ices_red_gurnard_3_8'),
  file.exists(file.path(root, 'discovery/source_reviews/ices_red_gurnard_3_8_2025.md'))
)

cat('ICES red gurnard 3-8 2025 current-method and age-input screen checks passed.\n')

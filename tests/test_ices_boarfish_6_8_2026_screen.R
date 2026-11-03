root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/366_screen_ices_boarfish_2026.R'))
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
row <- register[register$candidate_id == 'ICES:boc.27.6-8', , drop = FALSE]
unit <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- unit[!is.na(unit$candidate_unit_id) & unit$candidate_unit_id == 'ices_boarfish_6_8', , drop = FALSE]

stopifnot(
  nrow(row) == 1L,
  row$official_stock_id == 'boc.27.6-8',
  row$scientific_name == 'Capros aper',
  row$inventory_assessment_year == 2026,
  row$candidate_unit_id == 'ices_boarfish_6_8',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('does not use observed catch numbers-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('length compositions', row$survey_age_evidence, fixed = TRUE),
  grepl('L50 = 88 mm', row$maturity_evidence, fixed = TRUE),
  grepl('0.174', row$mortality_evidence, fixed = TRUE),
  grepl('age 0', row$output_evidence, fixed = TRUE),
  nrow(unit) == 1L,
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == 'boc.27.6-8', na.rm = TRUE),
  !any(assessments$stock_id == 'ices_boarfish_6_8'),
  !any(inputs$assessment_id == 'ices_boarfish_6_8'),
  !any(outputs$assessment_id == 'ices_boarfish_6_8'),
  file.exists(file.path(root, 'discovery/source_reviews/ices_boarfish_6_8_2026.md'))
)

cat('ICES boarfish 6-8 current-method and age-input screen checks passed.\n')

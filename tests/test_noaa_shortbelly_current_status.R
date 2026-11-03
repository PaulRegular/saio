root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:10398', , drop = FALSE]
unit_id <- 'noaa_shortbelly_rockfish_pacific_coast'
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_shortbelly_rockfish_current_status.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == unit_id,
  row$official_stock_id == '10398',
  row$scientific_name == 'Sebastes jordani',
  row$inventory_assessment_year == 2007,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('current-assessment scope', row$decision_reason, fixed = TRUE),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$eligibility == 'ineligible',
  grepl('ecosystem component', review, fixed = TRUE),
  grepl('2007 model is historical context', review, fixed = TRUE),
  grepl('not a finding that the archived model lacks age-structured data', review, fixed = TRUE),
  !any(stocks$authority_stock_id == '10398', na.rm = TRUE),
  !any(stocks$stock_id == unit_id, na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE)
)

cat('NOAA shortbelly current-assessment scope checks passed.\n')
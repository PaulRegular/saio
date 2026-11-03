root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:10435', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_sharpchin_rockfish_2013.md'), warn = FALSE), collapse = ' ')
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
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
  row$candidate_unit_id == 'noaa_pacific_sharpchin_rockfish',
  row$scientific_name == 'Sebastes zacentrus',
  row$assessment_area == 'Pacific Coast',
  row$inventory_assessment_year == 2013,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('fully accepted', review, fixed = TRUE),
  grepl('age-composition observations to zero', review, fixed = TRUE),
  grepl('mean-size-at-age observations to zero', review, fixed = TRUE),
  grepl('data through 2012', review, fixed = TRUE),
  any(grepl('NOAA:10435', units$candidate_ids, fixed = TRUE)),
  any(units$candidate_unit_id == 'noaa_pacific_sharpchin_rockfish'),
  !any(stocks$authority_stock_id == '10435', na.rm = TRUE),
  !any(stocks$scientific_name == 'Sebastes zacentrus', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_pacific_sharpchin_rockfish_2013', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_pacific_sharpchin_rockfish_2013', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_pacific_sharpchin_rockfish_2013', na.rm = TRUE)
)

cat('NOAA Pacific Coast Sharpchin identity and age-eligibility screen checks passed.\n')

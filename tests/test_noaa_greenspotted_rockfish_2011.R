root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:10437', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_greenspotted_rockfish_2011.md'), warn = FALSE), collapse = ' ')
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
  row$candidate_unit_id == 'noaa_pacific_greenspotted_rockfish',
  row$scientific_name == 'Sebastes chlorostictus',
  row$inventory_assessment_year == 2011,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'unresolved',
  row$import_status == 'not_started',
  grepl('populations as separate, independent', review, fixed = TRUE),
  grepl('coastwide stock definition', review, fixed = TRUE),
  grepl('M at 0.065', review, fixed = TRUE),
  grepl('numbers-at-age', review, fixed = TRUE),
  grepl('does not fit catch-at-age directly', review, fixed = TRUE),
  any(grepl('NOAA:10437', units$candidate_ids, fixed = TRUE)),
  any(units$candidate_unit_id == 'noaa_pacific_greenspotted_rockfish'),
  !any(stocks$authority_stock_id == '10437', na.rm = TRUE),
  !any(stocks$scientific_name == 'Sebastes chlorostictus', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_pacific_greenspotted_rockfish_2011', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_pacific_greenspotted_rockfish_2011', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_pacific_greenspotted_rockfish_2011', na.rm = TRUE)
)

cat('NOAA Greenspotted rockfish identity, boundary, source and no-import checks passed.\n')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:10546', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_brown_rockfish_pacific_coast_2013.md'), warn = FALSE), collapse = ' ')
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
  row$candidate_unit_id == 'noaa_pacific_brown_rockfish',
  row$scientific_name == 'Sebastes auriculatus',
  row$inventory_assessment_year == 2013,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('data through 2012', review, fixed = TRUE),
  grepl('XDB-SRA', review, fixed = TRUE),
  grepl('N_Agecomp_obs = 0', review, fixed = TRUE),
  grepl('1916-2012', review, fixed = TRUE),
  grepl('do not include annual numeric N-at-age', review, fixed = TRUE),
  any(grepl('NOAA:10546', units$candidate_ids, fixed = TRUE)),
  any(units$candidate_unit_id == 'noaa_pacific_brown_rockfish'),
  !any(stocks$authority_stock_id == '10546', na.rm = TRUE),
  !any(stocks$scientific_name == 'Sebastes auriculatus', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_pacific_brown_rockfish_2013', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_pacific_brown_rockfish_2013', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_pacific_brown_rockfish_2013', na.rm = TRUE)
)

cat('NOAA Brown rockfish identity, source, ineligibility and no-import checks passed.\n')
root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:10547', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_aurora_rockfish_2013.md'), warn = FALSE), collapse = ' ')
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
  row$candidate_unit_id == 'noaa_pacific_aurora_rockfish',
  row$scientific_name == 'Sebastes aurora',
  row$inventory_assessment_year == 2013,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'unresolved',
  row$import_status == 'not_started',
  grepl('most recent assessment', review, fixed = TRUE),
  grepl('data through 2012', review, fixed = TRUE),
  grepl('2003, 2008 and 2009', review, fixed = TRUE),
  grepl('0.0350', review, fixed = TRUE),
  grepl('0.0371', review, fixed = TRUE),
  grepl('0.5', review, fixed = TRUE),
  grepl('Table 13', review, fixed = TRUE),
  grepl('age-length key', review, fixed = TRUE),
  any(grepl('NOAA:10547', units$candidate_ids, fixed = TRUE)),
  any(units$candidate_unit_id == 'noaa_pacific_aurora_rockfish'),
  !any(stocks$authority_stock_id == '10547', na.rm = TRUE),
  !any(stocks$scientific_name == 'Sebastes aurora', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_pacific_aurora_rockfish_2013', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_pacific_aurora_rockfish_2013', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_pacific_aurora_rockfish_2013', na.rm = TRUE)
)

cat('NOAA Aurora rockfish identity, source, screening and no-import checks passed.\n')
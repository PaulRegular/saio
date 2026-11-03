root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:10404', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_blackgill_rockfish_2017.md'), warn = FALSE), collapse = ' ')
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
  row$official_stock_id == '10404',
  row$scientific_name == 'Sebastes melanostomus',
  row$assessment_area == 'Southern California',
  row$inventory_assessment_year == 2019,
  row$match_status == 'ambiguous',
  row$screening_status == 'screened',
  row$eligibility == 'unresolved',
  row$import_status == 'not_started',
  is.na(row$candidate_unit_id) || !nzchar(row$candidate_unit_id),
  any(grepl('10404', row$detailed_source_url, fixed = TRUE)),
  grepl('age-at-length', review, ignore.case = TRUE),
  grepl('larval production', review, fixed = TRUE),
  grepl('catch-only projections', review, fixed = TRUE),
  grepl('identity-ambiguous and eligibility-unresolved', review, fixed = TRUE),
  !any(grepl('NOAA:10404', units$candidate_ids, fixed = TRUE)),
  !any(stocks$authority_stock_id == '10404', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_blackgill_rockfish_pacific_coast', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_blackgill_rockfish_pacific_coast', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_blackgill_rockfish_pacific_coast', na.rm = TRUE)
)

cat('NOAA blackgill identity and source-screen checks passed.\n')
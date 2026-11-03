root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:11081', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_yellowtail_snapper_sedar96_2025.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_yellowtail_snapper_11081',
  row$scientific_name == 'Ocyurus chrysurus',
  row$assessment_area == 'Southern Atlantic Coast / Gulf of Mexico',
  row$inventory_assessment_year == 2025L,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'unresolved',
  row$import_status == 'not_started',
  grepl('SEDAR 96', row$decision_reason, fixed = TRUE),
  grepl('1992-2023', row$catch_age_evidence, fixed = TRUE),
  grepl('not linked to an index', row$survey_age_evidence, fixed = TRUE),
  grepl('July 1', row$timing_evidence, fixed = TRUE),
  grepl('sedar-96-southeastern-us-yellowtail-snapper-final-stock-assessment-report',
    row$detailed_source_url, fixed = TRUE),
  grepl('age- and size-structured', review, fixed = TRUE),
  grepl('not linked to an abundance index', review, fixed = TRUE),
  grepl('N-at-age surface', review, fixed = TRUE)
)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  !any(stocks$scientific_name == 'Ocyurus chrysurus', na.rm = TRUE),
  !any(grepl('noaa_yellowtail_snapper_11081', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_yellowtail_snapper_11081', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_yellowtail_snapper_11081', outputs$assessment_id, fixed = TRUE))
)

cat('NOAA Southeastern U.S. yellowtail snapper identity and source-availability screen passed.\n')

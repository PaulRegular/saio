root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root,
  'data-raw/scripts/noaa_yellowtail_snapper_11081/425_screen_noaa_yellowtail_snapper_sedar96_2025.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')
register <- read.csv(file.path(root, 'database/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:11081', , drop = FALSE]
review <- paste(readLines(file.path(root, 'data-raw/source_reviews/noaa_yellowtail_snapper_11081.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_yellowtail_snapper_11081',
  row$scientific_name == 'Ocyurus chrysurus',
  row$assessment_area == 'Southern Atlantic Coast / Gulf of Mexico',
  row$inventory_assessment_year == 2025L,
  row$matched_stock_id == 'noaa_yellowtail_snapper_11081',
  row$match_status == 'matched',
  row$screening_status == 'screened',
  row$eligibility == 'unresolved',
  row$import_status == 'partial',
  grepl('SEDAR 96', row$decision_reason, fixed = TRUE),
  grepl('no run-matched numeric catch-at-age vector was found',
    row$catch_age_evidence, fixed = TRUE),
  grepl('No survey age composition tied to the RVC indices was recovered',
    row$survey_age_evidence, fixed = TRUE),
  grepl('July 1', row$timing_evidence, fixed = TRUE),
  grepl('sedar-96-southeastern-us-yellowtail-snapper-final-stock-assessment-report',
    row$detailed_source_url, fixed = TRUE),
  grepl('Stock Synthesis 3.30.15 model', review, fixed = TRUE),
  grepl('not linked to the RVC abundance indices', review, fixed = TRUE),
  grepl('N-at-age surface', review, fixed = TRUE)
)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  sum(stocks$stock_id == 'noaa_yellowtail_snapper_11081', na.rm = TRUE) == 1L,
  sum(assessments$assessment_id == 'noaa_yellowtail_snapper_11081_2025' &
    assessments$stock_id == 'noaa_yellowtail_snapper_11081', na.rm = TRUE) == 1L
)

cat('NOAA Southeastern U.S. yellowtail snapper screen and partial import checks passed.\n')

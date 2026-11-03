root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/473_screen_noaa_lingcod_2021.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
north <- register[register$candidate_id == 'NOAA:12194', , drop = FALSE]
south <- register[register$candidate_id == 'NOAA:12195', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review_path <- file.path(root, 'discovery/source_reviews/noaa_lingcod_2021.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
review <- gsub('[[:space:]]+', ' ', review)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

stopifnot(
  nrow(north) == 1L,
  north$inventory_assessment_year == 2021,
  north$candidate_unit_id == 'noaa_lingcod_north_pacific_coast_2021',
  north$match_status == 'new',
  north$screening_status == 'screened',
  north$eligibility == 'eligible',
  north$import_status == 'not_started',
  grepl('Washington and Oregon recreational', north$catch_age_evidence, fixed = TRUE),
  grepl('age-logistic maturity parameters are fixed', north$maturity_evidence, fixed = TRUE),
  grepl('Triennial', north$survey_age_evidence, fixed = TRUE),
  nrow(south) == 1L,
  south$inventory_assessment_year == 2021,
  south$candidate_unit_id == 'noaa_lingcod_south_pacific_coast_2021',
  south$match_status == 'new',
  south$screening_status == 'screened',
  south$eligibility == 'ineligible',
  south$import_status == 'not_started',
  grepl('Negative-fleet', south$catch_age_evidence, fixed = TRUE),
  grepl('age-logistic maturity parameters are fixed', south$maturity_evidence, fixed = TRUE),
  grepl('other than WCGBTS were removed', south$decision_reason, fixed = TRUE),
  sum(units$candidate_unit_id == 'noaa_lingcod_north_pacific_coast_2021', na.rm = TRUE) == 1L,
  sum(units$candidate_unit_id == 'noaa_lingcod_south_pacific_coast_2021', na.rm = TRUE) == 1L,
  grepl('40°10′N', review, fixed = TRUE),
  grepl('data through 2020', review, fixed = TRUE),
  grepl('0–20', review, fixed = TRUE),
  grepl('no likelihood contribution', review, fixed = TRUE),
  !any(stocks$scientific_name == 'Ophiodon elongatus', na.rm = TRUE),
  !any(assessments$stock_id %in% c('noaa_lingcod_north_pacific_coast_2021',
    'noaa_lingcod_south_pacific_coast_2021')),
  !any(inputs$assessment_id %in% c('noaa_lingcod_north_pacific_coast_2021',
    'noaa_lingcod_south_pacific_coast_2021')),
  !any(outputs$assessment_id %in% c('noaa_lingcod_north_pacific_coast_2021',
    'noaa_lingcod_south_pacific_coast_2021'))
)

cat('NOAA 2021 northern and southern lingcod identity, run, age-input screening, source provenance, and no-import checks passed.\n')

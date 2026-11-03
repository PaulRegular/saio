root <- "."
source(file.path(root, 'scripts', 'database',
  '497_screen_noaa_pacific_coast_longnose_skate_2019.R'))

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10731', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_pacific_coast_longnose_skate', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_longnose_skate_pacific_2019.md'), warn = FALSE), collapse = ' ')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

stopifnot(nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_pacific_coast_longnose_skate',
  candidate$match_status == 'new', candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible', candidate$import_status == 'not_started',
  grepl('one fishery conditional age-at-length sample', candidate$catch_age_evidence, fixed = TRUE),
  grepl('2003, 2011 and 2012', candidate$survey_age_evidence, fixed = TRUE),
  grepl('no fitted Report.sso', candidate$output_evidence, fixed = TRUE),
  grepl('not a translation-readiness decision', candidate$decision_reason, fixed = TRUE),
  grepl('source_cache/discovery_noaa_longnose_skate_2019', review, fixed = TRUE),
  nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$eligibility == 'eligible', unit$screening_status == 'screened',
  !any(stocks$authority_stock_id == '10731', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_longnose_skate_pacific_2019', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_longnose_skate_pacific_2019', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_longnose_skate_pacific_2019', na.rm = TRUE))

cat('NOAA Pacific Coast longnose skate screen, cached-source checks, unit identity and no-import checks passed.\n')

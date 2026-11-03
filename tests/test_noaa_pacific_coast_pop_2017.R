root <- "."
candidate_id <- 'NOAA:10545'
unit_id <- 'noaa_pacific_coast_pop_uswc'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_pacific_coast_pop_2017.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$scientific_name == 'Sebastes alutus',
  candidate$candidate_unit_id == unit_id,
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'unresolved',
  candidate$import_status == 'not_started',
  grepl('1981-2016', candidate$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', candidate$survey_age_evidence, fixed = TRUE),
  grepl('537 samples', candidate$maturity_evidence, fixed = TRUE),
  grepl('0.054 per year', candidate$mortality_evidence, fixed = TRUE),
  grepl('Appendix D', candidate$output_evidence, fixed = TRUE),
  grepl('2017pop.dat', candidate$catch_age_evidence, fixed = TRUE),
  grepl('NOAA Fisheries still identifies the 2017 report as the latest',
    candidate$decision_reason, fixed = TRUE),
  grepl('independently of the British Columbia and Alaska[[:space:]]+populations', review),
  grepl('not SSB in tonnes', review, fixed = TRUE),
  grepl('steepness at 0.72', review, fixed = TRUE),
  nrow(unit) == 1L,
  unit$organizations == 'NOAA',
  unit$inventory_entries == 1L,
  unit$eligibility == 'unresolved',
  !any(stocks$authority_stock_id == candidate_id, na.rm = TRUE),
  !any(stocks$stock_id == unit_id, na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE)
)

cat('NOAA Pacific Coast Pacific ocean perch source screen checks passed.\n')

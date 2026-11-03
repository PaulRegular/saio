root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:10465', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_goa_atka_mackerel_2021.md'), warn = FALSE), collapse = ' ')
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
  row$candidate_unit_id == 'noaa_goa_atka_mackerel',
  row$scientific_name == 'Pleurogrammus monopterygius',
  row$assessment_area == 'Gulf of Alaska',
  row$inventory_assessment_year == 2016,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('planned 2025 operational assessment was not completed', review, fixed = TRUE),
  grepl('no population assessment model', review, fixed = TRUE),
  grepl('sparse survey otolith samples', row$survey_age_evidence, ignore.case = TRUE),
  grepl('not fitted age-specific population outputs', row$output_evidence, fixed = TRUE),
  any(grepl('NOAA:10465', units$candidate_ids, fixed = TRUE)),
  any(units$candidate_unit_id == 'noaa_goa_atka_mackerel'),
  !any(grepl('NOAA:11662', units$candidate_ids[
    units$candidate_unit_id == 'noaa_goa_atka_mackerel'], fixed = TRUE)),
  !any(stocks$authority_stock_id == '10465', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_goa_atka_mackerel_2021', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_goa_atka_mackerel_2021', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_goa_atka_mackerel_2021', na.rm = TRUE)
)

cat('NOAA GOA Atka mackerel identity and age-eligibility screen checks passed.\n')

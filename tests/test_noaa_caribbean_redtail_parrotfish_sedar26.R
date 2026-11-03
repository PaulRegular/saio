root <- '.'
candidate_id <- 'NOAA:10144'
unit_id <- 'noaa_redtail_parrotfish_caribbean'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root, 'source_reviews',
  'noaa_caribbean_redtail_parrotfish_sedar26.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == unit_id,
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  candidate$scientific_name == 'Sparisoma chrysopterum',
  grepl('catch-at-age/length was not developed', candidate$catch_age_evidence, fixed = TRUE),
  grepl('No species-specific standardized abundance index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('Puerto Rico, St. Thomas/St. John, and St. Croix', candidate$notes, fixed = TRUE),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$organizations == 'NOAA',
  unit$eligibility == 'ineligible',
  !any(stocks$authority_stock_id == '10144', na.rm = TRUE),
  !any(stocks$scientific_name == 'Sparisoma chrysopterum', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE),
  grepl('overfished status was unknown', review, fixed = TRUE),
  grepl('convergence problems for the Puerto Rico SEINE model', review, fixed = TRUE),
  grepl('SEDAR 103 is', review, fixed = TRUE)
)

cache <- file.path(root, 'source_cache', 'discovery_noaa_redtail_parrotfish_2012')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_paths <- file.path(cache, manifest$file)
stopifnot(
  nrow(manifest) == 4L,
  all(file.exists(source_paths)),
  all(file.info(source_paths)$size == manifest$bytes),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  all(grepl('2026-10-30', manifest$retrieved_on, fixed = TRUE)),
  any(grepl('sedar-26-caribbean-redtail', manifest$url, fixed = TRUE))
)

cat('NOAA Caribbean redtail parrotfish source screen checks passed.\n')

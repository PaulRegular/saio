root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
rows <- register[register$candidate_id %in% c('NOAA:10727', 'NOAA:10730'), , drop = FALSE]
parent <- register[register$candidate_id == 'NOAA:11005', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
units_goa <- units[units$candidate_unit_id %in% c('noaa_goa_other_skates',
  'noaa_goa_big_skate', 'noaa_goa_longnose_skate'), , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
afsc <- noaa[noaa$source_region == 'AFSC', , drop = FALSE]
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_skates_2023_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_goa_skate_component_crosswalk_2023.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(rows) == 2L,
  identical(rows$candidate_id, c('NOAA:10727', 'NOAA:10730')),
  identical(rows$candidate_unit_id, c('noaa_goa_big_skate', 'noaa_goa_longnose_skate')),
  identical(rows$scientific_name, c('Raja binoculata', 'Raja rhina')),
  identical(rows$screening_status, c('screened', 'screened')),
  identical(rows$eligibility, c('ineligible', 'ineligible')),
  identical(rows$import_status, c('not_started', 'not_started')),
  grepl('catch numbers-at-age', rows$catch_age_evidence[1], fixed = TRUE),
  grepl('random-effects model', rows$survey_age_evidence[2], fixed = TRUE),
  grepl('M = 0.1', rows$mortality_evidence[1], fixed = TRUE),
  nrow(parent) == 1L,
  parent$candidate_unit_id == 'noaa_goa_other_skates',
  nrow(units_goa) == 3L,
  all(units_goa$inventory_entries == 1L),
  setequal(units_goa$candidate_unit_id, c('noaa_goa_other_skates',
    'noaa_goa_big_skate', 'noaa_goa_longnose_skate')),
  nrow(manifest) == 3L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  afsc$inventory_rows == 89L,
  afsc$screening_complete == 89L,
  afsc$screening_not_started == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L,
  grepl('three distinct current management units', review, fixed = TRUE),
  grepl('8,869 t for Other skates', review, fixed = TRUE))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  !any(stocks$scientific_name %in% c('Raja binoculata', 'Raja rhina'), na.rm = TRUE),
  !any(grepl('noaa_goa_skate_complex', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_goa_skate_complex', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_goa_skate_complex', outputs$assessment_id, fixed = TRUE)))
cat('NOAA Gulf of Alaska Big and Longnose skate component crosswalk checks passed.\n')

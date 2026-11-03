root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c('NOAA:15496', 'NOAA:15558', 'NOAA:15649')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_caribbean_queen_triggerfish_2022_2024.md'), warn = FALSE), collapse = '\n')
cache <- file.path(root, 'source_cache', 'discovery_noaa_caribbean_queen_triggerfish_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(rows) == 3L,
  all(rows$scientific_name == 'Balistes vetula'),
  identical(rows$candidate_unit_id, c('noaa_queen_triggerfish_st_thomas_st_john',
    'noaa_queen_triggerfish_st_croix', 'noaa_queen_triggerfish_puerto_rico')),
  identical(rows$assessment_area, c('St. Thomas / St. John', 'St. Croix', 'Puerto Rico')),
  identical(as.integer(rows$inventory_assessment_year), c(2024L, 2024L, 2022L)),
  all(rows$match_status == 'new'),
  all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'),
  all(rows$import_status == 'not_started'),
  all(grepl('age-composition matrix', rows$catch_age_evidence, ignore.case = TRUE)),
  all(grepl('no fishery-independent age compositions', rows$survey_age_evidence, ignore.case = TRUE)),
  all(grepl('figures', rows$output_evidence, fixed = TRUE)),
  all(grepl('2024 follow-up assessments', rows$decision_reason[1:2], fixed = TRUE)),
  grepl('reviewed in 2022', rows$decision_reason[3], fixed = TRUE),
  nrow(manifest) == 5L,
  all(file.exists(file.path(cache, manifest$file))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(manifest$retrieval_date == '2026-11-02'),
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L,
  grepl('observed age data', review, fixed = TRUE),
  grepl('historical age-composition samples had not been collected', review, fixed = TRUE),
  grepl('numerical age-by-year series', review, fixed = TRUE),
  grepl('short-term management advice', review, fixed = TRUE)
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
  !any(stocks$scientific_name == 'Balistes vetula', na.rm = TRUE),
  !any(grepl('noaa_queen_triggerfish_', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_queen_triggerfish_', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_queen_triggerfish_', outputs$assessment_id, fixed = TRUE))
)
cat('NOAA Caribbean queen triggerfish source-screen checks passed.\n')

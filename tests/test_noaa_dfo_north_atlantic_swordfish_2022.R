root <- '.'
unit_id <- 'iccat_north_atlantic_swordfish'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_ids <- c('NOAA:10953', 'DFO:Maritimes:Swordfish - North Atlantic')
candidates <- register[match(candidate_ids, register$candidate_id), , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
review <- paste(readLines(file.path(root, 'source_reviews',
  'noaa_dfo_north_atlantic_swordfish_2022.md'), warn = FALSE), collapse = '\n')

stopifnot(
  nrow(candidates) == 2L,
  candidates$candidate_unit_id == unit_id,
  candidates$match_status == 'new',
  candidates$screening_status == 'screened',
  candidates$eligibility == 'ineligible',
  candidates$import_status == 'not_started',
  candidates$scientific_name == 'Xiphias gladius',
  candidates$detailed_source_url[1L] == candidates$detailed_source_url[2L],
  grepl('DFO Maritimes Swordfish - North Atlantic are crosswalked',
    candidates$notes[1L], fixed = TRUE),
  grepl('fishery catch-at-age was not reported', candidates$catch_age_evidence[1L], fixed = TRUE),
  grepl('age-specific EU-Spain longline CPUE indices', candidates$survey_age_evidence[1L], fixed = TRUE),
  nrow(unit) == 1L,
  unit$inventory_entries == 2L,
  unit$organizations == 'DFO | NOAA',
  unit$eligibility == 'ineligible',
  !any(stocks$authority_stock_id == '10953', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE),
  grepl('2022 ICCAT assessment using data through 2020', review, fixed = TRUE),
  grepl('North Atlantic MSE work', review, fixed = TRUE),
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L
)

cache <- file.path(root, 'source_cache', 'discovery_swordfish_north_atlantic_2022')
if (dir.exists(cache)) {
  manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
  stopifnot(all(file.exists(file.path(cache, manifest$file))),
    all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)))
}

cat('NOAA/DFO swordfish crosswalk and age-input screen checks passed.\n')

root <- "."
source(file.path(root, 'scripts', 'database',
  '502_screen_noaa_pacific_grenadier_2010.R'))

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10526', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_pacific_grenadier_2010.md'), warn = FALSE), collapse = ' ')
cache <- file.path(root, 'source_cache', 'discovery_noaa_pacific_grenadier_2010')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
pacific <- noaa[noaa$source_region == 'NWFSC / SWFSC', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_pacific_coast_pacific_grenadier',
  is.na(candidate$matched_stock_id),
  candidate$match_status == 'new', candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible', candidate$import_status == 'not_started',
  grepl('aggregated grenadier complex', candidate$catch_age_evidence, fixed = TRUE),
  grepl('age-specific survey index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('life-history assumptions', candidate$mortality_evidence, fixed = TRUE),
  grepl('grenadier complex', candidate$output_evidence, fixed = TRUE),
  grepl('not a species-specific fit', candidate$notes, fixed = TRUE),
  grepl('multispecies grenadier complex', review, fixed = TRUE),
  grepl('ineligible for the age-disaggregated source set', review, fixed = TRUE),
  all(c('noaa_tm_swfc_460_db_sra_2010.pdf',
    'pacific_coast_groundfish_safe_2024_published_2025.pdf') %in% manifest$file),
  all(manifest$status == 'downloaded'),
  sum(units$candidate_unit_id == 'noaa_pacific_coast_pacific_grenadier',
    na.rm = TRUE) == 1L,
  !any(stocks$scientific_name == 'Coryphaenoides acrolepis', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_pacific_coast_pacific_grenadier', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_pacific_coast_pacific_grenadier', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_pacific_coast_pacific_grenadier', na.rm = TRUE),
  sum(noaa$inventory_rows) == 432L, sum(noaa$new) == 388L,
  sum(noaa$identity_unreviewed) == 2L, sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  pacific$new == 130L, pacific$identity_unreviewed == 0L,
  pacific$excluded == 53L, pacific$eligibility_unresolved == 48L,
  pacific$screening_complete == 138L, pacific$screening_not_started == 0L,
  sum(progress$inventory_rows) == 905L, sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L, sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

cat('NOAA Pacific grenadier identity, source, eligibility and no-import checks passed.\n')

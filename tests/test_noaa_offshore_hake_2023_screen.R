root <- "."
source(file.path(root, 'scripts', 'database',
  '501_screen_noaa_offshore_hake_2023.R'))

register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10524', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_offshore_hake_us.md'), warn = FALSE), collapse = ' ')
cache <- file.path(root, 'source_cache', 'discovery_noaa_offshore_hake_2023')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
nefsc <- noaa[noaa$source_region == 'NEFSC', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

stopifnot(nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_offshore_hake_us',
  candidate$scientific_name == 'Merluccius albidus',
  candidate$match_status == 'new', candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible', candidate$import_status == 'not_started',
  candidate$inventory_assessment_year == 2011L,
  grepl('no offshore-hake catch-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('offshore-specific age-abundance index', candidate$survey_age_evidence, fixed = TRUE),
  grepl('rejected because data were insufficient', candidate$decision_reason, fixed = TRUE),
  grepl('not offshore-hake catch-at-age', review, fixed = TRUE),
  grepl('separate offshore-hake population assessment', review, fixed = TRUE),
  all(c('northern_silver_hake_management_track_2023.pdf',
    'small_mesh_multispecies_specs_2024_2026.pdf') %in% manifest$file),
  sum(manifest$status == 'access_denied') == 3L,
  sum(units$candidate_unit_id == 'noaa_offshore_hake_us', na.rm = TRUE) == 1L,
  !any(stocks$scientific_name == 'Merluccius albidus', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_offshore_hake_us', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_offshore_hake_us', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_offshore_hake_us', na.rm = TRUE),
  sum(noaa$inventory_rows) == 432L, sum(noaa$new) == 388L,
  sum(noaa$identity_unreviewed) == 2L, sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L, sum(noaa$screening_complete) == 432L, sum(noaa$screening_not_started) == 0L,
  nefsc$new == 39L, nefsc$identity_unreviewed == 0L,
  nefsc$excluded == 30L, nefsc$screening_complete == 55L,
  nefsc$screening_not_started == 0L,
  sum(progress$inventory_rows) == 905L, sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L, sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L, sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L, sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

cat('NOAA offshore hake identity, source, eligibility, provenance and no-import checks passed.\n')

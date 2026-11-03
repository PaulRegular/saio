root <- "."
source(file.path(root, 'scripts', 'database',
  '503_screen_noaa_coho_2026_additional.R'))

ids <- c(11869L, 11874L, 11875L)
candidate_ids <- paste0('NOAA:', ids)
unit_ids <- paste0('noaa_coho_', ids)
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
rows <- match(candidate_ids, register$candidate_id)
coho <- register[rows, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
pacific <- noaa[noaa$source_region == 'NWFSC / SWFSC', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_coho_2026.md'), warn = FALSE), collapse = ' ')
manifest <- read.csv(file.path(root, 'source_cache',
  'discovery_noaa_coho_2026', 'sources.csv'), stringsAsFactors = FALSE)
cache <- file.path(root, 'source_cache', 'discovery_noaa_coho_2026')
cached_sources <- file.path(cache, manifest$file)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  !anyNA(rows), !anyDuplicated(rows), nrow(coho) == 3L,
  identical(as.character(coho$candidate_unit_id), unit_ids),
  all(coho$match_status == 'new'), all(coho$screening_status == 'screened'),
  all(coho$eligibility == 'ineligible'), all(coho$import_status == 'not_started'),
  all(grepl('adult age class (age 3)', coho$catch_age_evidence, fixed = TRUE)),
  all(grepl('do not provide a multi-age survey', coho$survey_age_evidence,
    fixed = TRUE)),
  all(grepl('2026', coho$decision_reason, fixed = TRUE)),
  all(grepl('2025', coho$decision_reason, fixed = TRUE)),
  all(coho$review_date == '2026-11-01'),
  all(unit_ids %in% units$candidate_unit_id),
  nrow(pacific) == 1L,
  pacific$new == 130L, pacific$identity_unreviewed == 0L,
  pacific$excluded == 53L, pacific$eligibility_unresolved == 48L,
  pacific$screening_complete == 138L, pacific$screening_not_started == 0L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  all(grepl(as.character(ids[1]), review, fixed = TRUE)),
  all(grepl(as.character(ids[2]), review, fixed = TRUE)),
  all(grepl(as.character(ids[3]), review, fixed = TRUE)),
  grepl('single-age-3 forecast', review, fixed = TRUE),
  all(c('Preseason_Report_I_2026.pdf',
    'Review_of_2025_Ocean_Salmon_Fisheries.pdf',
    'Coho_FRAM_Model_Detail_2023.html') %in% manifest$file),
  all(file.exists(cached_sources)),
  all(manifest$retrieved_on == '2026-10-30'),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  !any(as.character(ids) %in% stocks$authority_stock_id),
  !any(unit_ids %in% assessments$assessment_id),
  !any(unit_ids %in% inputs$assessment_id),
  !any(unit_ids %in% outputs$assessment_id))

cat('NOAA 2026 coho additional-unit screen and no-import checks passed.\n')

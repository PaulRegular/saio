source('scripts/database/508_screen_noaa_puget_sound_pink_2025.R')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10576', , drop = FALSE]
review <- readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_puget_sound_pink_2025.md'), warn = FALSE)
review_text <- paste(review, collapse = ' ')

stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_puget_sound_pink_salmon',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  grepl('assessment 14157', row$decision_reason, fixed = TRUE),
  grepl('catch-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('age-specific abundance index', row$survey_age_evidence, fixed = TRUE),
  grepl('basis discrepancy', row$notes, fixed = TRUE),
  grepl('model category 3', review_text, fixed = TRUE),
  grepl('not report catch-at-age or age composition', review_text, fixed = TRUE),
  grepl('not imported into the canonical database', review_text, fixed = TRUE))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_puget_sound_pink_salmon', , drop = FALSE]
stopifnot(nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$screening_status == 'screened', unit$eligibility == 'ineligible')

cache <- file.path(root, 'source_cache', 'noaa_puget_sound_pink_2025')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
files <- c('Review_2024_Ocean_Salmon_Fisheries.pdf',
  'Preseason_I_2025_Ocean_Salmon_Fisheries.pdf',
  'PFMC_Historical_Escapements_Appendix_B.xlsx')
stopifnot(all(files %in% manifest$file),
  all(file.exists(file.path(cache, files))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])),
  all(nzchar(manifest$url[match(files, manifest$file)])))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$authority_stock_id == '10576', na.rm = TRUE),
  !any(grepl('noaa_puget_sound_pink_salmon', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_puget_sound_pink_salmon', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_puget_sound_pink_salmon', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L)

cat('NOAA Puget Sound pink salmon inventory screen passed.\n')

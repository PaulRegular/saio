root <- "."
source(file.path(root, 'scripts', 'database',
  '504_screen_noaa_pfmc_chinook_2026.R'))

stock_ids <- c(10605L, 10606L, 10607L, 10609L, 10611L, 10612L, 10613L,
  10614L, 10615L, 10616L, 10617L, 10618L, 10620L, 10621L, 10622L,
  10623L, 10624L, 10626L, 10627L, 10628L, 10629L, 10630L, 10631L,
  10632L, 10633L, 10634L, 11034L, 11035L, 11870L, 11872L)
candidate_ids <- paste0('NOAA:', stock_ids)
unit_ids <- paste0('noaa_chinook_', stock_ids)
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
rows <- match(candidate_ids, register$candidate_id)
chinook <- register[rows, , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
pacific <- noaa[noaa$source_region == 'NWFSC / SWFSC', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_west_coast_chinook_2026.md'), warn = FALSE), collapse = ' ')
cache <- file.path(root, 'source_cache',
  'discovery_noaa_puget_sound_chinook_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

stopifnot(
  !anyNA(rows), !anyDuplicated(rows), nrow(chinook) == length(stock_ids),
  identical(as.character(chinook$candidate_unit_id), unit_ids),
  all(chinook$match_status == 'new'), all(chinook$screening_status == 'screened'),
  all(chinook$eligibility == 'unresolved'),
  all(chinook$import_status == 'not_started'),
  all(grepl('full-acceptance', chinook$decision_reason, fixed = TRUE)),
  all(grepl('2026', chinook$decision_reason, fixed = TRUE)),
  all(grepl('2025', chinook$decision_reason, fixed = TRUE)),
  all(unit_ids %in% units$candidate_unit_id),
  all(!unit_ids %in% stocks$stock_id),
  all(!unit_ids %in% assessments$assessment_id),
  all(!unit_ids %in% inputs$assessment_id),
  all(!unit_ids %in% outputs$assessment_id),
  grepl('Thirty additional PFMC rows', review, fixed = TRUE),
  grepl('Eligibility therefore remains unresolved', review, fixed = TRUE),
  all(c('Preseason_Report_I_2026.pdf', 'Preseason_Report_II_2026.pdf',
    'Preseason_Report_III_2026.pdf', 'Chinook_FRAM_Model_Detail_2023.html') %in%
      manifest$file),
  all(file.exists(file.path(cache, manifest$file))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
  sum(noaa$inventory_rows) == 432L, sum(noaa$new) == 388L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(pacific) == 1L, pacific$new == 130L,
  pacific$identity_unreviewed == 0L,
  pacific$screening_complete == 138L,
  pacific$screening_not_started == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)

cat('NOAA PFMC Chinook screen and inventory updates passed.\n')

source('scripts/database/509_screen_noaa_far_north_chinook_2024.R')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10604', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_far_north_chinook_2024.md'), warn = FALSE), collapse = ' ')
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_chinook_10604',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  grepl('13942', row$decision_reason, fixed = TRUE),
  grepl('Composition Input Data is 0', row$catch_age_evidence, fixed = TRUE),
  grepl('model category 2', row$survey_age_evidence, fixed = TRUE),
  grepl('22 PSC indicator stocks', row$notes, fixed = TRUE),
  grepl('not overfished', review, fixed = TRUE),
  grepl('not mean catch-at-age', review, fixed = TRUE),
  grepl('No canonical assessment, input, or output rows were added', review, fixed = TRUE))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == 'noaa_chinook_10604', , drop = FALSE]
stopifnot(nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$match_status == 'new', unit$eligibility == 'ineligible',
  unit$screening_status == 'screened')

cache <- file.path(root, 'source_cache', 'noaa_far_north_chinook_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
files <- c('Status_Salmon_Stocks_FMP_2024.pdf',
  'NOAA_Q4_2025_Stock_Status_Tables.pdf', 'StockSMART_DataDictionary.pdf')
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
stopifnot(!any(stocks$authority_stock_id == '10604', na.rm = TRUE),
  !any(grepl('noaa_chinook_10604', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_chinook_10604', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_chinook_10604', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
afsc <- noaa[noaa$source_region == 'AFSC', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  nrow(afsc) == 1L, afsc$inventory_rows == 89L,
  afsc$screening_complete == 89L, afsc$screening_not_started == 0L)
cat('NOAA Far North Migrating Chinook screen passed.\n')

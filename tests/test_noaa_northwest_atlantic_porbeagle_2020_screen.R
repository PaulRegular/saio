source('scripts/database/512_screen_noaa_northwest_atlantic_porbeagle_2020.R')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10654', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_northwest_atlantic_porbeagle_2020.md'), warn = FALSE), collapse = ' ')
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_northwest_atlantic_porbeagle',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  row$inventory_assessment_year == 2021L,
  grepl('full-acceptance record', row$decision_reason, fixed = TRUE),
  grepl('not catch-at-age', row$decision_reason, fixed = TRUE),
  grepl('2018', row$notes, fixed = TRUE),
  grepl('Northwest Atlantic relative biomass', review, fixed = TRUE),
  grepl('not numbers caught at each age', review, fixed = TRUE),
  grepl('does not make an age-specific survey index part', review, fixed = TRUE),
  grepl('ineligible for the age-disaggregated assessment set', review, fixed = TRUE))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_northwest_atlantic_porbeagle', , drop = FALSE]
stopifnot(nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$screening_status == 'screened', unit$eligibility == 'ineligible')

cache <- file.path(root, 'source_cache', 'noaa_northwest_atlantic_porbeagle_2020')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
files <- c('ICCAT_2020_Porbeagle_assessment_meeting.pdf',
  'ICCAT_2024_2025_Porbeagle_executive_summary.pdf')
stopifnot(all(files %in% manifest$file),
  all(file.exists(file.path(cache, files))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])),
  all(nzchar(manifest$url[match(files, manifest$file)])),
  all(!is.na(manifest$revision[match(files, manifest$file)])),
  all(vapply(file.path(cache, files), function(path) {
    con <- file(path, 'rb')
    on.exit(close(con))
    identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
  }, logical(1L))))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$authority_stock_id == '10654', na.rm = TRUE),
  !any(grepl('noaa_northwest_atlantic_porbeagle', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_northwest_atlantic_porbeagle', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_northwest_atlantic_porbeagle', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L)

cat('NOAA Northwestern Atlantic porbeagle source screen passed.\n')

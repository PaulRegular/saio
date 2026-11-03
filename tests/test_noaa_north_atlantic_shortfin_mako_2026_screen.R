source('scripts/database/511_screen_noaa_north_atlantic_shortfin_mako_2026.R')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10657', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_north_atlantic_shortfin_mako_2026.md'), warn = FALSE), collapse = ' ')
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_north_atlantic_shortfin_mako',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'unresolved', row$import_status == 'not_started',
  row$inventory_assessment_year == 2017L,
  grepl('ICCAT 2026', row$decision_reason, fixed = TRUE),
  grepl('age-specific index', row$decision_reason, fixed = TRUE),
  grepl('conditional age-at-length', row$decision_reason, fixed = TRUE),
  grepl('No canonical numerical records were added', row$notes, fixed = TRUE),
  grepl('1950-2024', review, fixed = TRUE),
  grepl('not documented as annual catch-at-age', review, fixed = TRUE),
  grepl('eligibility unresolved', review, fixed = TRUE))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_north_atlantic_shortfin_mako', , drop = FALSE]
stopifnot(nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$screening_status == 'screened', unit$eligibility == 'unresolved')

cache <- file.path(root, 'source_cache', 'noaa_shortfin_mako_north_atlantic_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
files <- c('ICCAT_2026_North_Atlantic_shortfin_mako_meeting_report.pdf',
  'ICCAT_2026_North_Atlantic_shortfin_mako_SS3_runs.pdf')
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
stopifnot(!any(stocks$authority_stock_id == '10657', na.rm = TRUE),
  !any(grepl('noaa_north_atlantic_shortfin_mako', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_north_atlantic_shortfin_mako', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_north_atlantic_shortfin_mako', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
sefsc <- noaa[noaa$source_region == 'SEFSC', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(sefsc) == 1L, sefsc$new == 87L,
  sefsc$identity_unreviewed == 0L,
  sefsc$eligibility_unresolved == 21L,
  sefsc$screening_complete == 90L,
  sefsc$screening_not_started == 0L)

cat('NOAA North Atlantic shortfin mako source screen passed.\n')

source('scripts/database/510_screen_noaa_klamath_spring_chinook_2013.R')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10610', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_klamath_spring_chinook_2013.md'), warn = FALSE), collapse = ' ')
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_klamath_spring_chinook',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  row$inventory_assessment_year == 2013L,
  grepl('assessment 7879', row$decision_reason, fixed = TRUE),
  grepl('grilse, adult, and total bins', row$catch_age_evidence, fixed = TRUE),
  grepl('not an age-specific', row$survey_age_evidence, fixed = TRUE),
  grepl('4,082 adult spawners', row$output_evidence, fixed = TRUE),
  grepl('correspondence to the NOAA component table', row$notes, fixed = TRUE),
  grepl('still lists 2013 as the last assessment', row$decision_reason, fixed = TRUE),
  grepl('age greater than 2', review, fixed = TRUE),
  grepl('1980 through 2023', review, fixed = TRUE),
  grepl('No stock, assessment, input, or output records', review, fixed = TRUE),
  !any(register$candidate_id == 'NOAA:10609' &
    register$candidate_unit_id == row$candidate_unit_id))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_klamath_spring_chinook', , drop = FALSE]
stopifnot(nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$screening_status == 'screened', unit$eligibility == 'ineligible')

cache <- file.path(root, 'source_cache', 'noaa_klamath_spring_chinook_2013')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
files <- c('NOAA_TM_NMFS_SWFSC_502_2013.pdf',
  'NOAA_Q4_FY2025_Appendix_E_Assessment_Data_Gaps.pdf',
  'NOAA_Q4_2025_Stock_Status_Tables.pdf',
  'CDFW_Klamath_Spring_Chinook_Megatable_1980-2022.pdf',
  'CDFW_Klamath_Spring_Chinook_Megatable_1980-2023.pdf')
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
stopifnot(!any(stocks$authority_stock_id == '10610', na.rm = TRUE),
  !any(grepl('noaa_klamath_spring_chinook', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_klamath_spring_chinook', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_klamath_spring_chinook', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
swfsc <- noaa[noaa$source_region == 'NWFSC / SWFSC', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(swfsc) == 1L, swfsc$new == 130L,
  swfsc$identity_unreviewed == 0L, swfsc$excluded == 53L,
  swfsc$eligibility_unresolved == 48L,
  swfsc$screening_complete == 138L,
  swfsc$screening_not_started == 0L)

cat('NOAA Klamath spring Chinook source screen passed.\n')

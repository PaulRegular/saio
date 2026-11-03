source('scripts/database/507_screen_noaa_auke_creek_coho_2024.R')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10580', , drop = FALSE]
unit <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- unit[!is.na(unit$candidate_unit_id) &
  unit$candidate_unit_id == 'noaa_auke_creek_coho_southeast_alaska', , drop = FALSE]
review <- readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_auke_creek_coho_2024.md'), warn = FALSE)

stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_auke_creek_coho_southeast_alaska',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'ineligible', row$import_status == 'not_started',
  grepl('assessment 13939', row$decision_reason, fixed = TRUE),
  grepl('age-specific smolt samples', row$survey_age_evidence, fixed = TRUE),
  grepl('not multi-age population inputs', row$survey_age_evidence, fixed = TRUE),
  grepl('age-structured SSB outputs', row$output_evidence, fixed = TRUE),
  nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$screening_status == 'screened', unit$eligibility == 'ineligible',
  any(grepl('ages 1 and 2', review, fixed = TRUE)),
  any(grepl('not mean that independent Auke Creek research has never collected ages',
    review, fixed = TRUE)),
  any(grepl('No canonical numerical', review, fixed = TRUE)))

cache <- file.path(root, 'source_cache', 'noaa_auke_creek_coho_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stopifnot(all(c('Status_Deter_SE_AK_2024.pdf',
    'FMS24-04_Southeast_Alaska_Salmon_Escapement_Goals.pdf',
    'StockSMART_DataDictionary.pdf') %in% manifest$file),
  all(file.exists(file.path(cache, manifest$file))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$authority_stock_id == '10580', na.rm = TRUE),
  !any(grepl('noaa_auke_creek_coho_2024', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_auke_creek_coho_2024', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_auke_creek_coho_2024', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
afsc <- noaa[noaa$source_region == 'AFSC', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(afsc) == 1L, afsc$screening_complete == 89L,
  afsc$screening_not_started == 0L)

cat('NOAA Auke Creek coho source screen passed.\n')

root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/475_screen_noaa_spiny_dogfish_2021.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10702', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
progress <- read.csv(file.path(root, 'discovery/inventory_progress.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
nw <- noaa[noaa$source_region == 'NWFSC / SWFSC', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
review_path <- file.path(root, 'discovery/source_reviews/noaa_pacific_spiny_dogfish_2021.md')
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')

stopifnot(
  nrow(candidate) == 1L,
  candidate$scientific_name == 'Squalus acanthias',
  candidate$inventory_assessment_year == 2021,
  candidate$candidate_unit_id == 'noaa_spiny_dogfish_pacific_coast_2021',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  grepl('not observed catch-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('2010 WCGBTS conditional age-at-length', candidate$survey_age_evidence, fixed = TRUE),
  grepl('fixed at 0.065', candidate$mortality_evidence, fixed = TRUE),
  grepl('not direct inputs', candidate$decision_reason, fixed = TRUE),
  grepl('does not use observed fishery catch-at-age', review, fixed = TRUE),
  grepl('single survey-year age sample', review, fixed = TRUE),
  sum(stocks$stock_id == candidate$candidate_unit_id, na.rm = TRUE) == 0L,
  sum(assessments$stock_id == candidate$candidate_unit_id, na.rm = TRUE) == 0L,
  sum(inputs$assessment_id == candidate$candidate_unit_id, na.rm = TRUE) == 0L,
  sum(outputs$assessment_id == candidate$candidate_unit_id, na.rm = TRUE) == 0L,
  sum(units$candidate_unit_id == candidate$candidate_unit_id, na.rm = TRUE) == 1L,
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L,
  sum(noaa$ambiguous) == 14L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$eligible) == 89L,
  sum(noaa$eligible_new) == 75L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(nw) == 1L,
  nw$new == 130L,
  nw$eligible == 37L,
  nw$eligible_new == 36L,
  nw$screening_complete == 138L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

cat('NOAA Pacific Coast spiny dogfish screening, provenance, reconstruction caveats, and no-import checks passed.\n')

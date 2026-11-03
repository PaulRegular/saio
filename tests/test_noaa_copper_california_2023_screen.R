root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/476_screen_noaa_copper_california_2023.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidates <- register[register$candidate_id %in% c('NOAA:15332', 'NOAA:15333'), , drop = FALSE]
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
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_copper_rockfish_california_2023.md'), warn = FALSE), collapse = ' ')

stopifnot(nrow(candidates) == 2L,
  identical(screen$north$catch_units, 1L), identical(screen$south$catch_units, 1L),
  identical(candidates$candidate_id, c('NOAA:15332', 'NOAA:15333')),
  identical(candidates$scientific_name, c('Sebastes caurinus', 'Sebastes caurinus')),
  identical(candidates$candidate_unit_id,
    c('noaa_copper_rockfish_california_2023', 'noaa_copper_rockfish_california_2023')),
  all(candidates$match_status == 'new'), all(candidates$screening_status == 'screened'),
  all(candidates$eligibility == 'eligible'), all(candidates$import_status == 'not_started'),
  all(grepl('not observed annual catch numbers-at-age', candidates$catch_age_evidence, fixed = TRUE)),
  all(grepl('do not contain a direct annual abundance-at-age index', candidates$survey_age_evidence, fixed = TRUE)),
  all(grepl('fixed at 0.108', candidates$mortality_evidence, fixed = TRUE)),
  all(grepl('ages 0-50', candidates$output_evidence, fixed = TRUE)),
  grepl('one California assessment family', review, fixed = TRUE),
  grepl('450 conditional age-at-length rows', review, fixed = TRUE),
  grepl('747 conditional age-at-length rows', review, fixed = TRUE),
  sum(stocks$stock_id == 'noaa_copper_rockfish_california_2023', na.rm = TRUE) == 0L,
  sum(assessments$assessment_id == 'noaa_copper_rockfish_california_2023', na.rm = TRUE) == 0L,
  sum(inputs$assessment_id == 'noaa_copper_rockfish_california_2023', na.rm = TRUE) == 0L,
  sum(outputs$assessment_id == 'noaa_copper_rockfish_california_2023', na.rm = TRUE) == 0L,
  sum(units$candidate_unit_id == 'noaa_copper_rockfish_california_2023', na.rm = TRUE) == 1L,
  units$inventory_entries[units$candidate_unit_id %in% 'noaa_copper_rockfish_california_2023'] == 2L,
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$eligible) == 89L, sum(noaa$eligible_new) == 75L,
  sum(noaa$eligibility_unresolved) == 91L, sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(nw) == 1L, nw$new == 130L, nw$eligible == 37L,
  nw$eligible_new == 36L, nw$screening_complete == 138L,
  nrow(units) == 736L, sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

cat('NOAA California copper 2023 age-composition, source-integrity, crosswalk and no-import checks passed.\n')

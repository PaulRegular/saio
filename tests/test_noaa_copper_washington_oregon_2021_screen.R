root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/477_screen_noaa_copper_washington_oregon_2021.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidates <- register[register$candidate_id %in% c('NOAA:15330', 'NOAA:15331'), , drop = FALSE]
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
  'discovery/source_reviews/noaa_copper_rockfish_washington_oregon_2021.md'), warn = FALSE),
  collapse = ' ')

stopifnot(nrow(candidates) == 2L,
  identical(candidates$candidate_id, c('NOAA:15330', 'NOAA:15331')),
  identical(candidates$candidate_unit_id,
    c('noaa_copper_rockfish_washington_2021', 'noaa_copper_rockfish_oregon_2021')),
  identical(candidates$assessment_area,
    c('Washington', 'Oregon')),
  all(candidates$scientific_name == 'Sebastes caurinus'),
  all(candidates$inventory_assessment_year == '2021'),
  all(candidates$match_status == 'new'), all(candidates$screening_status == 'screened'),
  all(candidates$eligibility == 'ineligible'), all(candidates$import_status == 'not_started'),
  all(grepl('no annual catch-at-age', candidates$catch_age_evidence, fixed = TRUE)),
  all(grepl('fixed at 0.108', candidates$mortality_evidence, fixed = TRUE)),
  grepl('not used', candidates$survey_age_evidence[candidates$candidate_id == 'NOAA:15331'], fixed = TRUE),
  grepl('distinct assessment units', review, fixed = TRUE),
  grepl('Neither base model fits annual catch-at-age', review, fixed = TRUE),
  sum(stocks$stock_id %in% c('noaa_copper_rockfish_washington_2021',
    'noaa_copper_rockfish_oregon_2021'), na.rm = TRUE) == 0L,
  sum(assessments$assessment_id %in% candidates$candidate_unit_id, na.rm = TRUE) == 0L,
  sum(inputs$assessment_id %in% candidates$candidate_unit_id, na.rm = TRUE) == 0L,
  sum(outputs$assessment_id %in% candidates$candidate_unit_id, na.rm = TRUE) == 0L,
  sum(units$candidate_unit_id %in% candidates$candidate_unit_id, na.rm = TRUE) == 2L,
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$new) == 388L, sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$excluded) == 252L, sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L, sum(noaa$screening_not_started) == 0L,
  nrow(nw) == 1L, nw$new == 130L, nw$excluded == 53L,
  nw$eligibility_unresolved == 48L, nw$screening_complete == 138L,
  nw$screening_not_started == 0L,
  nrow(units) == 736L, sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

cat('NOAA Washington/Oregon copper 2021 source-integrity, exclusion, and no-import checks passed.\n')

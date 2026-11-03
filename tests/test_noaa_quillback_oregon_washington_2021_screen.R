root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/489_screen_noaa_quillback_oregon_washington_2021.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
oregon <- register[register$candidate_id == 'NOAA:15340', , drop = FALSE]
washington <- register[register$candidate_id == 'NOAA:15341', , drop = FALSE]
or_review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_quillback_rockfish_oregon_2021.md'), warn = FALSE),
  collapse = ' ')
wa_review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_quillback_rockfish_washington_2021.md'), warn = FALSE),
  collapse = ' ')

stopifnot(nrow(oregon) == 1L, nrow(washington) == 1L,
  oregon$candidate_unit_id == 'noaa_quillback_rockfish_oregon',
  washington$candidate_unit_id == 'noaa_quillback_rockfish_washington',
  oregon$assessment_area == 'Oregon', washington$assessment_area == 'Washington',
  oregon$match_status == 'new', washington$match_status == 'new',
  oregon$screening_status == 'screened', washington$screening_status == 'screened',
  oregon$eligibility == 'ineligible', washington$eligibility == 'ineligible',
  oregon$import_status == 'not_started', washington$import_status == 'not_started',
  grepl('comments them out', oregon$catch_age_evidence, fixed = TRUE),
  grepl('comments out', washington$catch_age_evidence, fixed = TRUE),
  grepl('no survey fleet or abundance-index observations', oregon$survey_age_evidence, fixed = TRUE),
  grepl('0.057 per year', washington$mortality_evidence, fixed = TRUE),
  grepl('Report.sso', oregon$output_evidence, fixed = TRUE),
  grepl('must not be pooled', or_review, fixed = TRUE),
  grepl('Amendment 37', wa_review, fixed = TRUE),
  sum(units$candidate_unit_id %in% c('noaa_quillback_rockfish_oregon',
    'noaa_quillback_rockfish_washington'), na.rm = TRUE) == 2L,
  all(units$inventory_entries[units$candidate_unit_id %in% c(
    'noaa_quillback_rockfish_oregon', 'noaa_quillback_rockfish_washington')] == 1L),
  sum(stocks$authority_stock_id %in% c('15340', '15341'), na.rm = TRUE) == 0L,
  sum(assessments$stock_id %in% c('noaa_quillback_rockfish_oregon',
    'noaa_quillback_rockfish_washington'), na.rm = TRUE) == 0L,
  sum(inputs$assessment_id %in% c('noaa_quillback_rockfish_oregon',
    'noaa_quillback_rockfish_washington'), na.rm = TRUE) == 0L,
  sum(outputs$assessment_id %in% c('noaa_quillback_rockfish_oregon',
    'noaa_quillback_rockfish_washington'), na.rm = TRUE) == 0L)

cat('NOAA quillback identity, source-screen, and no-import checks passed.\n')

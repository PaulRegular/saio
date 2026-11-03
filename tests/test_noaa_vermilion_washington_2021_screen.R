root <- "."
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/488_screen_noaa_vermilion_washington_2021.R'), local = screen)
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
components <- register[register$candidate_id %in% c('NOAA:15338', 'NOAA:15339'), , drop = FALSE]
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_vermilion_rockfish_or_wa', , drop = FALSE]
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_vermilion_rockfish_washington_2021.md'), warn = FALSE),
  collapse = ' ')

stopifnot(nrow(components) == 2L,
  all(components$candidate_unit_id == 'noaa_vermilion_rockfish_or_wa'),
  all(components$match_status == 'new'),
  all(components$screening_status == 'screened'),
  all(components$eligibility == 'eligible'),
  all(components$import_status == 'not_started'),
  all(components$scientific_name == 'Sebastes miniatus'),
  components$assessment_area[components$candidate_id == 'NOAA:15338'] == 'Oregon',
  components$assessment_area[components$candidate_id == 'NOAA:15339'] == 'Washington',
  nrow(unit) == 1L, unit$inventory_entries == 2L,
  grepl('conditional age-at-length', components$catch_age_evidence[components$candidate_id == 'NOAA:15339'],
    fixed = TRUE),
  grepl('no abundance index', components$survey_age_evidence[components$candidate_id == 'NOAA:15339'],
    fixed = TRUE),
  grepl('NUMBERS_AT_AGE', components$output_evidence[components$candidate_id == 'NOAA:15339'],
    fixed = TRUE),
  grepl('OR/WA', review, fixed = TRUE),
  grepl('a pooled OR/WA model', review, fixed = TRUE),
  sum(stocks$authority_stock_id %in% c('15338', '15339'), na.rm = TRUE) == 0L,
  sum(stocks$stock_id == 'noaa_vermilion_rockfish_or_wa', na.rm = TRUE) == 0L,
  sum(assessments$stock_id == 'noaa_vermilion_rockfish_or_wa', na.rm = TRUE) == 0L,
  sum(inputs$assessment_id == 'noaa_vermilion_rockfish_or_wa', na.rm = TRUE) == 0L,
  sum(outputs$assessment_id == 'noaa_vermilion_rockfish_or_wa', na.rm = TRUE) == 0L)

cat('NOAA Vermilion OR/WA identity, component screen and no-import checks passed.\n')

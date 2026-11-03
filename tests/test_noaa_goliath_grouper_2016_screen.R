root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/480_screen_noaa_goliath_grouper_2016.R'), local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate_ids <- c('NOAA:10315', 'NOAA:11042')
candidates <- register[match(candidate_ids, register$candidate_id), , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id ==
  'noaa_goliath_grouper_southeastern_us_2016', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
review <- paste(readLines(file.path(root,
  'discovery/source_reviews/noaa_goliath_grouper_2016.md'), warn = FALSE),
  collapse = ' ')

stopifnot(nrow(candidates) == 2L,
  all(candidates$candidate_unit_id == 'noaa_goliath_grouper_southeastern_us_2016'),
  all(candidates$scientific_name == 'Epinephelus itajara'),
  all(candidates$inventory_assessment_year == '2016'),
  identical(candidates$assessment_area,
    c('Gulf of Mexico', 'Southern Atlantic Coast / Gulf of Mexico')),
  all(candidates$match_status == 'new'),
  all(candidates$screening_status == 'screened'),
  all(candidates$eligibility == 'ineligible'),
  all(candidates$import_status == 'not_started'),
  all(grepl('no age structure', candidates$catch_age_evidence, fixed = TRUE)),
  all(grepl('22 adult', candidates$catch_age_evidence, fixed = TRUE)),
  all(grepl('rejected', candidates$output_evidence, ignore.case = TRUE)),
  nrow(unit) == 1L, unit$match_status == 'new',
  unit$eligibility == 'ineligible', unit$screening_status == 'screened',
  unit$inventory_entries == 2L,
  grepl('same SEDAR 47 assessment family', review, fixed = TRUE),
  grepl('not adequate for status inferences', review, fixed = TRUE),
  !any(stocks$scientific_name == 'Epinephelus itajara', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_goliath_grouper_southeastern_us_2016',
    na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_goliath_grouper_southeastern_us_2016',
    na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_goliath_grouper_southeastern_us_2016',
    na.rm = TRUE))

cat('NOAA goliath grouper identity, exclusion, provenance, and no-import checks passed.\n')

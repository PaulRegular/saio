root <- '.'
candidate_id <- 'NOAA:10559'
unit_id <- 'noaa_goa_dusky'
cache <- file.path(root, 'source_cache', 'discovery_noaa_dusky_rockfish_2024')
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- register[register$candidate_id == candidate_id, , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_dusky_rockfish_goa_2024.md'), warn = FALSE), collapse = ' ')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
unit <- units[units$unit_key == paste0('candidate:', unit_id), , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == unit_id,
  row$official_stock_id == '10559',
  row$scientific_name == 'Sebastes variabilis',
  row$inventory_assessment_year == 2024,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'eligible',
  row$import_status == 'not_started',
  grepl('1977-2024', row$catch_age_evidence, fixed = TRUE),
  grepl('1990-2023', row$survey_age_evidence, fixed = TRUE),
  grepl('30+', row$survey_age_evidence, fixed = TRUE),
  grepl('1928 g', row$weights_evidence, fixed = TRUE),
  grepl('10.3', row$maturity_evidence, fixed = TRUE),
  grepl('M=0.07', row$mortality_evidence, fixed = TRUE),
  grepl('fractional within-year survey timing', row$timing_evidence, fixed = TRUE),
  grepl('pre-dissemination peer-review harvest projection', row$output_evidence, fixed = TRUE),
  grepl('2027', row$decision_reason, fixed = TRUE),
  grepl('fishery age-sample year discrepancy', row$decision_reason, fixed = TRUE),
  grepl('pre-dissemination peer-review harvest projection', review, fixed = TRUE),
  grepl('ages 4–29 and a pooled 30+', review, fixed = TRUE),
  nrow(manifest) == 2L,
  all(file.exists(file.path(cache, manifest$file))),
  all(file.info(file.path(cache, manifest$file))$size == manifest$bytes),
  all(nzchar(manifest$url)),
  all(nzchar(manifest$sha256)),
  nrow(unit) == 1L,
  unit$eligibility == 'eligible',
  any(grepl(candidate_id, unit$candidate_ids, fixed = TRUE)),
  !any(stocks$authority_stock_id == '10559', na.rm = TRUE),
  !any(stocks$scientific_name == 'Sebastes variabilis', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id, na.rm = TRUE),
  !any(inputs$assessment_id == unit_id, na.rm = TRUE),
  !any(outputs$assessment_id == unit_id, na.rm = TRUE)
)

cat('NOAA dusky rockfish identity, current assessment, source evidence and no-import checks passed.\n')

old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts', 'database', '402_screen_noaa_dusky_rockfish_2024.R'))
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv('TAM_SOURCE_DRY_RUN', old_dry_run)

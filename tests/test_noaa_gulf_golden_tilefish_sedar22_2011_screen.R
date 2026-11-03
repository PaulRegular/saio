root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root,
  'scripts/database/482_screen_noaa_gulf_golden_tilefish_sedar22_2011.R'),
  local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10383', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_gulf_golden_tilefish', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
review <- paste(readLines(file.path(root, 'discovery/source_reviews',
  'noaa_golden_tilefish_gulf_sedar22_2011.md'), warn = FALSE), collapse = ' ')
stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
smart <- stocksmart_env$stock_assessment_summary
smart_row <- smart[smart$stock_id == 10383L, , drop = FALSE]

stopifnot(nrow(candidate) == 1L,
  candidate$official_stock_id == '10383',
  candidate$scientific_name == 'Lopholatilus chamaeleonticeps',
  candidate$stock_name == 'Tilefish - Gulf of Mexico',
  candidate$inventory_assessment_year == '2011',
  candidate$candidate_unit_id == 'noaa_gulf_golden_tilefish',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  grepl('conditional on 2-cm length bin', candidate$catch_age_evidence, fixed = TRUE),
  grepl('ages 2-30+', candidate$catch_age_evidence, fixed = TRUE),
  grepl('Status determinations only', candidate$notes, fixed = TRUE),
  grepl('Table 3.7', candidate$output_evidence, fixed = TRUE),
  grepl('not capture stock dynamics', candidate$decision_reason, fixed = TRUE),
  nrow(unit) == 1L, unit$match_status == 'new',
  unit$screening_status == 'screened', unit$eligibility == 'eligible',
  unit$inventory_entries == 1L,
  nrow(smart_row) == 1L, smart_row$assessment_id == 3057L,
  smart_row$assessment_year == 2011L, smart_row$last_data_year == 2009L,
  smart_row$review_result == 'Partial acceptance - Status determinations only',
  grepl('Gulf SSC concluded', review, fixed = TRUE),
  grepl('2026 preliminary data triage', review, fixed = TRUE),
  !any(stocks$scientific_name == 'Lopholatilus chamaeleonticeps', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_gulf_golden_tilefish', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_gulf_golden_tilefish', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_gulf_golden_tilefish', na.rm = TRUE))

cat('NOAA Gulf golden tilefish identity, conditional age-input screen, official-advice caveat, provenance and no-import checks passed.\n')

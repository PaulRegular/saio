root <- '.'
old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
screen <- new.env(parent = globalenv())
source(file.path(root, 'scripts/database/483_screen_noaa_bank_rockfish_california_2010.R'),
  local = screen)
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else
  Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
candidate <- register[register$candidate_id == 'NOAA:10448', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_bank_rockfish_california', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery/source_reviews',
  'noaa_bank_rockfish_california_2010.md'), warn = FALSE), collapse = ' ')
stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache/discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
smart <- get('stock_assessment_summary', envir = stocksmart_env)
smart_row <- smart[as.character(smart$stock_id) == '10448', , drop = FALSE]
manifest <- read.csv(file.path(root, 'source_cache/discovery_noaa_bank_rockfish_california',
  'sources.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

stopifnot(nrow(candidate) == 1L,
  candidate$official_stock_id == '10448',
  candidate$scientific_name == 'Sebastes rufus',
  candidate$stock_name == 'Bank rockfish - California',
  candidate$assessment_area == 'California',
  candidate$inventory_assessment_year == '2010',
  candidate$candidate_unit_id == 'noaa_bank_rockfish_california',
  candidate$match_status == 'new', candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible', candidate$import_status == 'not_started',
  grepl('2010 DB-SRA', candidate$catch_age_evidence, fixed = TRUE),
  grepl('5,064 commercial age readings', candidate$catch_age_evidence, fixed = TRUE),
  grepl('does not fit', candidate$catch_age_evidence, fixed = TRUE),
  grepl('94.3 mt', candidate$output_evidence, fixed = TRUE),
  grepl('585.0 mt', candidate$output_evidence, fixed = TRUE),
  grepl('0.09 probability', candidate$output_evidence, fixed = TRUE),
  grepl('2000 California-only', candidate$notes, fixed = TRUE),
  nrow(unit) == 1L, unit$match_status == 'new',
  unit$screening_status == 'screened', unit$eligibility == 'ineligible',
  unit$inventory_entries == 1L,
  nrow(smart_row) == 1L, smart_row$assessment_id == 11866L,
  smart_row$assessment_year == 2010L, smart_row$last_data_year == 2009L,
  smart_row$assessment_model == 'DB-SRA',
  grepl('cited Pacific Council URL returned 404', review, fixed = TRUE),
  nrow(manifest) == 3L,
  !any(stocks$scientific_name == 'Sebastes rufus', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_bank_rockfish_california', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_bank_rockfish_california', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_bank_rockfish_california', na.rm = TRUE))

cat('NOAA California bank rockfish assessment identity, DB-SRA age-input exclusion, provenance and no-import checks passed.\n')


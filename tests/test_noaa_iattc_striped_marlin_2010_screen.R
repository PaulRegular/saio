source('scripts/database/464_screen_noaa_iattc_striped_marlin_2010.R')
source('scripts/database/195_summarize_discovery.R')
source('scripts/database/196_summarize_inventory_units.R')
root <- "."
candidate <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- candidate[candidate$candidate_id == 'NOAA:11073', , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
manifest <- read.csv(file.path(root, 'source_cache',
  'discovery_noaa_iattc_striped_marlin_2010', 'sources.csv'),
  stringsAsFactors = FALSE)
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE)

stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'iattc_northeast_pacific_striped_marlin',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('no age-at-length data were available', row$catch_age_evidence, fixed = TRUE),
  grepl('standardized aggregate longline CPUE', row$survey_age_evidence, fixed = TRUE),
  grepl('annual spawning biomass and recruitment', row$output_evidence, fixed = TRUE),
  grepl('No-11-2011_Status-of-the-tuna-and-billfish-stocks-in-2009.pdf',
    row$detailed_source_url, fixed = TRUE),
  all(file.exists(file.path(root, 'source_cache',
    'discovery_noaa_iattc_striped_marlin_2010', manifest$file))),
  !any(stocks$authority_stock_id == '11073', na.rm = TRUE),
  !any(stocks$scientific_name == 'Kajikia audax', na.rm = TRUE),
  !any(assessments$assessment_id == 'iattc_northeast_pacific_striped_marlin', na.rm = TRUE),
  !any(inputs$assessment_id == 'iattc_northeast_pacific_striped_marlin', na.rm = TRUE),
  !any(outputs$assessment_id == 'iattc_northeast_pacific_striped_marlin', na.rm = TRUE),
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
cat('NOAA:11073 IATTC striped marlin source-screening checks passed.\n')

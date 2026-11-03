root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:10553', 'NOAA:10554')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
bsai_review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_shortraker_bsai_2024.md'), warn = FALSE), collapse = ' ')
goa_review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_shortraker_goa_2023.md'), warn = FALSE), collapse = ' ')
manifest <- read.csv(file.path(root, 'source_cache', 'discovery_noaa_shortraker_2023_2025',
  'sources.csv'), stringsAsFactors = FALSE)

stopifnot(
  nrow(rows) == 2L,
  rows$candidate_id[1] == 'NOAA:10553',
  rows$candidate_id[2] == 'NOAA:10554',
  rows$candidate_unit_id[1] == 'noaa_bsai_shortraker',
  rows$candidate_unit_id[2] == 'noaa_goa_shortraker',
  all(rows$scientific_name == 'Sebastes borealis'),
  all(rows$match_status == 'new'),
  all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'),
  all(rows$import_status == 'not_started'),
  rows$inventory_assessment_year[1] == 2024,
  rows$inventory_assessment_year[2] == 2023,
  grepl('Model 22_2024', rows$decision_reason[1], fixed = TRUE),
  grepl('Model 23.3', rows$decision_reason[2], fixed = TRUE),
  grepl('few fishery age samples had not been aged', rows$catch_age_evidence[2], fixed = TRUE),
  grepl('fixed at 0.03', rows$mortality_evidence[2], fixed = TRUE),
  grepl('Model 22_2024', bsai_review, fixed = TRUE),
  grepl('recommended the authors', bsai_review, fixed = TRUE),
  grepl('no numeric annual N-at-age or F-at-age', bsai_review, fixed = TRUE),
  grepl('2025 update was not completed', goa_review, fixed = TRUE),
  grepl('few fishery age samples had not been aged', goa_review, fixed = TRUE),
  grepl('not age-composition likelihood inputs', goa_review, fixed = TRUE),
  nrow(manifest) == 5L,
  all(file.exists(file.path(root, 'source_cache', 'discovery_noaa_shortraker_2023_2025',
    manifest$file))),
  any(grepl('NOAA:10553', units$candidate_ids, fixed = TRUE)),
  any(grepl('NOAA:10554', units$candidate_ids, fixed = TRUE)),
  all(units$candidate_unit_id[match(c('noaa_bsai_shortraker', 'noaa_goa_shortraker'),
    units$candidate_unit_id)] %in% c('noaa_bsai_shortraker', 'noaa_goa_shortraker')),
  !any(stocks$authority_stock_id %in% c('10553', '10554'), na.rm = TRUE),
  !any(stocks$scientific_name == 'Sebastes borealis', na.rm = TRUE),
  !any(assessments$assessment_id %in% c('noaa_bsai_shortraker_2024',
    'noaa_goa_shortraker_2023'), na.rm = TRUE),
  !any(inputs$assessment_id %in% c('noaa_bsai_shortraker_2024',
    'noaa_goa_shortraker_2023'), na.rm = TRUE),
  !any(outputs$assessment_id %in% c('noaa_bsai_shortraker_2024',
    'noaa_goa_shortraker_2023'), na.rm = TRUE)
)

cat('NOAA BSAI and GOA shortraker identity, source, ineligibility and no-import checks passed.\n')

old_dry_run <- Sys.getenv("TAM_SOURCE_DRY_RUN", unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = "1")
source(file.path(root, "scripts", "database", "394_screen_noaa_shortraker_2023_2024.R"))
if (is.na(old_dry_run)) Sys.unsetenv("TAM_SOURCE_DRY_RUN") else Sys.setenv(TAM_SOURCE_DRY_RUN = old_dry_run)


root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[match('NOAA:10956', register$candidate_id), , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_alaska_sablefish_2024.md'), warn = FALSE), collapse = ' ')
cache <- file.path(root, 'source_cache', 'discovery_noaa_alaska_sablefish_2024_2025')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_alaska_sablefish',
  row$official_stock_id == '10956',
  row$scientific_name == 'Anoplopoma fimbria',
  row$assessment_area == 'Eastern Bering Sea / Aleutian Islands / Gulf of Alaska',
  row$inventory_assessment_year == 2024,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'eligible',
  row$import_status == 'not_started',
  grepl('1999-2023', row$catch_age_evidence, fixed = TRUE),
  grepl('1996-2023', row$survey_age_evidence, fixed = TRUE),
  grepl('Table 3C.1', row$weights_evidence, fixed = TRUE),
  grepl('0.114', row$mortality_evidence, fixed = TRUE),
  grepl('fractional within-year timing', row$timing_evidence, fixed = TRUE),
  grepl('female and male N-at-age', row$output_evidence, fixed = TRUE),
  grepl('latest full production assessment located is the 2024 Model 23.5', row$decision_reason, fixed = TRUE),
  grepl('no 2025 assessment', row$decision_reason, fixed = TRUE),
  grepl('trawl fleet', row$catch_age_evidence, fixed = TRUE),
  grepl('31+', row$weights_evidence, fixed = TRUE),
  grepl('31+', review, fixed = TRUE),
  grepl('published numeric F-at-age table was not located', review, fixed = TRUE),
  nrow(manifest) == 14L,
  all(file.exists(file.path(cache, manifest$file))),
  any(grepl('NOAA:10956', units$candidate_ids, fixed = TRUE)),
  !any(stocks$authority_stock_id == '10956', na.rm = TRUE),
  !any(assessments$assessment_id == 'noaa_alaska_sablefish_2024', na.rm = TRUE),
  !any(inputs$assessment_id == 'noaa_alaska_sablefish_2024', na.rm = TRUE),
  !any(outputs$assessment_id == 'noaa_alaska_sablefish_2024', na.rm = TRUE)
)

cat('NOAA Alaska sablefish identity, source, eligibility and no-import checks passed.\n')

old_dry_run <- Sys.getenv('TAM_SOURCE_DRY_RUN', unset = NA_character_)
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts', 'database', '395_screen_noaa_alaska_sablefish_2024.R'))
if (is.na(old_dry_run)) Sys.unsetenv('TAM_SOURCE_DRY_RUN') else Sys.setenv('TAM_SOURCE_DRY_RUN' = old_dry_run)

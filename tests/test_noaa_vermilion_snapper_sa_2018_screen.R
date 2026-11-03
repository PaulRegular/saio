root <- "."
candidates <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- candidates[candidates$candidate_id == 'NOAA:10257', , drop = FALSE]
gulf <- candidates[candidates$candidate_id == 'NOAA:10256', , drop = FALSE]
unit_id <- 'noaa_vermilion_snapper_south_atlantic'
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10257 & stocksmart$assessment_id == 8220,
  , drop = FALSE]
review_path <- file.path(root, 'discovery', 'source_reviews',
  'noaa_vermilion_snapper_south_atlantic_2018.md')
script_path <- file.path(root, 'scripts', 'database',
  '459_screen_noaa_vermilion_snapper_sa_2018.R')

stopifnot(
  nrow(row) == 1L,
  nrow(gulf) == 1L,
  row$candidate_unit_id == unit_id,
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'eligible',
  row$import_status == 'not_started',
  row$scientific_name == gulf$scientific_name,
  row$assessment_area == 'Southern Atlantic Coast',
  gulf$assessment_area == 'Gulf of Mexico',
  row$candidate_unit_id != gulf$candidate_unit_id,
  grepl('SEDAR 55', row$catch_age_evidence, fixed = TRUE),
  grepl('age 12 as the plus group', row$catch_age_evidence, fixed = TRUE),
  grepl('SERFS chevron-trap', row$survey_age_evidence, fixed = TRUE),
  grepl('1,000 lb whole weight', row$catch_age_evidence, fixed = TRUE),
  grepl('egg production', row$maturity_evidence, fixed = TRUE),
  grepl('Lorenzen', row$mortality_evidence, fixed = TRUE),
  grepl('midyear', row$timing_evidence, fixed = TRUE),
  grepl('abundance-at-age', row$output_evidence, fixed = TRUE),
  nrow(run) == 1L,
  run$assessment_year == 2018L,
  run$last_data_year == 2016L,
  run$assessment_model == 'Beaufort Statistical Catch-at-Age Model',
  run$review_result == 'Full acceptance',
  run$assessment_type == 'Full Update',
  !any(stocks$authority == 'NOAA' & stocks$authority_stock_id == '10257', na.rm = TRUE),
  !any(assessments$assessment_id == unit_id),
  !any(inputs$assessment_id == unit_id),
  !any(outputs$assessment_id == unit_id),
  file.exists(review_path),
  file.exists(script_path)
)

cache <- file.path(root, 'source_cache',
  'discovery_noaa_south_atlantic_vermilion_2026')
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
  paths <- file.path(cache, manifest$file)
  stopifnot(
    nrow(manifest) == 10L,
    all(file.exists(paths)),
    all(file.info(paths)$size == manifest$bytes),
    all(grepl('^[[:xdigit:]]{64}$', manifest$sha256)),
    all(manifest$retrieved_utc == '2026-10-31'),
    any(grepl('sedarweb.org', manifest$url, fixed = TRUE)),
    any(grepl('SAFMC SSC final report, October 2023', manifest$revision, fixed = TRUE)),
    any(grepl('September 2026 meeting', manifest$revision, fixed = TRUE))
  )
}

cat('NOAA South Atlantic Vermilion Snapper candidate-screening checks passed.\n')

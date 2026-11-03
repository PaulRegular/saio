root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_skates_2023_2026')
review_date <- '2026-11-02'
candidate_id <- 'NOAA:11005'
unit_id <- 'noaa_goa_other_skates'

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
expected_files <- c('goa_skates_safe_2023.pdf', 'goa_groundfish_safe_intro_2024.pdf',
  'goa_skates_safe_2026.pdf')
expected_hashes <- c(
  'bde268cec68e29f8482b2ecd2b9cf2738810146477a64fba5a67b7888585e9b3',
  '7a8f279a0c7d561992486fbce4da686e1491ddd85c3f6f288c7ea6c639896249',
  '7e5ec4e2dcbd2860ee95d3c88ef86187896fb90ede9f5e86d32c533b4d1aa45c')
if (nrow(manifest) != length(expected_files) ||
    !identical(manifest$file, expected_files) ||
    !identical(tolower(manifest$sha256), expected_hashes) ||
    any(manifest$retrieval_date != review_date))
  stop('GOA skate source provenance does not match the reviewed snapshot.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached GOA skate source.', call. = FALSE)
  hashes
}
for (i in seq_along(expected_files)) {
  path <- file.path(cache, expected_files[i])
  if (!file.exists(path) || !identical(sha256_file(path), expected_hashes[i]))
    stop('A cached GOA skate source does not match its manifest: ',
      expected_files[i], call. = FALSE)
  con <- file(path, 'rb')
  header <- readBin(con, 'raw', 5L)
  close(con)
  if (!identical(header, charToRaw('%PDF-')))
    stop('A cached GOA skate source is not a PDF: ', expected_files[i], call. = FALSE)
}

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), metadata_env)
stocksmart <- metadata_env$stock_assessment_summary
assessment <- stocksmart[as.character(stocksmart$stock_id) == '11005' &
  as.character(stocksmart$assessment_id) == '13101', , drop = FALSE]
if (nrow(assessment) != 1L || assessment$stock_name != 'Gulf of Alaska Skate Complex' ||
    as.integer(assessment$assessment_year) != 2023L ||
    as.integer(assessment$last_data_year) != 2023L ||
    assessment$assessment_model != 'Survey Abundance' ||
    assessment$model_version != 'REMA' ||
    as.numeric(assessment$estimated_b) != 8869 ||
    assessment$review_result != 'Full acceptance' ||
    assessment$assessment_type != 'Operational')
  stop('The pinned NOAA Stock SMART assessment changed for stock 11005.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row_index <- match(candidate_id, candidates$candidate_id)
if (is.na(row_index) || any(candidates$candidate_unit_id[-row_index] == unit_id, na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id) || any(inputs$assessment_id == unit_id) ||
    any(outputs$assessment_id == unit_id))
  stop('GOA skate candidate identity overlaps an existing candidate or database record.', call. = FALSE)
if (any(stocks$scientific_name %in% c('Beringraja binoculata', 'Raja rhina'), na.rm = TRUE))
  stop('A GOA skate component already exists in the canonical stock database.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
row <- candidates[row_index, , drop = FALSE]
row$candidate_unit_id <- unit_id
row$scientific_name <- 'Bathyraja spp.'
row$assessment_area <- 'Gulf of Alaska (Other skates group)'
row$matched_stock_id <- ''
row$match_status <- 'new'
row$screening_status <- 'screened'
row$eligibility <- 'ineligible'
row$import_status <- 'not_started'
row$catch_age_evidence <- paste0(
  'The 2023 operational assessment reports aggregate catch by management group, in tonnes, not numbers-at-age. ',
  'The 2023 catch data were incomplete when the report was prepared. Fishery observer length compositions have been collected since 2009, but the report states they are not used to determine stock status.')
row$survey_age_evidence <- paste0(
  'The assessment uses AFSC bottom-trawl survey biomass indices (1984-2023 in the 2023 report; updated through 2025 in the September 2026 chapter). ',
  'These are aggregate biomass indices rather than age-specific abundance indices or age compositions.')
row$weights_evidence <- paste0(
  'No annual stock or survey weight-at-age series is reported or used in the biomass-only assessment. The Stock SMART biological-input score is not an age-specific input series.')
row$maturity_evidence <- paste0(
  'No maturity-at-age series is reported or used for the biomass-only assessment. General life-history discussion does not provide a run-specific maturity-at-age input.')
row$mortality_evidence <- paste0(
  'Natural mortality is fixed at M = 0.1 for Big skate, Longnose skate, and Other skates; there is no estimated age-specific M surface.')
row$timing_evidence <- paste0(
  'The model uses annual survey biomass observations. A within-year survey timing fraction is not specified because the assessment is a biomass-only random-effects model.')
row$output_evidence <- paste0(
  'The 2023 operational assessment reports estimated survey biomass and exploitation rates by management group, including regional biomass for Big and Longnose skates. ',
  'It does not report N-at-age, F-at-age, SSB, or recruitment. The 2026 chapter is pre-dissemination peer-review material and is not an accepted production run.')
row$detailed_source_url <- paste(manifest$url, collapse = '; ')
row$review_date <- review_date
row$decision_reason <- paste0(
  'NOAA Stock SMART identifies the 2023 REMA assessment as Operational with Full acceptance. ',
  'The 2023 SAFE report and 2024 SAFE introduction confirm a survey-biomass random-effects assessment. ',
  'The later September 2026 chapter is explicitly pre-dissemination and is used only to confirm the continuing biomass-only method and updated survey coverage, not as an accepted run. ',
  'No age-disaggregated catch, abundance, or biological inputs were identified; classified ineligible for age-structured source curation.')
row$notes <- paste0(
  'This Stock SMART record maps to the Other skates management group within the three-unit GOA skate assessment. NOAA:10727 (Big skate) and NOAA:10730 (Longnose skate) are separate current stock units with their own 2023 estimates. ',
  'The 2026 draft SAFE chapter is not treated as an accepted production assessment. No canonical stock, assessment, input, or output records were added.')

current <- candidates[row_index, names(row), drop = FALSE]
same <- all(vapply(names(row), function(name) {
  x <- current[[name]]
  y <- row[[name]]
  if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
}, logical(1L)))
initial <- candidates$match_status[row_index] == 'unreviewed' &&
  candidates$screening_status[row_index] == 'not_started' &&
  candidates$eligibility[row_index] == 'unresolved' &&
  candidates$import_status[row_index] == 'not_started' &&
  (is.na(candidates$candidate_unit_id[row_index]) || !nzchar(candidates$candidate_unit_id[row_index]))
reviewed <- candidates$candidate_unit_id[row_index] %in% c(unit_id, 'noaa_goa_skate_complex') &&
  candidates$match_status[row_index] == 'new' &&
  candidates$screening_status[row_index] == 'screened' &&
  candidates$eligibility[row_index] == 'ineligible' &&
  candidates$import_status[row_index] == 'not_started'
if (!same && !initial && !reviewed)
  stop('Unexpected existing candidate state for NOAA:11005.', call. = FALSE)
if (!same) {
  for (name in names(row)) candidates[[name]][row_index] <- row[[name]]
  replace_candidate_register_row(register_path, row_index,
    candidates[row_index, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA:11005 as the biomass-only GOA Other skates group; it is ineligible for age-structured source curation.\n')

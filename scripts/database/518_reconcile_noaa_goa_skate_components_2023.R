root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_skates_2023_2026')
review_date <- '2026-11-02'
candidate_ids <- c('NOAA:10727', 'NOAA:10730')
unit_ids <- c('noaa_goa_big_skate', 'noaa_goa_longnose_skate')
assessment_ids <- c('13084', '13093')
scientific_names <- c('Raja binoculata', 'Raja rhina')
group_names <- c('Big skate', 'Longnose skate')

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
assessment <- stocksmart[as.character(stocksmart$stock_id) %in% c('10727', '10730') &
  as.character(stocksmart$assessment_id) %in% assessment_ids, , drop = FALSE]
assessment <- assessment[match(assessment_ids, as.character(assessment$assessment_id)), , drop = FALSE]
if (nrow(assessment) != 2L ||
    !identical(as.character(assessment$stock_id), c('10727', '10730')) ||
    !identical(as.character(assessment$stock_name),
      c('Big skate - Gulf of Alaska', 'Longnose skate - Gulf of Alaska')) ||
    !identical(as.integer(assessment$assessment_year), c(2023L, 2023L)) ||
    !identical(as.integer(assessment$last_data_year), c(2023L, 2023L)) ||
    !identical(as.numeric(assessment$estimated_b), c(37804, 33804)) ||
    !all(assessment$assessment_model == 'Survey Abundance') ||
    !all(assessment$assessment_type == 'Operational') ||
    !all(assessment$review_result == 'Full acceptance'))
  stop('The pinned NOAA Stock SMART skate component records changed.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
parent <- candidates[candidates$candidate_id == 'NOAA:11005', , drop = FALSE]
if (nrow(parent) != 1L || parent$candidate_unit_id != 'noaa_goa_other_skates' ||
    parent$screening_status != 'screened' || parent$eligibility != 'ineligible')
  stop('The reviewed GOA skate-complex parent record is missing or changed.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (i in seq_along(candidate_ids)) {
  row_index <- match(candidate_ids[i], candidates$candidate_id)
  if (is.na(row_index)) stop('Missing GOA skate component ', candidate_ids[i], '.', call. = FALSE)
  row <- candidates[row_index, , drop = FALSE]
  row$candidate_unit_id <- unit_ids[i]
  row$scientific_name <- scientific_names[i]
  row$assessment_area <- paste0('Gulf of Alaska (', group_names[i], ')')
  row$matched_stock_id <- ''
  row$match_status <- 'new'
  row$screening_status <- 'screened'
  row$eligibility <- 'ineligible'
  row$import_status <- 'not_started'
  row$catch_age_evidence <- paste0(
    'The accepted 2023 GOA Skate SAFE reports aggregate catch for Big and Longnose skate in tonnes, not catch numbers-at-age. ' ,
    'Fishery length compositions are described but are not used to determine stock status.')
  row$survey_age_evidence <- paste0(
    'The 2023 SAFE uses a separate bottom-trawl survey biomass random-effects model for this group; it does not use an age-specific abundance index or age composition.')
  row$weights_evidence <- 'The assessment is biomass-based and does not use or report a group-specific annual weight-at-age input.'
  row$maturity_evidence <- 'The assessment is biomass-based and does not use or report a group-specific maturity-at-age input.'
  row$mortality_evidence <- 'The 2023 SAFE fixes natural mortality at M = 0.1 for Big skate and Longnose skate; no age-specific M surface is estimated.'
  row$timing_evidence <- 'The assessment uses annual survey biomass observations; the reviewed source does not specify a within-year timing fraction.'
  row$output_evidence <- paste0(
    'The accepted 2023 SAFE reports a distinct GOA-wide survey-biomass estimate for this management unit and exploitation rates, not N-at-age, F-at-age, SSB, or recruitment. ' ,
    'The 2024 biomass estimates are 37,804 t for Big skate and 33,804 t for Longnose skate.')
  row$detailed_source_url <- paste(manifest$url, collapse = '; ')
  row$review_date <- review_date
  row$decision_reason <- paste0(
    'NOAA Stock SMART component record ', assessment_ids[i], ' identifies ', group_names[i],
    ' as a separate current management unit in the accepted 2023 operational assessment. The 2023 SAFE models it with random-effects survey biomass, ' ,
    'not an age-structured population process. It has a distinct stock-unit key from the Other skates group; age-disaggregated inputs and outputs are unavailable.')
  row$notes <- paste0(
    'Separate current stock unit: ', unit_ids[i], '. The 2023 SAFE assesses Big skate, Longnose skate, and Other skates as separate management units with distinct survey-biomass estimates. ' ,
    'NOAA:11005 is the separate Other skates group. No canonical stock, assessment, input, or output rows were added.')

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
  reviewed <- candidates$candidate_unit_id[row_index] %in% c(unit_ids[i], 'noaa_goa_skate_complex') &&
    candidates$match_status[row_index] == 'new' &&
    candidates$screening_status[row_index] == 'screened' &&
    candidates$eligibility[row_index] == 'ineligible' &&
    candidates$import_status[row_index] == 'not_started'
  if (!same && !initial && !reviewed)
    stop('Unexpected existing candidate state for ', candidate_ids[i], '.', call. = FALSE)
  if (!same) {
    for (name in names(row)) candidates[[name]][row_index] <- row[[name]]
    replace_candidate_register_row(register_path, row_index,
      candidates[row_index, , drop = FALSE], candidate_ids[i])
  }
  candidates[row_index, names(row)] <- row
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA:10727 and NOAA:10730 as distinct age-free GOA skate assessment units.\n')

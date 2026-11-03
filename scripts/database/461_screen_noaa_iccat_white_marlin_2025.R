root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_iccat_white_marlin_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10955'
unit_id <- 'iccat_atlantic_white_marlin'

expected_sources <- data.frame(
  source_id = c('iccat_white_marlin_assessment_2025', 'iccat_white_marlin_data_prep_2025'),
  file = c('2025_WHM_SA_ENG.pdf', '2025_WHM_DP_ENG.pdf'),
  url = c(
    'https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_WHM_SA_ENG.pdf',
    'https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_WHM_DP_ENG.pdf'
  ),
  retrieved_at = c('2026-10-31', '2026-10-31'),
  bytes = c(4059053L, 1403363L),
  sha256 = c(
    'DE6B76F5BE524C5508E161CB87E316B6F5C1868B921FC445DAAA0F24CE9F4906',
    '134B34C04E6DE634C90B7113C8D274A0352E5A6E33C8D1442BC25A07C8BF7BF0'
  ),
  pinned_revision = c(
    'ICCAT 2025 White Marlin Stock Assessment Meeting report, 23-27 June 2025',
    'ICCAT 2025 White Marlin Data Preparatory Meeting report, 24-27 March 2025'
  ),
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE))
  if (length(hashes) != 1L)
    stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
if (!identical(manifest$source_id, expected_sources$source_id) ||
    !identical(manifest$file, expected_sources$file) ||
    !identical(manifest$url, expected_sources$url) ||
    !identical(manifest$retrieved_at, expected_sources$retrieved_at) ||
    !identical(as.integer(manifest$bytes), expected_sources$bytes) ||
    !identical(toupper(manifest$sha256), expected_sources$sha256) ||
    !identical(manifest$pinned_revision, expected_sources$pinned_revision))
  stop('Cached ICCAT white marlin manifest differs from the reviewed sources.', call. = FALSE)

for (i in seq_len(nrow(expected_sources))) {
  path <- file.path(cache, expected_sources$file[i])
  if (!file.exists(path) || file.info(path)$size != expected_sources$bytes[i] ||
      !identical(sha256_file(path), expected_sources$sha256[i]) ||
      !identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'))
    stop('Cached ICCAT white marlin source differs from its manifest: ',
      expected_sources$file[i], call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10955 &
  stocksmart$assessment_year == 2025, , drop = FALSE]
if (nrow(run) != 1L || run$assessment_id != 14051L ||
    run$last_data_year != 2023L || run$assessment_model != 'JABBA' ||
    run$review_result != 'Full acceptance' ||
    run$assessment_type != 'Operational' ||
    run$stock_name != 'White marlin - Atlantic')
  stop('NOAA Stock SMART metadata differs from the screened ICCAT assessment.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != '10955' ||
    candidates$scientific_name[row] != 'Kajikia albida' ||
    candidates$stock_name[row] != 'White marlin - Atlantic' ||
    candidates$assessment_area[row] != 'Atlantic' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(stocks$authority_stock_id == '10955', na.rm = TRUE))
  stop('ICCAT white marlin identity conflicts with the candidate register or database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The current assessment fits total fleet removals, including catches,',
    'dead discards and estimated post-release mortality. The reviewed reports',
    'do not document catch-at-age or an age-composition likelihood.'
  ),
  survey_age_evidence = paste(
    'The fitted abundance series are aggregate fleet CPUE indices and length',
    'compositions. No age-specific survey abundance index was identified.'
  ),
  weights_evidence = paste(
    'The reports describe growth and length-based biological assumptions,',
    'but do not provide a run-matched weight-at-age input matrix.'
  ),
  maturity_evidence = paste(
    'Maturity is summarized by length-at-50%-maturity; no maturity-at-age',
    'input vector or matrix was identified.'
  ),
  mortality_evidence = paste(
    'The JABBA life-history prior uses M = 0.2 with CV = 30%. The report',
    'recommends developing an age-specific M vector for future assessments.'
  ),
  timing_evidence = paste(
    'The assessment uses fishery CPUE indices rather than a seasonal survey',
    'observation, so a within-year survey timing fraction is not applicable.'
  ),
  output_evidence = paste(
    'The selected JABBA assessment reports aggregate biomass and fishing',
    'mortality indicators relative to reference points. Numeric annual',
    'N-at-age and F-at-age surfaces were not identified. Stock Synthesis',
    'results were not used for stock-status determination.'
  ),
  detailed_source_url = paste(c(
    expected_sources$url,
    'https://www.iccat.int/en/assess.html'
  ), collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste(
    'NOAA Stock SMART 10955 is the Atlantic white marlin unit. The 2025',
    'operational full-acceptance run uses JABBA on aggregate removals and',
    'CPUE. The companion Stock Synthesis model uses length compositions and',
    'was not selected for stock-status determination. No age-disaggregated',
    'observations or age-specific reported outputs were verified.'
  ),
  notes = paste(
    'The 2025 assessment combines white marlin and roundscale spearfish due',
    'species-identification and catch-reporting overlap. ICCAT marked the',
    'meeting report preliminary pending SCRS adoption; the current ICCAT',
    'assessment listing identifies JABBA as the model used for advice.',
    'No canonical database values were added was',
    'attempted. Official reports are cached under',
    'source_cache/discovery_noaa_iccat_white_marlin_2025/.'
  )
)

current <- lapply(names(review), function(column)
  as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) ||
    !nzchar(candidates$candidate_unit_id[row]))
if (!is_unreviewed && !same_review)
  stop('ICCAT white marlin candidate already has a conflicting review state.',
    call. = FALSE)
if (is_unreviewed || !same_review) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA:10955 as a new but ineligible ICCAT Atlantic white marlin unit.\n')

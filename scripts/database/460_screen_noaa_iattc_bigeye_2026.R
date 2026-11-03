root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_iattc_bigeye_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:11685'
unit_id <- 'iattc_eastern_pacific_bigeye'
source_file <- 'SAC-17-03_bigeye_tuna_eastern_pacific_update_2026.pdf'
source_url <- 'https://www.iattc.org/GetAttachment/c5e3d906-6a44-421e-a23c-5b60788f0250/SAC-17-03_BET-assessment-EN.pdf'
expected_sha256 <- '882466f7c3685f26c1f15dbd6541466ea1b00f7352c2019553d2ebc8acc126e8'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE))
  if (length(hashes) != 1L)
    stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest_path <- file.path(cache, 'sources.csv')
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
source_path <- file.path(cache, source_file)
if (nrow(manifest) != 1L || manifest$source_id != 'iattc_bigeye_update_2026' ||
    manifest$file != source_file || manifest$url != source_url ||
    manifest$retrieved_at != '2026-10-31' ||
    manifest$pinned_revision != 'IATTC SAC-17-03, issued 2026-05-15' ||
    !file.exists(source_path) || file.info(source_path)$size != 5130002 ||
    tolower(manifest$sha256) != expected_sha256 ||
    !identical(sha256_file(source_path), expected_sha256) ||
    !identical(rawToChar(readBin(source_path, 'raw', n = 4L)), '%PDF'))
  stop('Cached IATTC bigeye source differs from the reviewed manifest.', call. = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 11685 &
  stocksmart$assessment_year == 2026, , drop = FALSE]
stock_history <- stocksmart[stocksmart$stock_id == 11685, , drop = FALSE]
if (nrow(run) != 1L || nrow(stock_history) != 6L ||
    run$last_data_year != 2025L || run$assessment_model != 'SS' ||
    run$review_result != 'Full acceptance' ||
    run$assessment_type != 'Operational' ||
    run$stock_name != 'Bigeye tuna - Eastern Pacific' ||
    run$stock_area != 'Eastern Pacific')
  stop('NOAA Stock SMART metadata differs from the screened IATTC update.', call. = FALSE)

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
    candidates$official_stock_id[row] != '11685' ||
    candidates$scientific_name[row] != 'Thunnus obesus' ||
    candidates$stock_name[row] != 'Bigeye tuna - Eastern Pacific' ||
    candidates$assessment_area[row] != 'Eastern Pacific' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(stocks$authority_stock_id == '11685', na.rm = TRUE) ||
    any(stocks$stock_id == 'iattc_atlantic_bigeye_tuna', na.rm = TRUE))
  stop('IATTC bigeye identity conflicts with the candidate register or canonical database.',
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
    'The 2026 IATTC update fits catches for 22 purse-seine and longline',
    'fleets, with fleet-specific units and retained/discard components.',
    'It does not use observed catch-at-age or fishery age-composition',
    'likelihoods.'
  ),
  survey_age_evidence = paste(
    'The fitted abundance index is aggregate Japanese longline CPUE',
    'representing mature bigeye. The model does not fit an age-specific',
    'abundance index. The assessment also uses standardized length',
    'compositions, not age compositions.'
  ),
  weights_evidence = paste(
    'The 2026 update retains biological assumptions from the 2024 benchmark;',
    'its composition observations are lengths. A run-matched observed',
    'weight-at-age series was not identified as a fitted input.'
  ),
  maturity_evidence = paste(
    'The 2026 update retains the 2024 benchmark biological specification.',
    'A run-matched numeric maturity-at-age vector was not identified in',
    'the update report.'
  ),
  mortality_evidence = paste(
    'The update examines reference-model alternatives that estimate natural',
    'mortality, while retaining the 2024 benchmark framework. No observed',
    'age-specific mortality series is used as a data input.'
  ),
  timing_evidence = paste(
    'The report presents fishing mortality by quarter-based age groups.',
    'Abundance is informed by fishery-dependent longline CPUE; a single',
    'annual survey timing is not applicable to this index.'
  ),
  output_evidence = paste(
    'The report gives convergence and aggregate spawning-biomass and',
    'fishing-mortality status results. It presents F by grouped ages, but',
    'no numeric annual N-at-age or full annual F-at-age matrix was recovered.'
  ),
  detailed_source_url = paste(
    source_url,
    'https://www.iattc.org/en-US/Event/DetailEvent/Event-SAC-17',
    'https://www.iattc.org/GetAttachment/23cfd40e-2865-451a-b63a-b22132a760ab/SAC-15-02_Bigeye-tuna-benchmark-assessment-2024.pdf',
    'https://www.fisheries.noaa.gov/species/pacific-bigeye-tuna',
    sep = '; '
  ),
  review_date = '2026-10-31',
  decision_reason = paste(
    'NOAA Stock SMART 11685 is the Eastern Pacific bigeye management unit',
    'assessed by IATTC, not a separate NOAA assessment. The latest accepted',
    'assessment is the IATTC 2026 update, based on data through 2025. Its',
    'fitted data are catches, an aggregate longline index, and length',
    'compositions. It is ineligible for the age-disaggregated input screen.'
  ),
  notes = paste(
    'The 2026 update adds 2024-2025 catch, longline index, and length',
    'composition data to the 2024 benchmark without other model modifications.',
    'The 36 reference models are reported as converged with positive-definite',
    'Hessians. No canonical database values were imported and no tinyAM',
    'translation was attempted. The public report is cached locally under',
    'source_cache/discovery_noaa_iattc_bigeye_2026/ with its retrieval date',
    'and SHA-256 in sources.csv.'
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
  stop('IATTC bigeye candidate already has a conflicting review state.', call. = FALSE)
if (is_unreviewed || !same_review) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA:11685 as a new but ineligible IATTC Eastern Pacific bigeye unit.\n')
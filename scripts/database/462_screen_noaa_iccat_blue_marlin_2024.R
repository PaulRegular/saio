root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_iccat_blue_marlin_2024')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:11254'
unit_id <- 'iccat_atlantic_blue_marlin'

expected_sources <- data.frame(
  source_id = c('iccat_blue_marlin_assessment_2024', 'iccat_blue_marlin_data_prep_2024'),
  file = c('2024_BUM_SA_ENG.pdf', '2024_BUM_DP_ENG.pdf'),
  url = c(
    'https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_BUM_SA_ENG.pdf',
    'https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_BUM_DP_ENG.pdf'
  ),
  retrieved_at = c('2026-10-31', '2026-10-31'),
  bytes = c(5969276L, 4487779L),
  sha256 = c(
    '623E52E92CEFD4D7FD9B0816D71CC0569E9E0EA977DF69A58F5162B4F2775F5B',
    '43C50E731D3C53C566BA3ED7218E4E951C9B074610318DFEFF9564DC231E44C5'
  ),
  pinned_revision = c(
    'ICCAT 2024 Atlantic Blue Marlin Stock Assessment Meeting report, 17-21 June 2024',
    'ICCAT 2024 Atlantic Blue Marlin Data Preparatory Meeting report, 11-15 March 2024'
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
  stop('Cached ICCAT blue marlin manifest differs from the reviewed sources.', call. = FALSE)

for (i in seq_len(nrow(expected_sources))) {
  path <- file.path(cache, expected_sources$file[i])
  if (!file.exists(path) || file.info(path)$size != expected_sources$bytes[i] ||
      !identical(sha256_file(path), expected_sources$sha256[i]) ||
      !identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'))
    stop('Cached ICCAT blue marlin source differs from its manifest: ',
      expected_sources$file[i], call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 11254 &
  stocksmart$assessment_year == 2024, , drop = FALSE]
if (nrow(run) != 1L || run$assessment_id != 13566L ||
    run$last_data_year != 2022L || run$assessment_model != 'SS' ||
    run$review_result != 'Full acceptance' ||
    run$assessment_type != 'Operational' ||
    run$stock_name != 'Blue marlin - Atlantic')
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
    candidates$official_stock_id[row] != '11254' ||
    candidates$scientific_name[row] != 'Makaira nigricans' ||
    candidates$stock_name[row] != 'Blue marlin - Atlantic' ||
    candidates$assessment_area[row] != 'Atlantic' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(stocks$authority_stock_id == '11254', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Makaira nigricans', na.rm = TRUE))
  stop('ICCAT blue marlin identity conflicts with the candidate register or database.',
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
    'The 2024 assessment fits fleet removals and catch/length-frequency data.',
    'The reports do not describe catch-at-age or an age-composition likelihood.',
    'Otolith age-at-size observations inform growth, not population age composition.'
  ),
  survey_age_evidence = paste(
    'The assessment uses aggregate fishery CPUE abundance indices. No age-specific',
    'survey index or population age composition was identified.'
  ),
  weights_evidence = paste(
    'Sex-specific growth and length-weight relationships are reported and could',
    'support derived weights-at-age, but no run-matched observed weight-at-age matrix',
    'was identified.'
  ),
  maturity_evidence = paste(
    'The reports use length at 50% maturity of 206 cm. No maturity-at-age input',
    'vector or matrix was identified.'
  ),
  mortality_evidence = paste(
    'Natural mortality M = 0.148 from the 2018 assessment was used as an initial',
    'value, and the 2024 Stock Synthesis team attempted to estimate M. No age-specific',
    'M surface was identified.'
  ),
  timing_evidence = paste(
    'Abundance inputs are fishery CPUE indices rather than seasonal surveys. The',
    'reports do not specify a within-year survey timing fraction.'
  ),
  output_evidence = paste(
    'Management advice combines four Stock Synthesis and four JABBA scenarios in',
    'a joint grid of aggregate biomass and fishing-mortality results. Numeric annual',
    'N-at-age and F-at-age surfaces were not identified.'
  ),
  detailed_source_url = paste(c(
    expected_sources$url,
    'https://www.iccat.int/en/assess.html'
  ), collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste(
    'NOAA Stock SMART 11254 is the Atlantic blue marlin unit. Its 2024 operational',
    'full-acceptance assessment is an age-structured Stock Synthesis model used',
    'alongside JABBA, but the population data are aggregate removals, CPUE and',
    'length compositions; age-at-size observations inform growth. Required age-disaggregated',
    'population inputs and annual N/F-at-age outputs were not verified.'
  ),
  notes = paste(
    'The 2024 ICCAT report describes an Atlantic-wide single stock and data through',
    '2022. The reported biological assumptions do not substitute for population age',
    'compositions or age-specific output surfaces. No canonical values were added',
    'and no tinyAM translation was attempted. Official reports are cached under',
    'source_cache/discovery_noaa_iccat_blue_marlin_2024/.'
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
  stop('ICCAT blue marlin candidate already has a conflicting review state.',
    call. = FALSE)
if (is_unreviewed || !same_review) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA:11254 as a new but ineligible ICCAT Atlantic blue marlin unit.\n')

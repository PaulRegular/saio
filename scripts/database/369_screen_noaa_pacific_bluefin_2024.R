root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_pacific_bluefin_2024')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

expected <- data.frame(
  file = c('isc_pacific_bluefin_2024_assessment.pdf', 'isc_pbfwg_data_prep_2024.pdf',
    'isc_stock_assessment_catalogue.html'),
  sha256 = c('8B3BBF6F3F9A1C469EA4FF59436E7BC018FAB523118442F3969E09C1123E7B46',
    '25E1639624DCB2746A24D6A0001EB7B172056F134D027CC7FF5C561B59DE04DE',
    '11BAD140D41C32CC41F01169D1CDA2DBC2712A5871C1909AB9E54ABE71A76C6E'),
  stringsAsFactors = FALSE
)
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
for (i in seq_len(nrow(expected))) {
  path <- file.path(cache_dir, expected$file[i])
  source_row <- match(expected$file[i], manifest$file)
  if (!file.exists(path) || is.na(source_row) ||
      toupper(manifest$sha256[source_row]) != expected$sha256[i] ||
      sha256_file(path) != expected$sha256[i]) {
    stop('A pinned Pacific bluefin source is missing or differs from its manifest: ',
      expected$file[i], call. = FALSE)
  }
}

catalogue <- paste(readLines(file.path(cache_dir, 'isc_stock_assessment_catalogue.html'),
  warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('Pacific Bluefin Tuna', catalogue, fixed = TRUE) ||
    !grepl('non-disclosure agreement', catalogue, fixed = TRUE)) {
  stop('The pinned ISC catalogue no longer verifies the PBF listing or data-file access terms.',
    call. = FALSE)
}

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
stocksmart_env <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11687' &
  stocksmart$assessment_year == 2024, , drop = FALSE]
if (nrow(stocksmart) != 1L || stocksmart$assessment_id != 13484L ||
    stocksmart$last_data_year != 2023L || stocksmart$science_center != 'PIFSC' ||
    stocksmart$review_result != 'Full acceptance' || stocksmart$assessment_model != 'SS' ||
    abs(as.numeric(stocksmart$model_version) - 3.30) > 0.001) {
  stop('The pinned NOAA Stock SMART snapshot no longer verifies the 2024 Pacific bluefin run.',
    call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

candidate_id <- 'NOAA:11687'
unit_id <- 'noaa_isc_pacific_bluefin'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$scientific_name[row] != 'Thunnus orientalis' ||
    register$inventory_assessment_year[row] != 2024L ||
    any(stocks$scientific_name == 'Thunnus orientalis', na.rm = TRUE)) {
  stop('Pacific bluefin candidate identity or canonical matching changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    unit_id %in% assessments$assessment_id || unit_id %in% inputs$assessment_id ||
    unit_id %in% outputs$assessment_id) {
  stop('Pacific bluefin candidate-unit key conflicts with an existing record.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2024 ISC base case uses quarterly retained and discarded total catch and size compositions where available. It does not fit observed catch-at-age; the published annual catch-at-age is estimated internally from growth, catch, and selectivity.',
  survey_age_evidence = 'The base case uses annual standardized fishery CPUE abundance indices, not age-specific survey indices. The report identifies Japanese longline, Chinese Taipei longline, and Japanese troll series; selected recent indices are excluded from the base case. The data-preparation workshop considered age-group-specific VAST indices but retained the longer aggregate GLMM-South series and noted that the VAST groups were inconsistent with the assessment growth curve.',
  weights_evidence = 'The report provides fixed age-length-weight values derived from the growth curve and length-weight relationship; native model files are not publicly accessible from the ISC catalogue.',
  maturity_evidence = 'The assessment fixes mature proportions at 0 for ages 0-2, 0.2 at age 3, 0.5 at age 4, and 1.0 at age 5 and older as of April 1.',
  mortality_evidence = 'Natural mortality is fixed at 1.6 year-1 at age 0, 0.386 year-1 at age 1, and 0.25 year-1 at age 2 and older.',
  timing_evidence = 'The assessment uses July-June fishing years and quarterly catch/size observations. Its abundance likelihood is annual fishery CPUE; the report does not specify survey timing for an age-specific survey input.',
  output_evidence = 'The official report includes spawning biomass, recruitment, age-specific fishing-mortality summaries, and model-estimated catch-at-age. These are derived outputs; full numerical native N-at-age/F-at-age files were not public in the reviewed sources.',
  detailed_source_url = paste('https://isc.fra.go.jp/pdf/ISC24/ISC24_ANNEX13-Pacific_Bluefin_Tuna_Stock_Assessment_in_2024-FINAL.pdf',
    'https://isc.fra.go.jp/pdf/ISC24/ISC24_ANNEX10-Report_PBFWG_Workshop_February_29-March_8-April_11-12-FINAL.pdf',
    'https://isc.fra.go.jp/reports/stock_assessments.html', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('NOAA Stock SMART identifies the 2024 fully accepted SS 3.30 run through 2023, which matches the public ISC 2024 PBFWG benchmark. The fit uses catch totals, size compositions, and annual fishery CPUE indices rather than observed catch-at-age or age-specific abundance observations. It is therefore ineligible for the age-disaggregated input set despite its internal age structure and age-derived outputs.'),
  notes = paste('NOAA Stock SMART PIFSC ID 11687 represents the single Pacific-wide Thunnus orientalis assessment led through ISC/PBFWG; it is a new crosswalk unit and no canonical record was found. The official ISC catalogue states that native stock-assessment data files require an NDA. The report covers fishing years 1983-2022, ending June 2023. Public assessment report, data-preparation annex, and ISC catalogue are cached with provenance and checksums in source_cache/discovery_noaa_pacific_bluefin_2024/sources.csv. No canonical stock or numerical assessment records were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  grepl('does not fit observed catch-at-age', register$catch_age_evidence[row], fixed = TRUE)
update_review <- initial || (reviewed && (
  !grepl('age-group-specific VAST indices', register$survey_age_evidence[row], fixed = TRUE) ||
    grepl('',
      register$timing_evidence[row], fixed = TRUE)
))
if (!initial && !reviewed) stop('Pacific bluefin candidate has an unexpected prior review state.',
  call. = FALSE)
if (update_review) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && update_review) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  tmp <- tempfile(fileext = '.csv')
  write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  unlink(tmp)
  writeLines(lines, register_path, useBytes = TRUE)
}
cat('Screened NOAA Stock SMART 11687 against the 2024 ISC Pacific bluefin assessment; age-input eligibility is ineligible.\n')

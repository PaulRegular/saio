root <- "."
cache_dir <- file.path(root, 'source_cache',
  'discovery_noaa_isc_shortfin_mako_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

expected <- c('ISC24_ANNEX14_shortfin_mako_2024.pdf', 'ISC25_Plenary_Report_FINAL.pdf')
for (file in expected) {
  i <- match(file, manifest$file)
  path <- file.path(cache_dir, file)
  if (!file.exists(path) || is.na(i) ||
      !grepl('^[[:xdigit:]]{64}$', manifest$sha256[i]) ||
      sha256_file(path) != tolower(manifest$sha256[i]) ||
      file.info(path)$size != as.numeric(manifest$bytes[i])) {
    stop('A pinned ISC shortfin mako source is missing or differs from its manifest: ',
      file, call. = FALSE)
  }
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11715', , drop = FALSE]
latest <- stocksmart[which.max(as.integer(stocksmart$assessment_year)), , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_id != 13565L ||
    latest$assessment_year != 2024L || latest$last_data_year != 2022L ||
    latest$science_center != 'SWFSC / PIFSC' || latest$assessment_model != 'BSP' ||
    latest$review_result != 'Full acceptance') {
  stop('The Stock SMART snapshot no longer identifies NOAA:11715 as reviewed.', call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_id <- 'NOAA:11715'
unit_id <- 'noaa_north_pacific_shortfin_mako'
row <- which(register$candidate_id == candidate_id)
other_mako <- which(register$candidate_id == 'NOAA:10657')
if (length(row) != 1L || register$scientific_name[row] != 'Isurus oxyrinchus' ||
    any(stocks$scientific_name == 'Isurus oxyrinchus', na.rm = TRUE) ||
    length(other_mako) != 1L ||
    register$candidate_unit_id[other_mako] == unit_id) {
  stop('North Pacific shortfin mako identity or canonical matching changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE)) {
  stop('North Pacific shortfin mako candidate-unit key conflicts with another candidate.',
    call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2024 assessment used an annual surplus-production model. It combined catch reported in numbers or weight, converting weight to numbers with a Stock Synthesis model, but did not fit catch-at-age or age-composition observations. The report also describes size-composition inputs for an initial SS3 model; the final BSPM did not use age-composition data, and size compositions alone do not support an observed catch-at-age reconstruction.'),
  survey_age_evidence = paste('The accepted BSPM assessment used four standardized annual longline CPUE indices one at a time across its model ensemble. These are aggregate relative-abundance indices, not age-specific abundance observations. The report states that age structure was absent from the final estimation model.'),
  weights_evidence = paste('Length-weight relationships and growth inputs support conversion of some catch from weight to numbers and are used in diagnostic age-structured simulations. No independent weight-at-age input to the final BSPM assessment was recovered.'),
  maturity_evidence = paste('Maturity-at-length and derived maturity-at-age inform the report\'s age-structured simulation scenarios. They are not likelihood inputs to the accepted surplus-production model.'),
  mortality_evidence = paste('Natural-mortality-at-age scenarios inform diagnostic age-structured simulations. The accepted BSPM estimates aggregate productivity parameters and does not fit an age-specific natural-mortality schedule.'),
  timing_evidence = paste('The accepted assessment is annual; the modeled series and four relative-abundance indices are annual, with the report describing calendar-year data. There is no within-year survey timing fraction for these aggregate index series.'),
  output_evidence = paste('The 2024 accepted BSPM reports aggregate depletion, exploitation rate, removals/catch, MSY and related status quantities for 1994-2022, not fitted N-at-age, F-at-age, or M-at-age. The report also contains an age-structured simulation used to examine whether biological and fishery assumptions could reproduce observed index trends; these simulated scenarios are diagnostic analyses, not estimated age-specific production-assessment outputs.'),
  detailed_source_url = paste('https://isc.fra.go.jp/pdf/ISC24/ISC24_ANNEX14-North_Pacific_Ocean_Shortfin_Mako_Shark_Stock_Assessment_Through_2022-FINAL.pdf', 'https://isc.fra.go.jp/pdf/ISC25/ISC25_Plenary_Report_FINAL.pdf', 'https://isc.fra.go.jp/reports/stock_assessments.html', 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11715', sep = '; '),
  review_date = '2026-11-02',
  decision_reason = paste('Ineligible for the age-disaggregated comparison set. The latest accepted production assessment is the detailed 2024 ISC shortfin mako assessment through 2022, carried forward by ISC25. Its final model is a Bayesian state-space surplus-production model with aggregate annual catch and CPUE, and the report explicitly identifies the lack of age structure in estimation. The report\'s age-structured simulation is diagnostic and does not provide fitted age-specific population outputs. The earlier 2018 age-based SS3 assessment is superseded and is not substituted for the detailed 2024 run.'),
  notes = paste('NOAA Stock SMART ID 11715 maps to the North Pacific shortfin mako unit and is distinct from NOAA:10657, the North Atlantic unit. No canonical Isurus oxyrinchus stock row exists. Stock SMART identifies assessment 13565 (2024, data through 2022; SWFSC/PIFSC; BSP) as Full acceptance. The detailed ISC24 report and ISC25 Plenary report are cached with retrieval dates and SHA-256 values in source_cache/discovery_noaa_isc_shortfin_mako_2024/sources.csv. ISC states that access to assessment data files requires an NDA; no native fitted object was found in the public sources reviewed.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  grepl('age structure in estimation', register$decision_reason[row], fixed = TRUE)
if (!initial && !reviewed) {
  stop('North Pacific shortfin mako candidate has an unexpected prior review state.',
    call. = FALSE)
}
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE],
      candidate_id)
  }
}
cat('Screened NOAA 11715 as ineligible for age-disaggregated source curation; retained the current 2024 run.\n')

root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (sha256_file(stocksmart_path) !=
    'AD47F9EEB240C2E77B2B952809A12C4FA739E3F0D39BEAB283B413FDBAEF76A8') {
  stop('The pinned NOAA Stock SMART snapshot is missing or changed.', call. = FALSE)
}
stocksmart_env <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
expected_stocksmart <- data.frame(
  stock_id = c(11696L, 11731L),
  assessment_year = c(2024L, 2025L),
  last_data_year = c(2023L, 2023L),
  assessment_model = c('JABBA', 'JABBA'),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(expected_stocksmart))) {
  row <- stocksmart[stocksmart$stock_id == expected_stocksmart$stock_id[i] &
    stocksmart$assessment_year == expected_stocksmart$assessment_year[i], , drop = FALSE]
  if (nrow(row) != 1L || row$last_data_year != expected_stocksmart$last_data_year[i] ||
      row$assessment_model != expected_stocksmart$assessment_model[i] ||
      row$science_center != 'PIFSC' || row$review_result != 'Full acceptance') {
    stop('The pinned NOAA Stock SMART snapshot does not match the reviewed Marianas entry: ',
      expected_stocksmart$stock_id[i], call. = FALSE)
  }
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

species <- data.frame(
  candidate_id = c('NOAA:11696', 'NOAA:11731'),
  candidate_unit_id = c('noaa_guam_bottomfish_complex', 'noaa_cnmi_bottomfish_complex'),
  stock_name = c('Guam Bottomfish Multi-species Complex',
    'Northern Mariana Islands Bottomfish Multi-species Complex'),
  assessment_year = c(2024L, 2025L),
  stringsAsFactors = FALSE
)
catch_evidence <- c(
  'Annual total catch for the 13-species Guam complex, 1982-2023, with catch CVs; the input is aggregate catch rather than numbers-at-age.',
  'Annual total catch for the 13-species CNMI complex, 2000-2023, in thousand pounds with catch CVs; the input is aggregate catch rather than numbers-at-age.'
)
survey_evidence <- c(
  'Annual standardized boat-based creel CPUE for the complex, 1982-2023, in pounds per gear-hour with log-scale standard errors; no age-specific index is used.',
  'Annual standardized boat-based creel CPUE for the complex, 2000-2023, in pounds per gear-hour; no age-specific index is used.'
)
output_evidence <- c(
  'Reports annual exploitable biomass, relative biomass, harvest rate, stock status probabilities and projections through 2029. No numeric N-at-age or F-at-age series is reported.',
  'Reports annual exploitable biomass, relative biomass, harvest rate, stock status probabilities and projections for 2026-2030. No numeric N-at-age or F-at-age series is reported.'
)

review_rows <- lapply(seq_len(nrow(species)), function(i) {
  list(
    candidate_unit_id = species$candidate_unit_id[i],
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = catch_evidence[i],
    survey_age_evidence = survey_evidence[i],
    weights_evidence = 'No weight-at-age input is used by the biomass production assessment.',
    maturity_evidence = 'No maturity-at-age input is used by the biomass production assessment.',
    mortality_evidence = 'The assessment does not estimate age-specific M or use age-specific mortality inputs.',
    timing_evidence = 'Catch and standardized CPUE are annual aggregate series; fractional-year timing is not specified or applicable to an age-specific index.',
    output_evidence = output_evidence[i],
    detailed_source_url = if (i == 1L) paste(
      'https://repository.library.noaa.gov/view/noaa/61479/noaa_61479_DS1.pdf',
      'https://repository.library.noaa.gov/view/noaa/21164',
      'https://apps-st.fisheries.noaa.gov/stocksmart', sep = '; ') else paste(
      'https://repository.library.noaa.gov/view/noaa/71158/noaa_71158_DS1.pdf',
      'https://repository.library.noaa.gov/view/noaa/21164',
      'https://repository.library.noaa.gov/view/noaa/74400',
      'https://apps-st.fisheries.noaa.gov/stocksmart', sep = '; '),
    review_date = '2026-10-30',
    decision_reason = paste(
      'The latest official assessment is a biomass-based JABBA surplus-production update for the current 13-species complex.',
      'Its observations are aggregate catch and aggregate CPUE, not age-disaggregated inputs, and it reports no numeric age-specific population outputs.',
      'A 2026 CNMI life-history survey is not a newer stock assessment and is not substituted for the 2025 model inputs.'),
    notes = paste(
      'Stock SMART lists this as a PIFSC assessment with Full acceptance status; the detailed report is the current production update.',
      'This is one multispecies management unit, not 13 separate cases. No canonical assessment, input, or output records were added.')
  )
})
names(review_rows) <- species$candidate_id

rows <- match(species$candidate_id, register$candidate_id)
if (anyNA(rows) || anyDuplicated(rows)) stop('Marianas bottomfish inventory IDs are missing or duplicated.',
  call. = FALSE)
if (any(!is.na(register$matched_stock_id[rows]) & nzchar(register$matched_stock_id[rows]))) {
  stop('A Marianas bottomfish candidate has a canonical stock match requiring review.', call. = FALSE)
}
for (i in seq_along(rows)) {
  other_units <- register$candidate_unit_id[-rows[i]]
  proposed_unit <- review_rows[[species$candidate_id[i]]]$candidate_unit_id
  if (any(other_units == proposed_unit, na.rm = TRUE)) {
    stop('Candidate unit key already belongs to another inventory row: ', proposed_unit,
      call. = FALSE)
  }
}

if (any(grepl('Guam|Northern Mariana|CNMI', stocks$common_name, ignore.case = TRUE), na.rm = TRUE) ||
    any(grepl('Guam|Northern Mariana|CNMI', assessments$assessment_id, ignore.case = TRUE), na.rm = TRUE) ||
    any(grepl('Guam|Northern Mariana|CNMI', inputs$assessment_id, ignore.case = TRUE), na.rm = TRUE) ||
    any(grepl('Guam|Northern Mariana|CNMI', outputs$assessment_id, ignore.case = TRUE), na.rm = TRUE)) {
  stop('Unexpected Marianas bottomfish canonical records found; review matching before updating.',
    call. = FALSE)
}

initial <- vapply(seq_along(rows), function(i) {
  row <- rows[i]
  register$match_status[row] == 'unreviewed' &&
    register$screening_status[row] == 'not_started' &&
    register$eligibility[row] == 'unresolved' &&
    (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
}, logical(1L))
reviewed <- vapply(seq_along(rows), function(i) {
  row <- rows[i]
  review <- review_rows[[species$candidate_id[i]]]
  identical(as.character(register$match_status[row]), review$match_status) &&
    identical(as.character(register$screening_status[row]), review$screening_status) &&
    identical(as.character(register$eligibility[row]), review$eligibility) &&
    identical(ifelse(is.na(register$candidate_unit_id[row]), '', register$candidate_unit_id[row]),
      review$candidate_unit_id)
}, logical(1L))
if (any(!initial & !reviewed)) stop('A Marianas bottomfish candidate has an unexpected prior review state.',
  call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && any(initial)) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  for (i in which(initial)) {
    row <- rows[i]
    for (name in names(review_rows[[species$candidate_id[i]]])) {
      register[[name]][row] <- review_rows[[species$candidate_id[i]]][[name]]
    }
    tmp <- tempfile(fileext = '.csv')
    write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
    lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
    unlink(tmp)
  }
  writeLines(lines, register_path, useBytes = TRUE)
}

cat('Screened the Guam 2024 and CNMI 2025 current bottomfish-complex assessments; both are ineligible for age-disaggregated inputs.\n')

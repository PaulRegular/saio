root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_ices_pelagic_redfish_2026')
sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')

expected <- data.frame(
  candidate_id = c('ICES:reb.2127.dp', 'ICES:reb.2127.sp'),
  candidate_unit_id = c('ices_reb_2127_deep', 'ices_reb_2127_shallow'),
  assessment_year = c(2024L, 2024L),
  assessment_key = c('19189', '19246'),
  data_category = c('2.13', '3'),
  assessment_type = c('Analytical age-length structured, catches in model and forecast',
    'Survey trends-based assessment'),
  file = c('ICES_SAG_Source_19189_reb_dp.html', 'ICES_SAG_Source_19246_reb_sp.html'),
  mfri_file = c('MFRI_Deep_Pelagic_Redfish_2024.html',
    'MFRI_Shallow_Pelagic_Redfish_2024.html'),
  stringsAsFactors = FALSE)

expected_hashes <- c(
  ICES_SAG_Source_19189_reb_dp.html = 'dee103ddeaa27531e7ad3999604e544339715cb6d315bf1123c7ea48eef1e9b5',
  ICES_SAG_Source_19246_reb_sp.html = '4d02600b73264529b13c2002e8bcccdebf95d1730d42d5b1d9f155620735083b',
  MFRI_Deep_Pelagic_Redfish_2024.html = 'afc75231c8ba14d0c868eb090b84bd18741e489a1a49cc587ca3c26a39f2ed12',
  MFRI_Shallow_Pelagic_Redfish_2024.html = 'fb7e96cbd0590bdf2a1ec5f03b0463c64080a8d09542e7aa16487e175929a5b3')

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hash
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The cached redfish source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || as.numeric(manifest$bytes[row]) != file.info(path)$size ||
      tolower(manifest$sha256[row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached redfish source differs from manifest: ', file, call. = FALSE)
}

sid_manifest <- read.csv(file.path(root, 'source_cache', 'discovery_ices_sid', 'sources.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
sid_row <- match('stock_list_2026.json', sid_manifest$file)
if (is.na(sid_row) || !file.exists(sid_path) ||
    sid_manifest$retrieved_on[sid_row] != '2026-10-28' ||
    sha256_file(sid_path) !=
      '913d6a3eeab9449ae3cd0dd15661a150d36ff79b6e6a9ba78d86d46ba1035f42')
  stop('The cached ICES SID snapshot failed provenance checks.', call. = FALSE)

sid_text <- paste(readLines(sid_path, warn = FALSE), collapse = '')
sid_record <- function(stock_code) {
  token <- paste0('"StockKeyLabel":"', stock_code, '"')
  location <- regexpr(token, sid_text, fixed = TRUE)[1L]
  if (location < 0L) stop('Stock missing from cached SID: ', stock_code, call. = FALSE)
  before <- substr(sid_text, 1L, location)
  start <- max(unlist(gregexpr('\\{', before, perl = TRUE)))
  after <- substr(sid_text, location, nchar(sid_text))
  finish <- regexpr('\\}', after, perl = TRUE)[1L] + location - 1L
  substr(sid_text, start, finish)
}
sid_field <- function(record, name) {
  pattern <- paste0('"', name, '"\\s*:\\s*(?:"([^"]*)"|([^,}]*))')
  pieces <- regmatches(record, regexec(pattern, record, perl = TRUE))[[1L]]
  if (!length(pieces)) return(NA_character_)
  trimws(if (nzchar(pieces[2L])) pieces[2L] else pieces[3L])
}
records <- lapply(sub('^ICES:', '', expected$candidate_id), sid_record)
sid_year <- vapply(records, sid_field, character(1L), name = 'YearOfLastAssessment')
sid_key <- vapply(records, sid_field, character(1L), name = 'AssessmentKey')
sid_category <- vapply(records, sid_field, character(1L), name = 'DataCategory')
sid_method <- vapply(records, sid_field, character(1L), name = 'AssessmentType')
if (!identical(sid_year, as.character(expected$assessment_year)) ||
    !identical(sid_key, expected$assessment_key) ||
    !identical(sid_category, expected$data_category) ||
    !identical(sid_method, expected$assessment_type))
  stop('Cached SID records differ from the reviewed redfish units.', call. = FALSE)

graph_text <- vapply(expected$file, function(file)
  paste(readLines(file.path(cache, file), warn = FALSE), collapse = ' '), character(1L))
for (i in seq_len(nrow(expected))) {
  if (!grepl(sub('^ICES:', '', expected$candidate_id[i]), graph_text[i], fixed = TRUE) ||
      !grepl(expected$assessment_key[i], graph_text[i], fixed = TRUE) ||
      !grepl(paste0('id="lblYear">', expected$assessment_year[i]),
        graph_text[i], perl = TRUE))
    stop('Standard Graphs source does not match SID for ', expected$candidate_id[i], '.',
      call. = FALSE)
}

html_text <- function(file) {
  text <- paste(readLines(file.path(cache, file), warn = FALSE), collapse = ' ')
  text <- gsub('<[^>]+>', ' ', text)
  text <- gsub('&nbsp;|&#160;', ' ', text)
  tolower(gsub('\\s+', ' ', text))
}
deep_text <- html_text(expected$mfri_file[1L])
shallow_text <- html_text(expected$mfri_file[2L])
required_deep <- c('gadget model', 'length and age data from catches',
  'natural mortality is assumed to be 0.05',
  'age data have not been available since 2013', 'july 2024 covered',
  'expressed relative to the average of the time-series')
if (!all(vapply(required_deep, grepl, logical(1L), x = deep_text, fixed = TRUE)))
  stop('Deep pelagic redfish report no longer supports the documented evidence.', call. = FALSE)
required_shallow <- c('current assessment relies on survey information',
  'used as a relative index', 'next survey is planned for 2027')
if (!all(vapply(required_shallow, grepl, logical(1L), x = shallow_text, fixed = TRUE)))
  stop('Shallow pelagic redfish report no longer supports the documented evidence.',
    call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (any(tolower(sub('^ICES:', '', expected$candidate_id)) %in%
    tolower(trimws(stocks$authority_stock_id)), na.rm = TRUE))
  stop('One of the reviewed units already appears under its exact ICES code in stocks.csv.',
    call. = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

decisions <- list(
  list(
    candidate_unit_id = expected$candidate_unit_id[1L],
    match_status = 'new', screening_status = 'screened', eligibility = 'unresolved',
    catch_age_evidence = 'The 2024 Gadget assessment uses commercial catches and age data from catches, but the detailed native catch-at-age series has not yet been located.',
    survey_age_evidence = 'The international acoustic and trawl survey supplies a biomass index and length data. No age-specific survey index is identified in the reviewed 2024 source.',
    weights_evidence = 'Weight-at-age or weight-at-length data are not specified in the reviewed advice page; verify from the assessment report or native Gadget inputs.',
    maturity_evidence = 'Maturity-at-age or maturity-at-length is not specified in the reviewed advice page; verify from the assessment report or native Gadget inputs.',
    mortality_evidence = 'Natural mortality is fixed at 0.05 for all ages and years.',
    timing_evidence = 'International trawl-acoustic surveys are conducted during June-August; the 2024 survey covered June-July. Preserve the actual timing from the source if inputs are later imported.',
    output_evidence = 'The 2024 run reports relative recruitment, relative SSB and relative F, plus catch; outputs are scaled relative to the time-series mean and do not provide N-at-age, F-at-age or M-at-age surfaces.',
    detailed_source_url = 'https://www.hafogvatn.is/static/extras/images/11-deep-pelagic-redfish_2024_advice_en.html',
    review_date = '2026-10-31',
    decision_reason = 'The current production run is age-length structured and has recoverable input and aggregate output descriptions. Keep eligibility unresolved until stock-specific weight and maturity inputs and the native catch-age data are verified.',
    notes = 'Distinct deep-pelagic assessment unit, not a duplicate of the Northeast Arctic beaked-redfish stock already in the database. Catch/age data are unavailable after 2013; relative recruitment from 2009 onward is assumed at the earlier geometric mean. ICES source data are cached locally; see source_reviews/ices_pelagic_redfish_2026.md.'),
  list(
    candidate_unit_id = expected$candidate_unit_id[2L],
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    catch_age_evidence = 'The current survey-trends assessment does not use catch-at-age; reviewed sources report commercial catches/landings but no age-disaggregated catch series.',
    survey_age_evidence = 'Assessment uses an aggregate acoustic biomass index and survey information, not an age-specific survey index.',
    weights_evidence = 'Not required by the current trend-based assessment; no age-specific weight surface was identified.',
    maturity_evidence = 'Not required by the current trend-based assessment; no maturity-at-age input was identified.',
    mortality_evidence = 'The current survey-trends method does not estimate age-specific natural mortality.',
    timing_evidence = 'The acoustic redfish survey is irregular, with recent adequate coverage in 2021 and 2024; the 2024 assessment states the next survey is planned for 2027.',
    output_evidence = 'The current source reports aggregate biomass-index trends and catch information, not age-specific population or mortality outputs.',
    detailed_source_url = 'https://www.hafogvatn.is/static/extras/images/11-shallow-pelagic-redfish_2024_advice_en.html',
    review_date = '2026-10-31',
    decision_reason = 'The latest production method is a survey-trends assessment based on aggregate biomass indicators, without age-disaggregated assessment inputs or fitted age-specific outputs.',
    notes = 'Distinct shallow-pelagic assessment unit, not a duplicate of the deep-pelagic unit or the Northeast Arctic beaked-redfish stock. This decision concerns the latest official 2024 method, not availability of age samples for other purposes. ICES source data are cached locally; see source_reviews/ices_pelagic_redfish_2026.md.'))

changed <- integer()
for (i in seq_len(nrow(expected))) {
  row <- match(expected$candidate_id[i], register$candidate_id)
  if (is.na(row)) stop('Candidate missing: ', expected$candidate_id[i], call. = FALSE)
  if (!is.na(register$candidate_unit_id[row]) && nzchar(register$candidate_unit_id[row]) &&
      register$candidate_unit_id[row] != expected$candidate_unit_id[i])
    stop('Candidate already has a different unit crosswalk: ', expected$candidate_id[i],
      call. = FALSE)
  review <- decisions[[i]]
  current <- lapply(names(review), function(column) as.character(register[[column]][row]))
  names(current) <- names(review)
  desired <- lapply(review, as.character)
  already_reviewed <- all(vapply(names(review), function(column)
    identical(current[[column]], desired[[column]]), logical(1L)))
  pristine <- register$match_status[row] == 'unreviewed' &&
    register$screening_status[row] == 'not_started' &&
    register$eligibility[row] == 'unresolved' &&
    (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
  if (!pristine && !already_reviewed)
    stop('Candidate has an unexpected pre-existing review: ', expected$candidate_id[i],
      call. = FALSE)
  if (!already_reviewed) {
    for (column in names(review)) register[[column]][row] <- review[[column]]
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE],
      expected$candidate_id[i])
    changed <- c(changed, i)
  }
}
cat('Reviewed both ICES pelagic beaked-redfish units; updated', length(changed),
  'candidate rows. One remains unresolved pending input recovery; one is ineligible for the age-structured set.\n')

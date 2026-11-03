root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_ices_elasmobranch_group_2026')
sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')

expected <- data.frame(
  candidate_id = c('ICES:sho.27.67', 'ICES:gfb.27.nea', 'ICES:raj.27.89a',
    'ICES:rjb.27.89a', 'ICES:rjn.27.8c', 'ICES:syc.27.8abd'),
  candidate_unit_id = c('ices_sho_27_67', 'ices_gfb_27_nea', 'ices_raj_27_89a',
    'ices_rjb_27_89a', 'ices_rjn_27_8c', 'ices_syc_27_8abd'),
  assessment_year = c(2023L, 2026L, 2024L, 2024L, 2026L, 2025L),
  assessment_key = c('18348', '23774', '19096', '13860', '19116', '21069'),
  graph_year = c(2023L, 2026L, 2024L, 2020L, 2024L, 2025L),
  data_category = c('3.9', '3.2', '5.9', '6.3', '3', '3.9'),
  sid_method = c('Survey trends-based assessment', 'Survey trends-based assessment',
    'no assessment', 'no assessment',
    'Trends on biomass index and length-based indicators',
    'Trends biomass index and length-based indicator'),
  stringsAsFactors = FALSE)

expected_files <- c(
  ICES_SAG_Source_18348_sho.html = 'a984c72b42a9133261364fb4d0ec0297c4ea5f4e39b8d958b7bcda6ec2e7093f',
  ICES_SAG_Source_23774_gfb.html = '27572c842ee3ff3e7d0f2128c6a657b221182e81b55eedd799bc6808c9d90c73',
  ICES_SAG_Source_19096_raj.html = '74c902fef450b7a5de8d383754ed1ea8802ebe37a886ee27c50837b460d13914',
  ICES_SAG_Source_13860_rjb.html = '519e3256fa95adadc366696bbbb7ab48c39d4a5ce666639aaea335e888e33d21',
  ICES_SAG_Source_19116_rjn.html = '53474af94e3b2d74bd92865364be270314a22cea00d7d6c0c731d00ce6d2cb39',
  ICES_SAG_Source_21069_syc.html = 'fdd1256e9b02947c0461845739c33df5052fcf1e59d56eed4b8ce75408cc3c9a')

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
if (nrow(manifest) != length(expected_files) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_files)))
  stop('The cached ICES source manifest is incomplete.', call. = FALSE)
for (file in names(expected_files)) {
  row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || as.numeric(manifest$bytes[row]) != file.info(path)$size ||
      tolower(manifest$sha256[row]) != expected_files[[file]] ||
      sha256_file(path) != expected_files[[file]])
    stop('Cached ICES source differs from manifest: ', file, call. = FALSE)
}

sid_manifest <- read.csv(file.path(root, 'source_cache', 'discovery_ices_sid', 'sources.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
sid_row <- match('stock_list_2026.json', sid_manifest$file)
if (is.na(sid_row) || !file.exists(sid_path) ||
    sid_manifest$retrieved_on[sid_row] != '2026-10-28' ||
    sha256_file(sid_path) != '913d6a3eeab9449ae3cd0dd15661a150d36ff79b6e6a9ba78d86d46ba1035f42')
  stop('The cached ICES SID inventory snapshot failed provenance checks.', call. = FALSE)

sid_text <- paste(readLines(sid_path, warn = FALSE), collapse = '')
sid_record <- function(stock_code) {
  token <- paste0('"StockKeyLabel":"', stock_code, '"')
  location <- regexpr(token, sid_text, fixed = TRUE)[1L]
  if (location < 0L) stop('Stock is missing from the cached ICES SID snapshot: ', stock_code,
    call. = FALSE)
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
sid_records <- lapply(sub('^ICES:', '', expected$candidate_id), sid_record)
sid_year <- vapply(sid_records, sid_field, character(1L), name = 'YearOfLastAssessment')
sid_key <- vapply(sid_records, sid_field, character(1L), name = 'AssessmentKey')
sid_category <- vapply(sid_records, sid_field, character(1L), name = 'DataCategory')
sid_method <- vapply(sid_records, sid_field, character(1L), name = 'AssessmentType')
if (!identical(sid_year, as.character(expected$assessment_year)) ||
    !identical(sid_key, expected$assessment_key) ||
    !identical(sid_category, expected$data_category) ||
    !identical(sid_method, expected$sid_method))
  stop('The 2026 ICES SID snapshot does not match the reviewed units.', call. = FALSE)

graph_text <- vapply(names(expected_files), function(file)
  paste(readLines(file.path(cache, file), warn = FALSE), collapse = ' '), character(1L))
for (i in seq_len(nrow(expected))) {
  if (!grepl(sub('^ICES:', '', expected$candidate_id[i]), graph_text[i], fixed = TRUE) ||
      !grepl(expected$assessment_key[i], graph_text[i], fixed = TRUE) ||
      !grepl(paste0('id="lblYear">', expected$graph_year[i]), graph_text[i], fixed = TRUE))
    stop('Standard Graphs source does not match SID key/year for ',
      expected$candidate_id[i], '.', call. = FALSE)
}

decisions <- data.frame(
  catch_age_evidence = c(
    'The 2023 SID method is survey-trends-based. Standard Graphs publishes an aggregate B_Index series and landings, not catch-at-age.',
    'The 2026 SID method is survey-trends-based. Standard Graphs publishes aggregate B_index, landings, catches, and discards, not catch-at-age.',
    'The 2024 SID entry says no assessment. Its current Standard Graphs source contains landings only; no catch-at-age series is published.',
    'The 2024 SID entry says no assessment. Its linked Standard Graphs record is from 2020 and contains landings only; no current catch-at-age series is published.',
    'The 2026 SID describes biomass-index trends and length-based indicators. The linked Standard Graphs record is from 2024 and does not provide catch-at-age for the 2026 run.',
    'The 2025 SID describes biomass-index trends and length-based indicators. Standard Graphs reports aggregate catches, landings, and discards, not catch-at-age.'),
  survey_age_evidence = c(
    'The current method uses an aggregate survey biomass index; the published source has no age-specific survey index.',
    'The current method is survey-trends-based and the published source provides an aggregate B_index, not an age-specific tuning series.',
    'No age-specific survey index is identified for the 2024 no-assessment entry; the graph data are landings only.',
    'No age-specific survey index is identified for the 2024 no-assessment entry; the linked 2020 graph data are landings only.',
    'The current method is explicitly based on aggregate biomass-index trends and length indicators; the linked graph data do not provide age-specific survey indices.',
    'The current method uses biomass-index trends and length indicators; the published source provides B_index, not an age-specific survey index.'),
  outputs = c(
    'The 2023 graph reports B_Index and landings, with no N-at-age, F-at-age, or M-at-age.',
    'The 2026 graph reports aggregate B_index, landings, catches, and discards; it provides no age-indexed population or mortality outputs.',
    'The 2024 graph table contains landings only. Its generic SSB/F labels do not have age-indexed output rows.',
    'The 2026 SID retains source key 13860, but that graph identifies itself as assessment year 2020 and contains landings only. No current 2024 age-indexed output is exposed.',
    'The 2026 SID reports a trend/length method, but its retained source key 19116 is a 2024 graph; no 2026 age-indexed output is exposed.',
    'The 2025 graph reports aggregate B_index, Fproxy, catches, landings, and discards; it provides no N-at-age, F-at-age, or M-at-age.'),
  stringsAsFactors = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
official_codes <- tolower(sub('^ICES:', '', expected$candidate_id))
if (any(official_codes %in% tolower(trimws(stocks$authority_stock_id)), na.rm = TRUE))
  stop('One of the reviewed ICES units already appears under its exact official code in stocks.csv.',
    call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
review_date <- '2026-10-31'
changed <- integer()
for (i in seq_len(nrow(expected))) {
  row <- match(expected$candidate_id[i], register$candidate_id)
  if (is.na(row)) stop('Candidate is missing: ', expected$candidate_id[i], call. = FALSE)
  if (!is.na(register$candidate_unit_id[row]) && nzchar(register$candidate_unit_id[row]) &&
      register$candidate_unit_id[row] != expected$candidate_unit_id[i])
    stop('Candidate already has a different crosswalk key: ', expected$candidate_id[i], call. = FALSE)

  key_url <- paste0('https://standardgraphs.ices.dk/ViewSourceData.aspx?key=',
    expected$assessment_key[i])
  source_note <- paste('Reviewed against the current ICES SID snapshot and its linked Standard Graphs source. ',
    'See source_reviews/ices_elasmobranch_group_2026.md. ',
    'The SID AssessmentType is: ', expected$sid_method[i], '.', sep = '')
  decision <- paste('The current ICES method is not an age-structured population assessment, and the reviewed official source does not provide age-disaggregated assessment inputs or outputs. Screened ineligible for the age-disaggregated set; this does not establish that age samples are unavailable for other research uses.')
  review <- list(
    candidate_unit_id = expected$candidate_unit_id[i],
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    catch_age_evidence = decisions$catch_age_evidence[i],
    survey_age_evidence = decisions$survey_age_evidence[i],
    weights_evidence = 'No age-specific weight surface is identified in the current SID method or linked Standard Graphs source; the reviewed method is not an age-structured population model.',
    maturity_evidence = 'No maturity-at-age input is identified in the current SID method or linked Standard Graphs source; the reviewed method is not an age-structured population model.',
    mortality_evidence = paste('No age-specific M assumption is reported for the current method (', expected$sid_method[i], ').', sep = ''),
    timing_evidence = 'No age-specific survey timing is reported for the aggregate trend or landings method.',
    output_evidence = decisions$outputs[i], detailed_source_url = key_url,
    review_date = review_date, decision_reason = decision, notes = source_note)
  current <- lapply(names(review), function(column) as.character(register[[column]][row]))
  names(current) <- names(review)
  desired <- lapply(review, as.character)
  already_reviewed <- all(vapply(names(review), function(column)
    identical(current[[column]], desired[[column]]), logical(1L)))
  pristine <- register$match_status[row] == 'unreviewed' &&
    register$screening_status[row] == 'not_started' &&
    register$eligibility[row] == 'unresolved'
  if (!pristine && !already_reviewed)
    stop('Candidate has an unexpected pre-existing review: ', expected$candidate_id[i], call. = FALSE)
  if (!already_reviewed) {
    for (column in names(review)) register[[column]][row] <- review[[column]]
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE],
      expected$candidate_id[i])
    changed <- c(changed, i)
  }
}

cat('Screened', nrow(expected), 'ICES elasmobranch inventory units as ineligible for age-structured source curation; updated',
  length(changed), 'candidate rows.\n')

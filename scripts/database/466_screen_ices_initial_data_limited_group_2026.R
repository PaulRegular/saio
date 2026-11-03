root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_ices_screen_first_six_2026')
sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')

expected <- data.frame(
  candidate_id = c('ICES:rhg.27.nea', 'ICES:aru.27.6b7-1012',
    'ICES:mur.27.67a-ce-k89a', 'ICES:rji.27.67', 'ICES:rju.27.7bj',
    'ICES:rjm.27.67bj'),
  candidate_unit_id = c('ices_rhg_27_nea', 'ices_aru_27_6b7_1012',
    'ices_mur_27_67a_ce_k89a', 'ices_rji_27_67', 'ices_rju_27_7bj',
    'ices_rjm_27_67bj'),
  advice_id = c('3961', '3954', '7229', '3780', '3781', '7166'),
  graph_key = c('20946', '20919', '25910', '19099', '19179', '25849'),
  assessment_year = c(2025L, 2025L, 2026L, 2024L, 2024L, 2026L),
  data_category = c('6.3', '3.2', '5.2', '5.2', '6.3', '3'),
  sid_method = c('no assessment', 'Survey trends-based assessment',
    'no assessment', 'no assessment', 'no assessment',
    'Trends from biomass index and length-based indicators'),
  stringsAsFactors = FALSE)

expected_files <- c(
  ICES_Advice_3961_rhg_2025.html = '7678bd401363d575e3ad1a839ac87ba21877a0df4278b86dad8c086b310e40b0',
  ICES_Advice_3954_aru_2025.html = '4eb531111b6bdb614d0fe2fbf2861f1231df464a29e3b4edaed9f878bd3f10a6',
  ICES_Advice_7229_mur_2026.html = 'cc6091378beb91277a218ed2b1d3e63ed123a1fefc2d7ef6f27851aa625ab09e',
  ICES_Advice_3780_rji_2024.html = '359beefb9f1f0d38172416f1febe1ecfebd3d7f4de88a0740ca1c39faf091a68',
  ICES_Advice_3781_rju_2024.html = 'a9e4133c4a617d0d614501bee3d17a6aa540677239424573269e5bfe9aff9eb9',
  ICES_Advice_7166_rjm_2026.html = '498fde28462e40f95a7c107e94b78d87716c3bd584716b0a84d23e7db8e9f1bc',
  ICES_SAG_Source_20946_rhg_2025.html = '09aa8f8e3d85bc7a7a507a7405c2df2d327f9173d162afa70ecce8c5e9cec80f',
  ICES_SAG_Source_20919_aru_2025.html = '5062a2e98d9d04b81e35df5d4e7cfd0b000f5963b8e88bddfaf5b96418e29e05',
  ICES_SAG_Source_25910_mur_2026.html = '2d462394cab0fb84089c15a820095a62fd5a84a252d7fdaf98f8a46eb19eafd5',
  ICES_SAG_Source_19099_rji_2024.html = '47c15a5273932bd812934a5a2b39594d18a3343eef1d625addb252ab3854c9f8',
  ICES_SAG_Source_19179_rju_2024.html = '3a305180d891147a02d82c7252937f4d5300b8c7ecd9734252798bd93c8bfdfe',
  ICES_SAG_Source_25849_rjm_2026.html = 'ead781d8d2f8b5bbb9469c46e20e0bfebf0d446301b5ea00342b9ac6109faf1e')

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
sid_manifest_row <- match('stock_list_2026.json', sid_manifest$file)
if (is.na(sid_manifest_row) || !file.exists(sid_path) ||
    sid_manifest$retrieved_on[sid_manifest_row] != '2026-10-28' ||
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
  match <- regexec(pattern, record, perl = TRUE)
  pieces <- regmatches(record, match)[[1L]]
  if (!length(pieces)) return(NA_character_)
  value <- if (nzchar(pieces[2L])) pieces[2L] else pieces[3L]
  trimws(value)
}
sid <- lapply(sub('^ICES:', '', expected$candidate_id), sid_record)
sid_year <- vapply(sid, sid_field, character(1L), name = 'YearOfLastAssessment')
sid_category <- vapply(sid, sid_field, character(1L), name = 'DataCategory')
sid_method <- vapply(sid, sid_field, character(1L), name = 'AssessmentType')
if (!identical(sid_year, as.character(expected$assessment_year)) ||
    !identical(sid_category, expected$data_category) ||
    !identical(sid_method, expected$sid_method))
  stop('The 2026 ICES SID snapshot does not match the reviewed stock methods.', call. = FALSE)

read_cached <- function(file) paste(readLines(file.path(cache, file), warn = FALSE),
  collapse = ' ')
advice_files <- c('ICES_Advice_3961_rhg_2025.html', 'ICES_Advice_3954_aru_2025.html',
  'ICES_Advice_7229_mur_2026.html', 'ICES_Advice_3780_rji_2024.html',
  'ICES_Advice_3781_rju_2024.html', 'ICES_Advice_7166_rjm_2026.html')
graph_files <- c('ICES_SAG_Source_20946_rhg_2025.html', 'ICES_SAG_Source_20919_aru_2025.html',
  'ICES_SAG_Source_25910_mur_2026.html', 'ICES_SAG_Source_19099_rji_2024.html',
  'ICES_SAG_Source_19179_rju_2024.html', 'ICES_SAG_Source_25849_rjm_2026.html')
advice_text <- vapply(advice_files, read_cached, character(1L))
graph_text <- vapply(graph_files, read_cached, character(1L))
for (i in seq_len(nrow(expected))) {
  stock_code <- sub('^ICES:', '', expected$candidate_id[i])
  if (!grepl(stock_code, advice_text[i], fixed = TRUE) ||
      !grepl(stock_code, graph_text[i], fixed = TRUE) ||
      !grepl(expected$assessment_year[i], advice_text[i], fixed = TRUE) ||
      !grepl(expected$graph_key[i], graph_text[i], fixed = TRUE))
    stop('Advice and graph sources do not identify ', expected$candidate_id[i], '.', call. = FALSE)
}

decisions <- data.frame(
  catch_age_evidence = c(
    'The current 2025 advice is category 6.3 with no assessment; its published graph source contains annual total landings only, not catch-at-age.',
    'The 2025 ICES SID identifies a survey-trends-based assessment. The published source reports aggregate B_index (kg/haul), landings, discards, and a length-based fishing-pressure proxy; it does not expose catch-at-age used in an age-structured likelihood.',
    'The current 2026 advice is category 5.2 with no assessment and landings advice. The published graph source contains annual total landings only.',
    'The current 2024 advice is category 5 with no assessment and landings advice. The published graph source contains annual total landings only.',
    'The current 2024 advice is category 6.3, with a zero-catch precautionary recommendation and no age-structured assessment inputs reported.',
    'The 2026 SID describes trends from a biomass index and length-based indicators. Published outputs are an aggregate B_index, total landings, and length-based fishing-pressure proxy, not age-structured population outputs.'),
  survey_age_evidence = c(
    'No age-specific survey input is reported for the current advice run; the published source contains landings only.',
    'The current assessment is explicitly survey-trends-based and the official source reports only an aggregate biomass index, not age-specific survey tuning series.',
    'No age-specific survey input is reported for the current advice run; the published source contains landings only.',
    'No age-specific survey input is reported for the current advice run; the published source contains landings only.',
    'No age-specific survey input is reported for the current advice run; the published source does not expose an age-specific population index.',
    'The current method uses an aggregate biomass index; the published outputs do not provide abundance indices by age.'),
  outputs = c(
    '2025 Standard Graphs source data show total landings for 1990–2024. The graph template labels stock size as SSB and fishing pressure as F, but contains no numeric age-indexed N, F, or M outputs.',
    '2025 Standard Graphs source data identify stock size as B_index in kg per haul and fishing pressure as Fproxy; annual landings, catches, and discards are aggregate. No N-at-age, F-at-age, or M-at-age is published.',
    '2026 Standard Graphs source data report landings for 1975–2025 and no fitted age-structured population outputs.',
    '2024 Standard Graphs source data report landings for 2009–2024 and no fitted age-structured population outputs.',
    'The 2024 advice is a precautionary zero-catch recommendation; no fitted age-structured population outputs are provided in the current published source.',
    '2026 Standard Graphs source data identify stock size as B_index and fishing pressure as Lfm/Lmean; annual values are aggregate and no N-at-age, F-at-age, or M-at-age is published.'),
  stringsAsFactors = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stock_codes <- tolower(trimws(stocks$authority_stock_id))
official_codes <- tolower(sub('^ICES:', '', expected$candidate_id))
if (any(official_codes %in% stock_codes, na.rm = TRUE))
  stop('One of the reviewed ICES units already appears under its exact official code in stocks.csv.',
    call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
review_date <- '2026-10-31'
changed <- integer()
for (i in seq_len(nrow(expected))) {
  row <- match(expected$candidate_id[i], register$candidate_id)
  if (is.na(row)) stop('Candidate is missing: ', expected$candidate_id[i], call. = FALSE)
  if (!is.na(register$candidate_unit_id[row]) &&
      nzchar(register$candidate_unit_id[row]) &&
      register$candidate_unit_id[row] != expected$candidate_unit_id[i])
    stop('Candidate already has a different crosswalk key: ', expected$candidate_id[i], call. = FALSE)

  url <- paste0('https://asd.ices.dk/viewAdvice/', expected$advice_id[i],
    '; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=', expected$graph_key[i])
  source_note <- paste('Latest ICES advice/run reviewed from 2026 SID and the linked advice and Standard Graphs sources. See source_reviews/ices_initial_data_limited_group_2026.md. ',
    'The SID AssessmentType is: ', expected$sid_method[i], '.', sep = '')
  decision <- paste('The latest advice-linked method is not an age-structured population assessment, and current official source outputs do not provide age-specific assessment inputs or population outputs. Screened ineligible for the age-disaggregated assessment set; this does not imply that age samples are unavailable for other research uses.')
  review <- list(
    candidate_unit_id = expected$candidate_unit_id[i],
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    catch_age_evidence = decisions$catch_age_evidence[i],
    survey_age_evidence = decisions$survey_age_evidence[i],
    weights_evidence = 'No age-specific weight surface is identified in the current advice or published assessment outputs; the reviewed run does not use an age-structured population model.',
    maturity_evidence = 'No maturity-at-age input is identified in the current advice or published assessment outputs; the reviewed run does not use an age-structured population model.',
    mortality_evidence = paste('No age-specific M assumption or age-structured mortality surface is reported for the current method (', expected$sid_method[i], ').', sep = ''),
    timing_evidence = 'No age-specific survey observation timing is needed or reported for the published aggregate trend/landings advice.',
    output_evidence = decisions$outputs[i], detailed_source_url = url,
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

cat('Screened', nrow(expected), 'ICES inventory units as ineligible for age-structured source curation; updated',
  length(changed), 'candidate rows.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_ray_method_group_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')
sid_url <- 'https://sid.ices.dk/services/year/2026'
sid_hash <- '913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42'

expected <- data.frame(
  code = c('sho.27.89a', 'rjc.27.3a47d', 'rjh.27.4bc7d', 'rjn.27.3a4',
    'rjn.27.678abd', 'rjm.27.7ae-h', 'rjc.27.7afg', 'syt.27.67'),
  candidate_unit_id = c('ices_sho_27_89a', 'ices_rjc_27_3a47d',
    'ices_rjh_27_4bc7d', 'ices_rjn_27_3a4', 'ices_rjn_27_678abd',
    'ices_rjm_27_7ae_h', 'ices_rjc_27_7afg', 'ices_syt_27_67'),
  year = c(2025L, 2025L, 2025L, 2025L, 2026L, 2026L, 2026L, 2025L),
  key = c('21013', '21096', '21097', '21067', '25826', '25810', '25860', '21014'),
  scientific_name = c('Galeus melastomus', 'Raja clavata', 'Raja brachyura',
    'Leucoraja naevus', 'Leucoraja naevus', 'Raja montagui', 'Raja clavata',
    'Scyliorhinus stellaris'),
  assessment_type = c('Survey trends-based assessment', 'SPiCT', 'SPiCT',
    'Trends biomass index and length-based indicator',
    'Surplus Production Model in Continuous Time (SPiCT)',
    'Trends from biomass index and length-based indicators',
    'Trends from biomass index and length-based indicators',
    'Trends biomass index and length-based indicator'),
  stringsAsFactors = FALSE)
expected$candidate_id <- paste0('ICES:', expected$code)

expected_hashes <- c(
  ICES_SAG_Source_21013_sho_27_89a.html = '94f0f76fc50f7a9fa1dc8be441311e346e1998ea097db36fc54eb55d52be07aa',
  ICES_SAG_Source_21096_rjc_27_3a47d.html = '65541a786268114e06215a6ba9171063124d176ab996f74ce25d62ad0d602487',
  ICES_SAG_Source_21097_rjh_27_4bc7d.html = '1cb7b06586538b9407f8ecb8dc8c057e9867f8b968666036be41cdd1829e5740',
  ICES_SAG_Source_21067_rjn_27_3a4.html = 'de6d9f9e8465a7a04c0b1826e691e8942c1d44703c00f546031f6d7a5755fb09',
  ICES_SAG_Source_25826_rjn_27_678abd.html = '39aea0c6d5add6c656ab7bb0a2497490ab304e99118dac5720fe0e7c35d140f4',
  ICES_SAG_Source_25810_rjm_27_7ae_h.html = 'c77443bf3ef029c1eb9d1f523684487582242720a4f72262d5dd8e57cfe87206',
  ICES_SAG_Source_25860_rjc_27_7afg.html = '4a67feb9ba9a4248995d3ed5c1ff8d77eb3b98c513cffe6b29ac082462c5b594',
  ICES_SAG_Source_21014_syt_27_67.html = '01d3b782c5ca0d66ffd8175952af66bff4e4031b99ca65fc4c1bbdfbd2ed1af0')

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify ICES source checksum.', call. = FALSE)
  hash
}

sid_manifest <- read.csv(file.path(dirname(sid_path), 'sources.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
sid_row <- match(basename(sid_path), sid_manifest$file)
if (is.na(sid_row) || sid_manifest$url[sid_row] != sid_url ||
    sid_manifest$retrieved_on[sid_row] != '2026-10-28' ||
    toupper(sid_manifest$sha256[sid_row]) != sid_hash ||
    !file.exists(sid_path) || toupper(sha256_file(sid_path)) != sid_hash)
  stop('The cached 2026 ICES SID snapshot failed provenance validation.', call. = FALSE)

manifest_path <- file.path(cache, 'sources.csv')
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)) ||
    any(manifest$retrieved_on != '2026-11-01'))
  stop('The cached ICES Standard Graphs manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  row <- match(file, manifest$file)
  path <- file.path(cache, file)
  key <- sub('^ICES_SAG_Source_([0-9]+)_.*$', '\\1', file)
  expected_url <- paste0('https://standardgraphs.ices.dk/ViewSourceData.aspx?key=', key)
  if (!file.exists(path) || as.numeric(manifest$bytes[row]) != file.info(path)$size ||
      manifest$url[row] != expected_url ||
      tolower(manifest$sha256[row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached ICES source differs from manifest: ', file, call. = FALSE)
}

sid_text <- paste(readLines(sid_path, warn = FALSE), collapse = '')
sid_record <- function(code) {
  token <- paste0('"StockKeyLabel":"', code, '"')
  location <- regexpr(token, sid_text, fixed = TRUE)[1L]
  if (location < 0L) stop('Stock is missing from the cached ICES SID: ', code,
    call. = FALSE)
  start <- max(unlist(gregexpr('\\{', substr(sid_text, 1L, location), perl = TRUE)))
  finish <- regexpr('\\}', substr(sid_text, location, nchar(sid_text)), perl = TRUE)[1L] +
    location - 1L
  substr(sid_text, start, finish)
}
sid_field <- function(record, name) {
  pattern <- paste0('"', name, '"\\s*:\\s*(?:"([^"]*)"|([^,}]*))')
  pieces <- regmatches(record, regexec(pattern, record, perl = TRUE))[[1L]]
  if (!length(pieces)) return(NA_character_)
  trimws(if (nzchar(pieces[2L])) pieces[2L] else pieces[3L])
}
records <- lapply(expected$code, sid_record)
sid_year <- vapply(records, sid_field, character(1L), name = 'YearOfLastAssessment')
sid_key <- vapply(records, sid_field, character(1L), name = 'AssessmentKey')
sid_method <- vapply(records, sid_field, character(1L), name = 'AssessmentType')
sid_species <- vapply(records, sid_field, character(1L), name = 'SpeciesScientificName')
if (!identical(sid_year, as.character(expected$year)) ||
    !identical(sid_key, expected$key) ||
    !identical(sid_method, expected$assessment_type) ||
    !identical(sid_species, expected$scientific_name))
  stop('The ICES SID snapshot does not match the reviewed stock identities or methods.',
    call. = FALSE)

graph_text <- vapply(names(expected_hashes), function(file)
  paste(readLines(file.path(cache, file), warn = FALSE), collapse = ' '), character(1L))
for (i in seq_len(nrow(expected))) {
  if (!grepl(paste0('id="lblStockCode">', expected$code[i]), graph_text[i], fixed = TRUE) ||
      !grepl(paste0('id="lblYear">', expected$year[i]), graph_text[i], fixed = TRUE) ||
      !grepl(paste0('id="lblKey">', expected$key[i]), graph_text[i], fixed = TRUE) ||
      !grepl('id="lblFAge"></span>', graph_text[i], fixed = TRUE) ||
      !grepl('id="lblFLength"></span>', graph_text[i], fixed = TRUE))
    stop('Standard Graphs identity, year, key, or age/length output does not match ',
      expected$candidate_id[i], '.', call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
official_codes <- tolower(expected$code)
if (any(official_codes %in% tolower(trimws(stocks$authority_stock_id)), na.rm = TRUE))
  stop('A screened ICES stock code already appears in stocks.csv.', call. = FALSE)
other_rows <- !candidates$candidate_id %in% expected$candidate_id
existing_unit_ids <- candidates$candidate_unit_id[other_rows]
existing_unit_ids <- existing_unit_ids[!is.na(existing_unit_ids) & nzchar(existing_unit_ids)]
if (any(expected$candidate_unit_id %in% existing_unit_ids) ||
    anyDuplicated(expected$candidate_unit_id))
  stop('A ray/dogfish candidate-unit identifier is duplicated.', call. = FALSE)

decisions <- data.frame(
  catch = c(
    'The assessment is survey-trends-based; the official graph publishes an aggregate biomass index, landings, catches, and discards, not catch-at-age.',
    'The current assessment is SPiCT. The official graph publishes aggregate catches, landings, and discards, not catch-at-age.',
    'The current assessment is SPiCT. The official graph publishes aggregate catches, landings, and discards, not catch-at-age.',
    'The assessment uses biomass-index trends and length-based indicators; the official graph publishes aggregate index, landings, and F, not catch-at-age.',
    'The current assessment is SPiCT. The official graph publishes aggregate landings and F, not catch-at-age.',
    'The assessment uses biomass-index trends and length-based indicators; the official graph publishes aggregate index and landings, not catch-at-age.',
    'The assessment uses biomass-index trends and length-based indicators; the official graph publishes aggregate index and landings, not catch-at-age.',
    'The assessment uses biomass-index trends and length-based indicators; the official graph publishes aggregate index and landings, not catch-at-age.'),
  survey = c(
    'The published assessment uses an aggregate survey biomass index; no age-specific survey index is listed.',
    'The SPiCT assessment uses aggregate biomass information; no age-specific survey index is listed.',
    'The SPiCT assessment uses aggregate biomass information; no age-specific survey index is listed.',
    'The published B_index is aggregate and reported in kilograms per hour; no age-specific index is listed.',
    'The SPiCT assessment uses aggregate biomass information; no age-specific survey index is listed.',
    'The published B_index is aggregate and reported in kilograms per hour; no age-specific index is listed.',
    'The published B_index is aggregate and reported in kilograms per hour; no age-specific index is listed.',
    'The published B_index is aggregate; no age-specific survey index is listed.'),
  output = c(
    'Standard Graphs reports an aggregate B_index and catches/landings; it does not publish N-at-age, F-at-age, or M-at-age.',
    'Standard Graphs reports relative biomass and fishing pressure with aggregate catch data; it does not publish N-at-age, F-at-age, or M-at-age.',
    'Standard Graphs reports relative biomass and fishing pressure with aggregate catch data; it does not publish N-at-age, F-at-age, or M-at-age.',
    'Standard Graphs reports B_index, landings, and F; it does not publish N-at-age, F-at-age, or M-at-age.',
    'Standard Graphs reports relative biomass and fishing pressure with aggregate landings; it does not publish N-at-age, F-at-age, or M-at-age.',
    'Standard Graphs reports B_index, landings, and a length-based fishing-pressure proxy; it does not publish N-at-age, F-at-age, or M-at-age.',
    'Standard Graphs reports B_index, landings, and a length-based fishing-pressure proxy; it does not publish N-at-age, F-at-age, or M-at-age.',
    'Standard Graphs reports B_index, landings, and Fproxy; it does not publish N-at-age, F-at-age, or M-at-age.'),
  stringsAsFactors = FALSE)

dry_run <- identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')
if (!dry_run) source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (i in seq_len(nrow(expected))) {
  row <- match(expected$candidate_id[i], candidates$candidate_id)
  if (is.na(row) || sum(candidates$candidate_id == expected$candidate_id[i]) != 1L ||
      candidates$organization[row] != 'ICES' ||
      candidates$official_stock_id[row] != expected$code[i] ||
      candidates$scientific_name[row] != expected$scientific_name[i] ||
      as.integer(candidates$inventory_assessment_year[row]) != expected$year[i])
    stop('Candidate identity or inventory assessment year changed: ',
      expected$candidate_id[i], call. = FALSE)

  url <- paste0('https://standardgraphs.ices.dk/ViewSourceData.aspx?key=', expected$key[i])
  reason <- paste0('The current ICES method (', expected$assessment_type[i],
    ') is not an age-structured population assessment. The reviewed official source ',
    'does not present age-disaggregated assessment inputs or outputs. Screened ',
    'ineligible for the age-disaggregated set; this does not establish that age ',
    'samples are absent from other research.')
  source_note <- paste0('Distinct ICES stock code and assessment area reviewed against the ',
    'official 2026 Stock Information Database and the linked current Standard Graphs ',
    'source. See discovery/source_reviews/ices_ray_method_group_2026.md. No canonical ',
    'stock, assessment, input, or output record was added.')
  review <- list(
    candidate_unit_id = expected$candidate_unit_id[i],
    matched_stock_id = NA_character_,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = decisions$catch[i],
    survey_age_evidence = decisions$survey[i],
    weights_evidence = paste0('No age-specific weight surface is reported for the current ',
      'non-age-structured assessment method (', expected$assessment_type[i], ').'),
    maturity_evidence = paste0('No maturity-at-age input is reported for the current ',
      'non-age-structured assessment method (', expected$assessment_type[i], ').'),
    mortality_evidence = paste0('No age-specific natural mortality assumption is reported ',
      'for the current assessment method (', expected$assessment_type[i], ').'),
    timing_evidence = 'The linked source does not specify timing for an age-specific survey input.',
    output_evidence = decisions$output[i],
    detailed_source_url = url,
    review_date = '2026-11-01',
    decision_reason = reason,
    notes = source_note)

  current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
  names(current) <- names(review)
  desired <- lapply(review, as.character)
  already_reviewed <- all(vapply(names(review), function(column)
    identical(current[[column]], desired[[column]]), logical(1L)))
  pristine <- candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
  if (!pristine && !already_reviewed)
    stop('Candidate has an unexpected existing identity or review state: ',
      expected$candidate_id[i], call. = FALSE)
  if (!already_reviewed) {
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
    if (!dry_run) {
      replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE],
        expected$candidate_id[i])
      candidates <- read.csv(register_path, stringsAsFactors = FALSE,
        na.strings = c('', 'NA'), check.names = FALSE)
    }
  }
}

if (!dry_run) {
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened eight current ICES elasmobranch units as ineligible for age-disaggregated source curation.\n')

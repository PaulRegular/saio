root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_unstarted_age_audit_2026')
sid_path <- file.path(root, 'source_cache', 'discovery_ices_sid', 'stock_list_2026.json')
sid_hash <- '913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42'
register_path <- file.path(root, 'discovery', 'candidates.csv')
expected_codes <- c(
  'raj.27.3a47d', 'rjb.27.3a4', 'rjh.27.4a6', 'rjr.27.23a4', 'dab.27.3a4',
  'bsf.27.nea', 'gag.27.nea', 'jaa.27.10a2', 'usk.27.1-2', 'usk.27.12ac',
  'usk.27.3a45b6a7-912b', 'usk.27.6b', 'ory.27.nea', 'rng.27.5b6712b',
  'raj.27.1012', 'sbr.27.10', 'sck.27.nea', 'ele.2737.nea', 'bsk.27.nea',
  'tsu.27.nea', 'reb.27.14b', 'rjf.27.67', 'rjh.27.7afg', 'rjb.27.67a-ce-k',
  'cyo.27.nea', 'guq.27.nea', 'rng.27.1245a8914ab', 'mur.27.3a47d',
  'ldb.27.7b-k8abd', 'pil.27.7', 'lin.27.346-91214', 'raj.27.67a-ce-k',
  'bli.27.123a4')

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(tolower(digest::digest(file = path, algo = 'sha256')))
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hash <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hash) != 1L) stop('Could not verify an ICES source checksum.', call. = FALSE)
  hash
}

sid_manifest <- read.csv(file.path(dirname(sid_path), 'sources.csv'),
  stringsAsFactors = FALSE, check.names = FALSE)
if (!file.exists(sid_path) || !any(sid_manifest$file == basename(sid_path)) ||
    toupper(sha256_file(sid_path)) != sid_hash)
  stop('The cached 2026 ICES SID snapshot failed provenance validation.', call. = FALSE)

sid_text <- paste(readLines(sid_path, warn = FALSE), collapse = '')
sid_record <- function(code) {
  token <- paste0('"StockKeyLabel":"', code, '"')
  location <- regexpr(token, sid_text, fixed = TRUE)[1L]
  if (location < 0L) stop('Stock is missing from cached ICES SID: ', code, call. = FALSE)
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

records <- lapply(expected_codes, sid_record)
sid_year <- vapply(records, sid_field, character(1L), name = 'YearOfLastAssessment')
sid_category <- vapply(records, sid_field, character(1L), name = 'DataCategory')
sid_type <- vapply(records, sid_field, character(1L), name = 'AssessmentType')
sid_key <- vapply(records, sid_field, character(1L), name = 'AssessmentKey')
sid_species <- vapply(records, sid_field, character(1L), name = 'SpeciesScientificName')
if (anyNA(sid_year) || anyNA(sid_category) || anyNA(sid_type) || anyNA(sid_key) ||
    any(!nzchar(sid_key)))
  stop('An expected ICES row lacks a current assessment key or inventory metadata.',
    call. = FALSE)

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_codes) || anyDuplicated(manifest$official_stock_id) ||
    !setequal(manifest$official_stock_id, expected_codes) ||
    any(manifest$retrieved_on != '2026-11-01'))
  stop('The cached ICES source manifest is incomplete.', call. = FALSE)

for (i in seq_along(expected_codes)) {
  row <- match(expected_codes[i], manifest$official_stock_id)
  path <- file.path(cache, manifest$file[row])
  url <- paste0('https://standardgraphs.ices.dk/ViewSourceData.aspx?key=', sid_key[i])
  if (!file.exists(path) || as.numeric(manifest$bytes[row]) != file.info(path)$size ||
      manifest$url[row] != url || manifest$assessment_year[row] != sid_year[i] ||
      manifest$assessment_key[row] != sid_key[i] ||
      manifest$data_category[row] != sid_category[i] ||
      manifest$assessment_type[row] != sid_type[i] ||
      sha256_file(path) != manifest$sha256[row])
    stop('Cached ICES source differs from manifest: ', expected_codes[i], call. = FALSE)

  page <- paste(readLines(path, warn = FALSE), collapse = ' ')
  graph_year <- regmatches(page, regexec('id="lblYear">([^<]+)</span>', page))[[1L]][2L]
  if (!grepl(paste0('id="lblStockCode">', expected_codes[i], '</span>'), page,
      fixed = TRUE) ||
      !grepl(paste0('id="lblKey">', sid_key[i], '</span>'), page, fixed = TRUE) ||
      !grepl('id="lblFAge"></span>', page, fixed = TRUE) ||
      !grepl('id="lblFLength"></span>', page, fixed = TRUE) ||
      is.na(graph_year) || manifest$standard_graph_year[row] != graph_year)
    stop('ICES Standard Graph identity or age/length fields differ for ',
      expected_codes[i], '.', call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_ids <- paste0('ICES:', expected_codes)
unit_ids <- paste0('ices_', gsub('[^a-z0-9]+', '_', tolower(expected_codes)))
if (anyDuplicated(unit_ids) ||
    any(tolower(expected_codes) %in% tolower(trimws(stocks$authority_stock_id)),
      na.rm = TRUE))
  stop('An ICES unit key duplicates another candidate or canonical stock.', call. = FALSE)

dry_run <- identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')
if (!dry_run) source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (i in seq_along(candidate_ids)) {
  row <- match(candidate_ids[i], candidates$candidate_id)
  if (is.na(row) || sum(candidates$candidate_id == candidate_ids[i]) != 1L ||
      candidates$organization[row] != 'ICES' ||
      candidates$official_stock_id[row] != expected_codes[i] ||
      candidates$scientific_name[row] != sid_species[i] ||
      as.character(candidates$inventory_assessment_year[row]) != sid_year[i])
    stop('ICES candidate identity or inventory year changed: ', candidate_ids[i],
      call. = FALSE)

  source_row <- match(expected_codes[i], manifest$official_stock_id)
  graph_year <- as.character(manifest$standard_graph_year[source_row])
  method <- sid_type[i]
  unit_id <- unit_ids[i]
  status_year <- sid_year[i]
  reason <- paste0('The 2026 ICES SID lists data category ', sid_category[i],
    ' and method “', method, '” for its ', status_year,
    ' stock record. The linked Standard Graph is from ', graph_year,
    ' and leaves the age-specific F and length fields empty. No age-disaggregated ' ,
    'catch or survey likelihood inputs or N-, F-, or M-at-age outputs are verified. ',
    'Ineligible for this age-disaggregated source set; this does not establish that ' ,
    'age samples are absent from other research.')
  if (expected_codes[i] == 'rjb.27.67a-ce-k' && status_year != graph_year)
    reason <- paste0(reason, ' The SID says 2024 but labels the record “no assessment”; ' ,
      'its linked graph is the 2020 output and is not treated as a 2024 detailed run.')

  review <- list(
    candidate_unit_id = unit_id,
    matched_stock_id = NA_character_,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste0('The linked ICES Standard Graph reports the current ' ,
      'official source series at aggregate scale; no catch-at-age series is listed. ' ,
      'The SID method is “', method, '”.'),
    survey_age_evidence = 'The official page does not identify an age-specific survey index; its age and length assessment fields are empty.',
    weights_evidence = 'The reviewed Standard Graph has no age-specific assessment surface. This does not rule out age samples or biological tables in other sources.',
    maturity_evidence = 'The reviewed Standard Graph has no maturity-at-age model input. This does not establish that maturity studies are unavailable.',
    mortality_evidence = paste0('The SID method “', method,
      '” and the linked graph report no age-specific M process or M-at-age output.'),
    timing_evidence = 'No age-specific index is reported, so timing for an age-specific survey input is not available from the linked source.',
    output_evidence = 'The linked Standard Graph leaves age-specific F and length fields empty and does not report N-at-age, F-at-age, M-at-age, or a recruitment series.',
    detailed_source_url = manifest$url[source_row],
    review_date = '2026-11-01',
    decision_reason = reason,
    notes = paste0('Distinct ICES SID stock code and assessment area; assigned provisional candidate unit ',
      unit_id, '. The 2026 SID snapshot and linked Standard Graph are cached under ',
      'source_cache/discovery_ices_unstarted_age_audit_2026/. No canonical stock, ',
      'assessment, input, or output data were added.'))

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
    stop('ICES candidate has an unexpected existing review state: ', candidate_ids[i],
      call. = FALSE)
  if (!already_reviewed) {
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
    if (!dry_run) {
      replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE],
        candidate_ids[i])
      candidates <- read.csv(register_path, stringsAsFactors = FALSE,
        na.strings = c('', 'NA'), check.names = FALSE)
    }
  }
}

if (!dry_run) {
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened 33 ICES current assessment records with no age-disaggregated fields as ineligible.\n')

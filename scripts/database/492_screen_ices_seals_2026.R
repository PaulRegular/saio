root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_sid')
register_path <- file.path(root, 'discovery', 'candidates.csv')
source_path <- file.path(cache, 'stock_list_2026.json')
manifest_path <- file.path(cache, 'sources.csv')
source_url <- 'https://sid.ices.dk/services/year/2026'
source_hash <- '913D6A3EEAB9449AE3CD0DD15661A150D36FF79B6E6A9BA78D86D46BA1035F42'

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(toupper(digest::digest(file = path, algo = 'sha256')))
  executable <- if (.Platform$OS.type == 'windows') 'certutil' else 'sha256sum'
  path_arg <- shQuote(normalizePath(path,
    winslash = if (.Platform$OS.type == 'windows') '\\' else '/', mustWork = TRUE))
  output <- system2(executable,
    c(if (.Platform$OS.type == 'windows') '-hashfile' else NULL, path_arg,
      if (.Platform$OS.type == 'windows') 'SHA256' else NULL), stdout = TRUE)
  hashes <- grep('^[[:xdigit:]]{64}$', gsub('[[:space:]]', '', output), value = TRUE)
  if (length(hashes) != 1L) stop('Could not verify ICES SID checksum.', call. = FALSE)
  toupper(hashes)
}

manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
manifest_row <- which(manifest$file == basename(source_path))
if (length(manifest_row) != 1L || manifest$url[manifest_row] != source_url ||
    manifest$retrieved_on[manifest_row] != '2026-10-28' ||
    toupper(manifest$sha256[manifest_row]) != source_hash ||
    !file.exists(source_path) || toupper(sha256_file(source_path)) != source_hash ||
    file.info(source_path)$size != 324088)
  stop('The cached 2026 ICES SID source failed provenance validation.', call. = FALSE)

source_text <- paste(readLines(source_path, warn = FALSE), collapse = '')
reviews <- list(
  'ICES:seh.27.125a14' = list(
    candidate_unit_id = 'ices_harp_seal_greenland_sea',
    scientific_name = 'Pagophilus groenlandicus',
    assessment_area = 'Greenland Sea stock (subareas 1, 2, and 14; Division 5.a)',
    source_fragment = '"StockKeyLabel":"seh.27.125a14"',
    assessment_note = paste0('The 2026 SID identifies the 2019 last assessment and analytical model type, ' ,
      'but does not specify age-indexed inputs or outputs in the stock-list record.'),
    stock_boundary = 'Greenland Sea harp seal stock; do not combine with the Barents and White Sea stock or DFO Northwest Atlantic harp seals.'),
  'ICES:seh.27.1' = list(
    candidate_unit_id = 'ices_harp_seal_barents_white_sea',
    scientific_name = 'Pagophilus groenlandicus',
    assessment_area = 'Barents and White Sea stock (Subarea 1)',
    source_fragment = '"StockKeyLabel":"seh.27.1"',
    assessment_note = paste0('The 2026 SID identifies a 2019 age-based analytical SAM assessment, ' ,
      'considered indicative of trends only. Its age-specific input and output tables were not reviewed.'),
    stock_boundary = 'Barents and White Sea harp seal stock; keep distinct from the Greenland Sea and DFO Northwest Atlantic stocks.'),
  'ICES:sez.27.2514' = list(
    candidate_unit_id = 'ices_hooded_seal_greenland_sea',
    scientific_name = 'Cystophora cristata',
    assessment_area = 'Greenland Sea stock (subareas 2, 5, and 14)',
    source_fragment = '"StockKeyLabel":"sez.27.2514"',
    assessment_note = paste0('The 2026 SID identifies the 2019 last assessment and analytical model type, ' ,
      'but does not specify age-indexed inputs or outputs in the stock-list record.'),
    stock_boundary = 'Greenland Sea hooded seal stock; distinct from the harp seal units.'))

if (any(!vapply(reviews, function(review)
  grepl(review$source_fragment, source_text, fixed = TRUE) &&
    grepl(paste0('"SpeciesScientificName":"', review$scientific_name, '"'),
      source_text, fixed = TRUE), logical(1L))))
  stop('The cached ICES SID does not contain the expected seal stock identities.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
for (candidate_id in names(reviews)) {
  row <- match(candidate_id, candidates$candidate_id)
  review <- reviews[[candidate_id]]
  if (is.na(row) || sum(candidates$candidate_id == candidate_id) != 1L ||
      candidates$scientific_name[row] != review$scientific_name ||
      candidates$organization[row] != 'ICES' ||
      candidates$official_stock_id[row] != sub('^ICES:', '', candidate_id))
    stop('Unexpected ICES seal candidate identity: ', candidate_id, call. = FALSE)
  if (candidates$match_status[row] == 'unreviewed') {
    if (!is.na(candidates$candidate_unit_id[row]) && nzchar(candidates$candidate_unit_id[row]))
      stop('Unreviewed ICES seal row already has a candidate unit ID: ', candidate_id, call. = FALSE)
  } else if (candidates$match_status[row] != 'new' ||
      candidates$candidate_unit_id[row] != review$candidate_unit_id ||
      candidates$screening_status[row] != 'screened' ||
      candidates$eligibility[row] != 'ineligible') {
    stop('Conflicting ICES seal identity or screening state: ', candidate_id, call. = FALSE)
  }
}

dry_run <- identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')
if (!dry_run) source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (candidate_id in names(reviews)) {
  row <- match(candidate_id, candidates$candidate_id)
  review <- reviews[[candidate_id]]
  status_matches <- candidates$match_status[row] == 'new' &&
    candidates$candidate_unit_id[row] == review$candidate_unit_id &&
    candidates$screening_status[row] == 'screened' &&
    candidates$eligibility[row] == 'ineligible'
  if (!status_matches) {
    dfo_boundary_note <- if (grepl('harp_seal', review$candidate_unit_id, fixed = TRUE))
      ' The DFO Northwest Atlantic harp seal inventory record is a separate stock area.' else ''
    screening_reason <- paste0('Outside the initial marine-finfish scope: this is a seal (marine mammal), ' ,
      'not a finfish. This scope decision does not establish that age-structured data are absent.')
    source_note <- paste0('Identity and boundary checked against the official ICES 2026 Stock Information ' ,
      'Database snapshot (retrieved 2026-10-28; SHA-256 ', source_hash, '). ',
      review$assessment_note, ' ', review$stock_boundary, dfo_boundary_note,
      ' Detailed input and output series were not screened because the stock is outside the initial scope. ' ,
      'No canonical stock, assessment, input, or output record was added.')
    not_screened <- 'Not assessed: outside the marine-finfish screen; this is not evidence that the series is absent.'
    candidates$candidate_unit_id[row] <- review$candidate_unit_id
    candidates$matched_stock_id[row] <- NA_character_
    candidates$match_status[row] <- 'new'
    candidates$screening_status[row] <- 'screened'
    candidates$eligibility[row] <- 'ineligible'
    candidates$import_status[row] <- 'not_started'
    candidates$assessment_area[row] <- review$assessment_area
    candidates$catch_age_evidence[row] <- not_screened
    candidates$survey_age_evidence[row] <- not_screened
    candidates$weights_evidence[row] <- not_screened
    candidates$maturity_evidence[row] <- not_screened
    candidates$mortality_evidence[row] <- not_screened
    candidates$timing_evidence[row] <- not_screened
    candidates$output_evidence[row] <- not_screened
    candidates$detailed_source_url[row] <- source_url
    candidates$review_date[row] <- '2026-11-01'
    candidates$decision_reason[row] <- screening_reason
    candidates$notes[row] <- source_note
    if (!dry_run) {
      replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
      candidates <- read.csv(register_path, stringsAsFactors = FALSE,
        na.strings = c('', 'NA'), check.names = FALSE)
    }
  }
}

if (!dry_run) {
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Reconciled three distinct ICES seal units and excluded them from the initial marine-finfish scope.\n')

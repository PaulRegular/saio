root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_greenland_cod_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

reviews <- data.frame(
  candidate_id = c('ICES:cod.21.1.osc', 'ICES:cod.21.1.isc',
    'ICES:cod.21.27.1.14'),
  official_stock_id = c('cod.21.1.osc', 'cod.21.1.isc', 'cod.21.27.1.14'),
  scientific_name = 'Gadus morhua',
  inventory_assessment_year = '2026',
  stock_name = c(
    'Cod (Gadus morhua) in NAFO Subarea 1 (West Greenland offshore spawning cod)',
    'Cod (Gadus morhua) in NAFO Subarea 1 (West Greenland inshore spawning cod)',
    'Cod (Gadus morhua) in NAFO Subarea 1 and ICES Subarea 14 (East Greenland-Iceland offshore spawning cod)'),
  candidate_unit_id = c('ices_cod_west_greenland_offshore',
    'ices_cod_west_greenland_inshore', 'ices_cod_east_greenland_iceland_offshore'),
  advice_file = c('cod_21_1_osc_advice_2026.html',
    'cod_21_1_isc_advice_2026.html', 'cod_21_27_1_14_advice_2026.html'),
  advice_id = c('5088', '5089', '5091'),
  stringsAsFactors = FALSE
)
reviews$advice_url <- paste0('https://asd.ices.dk/viewAdvice/', reviews$advice_id)

manifest_advice <- match(reviews$advice_file, manifest$file)
if (anyDuplicated(manifest$file) || anyNA(manifest_advice) ||
    any(manifest$retrieved_on[manifest_advice] != '2026-11-01'))
  stop('The Greenland cod source manifest is incomplete or has changed.', call. = FALSE)

for (i in seq_len(nrow(reviews))) {
  manifest_row <- manifest_advice[i]
  path <- file.path(cache, reviews$advice_file[i])
  page <- if (file.exists(path)) paste(readLines(path, warn = FALSE), collapse = '\n') else ''
  if (!file.exists(path) || manifest$url[manifest_row] != reviews$advice_url[i] ||
      as.numeric(manifest$bytes[manifest_row]) != file.info(path)$size ||
      tolower(manifest$sha256[manifest_row]) != sha256_file(path) ||
      !grepl(reviews$official_stock_id[i], page, fixed = TRUE) ||
      !grepl('Assessment Year', page, fixed = TRUE))
    stop('Cached ICES advice source failed validation: ', reviews$advice_file[i], call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
for (i in seq_len(nrow(reviews))) {
  row <- match(reviews$candidate_id[i], candidates$candidate_id)
  if (is.na(row) || candidates$official_stock_id[row] != reviews$official_stock_id[i] ||
      candidates$scientific_name[row] != reviews$scientific_name[i] ||
      candidates$inventory_assessment_year[row] != reviews$inventory_assessment_year[i] ||
      candidates$stock_name[row] != reviews$stock_name[i])
    stop('The Greenland cod inventory identity changed: ', reviews$candidate_id[i], call. = FALSE)
  if (any(stocks$authority == 'ICES' & stocks$authority_stock_id == reviews$official_stock_id[i],
      na.rm = TRUE))
    stop('An ICES Greenland cod identifier already exists in canonical stocks: ',
      reviews$official_stock_id[i], call. = FALSE)
  same_unit <- candidates$candidate_unit_id == reviews$candidate_unit_id[i]
  same_unit[is.na(same_unit)] <- FALSE
  if (any(same_unit & candidates$candidate_id != reviews$candidate_id[i]))
    stop('A Greenland cod candidate-unit ID is already assigned: ',
      reviews$candidate_unit_id[i], call. = FALSE)
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (i in seq_len(nrow(reviews))) {
  row <- match(reviews$candidate_id[i], candidates$candidate_id)
  identity_review <- list(
    candidate_unit_id = reviews$candidate_unit_id[i],
    match_status = 'new',
    matched_stock_id = NA_character_,
    review_date = '2026-11-01',
    decision_reason = paste0(
      'Distinct ICES 2026 spawning-stock assessment component ',
      reviews$official_stock_id[i], '. Official advice treats the Greenland cod ',
      'components separately even though the NAFO Subarea 1 fishery mixes catch ',
      'from them; no canonical record covers this stock area. Identity reviewed; ',
      'age-input/output eligibility screening remains unresolved.'),
    detailed_source_url = reviews$advice_url[i],
    notes = paste0(
      'Identity review only. The ICES Advice and Scenarios Database lists 2026 ',
      'advice for this separate Greenland spawning component. Do not combine with ',
      'other Greenland cod candidate units; official advice notes their fisheries ',
      'can be mixed. Cached page: source_cache/discovery_ices_greenland_cod_2026/',
      reviews$advice_file[i], '. Age-data eligibility remains unresolved.')
  )
  pristine <- candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
  identity_matches <- candidates$candidate_unit_id[row] == reviews$candidate_unit_id[i] &&
    candidates$match_status[row] == 'new' &&
    (is.na(candidates$matched_stock_id[row]) || !nzchar(candidates$matched_stock_id[row]))
  if (!(pristine || identity_matches))
    stop('Conflicting ICES Greenland cod identity review: ',
      reviews$candidate_id[i], call. = FALSE)
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    if (pristine) for (column in names(identity_review)) candidates[[column]][row] <- identity_review[[column]]
    replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE],
      reviews$candidate_id[i])
    candidates <- read.csv(register_path, stringsAsFactors = FALSE,
      na.strings = c('', 'NA'), check.names = FALSE)
  }
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Reconciled the three ICES Greenland cod advice-unit identities; screening results are recorded separately.\n')

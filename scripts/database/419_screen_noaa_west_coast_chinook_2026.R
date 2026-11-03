root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_puget_sound_chinook_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')

source_files <- data.frame(
  file = c('Preseason_Report_I_2026.pdf', 'Review_of_2025.pdf',
    'StockSMART_DataDictionary.pdf'),
  url = c(
    'https://www.pcouncil.org/documents/2026/03/preseason-report-1-stock-abundance-analysis-and-environmental-assessment-part-1-for-2026-ocean-salmon-fishery-regulations.pdf/',
    'https://www.pcouncil.org/documents/review-of-2025-ocean-salmon-fisheries/',
    'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf'),
  retrieved_on = '2026-10-30',
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  path <- normalizePath(path,
    winslash = if (.Platform$OS.type == 'windows') '\\' else '/', mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', result, value = TRUE))
  } else {
    result <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', result[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files$file, manifest$file)
source_paths <- file.path(cache, source_files$file)
if (anyNA(source_rows) || any(!file.exists(source_paths)))
  stop('The cached NOAA salmon source set is incomplete.', call. = FALSE)
if (any(manifest$url[source_rows] != source_files$url) ||
    any(manifest$retrieved_on[source_rows] != source_files$retrieved_on) ||
    !identical(as.numeric(manifest$bytes[source_rows]), as.numeric(file.info(source_paths)$size)) ||
    !identical(tolower(manifest$sha256[source_rows]),
      unname(vapply(source_paths, sha256_file, character(1L)))))
  stop('The cached NOAA salmon sources do not match their manifest.', call. = FALSE)
if (any(!startsWith(vapply(source_paths, function(path)
  rawToChar(readBin(path, 'raw', n = 5L)), character(1L)), '%PDF-')))
  stop('A cached NOAA salmon source is not a PDF.', call. = FALSE)

noaa_cache <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart')
noaa_source_manifest <- read.csv(file.path(noaa_cache, 'sources.csv'), stringsAsFactors = FALSE)
noaa_metadata_path <- file.path(noaa_cache, 'stock_assessment_summary.rda')
metadata_source <- noaa_source_manifest[noaa_source_manifest$file ==
  'stock_assessment_summary.rda', , drop = FALSE]
if (nrow(metadata_source) != 1L || !file.exists(noaa_metadata_path) ||
    !identical(tolower(metadata_source$sha256), sha256_file(noaa_metadata_path)))
  stop('The cached NOAA Stock SMART metadata does not match its manifest.', call. = FALSE)
metadata_env <- new.env(parent = emptyenv())
load(noaa_metadata_path, envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary

screens <- data.frame(
  stock_id = 10483:10494,
  candidate_id = paste0('NOAA:', 10483:10494),
  candidate_unit_id = paste0('noaa_chinook_', 10483:10494),
  stringsAsFactors = FALSE
)
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

rows <- match(screens$candidate_id, register$candidate_id)
if (anyNA(rows) || anyDuplicated(rows) || anyDuplicated(screens$candidate_unit_id))
  stop('Expected one NOAA register row and one unit key per Stock SMART ID.', call. = FALSE)

metadata <- metadata[order(metadata$stock_id, -as.numeric(metadata$assessment_year),
  metadata$assessment_id, na.last = TRUE), , drop = FALSE]
metadata <- metadata[!duplicated(metadata$stock_id), , drop = FALSE]
metadata_rows <- match(screens$stock_id, metadata$stock_id)
if (anyNA(metadata_rows)) stop('A NOAA Stock SMART metadata row is missing.', call. = FALSE)
latest <- metadata[metadata_rows, , drop = FALSE]
if (any(register$official_stock_id[rows] != as.character(screens$stock_id)) ||
    any(register$scientific_name[rows] != latest$scientific_name) ||
    any(register$stock_name[rows] != latest$stock_name) ||
    any(latest$assessment_year != 2026) || any(latest$assessment_type != 'Operational') ||
    any(latest$assessment_model != 'Cohort Analysis') ||
    any(latest$composition_input_data != 4) ||
    any(!latest$model_category %in% c(2, 4)) ||
    sum(latest$model_category == 2) != 1L)
  stop('NOAA stock identities or current assessment metadata changed.', call. = FALSE)
if (any(stocks$scientific_name %in% latest$scientific_name) ||
    any(as.character(screens$stock_id) %in% stocks$authority_stock_id, na.rm = TRUE))
  stop('A NOAA Chinook unit now overlaps an existing canonical stock identity.', call. = FALSE)
if (any(screens$candidate_unit_id %in% c(assessments$assessment_id,
    inputs$assessment_id, outputs$assessment_id), na.rm = TRUE) ||
    any(screens$candidate_unit_id %in% register$candidate_unit_id[-rows], na.rm = TRUE))
  stop('A NOAA candidate unit key conflicts with an existing record.', call. = FALSE)

initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == screens$candidate_unit_id &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == 'unresolved'
if (any(!initial & !reviewed))
  stop('At least one NOAA Chinook candidate has a conflicting prior review.', call. = FALSE)

format_metric <- function(value, unit, year, basis = '') {
  if (is.na(value) || is.na(unit) || !nzchar(as.character(unit))) return('not reported')
  display_value <- format(round(as.numeric(value), 3), trim = TRUE, scientific = FALSE)
  result <- paste(display_value, unit, 'for', year)
  if (!is.na(basis) && nzchar(as.character(basis))) result <- paste0(result, ' (', basis, ')')
  result
}

composition_text <- paste0(
  'NOAA Stock SMART reports Composition Input Data level ', latest$composition_input_data,
  ' for this current operational assessment. NOAA defines this level as sufficient age-composition information to support methods using fishery age compositions. The Stock SMART summary does not expose the annual catch-at-age vectors or observation grouping needed to verify the input series. Model Category is ',
  latest$model_category,
  ' (VPA for category 4; index-based for category 2), so the Skokomish record must not be assumed to share the other units\' model structure.'
)
survey_text <- paste0(
  'The 2026 PFMC preseason report provides run-size and adult-return forecasts; no age-specific marine survey abundance series for this unit was verified in the reviewed sources. For the 11 Puget Sound units, the report says forecast methods are in annual management reports by management unit and describes adult returns as generally age-4 dominated.'
)
output_text <- vapply(seq_len(nrow(latest)), function(i) {
  b <- format_metric(latest$estimated_b[i], latest$b_unit[i], latest$b_year[i], latest$b_basis[i])
  f <- format_metric(latest$estimated_f[i], latest$f_unit[i], latest$f_year[i], latest$f_basis[i])
  paste0('Stock SMART 2026 summary reports B: ', b, '; F: ', f,
    '. These are aggregate stock indicators where present, not N-at-age or F-at-age. The 2026 preseason report gives run-size forecasts; the 2025 review reports fishery and escapement history. No complete age-specific population-output surface was verified.')
}, character(1L))
reason <- paste0(
  'Screened with eligibility unresolved. Stock SMART provides positive age-composition metadata for these units, but the reviewed current reports do not expose the annual catch-at-age likelihood vectors, age-specific survey index, weights-at-age, maturity-at-age, age-specific mortality assumptions, or a comparable population-at-age output. Keep these candidates unresolved rather than classing the age inputs as absent; the detailed annual regional management reports and underlying assessment material remain to be checked.'
)

source_urls <- paste(
  source_files$url[1L], source_files$url[2L], sep = '; ')
review_values <- lapply(seq_along(rows), function(i) {
  list(
    candidate_unit_id = screens$candidate_unit_id[i],
    match_status = 'new', screening_status = 'screened', eligibility = 'unresolved',
    import_status = 'not_started',
    catch_age_evidence = paste0(composition_text[i], ' Stock SMART catch-input level ',
      latest$catch_input_data[i], ' is recorded, but the detailed annual catch numbers-at-age series was not present in the reviewed public report.'),
    survey_age_evidence = survey_text,
    weights_evidence = 'The reviewed public reports do not provide a stock-specific weights-at-age series; underlying annual management inputs remain unverified.',
    maturity_evidence = 'The reviewed public reports do not provide a stock-specific maturity-at-age series; underlying annual management inputs remain unverified.',
    mortality_evidence = paste0('Stock SMART reports F as ',
      format_metric(latest$estimated_f[i], latest$f_unit[i], latest$f_year[i], latest$f_basis[i]),
      ' where available. This is an aggregate exploitation-rate indicator, not age-specific F; age-specific M was not verified.'),
    timing_evidence = 'No age-specific survey index was verified, so an observation timing for that index cannot yet be specified.',
    output_evidence = output_text[i],
    detailed_source_url = paste0(source_urls,
      '; https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=',
      screens$stock_id[i]),
    review_date = '2026-10-30', decision_reason = reason,
    notes = paste0('Candidate identity is based on distinct NOAA Stock SMART stock ID ',
      screens$stock_id[i], 'and the matching stock name and scientific name in the 2026 operational metadata; no canonical Oncorhynchus tshawytscha stock exists in the current database. Stock SMART metadata are cached at the NOAA-EDAB source revision in discovery_noaa_stocksmart/sources.csv. The current PFMC reports and NOAA data dictionary are cached under source_cache/discovery_noaa_puget_sound_chinook_2026/sources.csv. Metadata are screening evidence only.')
  )
})

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in seq_along(rows)) {
    for (field in names(review_values[[i]])) register[[field]][rows[i]] <- review_values[[i]][[field]]
    replace_candidate_register_row(register_path, rows[i], register[rows[i], , drop = FALSE],
      screens$candidate_id[i])
  }
}

cat('Reconciled and screened 12 distinct 2026 NOAA West Coast Chinook candidate units; age-series eligibility remains unresolved.\n')

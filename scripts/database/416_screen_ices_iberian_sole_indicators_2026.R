root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_iberian_sole_indicators_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')

screens <- data.frame(
  candidate_id = c('ICES:oal.27.8c9a', 'ICES:sos.27.8c9a'),
  unit_id = c('ices_senegalese_sole_8c9a', 'ices_sand_sole_8c9a'),
  scientific_name = c('Solea senegalensis', 'Pegusa lascaris'),
  stock_name = c(
    'Senegalese sole (Solea senegalensis) in divisions 8.c and 9.a (Cantabrian Sea and Atlantic Iberian waters)',
    'Sand sole (Pegusa lascaris) in divisions 8.c and 9.a (Cantabrian Sea and Atlantic Iberian waters)'),
  source_key = c('22600', '23772'),
  file = c('oal_27_8c9a_source_data_2026.html', 'sos_27_8c9a_source_data_2026.html'),
  stock_size = c('No stock-size output', 'No stock-size output'),
  fishing_data = c('Landings and polyvalent-fleet effort/CPUE',
    'Landings and polyvalent-fleet effort'),
  stringsAsFactors = FALSE
)
screens$source_url <- paste0('https://standardgraphs.ices.dk/ViewSourceData.aspx?key=',
  screens$source_key)

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

manifest_path <- file.path(cache, 'sources.csv')
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
source_paths <- file.path(cache, screens$file)
stock_list_path <- file.path(cache, 'stock_list_2026.html')
stock_list_row <- c(
  'href="ViewCharts.aspx\\?key=22600">oal\\.27\\.8c9a\\s*</a>\\s*</td><td[^>]*>5</td>',
  'href="ViewCharts.aspx\\?key=23772">sos\\.27\\.8c9a\\s*</a>\\s*</td><td[^>]*>5</td>')
manifest_files <- c('stock_list_2026.html', screens$file)
manifest_rows <- match(manifest_files, manifest$file)
manifest_paths <- file.path(cache, manifest_files)
if (anyNA(manifest_rows) || any(!file.exists(manifest_paths)))
  stop('The local ICES source cache is incomplete.', call. = FALSE)
if (any(as.character(manifest$url[manifest_rows]) != c(
    'https://standardgraphs.ices.dk/stockList.aspx', screens$source_url)) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(manifest_paths)$size)) ||
    !identical(tolower(as.character(manifest$sha256[manifest_rows])),
      unname(vapply(manifest_paths, sha256_file, character(1L)))))
  stop('The cached ICES sources do not match their manifest.', call. = FALSE)

stock_list <- paste(readLines(stock_list_path, warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_text <- lapply(source_paths, function(path)
  paste(readLines(path, warn = FALSE, encoding = 'UTF-8'), collapse = ' '))
for (i in seq_len(nrow(screens))) {
  stock_list_verified <- grepl(stock_list_row[i], stock_list, perl = TRUE)
  expected <- c(paste0('lblStockCode">', sub('^ICES:', '', screens$candidate_id[i]), '</span>'),
    'lblYear">2026</span>', paste0('lblKey">', screens$source_key[i], '</span>'),
    'lblFAge"></span>', 'lblFLength"></span>', 'lblStockSizeDescription"></span>')
  if (!stock_list_verified ||
      !all(vapply(expected, grepl, logical(1L), x = source_text[[i]], fixed = TRUE)))
    stop('Cached ICES stock list or source page does not verify ', screens$candidate_id[i],
      '.', call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
rows <- match(screens$candidate_id, register$candidate_id)
if (anyNA(rows) || anyDuplicated(screens$candidate_id) || anyDuplicated(screens$unit_id))
  stop('Expected one register row and one unit key per screened ICES stock.', call. = FALSE)
if (any(register$scientific_name[rows] != screens$scientific_name) ||
    any(register$stock_name[rows] != screens$stock_name) ||
    any(register$official_stock_id[rows] != sub('^ICES:', '', screens$candidate_id)))
  stop('ICES stock identity does not match the published 2026 Standard Graphs list.',
    call. = FALSE)
if (any(tolower(stocks$authority_stock_id) %in% tolower(sub('^ICES:', '', screens$candidate_id)),
    na.rm = TRUE))
  stop('An ICES stock code already appears in the canonical database.', call. = FALSE)
if (any(screens$unit_id %in% c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id),
    na.rm = TRUE) || any(screens$unit_id %in% register$candidate_unit_id[-rows], na.rm = TRUE))
  stop('A candidate unit key conflicts with an existing record.', call. = FALSE)

review_values <- list(
  list(
    candidate_unit_id = screens$unit_id[1], match_status = 'new',
    screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2026 category 5 record reports annual catches or landings in tonnes; it does not report catch numbers-at-age or catch-at-age compositions.',
    survey_age_evidence = 'The source reports no age-specific survey abundance series. Its custom commercial-fleet effort/CPUE fields are not survey indices.',
    weights_evidence = 'No weight-at-age series is reported in the current advice-linked source.',
    maturity_evidence = 'No maturity-at-age surface is reported in the current advice-linked source.',
    mortality_evidence = 'The current record has no age-specific fishing-mortality or natural-mortality output.',
    timing_evidence = 'The record contains no age-specific survey observation for which within-year timing could be specified.',
    output_evidence = 'The 2026 Standard Graphs page provides landings and polyvalent-fleet effort/CPUE, but no stock-size, F-at-age, N-at-age, or M-at-age output.',
    detailed_source_url = screens$source_url[1], review_date = '2026-10-30',
    decision_reason = 'Ineligible for the current age-disaggregated comparison: the 2026 category 5 advice-linked record provides landings and commercial-fleet effort/CPUE but no age-specific inputs or comparable population or mortality outputs. This is a limit of the published assessment record reviewed, not evidence that biological age samples do not exist.',
    notes = 'Identity and assessment year were checked against the published 2026 ICES Standard Graphs list and stock-specific source data. Cached URLs, retrieval date, revisions, byte sizes, and SHA-256 checksums are recorded in source_cache/discovery_ices_iberian_sole_indicators_2026/sources.csv. No canonical records were added.'),
  list(
    candidate_unit_id = screens$unit_id[2], match_status = 'new',
    screening_status = 'screened', eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = 'The 2026 category 5 record reports annual landings in tonnes; it does not report catch numbers-at-age or catch-at-age compositions.',
    survey_age_evidence = 'The source reports no age-specific survey abundance series. Its custom commercial-fleet effort field is not a survey index.',
    weights_evidence = 'No weight-at-age series is reported in the current advice-linked source.',
    maturity_evidence = 'No maturity-at-age surface is reported in the current advice-linked source.',
    mortality_evidence = 'The current record has no age-specific fishing-mortality or natural-mortality output.',
    timing_evidence = 'The record contains no age-specific survey observation for which within-year timing could be specified.',
    output_evidence = 'The 2026 Standard Graphs page provides landings and polyvalent-fleet effort, but no stock-size, F-at-age, N-at-age, or M-at-age output.',
    detailed_source_url = screens$source_url[2], review_date = '2026-10-30',
    decision_reason = 'Ineligible for the current age-disaggregated comparison: the 2026 category 5 advice-linked record provides landings and commercial-fleet effort but no age-specific inputs or comparable population or mortality outputs. This is a limit of the published assessment record reviewed, not evidence that biological age samples do not exist.',
    notes = 'Identity and assessment year were checked against the published 2026 ICES Standard Graphs list and stock-specific source data. Cached URLs, retrieval date, revisions, byte sizes, and SHA-256 checksums are recorded in source_cache/discovery_ices_iberian_sole_indicators_2026/sources.csv. No canonical records were added.')
)

is_initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
is_reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == screens$unit_id &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == 'ineligible'
if (any(!is_initial & !is_reviewed))
  stop('At least one candidate has a conflicting prior review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in seq_along(rows)) {
    if (is_initial[i] || is_reviewed[i]) {
      for (field in names(review_values[[i]])) register[[field]][rows[i]] <- review_values[[i]][[field]]
      replace_candidate_register_row(register_path, rows[i], register[rows[i], , drop = FALSE],
        screens$candidate_id[i])
    }
  }
}

cat('Screened the 2026 ICES Senegalese sole and sand sole units as ineligible for age-disaggregated comparison.\n')

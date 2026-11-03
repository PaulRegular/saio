root <- "."
stock_id <- 'ck_ices_wgbfas_morhua_bs_25_32'
candidate_id <- 'ICES:cod.27.24-32'
cache <- file.path(root, 'source_cache',
  'ck_ices_wgbfas_morhua_bs_25_32', 'assessment_2026')
stocks_path <- file.path(root, 'database', 'stocks.csv')
candidates_path <- file.path(root, 'discovery', 'candidates.csv')
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidates <- read.csv(candidates_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
xml_path <- file.path(cache, 'SAG_2026_key_22502.xml')
xml <- paste(readLines(xml_path, warn = FALSE), collapse = ' ')
stock_row <- match(stock_id, stocks$stock_id)
candidate_row <- match(candidate_id, candidates$candidate_id)
current_id_count <- sum(stocks$authority_stock_id == 'cod.27.24-32', na.rm = TRUE)
stock_has_current_id <- !is.na(stocks$authority_stock_id[stock_row]) &&
  stocks$authority_stock_id[stock_row] == 'cod.27.24-32'

if (is.na(stock_row) || is.na(candidate_row) ||
    sum(stocks$stock_id == stock_id) != 1L ||
    sum(candidates$candidate_id == candidate_id) != 1L ||
    current_id_count > as.integer(stock_has_current_id) ||
    !all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
      '<StockCode>cod.27.24-32</StockCode>',
      '<StockSizeDescription>B_index</StockSizeDescription>'),
      grepl, logical(1L), x = xml, fixed = TRUE)) ||
    !all(c('ices_cod_eastern_baltic_2024', 'ices_cod_eastern_baltic_2026') %in%
      assessments$assessment_id))
  stop('Eastern Baltic cod identity or source evidence does not match.', call. = FALSE)

stock_current <- stocks[stock_row, , drop = FALSE]
candidate_current <- candidates[candidate_row, , drop = FALSE]
stock <- stock_current
stock$authority_stock_id <- 'cod.27.24-32'
stock$common_name <- 'Eastern Baltic cod'
stock$area <- 'Subdivisions 24-32 (eastern Baltic)'
stock$notes <- paste(
  'Originally seeded from Charbonneau-Keith Master.csv, revision',
  '7e4daca3cbfc14ce7fa0b28ed824eebe7113249b, with the historical area label',
  'BS 25-32. Reconciled to current ICES unit cod.27.24-32, which covers',
  'subdivisions 24-32. The 2024 Stock Synthesis record is retained as a',
  'separate historical assessment; the current 2026 category 3.2 assessment',
  'is an aggregate BITS survey-index method. See',
  'source_reviews/ck_ices_wgbfas_morhua_bs_25_32.md.')

candidate <- candidate_current
candidate$candidate_unit_id <- NA_character_
candidate$matched_stock_id <- stock_id
candidate$match_status <- 'matched'
candidate$screening_status <- 'screened'
candidate$eligibility <- 'ineligible'
candidate$import_status <- 'imported'
candidate$catch_age_evidence <- paste(
  'The current 2026 assessment is an aggregate index method and has no',
  'catch-at-age likelihood. The older 2024 SS3 assessment has partial age',
  'outputs and aggregate catches already recorded separately in the database.')
candidate$survey_age_evidence <- paste(
  'The current assessment uses a combined BITS Q1/Q4 biomass index, not',
  'age-specific abundance or age-composition observations.')
candidate$weights_evidence <- paste(
  'The current index standardization uses numbers-at-length and annual',
  'weight-at-length; age-specific weights are not current model inputs.')
candidate$maturity_evidence <- paste(
  'Age-specific maturity is not used by the current index-based assessment.')
candidate$mortality_evidence <- paste(
  'The current index-based method does not estimate or report age-specific',
  'natural or fishing mortality.')
candidate$timing_evidence <- paste(
  'The combined BITS series covers Q1/Q4 surveys; no age-specific index timing',
  'applies to the current method.')
candidate$output_evidence <- paste(
  'The current model reports the combined BITS biomass index and aggregate',
  'catch context, not N-at-age, F-at-age, or M-at-age. The 2024 SS3 run is',
  'retained separately as a historical age-structured output record.')
candidate$detailed_source_url <- paste(
  'https://doi.org/10.17895/ices.pub.32455056;',
  'https://asd.ices.dk/viewAdvice/6135;',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/22502', sep = ' ')
candidate$review_date <- '2026-10-30'
candidate$decision_reason <- paste(
  'The 2026 official assessment is a Category 3.2 aggregate BITS index method',
  'with no age-specific population inputs or outputs. It is ineligible for the',
  'age-disaggregated candidate set. This inventory unit matches the existing',
  'eastern Baltic cod stock; no duplicate stock or assessment was added.')
candidate$notes <- paste(
  'Reconciled to canonical stock ck_ices_wgbfas_morhua_bs_25_32. Current ICES',
  'assessment unit cod.27.24-32 covers subdivisions 24-32; the source record',
  'retains the historical Charbonneau-Keith BS 25-32 identifier and the 2024',
  'SS3 assessment separately. See source_reviews/ck_ices_wgbfas_morhua_bs_25_32.md.')

replace_row <- function(path, key_column, key, replacement) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- match(key, read.csv(path, stringsAsFactors = FALSE,
    na.strings = c('', 'NA'))[[key_column]]) + 1L
  if (is.na(physical_line) || length(line_feeds) < physical_line)
    stop('Could not find the row to update in ', path, '.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(replacement, tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '')
  serialized <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  serialized <- sub('\r?\n$', '', rawToChar(serialized), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(serialized), ending, after), path)
}

already_reconciled <- !is.na(stock_current$authority_stock_id) &&
  stock_current$authority_stock_id == 'cod.27.24-32' &&
  stock_current$common_name == 'Eastern Baltic cod' &&
  candidate_current$match_status == 'matched' &&
  candidate_current$matched_stock_id == stock_id
if (!already_reconciled && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  replace_row(stocks_path, 'stock_id', stock_id, stock)
  replace_row(candidates_path, 'candidate_id', candidate_id, candidate)
}

cat('Reconciled ICES cod.27.24-32 to the existing eastern Baltic cod stock.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
cache_file <- 'stock_assessment_summary.rda'
cache_path <- file.path(cache, cache_file)
expected_url <- paste0('https://raw.githubusercontent.com/NOAA-EDAB/stocksmart/',
  '664c4237e26520b260a090e1821a2cee5d1cdf07/data/stock_assessment_summary.rda')
expected_revision <- '664c4237e26520b260a090e1821a2cee5d1cdf07'
stock_ids <- c('10079', '10081', '10083')
candidate_ids <- paste0('NOAA:', stock_ids)
unit_ids <- c('noaa_brown_shrimp_gulf', 'noaa_pink_shrimp_gulf',
  'noaa_white_shrimp_gulf')
scientific_names <- c('Farfantepenaeus aztecus', 'Farfantepenaeus duorarum',
  'Litopenaeus setiferus')
common_names <- c('Brown shrimp', 'Pink shrimp', 'White shrimp')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (!file.exists(cache_path)) stop('Missing cached NOAA Stock SMART metadata.', call. = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_row <- match(cache_file, manifest$file)
if (is.na(manifest_row) || manifest$url[manifest_row] != expected_url ||
    manifest$revision[manifest_row] != expected_revision ||
    tolower(manifest$sha256[manifest_row]) != sha256_file(cache_path))
  stop('Cached NOAA metadata differs from its recorded pinned source.', call. = FALSE)

source_env <- new.env(parent = emptyenv())
load(cache_path, envir = source_env)
metadata <- source_env$stock_assessment_summary
for (i in seq_along(stock_ids)) {
  rows <- metadata[as.character(metadata$stock_id) == stock_ids[i], , drop = FALSE]
  if (!nrow(rows) || !all(rows$scientific_name == scientific_names[i]) ||
      !all(rows$common_name == common_names[i]) ||
      !all(rows$regional_ecosystem == 'Gulf of Mexico'))
    stop('Stock SMART identity metadata did not verify ', candidate_ids[i], '.',
      call. = FALSE)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
rows <- match(candidate_ids, candidates$candidate_id)
initial_state <- !anyNA(rows) && all(candidates$match_status[rows] == 'unreviewed') &&
  all(candidates$screening_status[rows] == 'screened') &&
  all(candidates$eligibility[rows] == 'ineligible') &&
  all(is.na(candidates$candidate_unit_id[rows]) | !nzchar(candidates$candidate_unit_id[rows]))
reviewed_state <- !anyNA(rows) &&
  identical(as.character(candidates$candidate_unit_id[rows]), unit_ids) &&
  all(candidates$match_status[rows] == 'new') &&
  all(candidates$screening_status[rows] == 'screened') &&
  all(candidates$eligibility[rows] == 'ineligible') &&
  all(grepl('Stock SMART identifies a distinct Gulf of Mexico',
    candidates$decision_reason[rows], fixed = TRUE)) &&
  all(grepl('Identity verified against the pinned NOAA-EDAB Stock SMART snapshot',
    candidates$notes[rows], fixed = TRUE))
if (anyNA(rows) || anyDuplicated(rows) ||
    !identical(as.character(candidates$official_stock_id[rows]), stock_ids) ||
    !identical(as.character(candidates$scientific_name[rows]), scientific_names) ||
    (!initial_state && !reviewed_state))
  stop('NOAA shrimp inventory rows are no longer in the expected unresolved-identity state.',
    call. = FALSE)
if (any(stocks$authority_stock_id %in% stock_ids, na.rm = TRUE) ||
    any(stocks$scientific_name %in% scientific_names, na.rm = TRUE) ||
    any(assessments$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(inputs$assessment_id %in% unit_ids, na.rm = TRUE) ||
    any(outputs$assessment_id %in% unit_ids, na.rm = TRUE))
  stop('NOAA shrimp identity conflicts with canonical records.', call. = FALSE)

for (i in seq_along(rows)) {
  row <- rows[i]
  candidates$candidate_unit_id[row] <- unit_ids[i]
  candidates$match_status[row] <- 'new'
  candidates$decision_reason[row] <- paste('Stock SMART identifies a distinct Gulf of Mexico',
    common_names[i], 'unit. This crustacean is outside the initial marine-finfish scope,',
    'so it is screened ineligible without assessing its model inputs.')
  candidates$notes[row] <- paste('Identity verified against the pinned NOAA-EDAB Stock SMART',
    'snapshot. Assessment and age-input completeness remain unreviewed because the taxon is',
    'outside the initial marine-finfish scope.')
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  for (row in rev(rows)) {
    physical_line <- row + 1L
    if (length(line_feeds) < physical_line)
      stop('Candidate CSV row is out of range for ', candidates$candidate_id[row],
        '.', call. = FALSE)
    first <- line_feeds[physical_line - 1L] + 1L
    last <- line_feeds[physical_line]
    ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
      as.raw(c(13L, 10L)) else as.raw(10L)
    tmp <- tempfile(fileext = '.csv')
    write.table(candidates[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
      col.names = FALSE, quote = TRUE, na = '')
    replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
    unlink(tmp)
    replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
    before <- bytes[seq_len(first - 1L)]
    after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
    bytes <- c(before, charToRaw(replacement), ending, after)
  }
  writeBin(bytes, candidate_path)
}

cat('Reconciled three NOAA Gulf shrimp stock identities; all remain out of scope.\n')

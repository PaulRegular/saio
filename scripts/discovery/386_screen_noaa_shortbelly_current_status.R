root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_shortbelly_status_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10398'
unit_id <- 'noaa_shortbelly_rockfish_pacific_coast'
source_files <- c('shortbelly_2007_assessment.pdf',
  'pacific_groundfish_fmp_amendment_37_2026.pdf')
source_urls <- c(
  'https://www.pcouncil.org/documents/2007/04/stock-assessment-model-for-the-shortbelly-rockfish-sebastes-jordani-in-the-california-current.pdf',
  'https://www.fisheries.noaa.gov/s3/2026-02/fmp-text-am37-01-2026.pdf')
source_revisions <- c(
  'Field et al., NOAA Technical Memorandum SWFSC-405, April 2007',
  'Pacific Coast Groundfish Fishery Management Plan, amended through Amendment 37 (2026)')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 1000L))
  stop('Cache the reviewed NOAA shortbelly sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (anyNA(source_rows) || !all(source_valid))
  stop('Cached NOAA shortbelly sources differ from the reviewed manifest.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
if (sum(register$candidate_id == candidate_id) != 1L)
  stop('Expected one NOAA shortbelly inventory row.', call. = FALSE)
if (any(register$candidate_unit_id == unit_id, na.rm = TRUE) &&
    !any(register$candidate_id == candidate_id & register$candidate_unit_id == unit_id, na.rm = TRUE))
  stop('The NOAA shortbelly unit is already assigned to another row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10398', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical shortbelly assessment records.', call. = FALSE)

row <- match(candidate_id, register$candidate_id)
if (register$scientific_name[row] != 'Sebastes jordani' ||
    register$inventory_assessment_year[row] != 2007)
  stop('Unexpected NOAA shortbelly inventory identity or assessment year.', call. = FALSE)
initial_state <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
current_state <- register$match_status[row] == 'new' &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  register$candidate_unit_id[row] == unit_id
if (!initial_state && !current_state)
  stop('NOAA shortbelly row has a conflicting review state.', call. = FALSE)

screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = unit_id,
  organization = 'NOAA',
  official_stock_id = '10398',
  scientific_name = 'Sebastes jordani',
  stock_name = 'Shortbelly rockfish - Pacific Coast',
  assessment_area = 'Pacific Coast',
  inventory_assessment_year = '2007',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10398',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'No current production assessment is identified for the active stock unit; the archived 2007 model is not selected for current-assessment curation.',
  survey_age_evidence = 'No current production assessment is identified for the active stock unit; the archived 2007 model is not selected for current-assessment curation.',
  weights_evidence = 'Not screened for a current production assessment because the current FMP classifies Shortbelly rockfish as an ecosystem component species.',
  maturity_evidence = 'Not screened for a current production assessment because the current FMP classifies Shortbelly rockfish as an ecosystem component species.',
  mortality_evidence = 'Not screened for a current production assessment because the current FMP classifies Shortbelly rockfish as an ecosystem component species.',
  timing_evidence = 'Not screened for a current production assessment because the current FMP classifies Shortbelly rockfish as an ecosystem component species.',
  output_evidence = 'The 2007 NOAA technical memorandum documents an archival population model; no current official production-assessment outputs were identified for this inventory entry.',
  detailed_source_url = paste(c('https://repository.library.noaa.gov/view/noaa/3947',
    source_urls), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'Ineligible under the current-assessment scope: the 2026 FMP lists Shortbelly rockfish as an ecosystem component species, while the inventory points only to an archived 2007 model. This does not imply that the archived model lacks age-structured data.',
  notes = 'Do not substitute the 2007 model for a current production assessment or import it as current data. See discovery/source_reviews/noaa_shortbelly_rockfish_current_status.md and the local source cache.',
  stringsAsFactors = FALSE, check.names = FALSE)

if (current_state &&
    !all(vapply(names(screened), function(name)
      identical(as.character(register[[name]][row]), as.character(screened[[name]])), logical(1L))))
  stop('The screened NOAA shortbelly row differs from the reviewed decision.', call. = FALSE)

csv_line <- function(x) {
  path <- tempfile(fileext = '.csv')
  write.table(x, path, sep = ',', row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = '', qmethod = 'double')
  raw <- readBin(path, 'raw', n = file.info(path)$size)
  unlink(path)
  charToRaw(sub('\\r?\n$', '', rawToChar(raw), perl = TRUE))
}
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && initial_state) {
  bytes <- readBin(register_path, 'raw', n = file.info(register_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Inventory row is out of range.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, csv_line(screened), ending, after), register_path)
}
cat('Screened NOAA:10398 as ineligible for current-assessment curation; the archived 2007 model was not treated as current.\n')
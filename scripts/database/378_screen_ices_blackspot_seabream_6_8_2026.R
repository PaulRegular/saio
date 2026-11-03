root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_blackspot_seabream_6_8_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:sbr.27.6-8'
unit_id <- 'ices_blackspot_seabream_6_8'

files <- c('advice_2026.html', 'source_data_2026.html', 'source_data_2024.html')
urls <- c(
  'https://asd.ices.dk/viewAdvice/7189',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22362',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=18952')
revisions <- c(
  'ICES advice for 2027-2028, assessment year 2026, category 6; published 2026-06-08',
  'ICES Standard Graphs source data, assessment year 2026, key 22362',
  'ICES Standard Graphs source data, assessment year 2024, key 18952')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed ICES advice and source-data pages before screening ', candidate_id, '.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
if (anyNA(source_rows) || !identical(as.character(sources$url[source_rows]), urls) ||
    !identical(as.character(sources$revision[source_rows]), revisions) ||
    !identical(tolower(as.character(sources$sha256[source_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached source files differ from the reviewed source manifest.', call. = FALSE)

advice <- paste(readLines(paths[1L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
current <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
previous <- paste(readLines(paths[3L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('sbr.27.6-8', advice, fixed = TRUE) ||
    !grepl('zero catch in each of the years 2027 and 2028', advice, fixed = TRUE) ||
    !grepl('sbr.27.6-8', current, fixed = TRUE) ||
    !grepl('lblYear">2026<', current, fixed = TRUE) ||
    !grepl('lblRecruitmentAge">0<', current, fixed = TRUE) ||
    !grepl('lblFAge"></span>', current, fixed = TRUE) ||
    !grepl('lblStockSizeDescription">B_index<', current, fixed = TRUE) ||
    !grepl('<th scope="col">Year</th><th scope="col">Landings</th><th scope="col">Catches</th><th scope="col">Discards</th>', current, fixed = TRUE) ||
    !grepl('lblYear">2024<', previous, fixed = TRUE) ||
    !grepl('<th scope="col">Year</th><th scope="col">Landings</th><th scope="col">Catches</th><th scope="col">Discards</th>', previous, fixed = TRUE))
  stop('Cached ICES sources do not match the reviewed aggregate-only evidence.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    register$official_stock_id[row] != 'sbr.27.6-8' ||
    register$scientific_name[row] != 'Pagellus bogaraveo' ||
    any(stocks$authority_stock_id == 'sbr.27.6-8', na.rm = TRUE) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Blackspot seabream identity conflicts with the register or canonical database.', call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('Official 2026 and 2024 Standard Graphs source tables report annual',
    'landings, catches, and discards only; no catch-at-age or age composition is provided.'),
  survey_age_evidence = paste('The reviewed current and prior Standard Graphs pages do not report',
    'an age-specific survey index or survey age composition.'),
  weights_evidence = 'No weights-at-age are reported in the reviewed current assessment sources.',
  maturity_evidence = 'No maturity-at-age is reported in the reviewed current assessment sources.',
  mortality_evidence = 'No age-specific mortality assumption is reported in the reviewed current assessment sources.',
  timing_evidence = 'No age-specific survey series is reported, so survey timing is not applicable to this screen.',
  output_evidence = paste('The 2026 official advice is category 6 and recommends zero catch for 2027-2028.',
    'The current Standard Graphs entry does not provide recruitment, SSB, F, or population-at-age trajectories.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest current-unit record is the 2026 category 6 advice and linked Standard',
    'Graphs source data. Reviewed 2026 and 2024 tables contain only aggregate landings, catches, and',
    'discards, with no age-disaggregated observations or population outputs. The current record is',
    'therefore ineligible for the age-disaggregated set.'),
  notes = paste('Current unit identity confirmed against the official ICES advice and Standard Graphs.',
    'The 2024 source page was checked as a prior-year cross-check; it does not replace or fill the',
    'current 2026 record. Cached source URLs, assessment keys, revisions, retrieval date, sizes, and',
    'SHA-256 checksums are recorded under source_cache/discovery_ices_blackspot_seabream_6_8_2026/.',
    'No canonical numerical data or tinyAM translation were added.')
)

is_initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
is_reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (!is_initial && !is_reviewed)
  stop('Blackspot seabream candidate already has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && is_initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  bytes <- readBin(register_path, 'raw', n = file.info(register_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', candidate_id, '.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(register[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), register_path)
}

cat('Screened ICES blackspot seabream sbr.27.6-8 as ineligible for age-disaggregated inputs and outputs.\n')

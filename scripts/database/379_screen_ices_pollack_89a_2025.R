root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_pollack_89a_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:pol.27.89a'
unit_id <- 'ices_pollack_89a'

files <- c('advice_2025.html', 'charts_2025.html', 'source_data_2025.html')
urls <- c(
  'https://asd.ices.dk/viewAdvice/3922',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=19891',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19891')
revisions <- c(
  'ICES advice for 2026-2027, assessment year 2025, category 3.2',
  'ICES Standard Graphs, assessment year 2025, key 19891',
  'ICES Standard Graphs source data, assessment year 2025, key 19891')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed ICES advice and Standard Graphs pages before screening ', candidate_id, '.',
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
charts <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('pol.27.89a', advice, fixed = TRUE) ||
    !grepl('commercial catches should be no more than 703 tonnes', advice, fixed = TRUE) ||
    !grepl('recreational catches cannot be quantified', advice, fixed = TRUE) ||
    !grepl('lblStockCode" class="text">pol.27.89a', charts, fixed = TRUE) ||
    !grepl('lblYear" class="text">2025', charts, fixed = TRUE) ||
    !grepl('B_index', charts, fixed = TRUE) ||
    !grepl('Kilograms per hour', charts, fixed = TRUE) ||
    !grepl('Length-based fishing pressure proxy', charts, fixed = TRUE) ||
    !grepl('lblStockSizeDescription">B_index<', source_data, fixed = TRUE) ||
    !grepl('lblRecruitmentAge">0<', source_data, fixed = TRUE) ||
    !grepl('lblFAge"></span>', source_data, fixed = TRUE))
  stop('Cached ICES sources do not match the reviewed aggregate-index evidence.', call. = FALSE)

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
    register$official_stock_id[row] != 'pol.27.89a' ||
    register$scientific_name[row] != 'Pollachius pollachius' ||
    any(stocks$authority_stock_id == 'pol.27.89a', na.rm = TRUE) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Pollack identity conflicts with the register or canonical database.', call. = FALSE)
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
  catch_age_evidence = paste('The 2025 assessment source provides annual landings and discards,',
    'not catch-at-age or fishery age compositions.'),
  survey_age_evidence = paste('The 2025 assessment provides an aggregate biomass index in',
    'kg/hour and no age-specific survey index or age-composition series.'),
  weights_evidence = 'Age-specific weights are not reported in the reviewed current assessment sources.',
  maturity_evidence = 'Age-specific maturity is not reported in the reviewed current assessment sources.',
  mortality_evidence = 'Age-specific mortality assumptions are not reported in the reviewed current assessment sources.',
  timing_evidence = 'No age-specific survey series is reported, so survey timing is not applicable to this screen.',
  output_evidence = paste('The official assessment reports a biomass index with uncertainty bounds,',
    'landings, discards, and a length-based fishing-pressure proxy; it does not report N/F/M at age.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest official assessment is the 2025 category 3.2 index assessment.',
    'The current advice and Standard Graphs expose an aggregate biomass index and a length-based',
    'fishing-pressure proxy, with no age-specific inputs or population outputs. The unit is',
    'ineligible for the age-disaggregated assessment set.'),
  notes = paste('The official 2025 advice applies to 2026-2027 and states that recreational catches',
    'cannot be quantified. Standard Graphs labels the stock-size series B_index in kg/hour; generic',
    'SSB table headings are not interpreted as spawning-stock biomass. Cached source URLs, assessment',
    'key, retrieval date, sizes, and SHA-256 checksums are recorded under',
    'source_cache/discovery_ices_pollack_89a_2025/. No canonical numerical data or tinyAM translation',
    'were added.')
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
  stop('Pollack candidate already has a conflicting review.', call. = FALSE)

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

cat('Screened ICES pollack pol.27.89a as ineligible for age-disaggregated inputs and outputs.\n')

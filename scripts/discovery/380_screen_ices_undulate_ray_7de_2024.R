root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_undulate_ray_7de_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:rju.27.7de'
unit_id <- 'ices_undulate_ray_7de'

files <- c('advice_2024.html', 'charts_2024.html', 'source_data_2024.html', 'wkelasmo_2022.pdf')
urls <- c(
  'https://asd.ices.dk/viewAdvice/3798',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=19173',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19173',
  'https://ndownloader.figshare.com/files/37635047')
revisions <- c(
  'ICES Advice for 2025-2026, assessment year 2024, assessment key 19173',
  'ICES Standard Graphs, assessment year 2024, key 19173',
  'ICES Standard Graphs source data, assessment year 2024, key 19173',
  'ICES WKELASMO 2022 benchmark report, DOI 10.17895/ices.pub.21025021.v1, Figshare article 21025021, file 37635047')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed ICES advice, Standard Graphs pages, and benchmark report before screening ', candidate_id, '.', call. = FALSE)
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
if (!grepl('rju.27.7de', advice, fixed = TRUE) ||
    !grepl('value="4637"', advice, fixed = TRUE) ||
    !grepl('Stock code: <span id="lblStockCode" class="text">rju.27.7de', charts, fixed = TRUE) ||
    !grepl('lblYear" class="text">2024', charts, fixed = TRUE) ||
    !grepl('Relative Biomass', charts, fixed = TRUE) ||
    !grepl('Relative fishing pressure', charts, fixed = TRUE) ||
    !grepl('lblStockSizeDescription">B/Bmsy<', source_data, fixed = TRUE) ||
    !grepl('lblFAge"></span>', source_data, fixed = TRUE))
  stop('Cached ICES sources do not match the reviewed aggregate-indicator evidence.', call. = FALSE)

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
    register$official_stock_id[row] != 'rju.27.7de' ||
    register$scientific_name[row] != 'Raja undulata' ||
    any(stocks$authority_stock_id == 'rju.27.7de', na.rm = TRUE) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Undulate ray identity conflicts with the register or canonical database.', call. = FALSE)
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
  catch_age_evidence = paste('The 2024 advice-linked model is an aggregate SPiCT production assessment,',
    'using removals rather than catch-at-age.'),
  survey_age_evidence = paste('The assessment uses aggregate survey biomass indices (FR-CGFS and',
    'Q1SWECOS in the 2022 benchmark), not age-specific survey abundance.'),
  weights_evidence = 'Age-specific weights are not required by the aggregate SPiCT assessment and are not reported as current model inputs.',
  maturity_evidence = 'Age-specific maturity is not required by the aggregate SPiCT assessment and is not reported as a current model input.',
  mortality_evidence = 'Age-specific natural mortality is not represented by the aggregate SPiCT model.',
  timing_evidence = 'The 2022 benchmark identifies the FR-CGFS autumn survey and Q1SWECOS series; survey timing is not an age-structured model input here.',
  output_evidence = paste('The 2024 Standard Graphs report aggregate relative biomass and relative',
    'fishing pressure with uncertainty bounds; no N/F/M-at-age outputs are reported.'),
  detailed_source_url = paste(c(urls[1:3],
    'https://ices-library.figshare.com/articles/report/Benchmark_Workshop_for_selected_elasmobranch_stocks_WKELASMO_/21025021'),
    collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest located advice-linked assessment is the 2024 category 2 aggregate',
    'SPiCT assessment. Its model inputs and outputs are removals, biomass indices, relative biomass,',
    'and relative fishing pressure. No age-disaggregated likelihood inputs or population outputs are',
    'reported, so the unit is ineligible for the age-disaggregated assessment set.'),
  notes = paste('The 2026 SID row is inventory membership, not an assessment run. The 2024 advice and',
    'Standard Graphs assessment key 19173 identify the current run; the 2022 WKELASMO benchmark',
    'documents the aggregate production-model approach. Cached source URLs, revisions, retrieval date,',
    'sizes, and SHA-256 checksums are recorded under source_cache/discovery_ices_undulate_ray_7de_2024/.',
    'No canonical numerical records were added.')
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
  stop('Undulate ray candidate already has a conflicting review.', call. = FALSE)

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

cat('Screened ICES undulate ray rju.27.7de as ineligible for age-disaggregated inputs and outputs.\n')

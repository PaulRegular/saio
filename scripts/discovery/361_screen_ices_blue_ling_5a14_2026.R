root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_blue_ling_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:bli.27.5a14'
unit_id <- 'ices_blue_ling_5a14'

files <- c('MFRI_blue_ling_2026_technical_report.html',
  'ICES_stock_graphs_2026_key_22662.html', 'ICES_source_data_2026_key_22662.html',
  'ICES_advice_2026_record_7206.html')
urls <- c(
  'https://www.hafogvatn.is/static/extras/images/7_bli_2026_1_techreport_en.html',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22662',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22662',
  'https://asd.ices.dk/viewAdvice/7206'
)
revisions <- c(
  'MFRI Blue ling 2026 technical report, published 2026-06-12',
  'ICES Standard Graphs, assessment year 2026, stock bli.27.5a14, key 22662',
  'ICES source data, assessment year 2026, stock bli.27.5a14, key 22662',
  'ICES 2026 advice record 7206, stock bli.27.5a14'
)
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size <= 100L))
  stop('Cache the reviewed ICES and MFRI sources before screening ', candidate_id, '.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
if (anyNA(source_rows) || !identical(sources$url[source_rows], urls) ||
    !identical(sources$revision[source_rows], revisions) ||
    !identical(tolower(sources$sha256[source_rows]),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached source files differ from the reviewed source manifest.', call. = FALSE)

report_text <- paste(readLines(file.path(cache,
  'MFRI_blue_ling_2026_technical_report.txt'), warn = FALSE), collapse = ' ')
graphs <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
advice <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
if (!grepl('no reliable data on the age composition of blue ling', report_text, fixed = TRUE) ||
    !grepl('no reliable weight-at-age data for blue ling', report_text, fixed = TRUE) ||
    !grepl('No data is available due to difficulties in ageing blue ling', report_text,
      fixed = TRUE) ||
    !grepl('age-length based assessment model (GADGET)', report_text, fixed = TRUE) ||
    !grepl('M = 0.15 for all ages of both stocks', report_text, fixed = TRUE) ||
    !grepl('length-disaggregated survey indices', report_text, fixed = TRUE) ||
    !grepl('bli.27.5a14', graphs, fixed = TRUE) ||
    !grepl('id="lblYear" class="text">2026', graphs, fixed = TRUE) ||
    !grepl('lblRecruitmentAge">5', source_data, fixed = TRUE) ||
    !grepl('lblFAge">10-20', source_data, fixed = TRUE) ||
    !grepl('1 898', advice, fixed = TRUE))
  stop('Cached public sources do not match the reviewed stock and input/output evidence.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id) != 1L ||
    candidates$official_stock_id[row] != 'bli.27.5a14' ||
    candidates$scientific_name[row] != 'Molva dypterygia' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'bli.27.5a14', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Blue ling identity conflicts with the register or canonical database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2026 GADGET assessment uses quarterly landings and',
    'commercial length distributions. The report states there is no reliable age',
    'composition for blue ling; catch-at-age is not available.'),
  survey_age_evidence = paste('The assessment uses a combined index from length-',
    'disaggregated autumn and East Greenland survey indices. These are not age-specific',
    'abundance indices; the spring survey is not used for the assessment.'),
  weights_evidence = 'The MFRI report states there are no reliable weight-at-age data for blue ling.',
  maturity_evidence = paste('The assessment uses maturation data at length from the autumn',
    'survey and a length-based maturation ogive; maturity-at-age is unavailable.'),
  mortality_evidence = paste('Natural mortality is fixed at M = 0.15 for all ages in both',
    'the immature and mature model components.'),
  timing_evidence = paste('The Icelandic autumn groundfish survey is used from 2001 onward;',
    'the current report does not specify a survey fraction of year.'),
  output_evidence = paste('ICES 2026 reports age-5 recruitment (thousands), female SSB and',
    'total biomass (tonnes), and F for ages 10-20 with 2.5% and 97.5% limits. The publicly',
    'reported outputs do not include N-at-age or F-at-age surfaces.'),
  detailed_source_url = paste(c(
    'https://www.hafogvatn.is/static/extras/images/7_bli_2026_1_techreport_en.html',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22662',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22662',
    'https://asd.ices.dk/viewAdvice/7206'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('ICES unit bli.27.5a14 is not represented in the canonical stocks',
    'table. The current 2026 assessment is a GADGET age-length model, not an assessment',
    'with observed age composition. Its inputs are length distributions and length-',
    'disaggregated indices; reliable weight-at-age and maturity-at-age data are unavailable.',
    'Although official biomass, recruitment, and F summaries are published, the required',
    'age-disaggregated inputs are not available for a defensible. Screen',
    'ineligible for the age-disaggregated set.'),
  notes = paste('The 2025 benchmark changed the advice basis to an age-length GADGET model.',
    'The 2026 MFRI technical report describes two model components, quarterly time steps,',
    'fixed M = 0.15, and length-based maturity. Official ICES advice record 7206 recommends',
    '1,898 tonnes for the 2026/2027 fishing year. Source files, URLs, revisions, retrieval',
    'dates, and SHA-256 values are recorded in',
    'source_cache/discovery_ices_blue_ling_2026/sources.csv. No canonical numerical records',
    'were added.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('Blue ling candidate already has a conflicting review.', call. = FALSE)
for (column in names(review)) candidates[[column]][row] <- review[[column]]

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', candidate_id, '.', call. = FALSE)
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
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
}

cat('Screened ICES blue ling as ineligible for the age-disaggregated set.\n')

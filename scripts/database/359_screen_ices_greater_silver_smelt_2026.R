root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_greater_silver_smelt_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:aru.27.5a14'
unit_id <- 'ices_greater_silver_smelt_5a14'

files <- c('MFRI_greater_silver_smelt_2026_technical_report.html',
  'WKBDEEP_2025_report.pdf', 'ICES_stock_graphs_2026_key_22476.html',
  'ICES_source_data_2026_key_22476.html', 'ICES_advice_2026_record_7182.html')
urls <- c(
  'https://www.hafogvatn.is/static/extras/images/19_arg_2026_1_techreport_en.html',
  'https://ndownloader.figshare.com/files/57458506',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22476',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22476',
  'https://asd.ices.dk/viewAdvice/7182'
)
revisions <- c(
  'MFRI Assessment Report 2026, Greater silver smelt, technical report published 2026-06-12',
  'ICES WKBDEEP 2025 report, version 2, DOI 10.17895/ices.pub.28882295.v2',
  'ICES Stock Assessment Graphs for aru.27.5a14, assessment year 2026, key 22476',
  'ICES source-data page for aru.27.5a14, assessment year 2026, key 22476',
  'ICES advice record 7182 for aru.27.5a14, assessment year 2026'
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
  'MFRI_greater_silver_smelt_2026_technical_report.txt'), warn = FALSE), collapse = ' ')
graphs <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
advice <- paste(readLines(paths[5L], warn = FALSE), collapse = ' ')
if (!grepl('Figure 8: Greater silver smelt. Catch at age', report_text, fixed = TRUE) ||
    !grepl('Figure 15: Greater silver smelt. Age disaggregated indices', report_text,
      fixed = TRUE) ||
    !grepl('Figure 16: Greater silver smelt. Stock weights', report_text, fixed = TRUE) ||
    !grepl('Figure 17: Greater silver smelt. Maturity at age', report_text, fixed = TRUE) ||
    !grepl('conducted annually in March', report_text, fixed = TRUE) ||
    !grepl('obtained from the autumn groundfish survey in October', report_text, fixed = TRUE) ||
    !grepl('id="lblYear" class="text">2026', graphs, fixed = TRUE) ||
    !grepl('aru.27.5a14', graphs, fixed = TRUE) ||
    !grepl('lblRecruitmentAge">5', source_data, fixed = TRUE) ||
    !grepl('lblFAge">6-14', source_data, fixed = TRUE) ||
    !grepl('tonnes', source_data, fixed = TRUE) ||
    !grepl('thousands', source_data, fixed = TRUE) ||
    !grepl('aru.27.5a14', advice, fixed = TRUE) ||
    !grepl('Assessment Year', advice, fixed = TRUE) ||
    !grepl('7 636 tonnes', advice, fixed = TRUE))
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
    candidates$official_stock_id[row] != 'aru.27.5a14' ||
    candidates$scientific_name[row] != 'Argentina silus' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'aru.27.5a14', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Greater silver smelt identity conflicts with the register or canonical database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('Figure 8 reports catch biomass by year and age, while Figure 9',
    'reports mean catch weight at age. Dividing biomass by weight can reconstruct',
    'numbers-at-age where both figures provide nonzero coverage. The report also provides',
    'age-composition sample coverage. All values are figure-based and require digitization,',
    'unit checks, and validation against sample coverage.'),
  survey_age_evidence = paste('The MFRI report identifies the Icelandic autumn survey (SMH)',
    'and spring survey (SMB) as assessment inputs and provides age-disaggregated survey',
    'indices in Figure 15. The spring series began in 1985 and is conducted in March; the',
    'autumn survey began in 1996 and expanded in 2000. Survey age indices are figure-based.'),
  weights_evidence = paste('Figure 9 provides catch weights-at-age. Figure 16 provides stock',
    'weights-at-age from the autumn survey; the report states these weights are also used',
    'for spawning-stock calculations. Numerical values require figure digitization.'),
  maturity_evidence = paste('Figure 17 reports the age-specific maturity schedule used to',
    'calculate spawning stock. The MFRI report points to the stock annex for the source',
    'ogive; numerical values in the report are figure-based.'),
  mortality_evidence = paste('The ICES WKBDEEP 2025 benchmark examined natural-mortality',
    'sensitivity and selected fixed M = 0.1 as the assessment assumption. The report notes',
    'that M = 0.15 also fit within the profile-likelihood range, so this remains an explicit',
    'fixed assumption rather than an estimated age-specific M output.'),
  timing_evidence = paste('The report identifies the spring survey in March and stock weights',
    'from the autumn survey in October. These provide seasonal timing; a month-midpoint',
    'fractional-year convention is an approximation if used for a tinyAM translation.'),
  output_evidence = paste('ICES 2026 Standard Graphs report recruitment at age 5 (thousands),',
    'SSB (tonnes), and F for ages 6-14 with uncertainty. The source reports aggregate',
    'population/mortality outputs, not annual N-at-age or F-at-age surfaces.'),
  detailed_source_url = paste(c(
    'https://www.hafogvatn.is/static/extras/images/19_arg_2026_1_techreport_en.html',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22476',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22476',
    'https://asd.ices.dk/viewAdvice/7182',
    'https://doi.org/10.17895/ices.pub.28882295'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('ICES unit aru.27.5a14 is not represented in the canonical stocks table.',
    'The current 2026 assessment is an age-based SAM assessment used for advice. The MFRI',
    'technical report documents age-specific catch biomass and catch weights, which support',
    'a numbers-at-age reconstruction, plus spring and autumn survey indices,',
    'catch and stock weights-at-age, and maturity-at-age; the benchmark documents fixed',
    'M = 0.1. These source inputs are available primarily as figures, so numerical curation',
    'requires transparent digitization and unit checks. Official 2026 outputs include',
    'recruitment, SSB, and F summaries with uncertainty. Eligible for source curation, with',
    'figure digitization and limited age-specific outputs recorded as constraints.'),
  notes = paste('The MFRI 2026 report describes a 2025 SAM benchmark update and contains',
    'input and output plots through the current advice cycle. The official ICES 2026 advice',
    'and Standard Graphs pages confirm assessment year 2026, stock code aru.27.5a14,',
    'recruitment age 5, and F ages 6-14. The SAG XML endpoint returned HTTP 503 during',
    'retrieval; the official graph, source-data, and advice pages are cached instead. Source',
    'files and hashes are recorded in source_cache/discovery_ices_greater_silver_smelt_2026/.',
    'No canonical numerical records were added.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('Greater silver smelt candidate already has a conflicting review.', call. = FALSE)
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

cat('Screened ICES greater silver smelt as an eligible figure-based source-curation candidate.\n')

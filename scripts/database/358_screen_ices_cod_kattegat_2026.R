root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_cod_kattegat_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:cod.27.21'
unit_id <- 'ices_cod_kattegat_21'

files <- c('SAG_2026_key_22381.xml', 'ICES_stock_graphs_2026.html',
  'ICES_source_data_2026.html', 'ICES_advice_2026_record_6134.html')
urls <- c(
  'https://sag.ices.dk/SAG_API/StockXmlDownload/22381',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22381',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22381',
  'https://asd.ices.dk/viewAdvice/6134'
)
revisions <- c(
  'Official ICES Stock Assessment Graphs XML, assessment key 22381',
  'Official ICES Stock Assessment Graphs for cod.27.21, assessment year 2026',
  'Official ICES source-data page for cod.27.21, assessment year 2026',
  'Official ICES advice record 6134, assessment year 2026'
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
  stop('Cache the reviewed ICES sources before screening ', candidate_id, '.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
if (anyNA(source_rows) || !identical(sources$url[source_rows], urls) ||
    !identical(sources$revision[source_rows], revisions) ||
    !identical(tolower(sources$sha256[source_rows]),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached ICES files differ from the reviewed source manifest.', call. = FALSE)

report_dir <- file.path(root, 'source_cache', 'ck_ices_wgbfas_morhua_bs_25_32',
  'assessment_2026')
report_pdf <- file.path(report_dir, 'WGBFAS_2026.pdf')
report_text_path <- file.path(report_dir, 'WGBFAS_2026.txt')
report_manifest <- read.csv(file.path(report_dir, 'manifest.csv'), stringsAsFactors = FALSE)
report_pdf_row <- match('WGBFAS_2026.pdf', report_manifest$cached_file)
if (is.na(report_pdf_row) || !file.exists(report_pdf) ||
    tolower(report_manifest$sha256[report_pdf_row]) != sha256_file(report_pdf))
  stop('The shared WGBFAS 2026 report does not match its source manifest.', call. = FALSE)
report_text <- gsub('[[:space:]]+', ' ',
  paste(readLines(report_text_path, warn = FALSE), collapse = ' '))
if (!grepl('age based \\(SAM\\) indicative of trends, not able to mimic catches',
    report_text, ignore.case = TRUE) ||
    !grepl('This section of the report will be published on 30 June 2026',
      report_text, fixed = TRUE))
  stop('The shared report text no longer supports the documented screening decision.',
    call. = FALSE)

graphs <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
advice <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
xml <- paste(readLines(paths[1L], warn = FALSE), collapse = ' ')
if (!grepl('id="lblYear" class="text">2026', graphs, fixed = TRUE) ||
    !grepl('cod.27.21', graphs, fixed = TRUE) ||
    !grepl('cod.27.21', xml, fixed = TRUE) ||
    !grepl('lblRecruitmentAge\">1', source_data, fixed = TRUE) ||
    !grepl('lblFAge\">3-5', source_data, fixed = TRUE) ||
    !grepl('cod.27.21', advice, fixed = TRUE) ||
    !grepl('<StockCategory>3</StockCategory>', xml, fixed = TRUE) ||
    !grepl('should be zero catch in 2027 and 2028', advice, fixed = TRUE))
  stop('Cached ICES files do not match the reviewed stock and advice.', call. = FALSE)

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
    candidates$official_stock_id[row] != 'cod.27.21' ||
    candidates$scientific_name[row] != 'Gadus morhua' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'cod.27.21', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES Kattegat cod identity conflicts with the register or canonical database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2026 report confirms an age-based SAM assessment, but its',
    'Kattegat chapter is a placeholder in the published working-group report. The official',
    'source-data page reports aggregate annual landings, catches and discards in tonnes;',
    'no run-matched catch-at-age table or age-composition input was verified.'),
  survey_age_evidence = paste('The assessment is described as age-based SAM and the 2023',
    'audit refers to four surveys, but the current 2026 public source tables do not expose',
    'survey age compositions or an age-specific abundance index. Run-matched survey inputs',
    'remain unresolved.'),
  weights_evidence = paste('The current report chapter and official source-data page do not',
    'provide run-matched catch, stock or survey weights-at-age.'),
  maturity_evidence = paste('The current report chapter and official source-data page do not',
    'provide a run-matched maturity-at-age schedule.'),
  mortality_evidence = paste('The assessment is identified as an age-based SAM model, but the',
    'reviewed public sources do not document the run-matched M assumptions or estimated',
    'age-specific M output.'),
  timing_evidence = paste('The reviewed 2026 sources do not identify a fractional timing for',
    'the survey observations in the age-based assessment.'),
  output_evidence = paste('ICES Stock Assessment Graphs key 22381 reports relative recruitment',
    'at age 1, relative SSB and relative mortality for ages 3-5 with uncertainty, plus',
    'aggregate catches and discards. No age-specific N, F or M surfaces are reported.'),
  detailed_source_url = paste(c(
    'https://doi.org/10.17895/ices.pub.32455056',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22381',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22381',
    'https://asd.ices.dk/viewAdvice/6134'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The current ICES unit cod.27.21 is distinct from the cod units',
    'already in the database. WGBFAS 2026 describes an accepted, age-based SAM update as',
    'indicative of trends and not able to mimic catches; no forecast is presented. The',
    'published chapter is a placeholder, while the public ICES tables provide aggregate',
    'outputs but not run-matched age-disaggregated inputs. Keep eligibility unresolved until',
    'the current assessment inputs can be verified; do not infer eligibility from the',
    'age-based model label alone.'),
  notes = paste('The ICES 2026 advice record is Category 3 and advises zero catch in 2027',
    'and 2028. The WGBFAS 2026 report section 2.2 was not included in the full report;',
    'its audit appendix describes the assessment as age-based SAM for trend indication.',
    'The ICES Standard Graphs and source-data pages and XML are cached under',
    'source_cache/discovery_ices_cod_kattegat_2026/. The shared WGBFAS report PDF and its',
    'checksum are in source_cache/ck_ices_wgbfas_morhua_bs_25_32/assessment_2026/.',
    'No canonical numerical data were added.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES Kattegat cod candidate already has a conflicting review.', call. = FALSE)
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

cat('Screened ICES Kattegat cod as a distinct age-based trend assessment with unresolved input coverage.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_witch_northsea_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:lem.27.3a47d'
unit_id <- 'ices_lemon_sole_3a47d'
report_file <- 'wgnssk_witch.pdf'
report_path <- file.path(cache, report_file)
report_url <- 'https://doi.org/10.17895/ices.pub.32676345.v2'

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (!file.exists(report_path) || !file.exists(file.path(cache, 'wgnssk_witch.txt')))
  stop('Cache the 2026 WGNSSK report and text extraction before screening ', candidate_id,
    '.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_row <- match(report_file, basename(sources$file))
if (is.na(source_row) || sources$url[source_row] !=
    'https://ndownloader.figshare.com/files/69947256' ||
    tolower(sources$sha256[source_row]) != sha256_file(report_path))
  stop('Cached report differs from its recorded source manifest.', call. = FALSE)

report_text <- paste(readLines(file.path(cache, 'wgnssk_witch.txt'), warn = FALSE),
  collapse = ' ')
report_normalized <- tolower(gsub('[^[:alnum:]]+', ' ', report_text))
lem_start <- regexpr('audit of lem 27 3a47d', report_normalized, fixed = TRUE)[1L]
lem_text <- if (lem_start > 0L) substr(report_normalized, lem_start, lem_start + 5000L) else ''
if (!grepl('stock size indicator based on survey based assessment', lem_text, fixed = TRUE) ||
    !grepl('surbar', lem_text, fixed = TRUE) ||
    !grepl('chr rule', lem_text, fixed = TRUE) ||
    !grepl('benchmark process 2026 2027', lem_text, fixed = TRUE))
  stop('The cached report does not support the reviewed lemon-sole assessment method.',
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
    candidates$official_stock_id[row] != 'lem.27.3a47d' ||
    candidates$scientific_name[row] != 'Microstomus kitt' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'lem.27.3a47d', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Microstomus kitt', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Lemon sole identity conflicts with the register or canonical database.',
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
  catch_age_evidence = paste('The 2026 WGNSSK audit identifies the current assessment as a',
    'survey-based stock-size indicator assessment. The advice method uses SURBAR relative',
    'SSB and the chr rule; catch-at-age is not part of the described current model.'),
  survey_age_evidence = paste('The current advised method uses SURBAR stock-size indicators.',
    'The 2026 report does not identify an age-specific survey index used in the assessment.'),
  weights_evidence = paste('The 2026 assessment summary does not identify weight-at-age inputs;',
    'the current advice model is survey-based and not an age-structured population model.'),
  maturity_evidence = paste('The 2026 assessment summary does not identify maturity-at-age inputs;',
    'the current advice model is survey-based and not an age-structured population model.'),
  mortality_evidence = paste('The 2026 assessment summary does not identify a run-specific',
    'age-structured natural-mortality input.'),
  timing_evidence = paste('The current SURBAR-based stock-size indicator method does not report',
    'age-specific survey timing for an age-structured population model.'),
  output_evidence = paste('The 2026 audit describes relative SSB from SURBAR as the stock-size',
    'indicator for the chr advice rule. It does not identify N-at-age or F-at-age outputs.'),
  detailed_source_url = report_url,
  review_date = '2026-10-30',
  decision_reason = paste('ICES unit lem.27.3a47d is a distinct current stock not represented',
    'in the canonical stocks table. The 2026 WGNSSK report identifies the current advised',
    'method as a survey-based stock-size indicator using SURBAR relative SSB and the chr',
    'rule; it is not an age-structured population assessment with the age-specific inputs',
    'required for tinyAM. Screen ineligible for the age-disaggregated set.'),
  notes = paste('The assessment has used the SURBAR-based DLS method since 2023. The report',
    'states that the stock will be benchmarked in 2026-2027, when other methods may be',
    'explored. This review applies to the current 2026 advised method only. The WGNSSK',
    'report and checksum are recorded in',
    'source_cache/discovery_ices_witch_northsea_2026/sources.csv. No canonical numerical',
    'records were added.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('Lemon sole candidate already has a conflicting review.', call. = FALSE)
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

cat('Screened ICES lemon sole as ineligible for the age-disaggregated set.\n')

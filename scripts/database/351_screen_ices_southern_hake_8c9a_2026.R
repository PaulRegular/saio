root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_ices_southern_hake_8c9a_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:hke.27.8c9a'
unit_id <- 'ices_southern_hake_8c9a'
files <- c(
  'ICES_Advice_5108.html',
  'ICES_StockGraphs_23751.html',
  'ICES_SourceData_23751.html',
  'ICES_StockAssessment_23751.xml'
)
paths <- file.path(cache, files)
report_path <- file.path(root, 'source_cache',
  'discovery_ices_black_bellied_anglerfish_78abd_2026', 'ICES_WGBIE_2026.pdf')
urls <- c(
  'https://asd.ices.dk/viewAdvice/5108',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=23751',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23751',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/23751'
)
revisions <- c(
  'ICES 2026 advice record 5108 for hke.27.8c9a',
  'ICES Stock Assessment Graphs, assessment year 2026, key 23751',
  'ICES Stock Assessment Graphs source data, assessment year 2026, key 23751',
  'ICES Stock Assessment Graphs XML assessment data, assessment year 2026, key 23751'
)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size <= 0) ||
    !file.exists(report_path) || file.info(report_path)$size <= 0)
  stop('Cache the reviewed ICES sources before screening ', id, '.', call. = FALSE)

sources <- data.frame(
  file = files, url = urls, retrieval_date = '2026-10-30', revision = revisions,
  bytes = unname(file.info(paths)$size),
  sha256 = unname(vapply(paths, sha256_file, character(1L))),
  retrieved_utc = '2026-10-30', stringsAsFactors = FALSE
)
report_source <- data.frame(
  file = '../discovery_ices_black_bellied_anglerfish_78abd_2026/ICES_WGBIE_2026.pdf',
  url = 'https://archimer.ifremer.fr/doc/01075/118683/132700.pdf',
  retrieval_date = '2026-10-30',
  revision = 'ICES Scientific Reports 8:46, WGBIE 2026, section 10, DOI 10.17895/ices.pub.32790321.v1',
  bytes = unname(file.info(report_path)$size), sha256 = sha256_file(report_path),
  retrieved_utc = '2026-10-30', stringsAsFactors = FALSE
)
sources <- rbind(sources, report_source)
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  rows <- match(sources$file, previous$file)
  if (anyNA(rows) || !identical(previous$url[rows], sources$url) ||
      !identical(previous$revision[rows], sources$revision) ||
      !identical(tolower(previous$sha256[rows]), sources$sha256))
    stop('Cached ICES files differ from the reviewed source manifest.', call. = FALSE)
} else {
  write.csv(sources, manifest_path, row.names = FALSE, na = '')
}

advice <- paste(readLines(paths[1L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
xml <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
if (!all(vapply(c('hke.27.8c9a', '2026', 'Stock Category', '23751'),
    grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('hke.27.8c9a', '2026', '23751', 'Age and Length',
      'Unit recruitment'),
      grepl, logical(1L), x = source_data, ignore.case = TRUE)) ||
    !all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
      '<StockCode>hke.27.8c9a</StockCode>', '<StockCategory>1</StockCategory>',
      '<Fage>1-7</Fage>', '<RecruitmentAge>0</RecruitmentAge>',
      '<StockSizeDescription>SSB</StockSizeDescription>',
      '<ConfidenceIntervalDefinition>90%</ConfidenceIntervalDefinition>'),
      grepl, logical(1L), x = xml, fixed = TRUE)))
  stop('Cached ICES advice or graph data do not match the reviewed assessment.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'hke.27.8c9a' ||
    candidates$scientific_name[row] != 'Merluccius merluccius' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'hke.27.8c9a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES southern hake identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'WGBIE 2026 describes the current production method as length-based. The',
    'assessment inputs are seasonal catches and length compositions; no',
    'catch-at-age or age-composition likelihood series is reported.'),
  survey_age_evidence = paste(
    'The current assessment uses aggregate survey/CPUE indices and length',
    'compositions. No age-specific survey abundance index or age composition',
    'is reported for the production model.'),
  weights_evidence = paste(
    'The current length-based assessment uses length data. No run-matched',
    'weight-at-age input series was recovered from the current sources.'),
  maturity_evidence = paste(
    'Maturity is not an age-specific likelihood input in the current',
    'length-based assessment; no run-matched age-specific maturity series was',
    'recovered.'),
  mortality_evidence = paste(
    'The 2026 graph reports F averaged over ages 1-7; it does not report an',
    'estimated M-at-age surface. The 2026 production report describes the',
    'assessment method as length-based.'),
  timing_evidence = paste(
    'The current model and graph provide seasonal/aggregate survey context, but',
    'no run-matched fractional-year observation timing was recovered.'),
  output_evidence = paste(
    'ICES Standard Graphs reports age-0 recruitment (thousands), SSB (tonnes),',
    'and F averaged over ages 1-7, with 90% uncertainty intervals. It does not',
    'provide historical N-at-age, F-at-age or M-at-age surfaces.'),
  detailed_source_url = paste(c(urls,
    'https://doi.org/10.17895/ices.pub.32790321.v1'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The latest current-unit assessment is the 2026 ICES Category 1 production',
    'run. WGBIE classifies southern hake among the length-based assessments;',
    'the current run has no reported catch-at-age or age-specific survey inputs.',
    'Its public outputs include age-0 recruitment and Fbar ages 1-7, but not',
    'historical age-specific population surfaces. It is ineligible for the',
    'age-disaggregated candidate set; no canonical data were added.'),
  notes = paste(
    'Advice record 5108 and Standard Graphs key 23751 identify the 2026 run',
    'used for advice for 2027. Graph units are recruitment in thousands and SSB',
    'in tonnes; uncertainty is 90%. The WGBIE 2026 PDF is shared with the',
    'black-bellied anglerfish source cache and referenced in this case manifest.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES southern hake candidate already has a conflicting review.', call. = FALSE)
for (column in names(review)) candidates[[column]][row] <- review[[column]]

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', id, '.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(candidates[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\r?\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
}

cat('Screened ICES southern hake as a length-based assessment.\n')

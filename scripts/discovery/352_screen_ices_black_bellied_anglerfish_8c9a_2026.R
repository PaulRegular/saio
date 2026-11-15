root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_black_bellied_anglerfish_8c9a_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:ank.27.8c9a'
unit_id <- 'ices_black_bellied_anglerfish_8c9a'
files <- c('ICES_Advice_7174.html', 'ICES_StockGraphs_23769.html',
  'ICES_SourceData_23769.html', 'ICES_StockAssessment_23769.xml')
paths <- file.path(cache, files)
report_path <- file.path(root, 'source_cache',
  'discovery_ices_black_bellied_anglerfish_78abd_2026', 'ICES_WGBIE_2026.pdf')
urls <- c('https://asd.ices.dk/viewAdvice/7174',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=23769',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23769',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/23769')
revisions <- c('ICES 2026 advice record 7174 for ank.27.8c9a',
  'ICES Stock Assessment Graphs, assessment year 2026, key 23769',
  'ICES Stock Assessment Graphs source data, assessment year 2026, key 23769',
  'ICES Stock Assessment Graphs XML assessment data, assessment year 2026, key 23769')

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

sources <- data.frame(file = files, url = urls, retrieval_date = '2026-10-30',
  revision = revisions, bytes = unname(file.info(paths)$size),
  sha256 = unname(vapply(paths, sha256_file, character(1L))),
  retrieved_utc = '2026-10-30', stringsAsFactors = FALSE)
sources <- rbind(sources, data.frame(
  file = '../discovery_ices_black_bellied_anglerfish_78abd_2026/ICES_WGBIE_2026.pdf',
  url = 'https://archimer.ifremer.fr/doc/01075/118683/132700.pdf',
  retrieval_date = '2026-10-30',
  revision = 'ICES Scientific Reports 8:46, WGBIE 2026, section 4.3, DOI 10.17895/ices.pub.32790321.v1',
  bytes = unname(file.info(report_path)$size), sha256 = sha256_file(report_path),
  retrieved_utc = '2026-10-30', stringsAsFactors = FALSE))
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
if (!all(vapply(c('ank.27.8c9a', '2026', 'Stock Category', '23769'),
    grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('ank.27.8c9a', '2026', '23769', 'Age and Length',
      'Unit recruitment', 'Fish data'),
      grepl, logical(1L), x = source_data, ignore.case = TRUE)) ||
    !all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
      '<StockCode>ank.27.8c9a</StockCode>', '<StockCategory>1</StockCategory>',
      '<Fage></Fage>', '<RecruitmentAge>0</RecruitmentAge>',
      '<StockSizeDescription>SSB</StockSizeDescription>',
      '<ConfidenceIntervalDefinition>90%</ConfidenceIntervalDefinition>'),
      grepl, logical(1L), x = xml, fixed = TRUE)))
  stop('Cached ICES advice or graph data do not match the reviewed assessment.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'ank.27.8c9a' ||
    candidates$scientific_name[row] != 'Lophius budegassa' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'ank.27.8c9a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES southern black-bellied anglerfish identity conflicts with the register or database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('WGBIE 2026 classifies the current assessment as a',
    'surplus-production model. It does not use catch-at-age observations.'),
  survey_age_evidence = paste('The production model is surplus-production and uses',
    'aggregate indicators; no age-specific survey abundance or age-composition',
    'series is reported.'),
  weights_evidence = 'Age-specific weights are not model inputs for the current aggregate production assessment.',
  maturity_evidence = 'Age-specific maturity is not a model input for the current aggregate production assessment.',
  mortality_evidence = paste('The graph reports aggregate F with no F age range;',
    'no age-specific natural-mortality surface is reported.'),
  timing_evidence = paste('No age-specific index timing applies to the aggregate',
    'production model; the report provides no age-indexed observation schedule.'),
  output_evidence = paste('Standard Graphs reports recruitment (age 0), SSB in',
    'tonnes, catches, and aggregate F with 90% intervals. The graph has no F age',
    'range and provides no historical N-at-age, F-at-age, or M-at-age surface.'),
  detailed_source_url = paste(c(urls, 'https://doi.org/10.17895/ices.pub.32790321.v1'),
    collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest current-unit assessment is the 2026 ICES',
    'Category 1 production run. WGBIE identifies it as a surplus-production',
    'model; the graph provides aggregate recruitment, SSB, catch, and F only.',
    'It is ineligible for the age-disaggregated candidate set; no canonical',
    'assessment or data rows were added.'),
  notes = paste('Advice record 7174 and Standard Graphs key 23769 identify the',
    '2026 run used for 2027 advice. Although the generic graph page contains an',
    '“Age and Length” heading, its F age field is blank and the report classifies',
    'the model as surplus-production. The WGBIE PDF is shared with the 78abd',
    'black-bellied source cache and referenced in this case manifest.'))

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES southern black-bellied anglerfish candidate already has a conflicting review.',
    call. = FALSE)
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

cat('Screened ICES southern black-bellied anglerfish as surplus-production.\n')

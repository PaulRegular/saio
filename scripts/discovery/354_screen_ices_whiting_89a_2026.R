root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_whiting_89a_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:whg.27.89a'
unit_id <- 'ices_whiting_89a'
files <- c('ICES_Advice_7180.html', 'ICES_StockGraphs_23773.html',
  'ICES_SourceData_23773.html', 'ICES_StockAssessment_23773.xml')
paths <- file.path(cache, files)
report_path <- file.path(root, 'source_cache',
  'discovery_ices_black_bellied_anglerfish_78abd_2026', 'ICES_WGBIE_2026.pdf')
urls <- c('https://asd.ices.dk/viewAdvice/7180',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=23773',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23773',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/23773')
revisions <- c('ICES 2026 advice record 7180 for whg.27.89a',
  'ICES Stock Assessment Graphs, assessment year 2026, key 23773',
  'ICES Stock Assessment Graphs source data, assessment year 2026, key 23773',
  'ICES Stock Assessment Graphs XML assessment data, assessment year 2026, key 23773')

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
  revision = 'ICES Scientific Reports 8:46, WGBIE 2026, DOI 10.17895/ices.pub.32790321.v1',
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
graph <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
xml <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
if (!all(vapply(c('whg.27.89a', '2026', '23773', '3.2'), grepl,
    logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('whg.27.89a', '2026', '23773', 'Biomass index',
      'Fishing pressure', 'Landings', 'Discards'), grepl, logical(1L), x = graph,
      ignore.case = TRUE)) ||
    !all(vapply(c('whg.27.89a', '2026', '23773', 'B_index', 'Unit recruitment',
      'Fish data', 'lblFAge'), grepl, logical(1L), x = source_data,
      ignore.case = TRUE)) ||
    !all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
      '<StockCode>whg.27.89a</StockCode>', '<StockCategory>3.2</StockCategory>',
      '<Fage></Fage>', '<StockSizeDescription>B_index</StockSizeDescription>'),
      grepl, logical(1L), x = xml, fixed = TRUE)))
  stop('Cached ICES advice or graph data do not match the 2026 assessment.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'whg.27.89a' ||
    candidates$scientific_name[row] != 'Merlangius merlangus' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'whg.27.89a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES whiting identity conflicts with the register or database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2026 Category 3.2 advice is based on a biomass',
    'index and length-based indicator, not an age-structured population model.',
    'Published catch information is aggregate landings and discards.'),
  survey_age_evidence = paste('The 2026 Standard Graphs source reports an aggregate',
    'biomass-index series. No age-specific index or age-composition series is',
    'reported for the current assessment.'),
  weights_evidence = 'Age-specific stock and catch weights are not inputs to the current length-based indicator assessment.',
  maturity_evidence = 'Age-specific maturity is not used or reported for the current length-based indicator assessment.',
  mortality_evidence = paste('The current assessment reports a length-based fishing',
    'pressure proxy, not age-specific fishing or natural mortality.'),
  timing_evidence = paste('No age-specific index timing applies to the current',
    'length-based indicator assessment.'),
  output_evidence = paste('Standard Graphs key 23773 reports a relative biomass',
    'index, aggregate landings/discards, and a length-based fishing-pressure',
    'proxy. The F age field is blank; it does not provide age-specific N, F, or',
    'M surfaces for comparison.'),
  detailed_source_url = paste(c(urls, 'https://doi.org/10.17895/ices.pub.32790321.v1'),
    collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest current-unit assessment is the 2026 ICES',
    'Category 3.2 assessment. Official Standard Graphs identify a biomass index',
    'and length-based fishing-pressure proxy, with no F age range or age-specific',
    'population outputs. It is ineligible for this age-disaggregated inventory;',
    'no canonical assessment or data rows were added.'),
  notes = paste('Advice record 7180 and Standard Graphs key 23773 identify the',
    '2026 assessment. The WGBIE 2026 report lists the stocks with age-structured',
    'models separately; whg.27.89a is not among them. The 2026 model retains',
    'aggregate index and length-based reporting. The report PDF is shared with',
    'another WGBIE screen and referenced in this case manifest.'))

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES whiting candidate already has a conflicting review.', call. = FALSE)
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

cat('Screened ICES whiting as not age-structured.\n')

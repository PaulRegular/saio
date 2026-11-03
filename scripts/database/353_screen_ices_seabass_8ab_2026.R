root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_seabass_8ab_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:bss.27.8ab'
unit_id <- 'ices_seabass_8ab'
files <- c(
  'ICES_Advice_6153.html', 'ICES_StockGraphs_22538.html',
  'ICES_SourceData_22538.html', 'ICES_StockAssessment_22538.xml',
  'ICES_WGBIE_2026_Section11_seabass_north.pdf',
  'ICES_Advice_3931.html', 'ICES_StockGraphs_20993.html',
  'ICES_SourceData_20993.html', 'ICES_StockAssessment_20993.xml',
  'ICES_WKBSEABASS_2025.pdf'
)
paths <- file.path(cache, files)
urls <- c(
  'https://asd.ices.dk/viewAdvice/6153',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22538',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22538',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/22538',
  'https://ndownloader.figshare.com/files/66353375',
  'https://asd.ices.dk/viewAdvice/3931',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=20993',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=20993',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/20993',
  'https://ndownloader.figshare.com/files/56883308'
)
revisions <- c(
  'ICES advice record 6153, assessment year 2026, bss.27.8ab',
  'ICES Stock Assessment Graphs, assessment year 2026, key 22538',
  'ICES Stock Assessment Graphs source data, assessment year 2026, key 22538',
  'ICES Stock Assessment Graphs XML assessment data, assessment year 2026, key 22538',
  'ICES Scientific Reports 8:46, WGBIE 2026, section 11, DOI 10.17895/ices.pub.32790321.v1',
  'ICES advice record 3931, assessment year 2025, bss.27.8ab',
  'ICES Stock Assessment Graphs, assessment year 2025, key 20993',
  'ICES Stock Assessment Graphs source data, assessment year 2025, key 20993',
  'ICES Stock Assessment Graphs XML assessment data, assessment year 2025, key 20993',
  'ICES Scientific Reports 7:3, WKBSEABASS 2025, Bay of Biscay stock model annex, DOI 10.17895/ices.pub.25002488.v1'
)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the reviewed ICES sources before screening ', id, '.', call. = FALSE)

sources <- data.frame(
  file = files, url = urls, retrieval_date = '2026-10-30', revision = revisions,
  bytes = unname(file.info(paths)$size),
  sha256 = unname(vapply(paths, sha256_file, character(1L))),
  retrieved_utc = '2026-10-30', stringsAsFactors = FALSE
)
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
if (!all(vapply(c('bss.27.8ab', '2026', '6153', '22538'), grepl,
    logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('bss.27.8ab', '2026', '22538', 'Age and Length',
      'Unit recruitment', 'Fish data'), grepl, logical(1L), x = source_data,
      ignore.case = TRUE)) ||
    !all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
      '<StockCode>bss.27.8ab</StockCode>', '<StockCategory>1</StockCategory>',
      '<Fage>4-15</Fage>', '<RecruitmentAge>0</RecruitmentAge>',
      '<StockSizeDescription>Combined-sex SSB</StockSizeDescription>',
      '<ConfidenceIntervalDefinition>90%</ConfidenceIntervalDefinition>',
      '<Fish_Data><Year>2025</Year>'), grepl, logical(1L), x = xml, fixed = TRUE)))
  stop('Cached ICES advice or graph data do not match the 2026 assessment.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'bss.27.8ab' ||
    candidates$scientific_name[row] != 'Dicentrarchus labrax' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'bss.27.8ab', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES Bay of Biscay sea bass identity conflicts with the register or database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2026 SS3 assessment fits catch and length compositions plus annual',
    'conditional age-at-length observations. The report says combined annual',
    'age-length keys are used to provide catch-at-age estimates; marginal',
    'fleet age compositions are not in the likelihood. Catch-at-age is',
    'reconstructible from source quantities, not a direct likelihood input.'),
  survey_age_evidence = paste(
    'Nourdem Loire (2016-2025) and Gironde (2019-2025) provide juvenile',
    'abundance indices; the 2025 benchmark describes these as covering ages',
    '1-4. The adult OTB LPUE series spans 2000-2025, excluding 2000 and 2008',
    'from the fit. The 2026 report publishes aggregate index series rather',
    'than age-by-age index values.'),
  weights_evidence = paste(
    'The model estimates von Bertalanffy growth parameters and fixes',
    'length-at-age 30 at 87.7611 cm. Exact weight-at-age inputs and the',
    'growth/weight conversion remain to be extracted from model files.'),
  maturity_evidence = paste(
    'Female maturity is length-based, with L50 = 42.14 cm and logistic slope',
    '-0.37809. Maturity-at-age is derivable from the official growth model,',
    'but the report does not publish an age-specific maturity vector.'),
  mortality_evidence = paste(
    'Natural mortality at ages 0-5 is 0.840918, 0.463849, 0.365109, 0.306347,',
    '0.267492, and 0.24 per year; ages 6+ use 0.24.'),
  timing_evidence = paste(
    'The model is annual. The reviewed 2026 report gives Q3/Q4 catch',
    'reallocation rates for seasonal stock mixing, but does not provide an',
    'exact fractional-year timing for the abundance indices.'),
  output_evidence = paste(
    'Standard Graphs key 22538 reports age-0 recruitment (thousands),',
    'combined-sex SSB (tonnes), and F averaged over ages 4-15, with 90%',
    'intervals. The 2026 model uses data through 2025; the 2026 output row is',
    'a forecast. No historical N-at-age, F-at-age, or M-at-age arrays are',
    'reported in the standard graph.'),
  detailed_source_url = paste(c(urls[1:5],
    'https://doi.org/10.17895/ices.pub.25002488.v1'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The latest current-unit assessment is the 2026 Category 1 update using',
    'data through 2025 and the 2025 WKBSEABASS model structure. It is eligible',
    'for source curation because commercial catch/length and conditional',
    'age-at-length inputs support a documented catch-at-age reconstruction,',
    'juvenile survey indices and their age information are available, and',
    'official annual recruitment, SSB, and Fbar outputs are published. Exact',
    'weights-at-age and survey timing still require extraction and validation.'),
  notes = paste(
    'Advice record 6153 and Standard Graphs key 22538 identify the 2026',
    'assessment used for 2027 advice. The WGBIE 2026 report identifies the',
    'assessment as an update using 2025 data and the WKBSEABASS 2025 model',
    'structure. No numerical data were added to the canonical database.')
)

same_review <- all(vapply(names(review), function(column) {
  identical(as.character(candidates[[column]][row]), as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES sea bass candidate already has a conflicting review.', call. = FALSE)
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
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
}

cat('Screened ICES Bay of Biscay sea bass as eligible for source curation.\n')

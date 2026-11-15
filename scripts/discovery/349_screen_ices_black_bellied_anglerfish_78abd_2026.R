root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_ices_black_bellied_anglerfish_78abd_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:ank.27.78abd'
unit_id <- 'ices_black_bellied_anglerfish_78abd'
files <- c(
  'ICES_Advice_5112.html',
  'ICES_StockGraphs_23768.html',
  'ICES_SourceData_23768.html',
  'ICES_StockAssessment_23768.xml',
  'ICES_WGBIE_2026.pdf'
)
paths <- file.path(cache, files)
urls <- c(
  'https://asd.ices.dk/viewAdvice/5112',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=23768',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23768',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/23768',
  'https://archimer.ifremer.fr/doc/01075/118683/132700.pdf'
)
revisions <- c(
  'ICES 2026 advice record 5112 for ank.27.78abd',
  'ICES Stock Assessment Graphs, assessment year 2026, key 23768',
  'ICES Stock Assessment Graphs source data, assessment year 2026, key 23768',
  'ICES Stock Assessment Graphs XML assessment data, assessment year 2026, key 23768',
  'ICES Scientific Reports 8:46, WGBIE 2026, section 3.3, DOI 10.17895/ices.pub.32790321'
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
graphs <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE), collapse = ' ')
xml <- paste(readLines(paths[4L], warn = FALSE), collapse = ' ')
if (!all(vapply(c('ank.27.78abd', '2026', 'Stock Category', '19 130 tonnes'),
    grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('ank.27.78abd', '2026', '23768', 'Age and Length',
      'Recruitment', 'lblFAge', '3-10'),
      grepl, logical(1L), x = source_data, ignore.case = TRUE)) ||
    !all(vapply(c('<ModelType>AL</ModelType>', '<ModelName>SS3</ModelName>',
      '<StockSizeDescription>Combined-sex SSB</StockSizeDescription>',
      '<RecruitmentAge>0</RecruitmentAge>', '<Fage>3-10</Fage>'),
      grepl, logical(1L), x = xml, fixed = TRUE)))
  stop('Cached ICES advice or graph data do not match the reviewed assessment.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'ank.27.78abd' ||
    candidates$scientific_name[row] != 'Lophius budegassa' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'ank.27.78abd', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES black-bellied anglerfish identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'WGBIE 2026 section 3.3 describes landings/discards and catch numbers-at-length;',
    '65% of 2025 landings had length data. The production observations are not',
    'catch-at-age or age-composition likelihood inputs.'),
  survey_age_evidence = paste(
    'The assessment uses the combined FR_IE_IBTS index (French EVHOE-WIBTS-Q4 and',
    'Irish IGFS-WIBTS-Q4) and the Irish IAMS index. The report describes survey',
    'length distributions, not age-specific abundance indices or age compositions.'),
  weights_evidence = paste(
    'The production report says growth and length-weight parameters are fixed and',
    'described in the Stock Annex. No run-matched weight-at-age input was recovered.'),
  maturity_evidence = paste(
    'Maturity is fixed and described in the Stock Annex; no age-specific maturity',
    'input series was recovered from the production report.'),
  mortality_evidence = paste(
    'Natural mortality is fixed, not estimated, and specified in the Stock Annex.',
    'No estimated M-at-age output is reported.'),
  timing_evidence = paste(
    'FR_IE_IBTS combines quarter-4 French and Irish surveys. IAMS occurs at the',
    'start of the year but is entered as an index on 31 December of the preceding',
    'year for the in-year assessment; the exact survey timing convention is documented'),
  output_evidence = paste(
    'Stock Assessment Graphs reports age-0 recruitment (thousands), combined-sex',
    'SSB (tonnes) and F for ages 3-10. It does not report N-at-age, F-at-age or',
    'M-at-age surfaces for this assessment.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The latest current-unit assessment is the 2026 ICES Category 1 production run.',
    'WGBIE describes it as a length-based age-structured Stock Synthesis model,',
    'but the documented catch and survey composition observations are at length.',
    'The public graph reports aggregate SSB, age-0 recruitment and F ages 3-10,',
    'not age-specific population outputs. It is therefore ineligible for the',
    'age-disaggregated candidate set; no canonical data were added.'),
  notes = paste(
    'ICES advice record 5112 identifies assessment year 2026, Category 1 and graph',
    'key 23768. The report describes assessment data through 2025; its section 3.3',
    'states that maturity, M, growth and length-weight parameters are fixed. The',
    '2026 graph is retained as published and is not used to imply age-specific inputs.',
    'Cached files and SHA-256 checks are in the ignored source cache.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES black-bellied anglerfish candidate already has a conflicting review.',
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
  bytes <- c(before, charToRaw(replacement), ending, after)
  writeBin(bytes, candidate_path)
}

cat('Screened ICES black-bellied anglerfish as length-based age-structured SS3.\n')

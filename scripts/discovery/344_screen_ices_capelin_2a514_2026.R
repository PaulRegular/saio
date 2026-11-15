root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_capelin_2a514_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:cap.27.2a514'
unit_id <- 'ices_capelin_iegjm'
files <- c(
  'MFRI_Capelin_2026_1_TechReport.html',
  'MFRI_Capelin_2026_2_Advice.html',
  'ICES_SAG_23744.html',
  'ICES_SAG_source_23744.html'
)
paths <- file.path(cache, files)
urls <- c(
  'https://www.hafogvatn.is/static/extras/images/31_cap_2026_1_techreport_en.html',
  'https://www.hafogvatn.is/static/extras/images/31_cap_2026_2_advice_en.html',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=23744',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23744'
)
revisions <- c(
  'MFRI technical report published 2026-06-12; 2025 autumn and January 2026 acoustic surveys',
  'MFRI and GINR intermediate advice published 2026-10-12; autumn 2026 acoustic survey',
  'ICES Stock Assessment Graphs assessment year 2026, assessment key 23744',
  'ICES Stock Assessment Graphs source data, assessment key 23744'
)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
if (any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the reviewed ICES/MFRI sources before screening ', id, '.', call. = FALSE)

sources <- data.frame(
  file = files, url = urls, retrieval_date = '2026-10-30',
  revision = revisions, sha256 = unname(vapply(paths, sha256_file, character(1L))),
  stringsAsFactors = FALSE
)
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  rows <- match(sources$file, previous$file)
  if (anyNA(rows) || !identical(previous$url[rows], sources$url) ||
      !identical(previous$revision[rows], sources$revision) ||
      !identical(tolower(previous$sha256[rows]), sources$sha256))
    stop('Cached ICES/MFRI files differ from the reviewed source manifest.', call. = FALSE)
} else {
  write.csv(sources, manifest_path, row.names = FALSE)
}

plain_text <- function(html) {
  html <- gsub('<[^>]+>', ' ', html)
  html <- gsub('&nbsp;|&#160;|&#xA0;', ' ', html, ignore.case = TRUE)
  gsub('[[:space:]]+', ' ', html)
}
tech_report <- plain_text(paste(readLines(paths[1L], warn = FALSE), collapse = ' '))
advice <- plain_text(paste(readLines(paths[2L], warn = FALSE), collapse = ' '))
chart <- plain_text(paste(readLines(paths[3L], warn = FALSE), collapse = ' '))
if (!all(vapply(c('catch in numbers', 'age', 'January acoustic survey',
    'proportion mature'), grepl, logical(1L), x = tech_report,
    ignore.case = TRUE)) ||
    !all(vapply(c('assessment type', 'survey index based estimates',
      'input data for the initial advice', 'abundance estimate'), grepl,
      logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('cap.27.2a514', 'Assessment Year', '23744',
      'Immature Index', 'Biomass'), grepl, logical(1L), x = chart,
      ignore.case = TRUE)))
  stop('Cached ICES/MFRI pages do not match the reviewed capelin assessment.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    any(stocks$authority_stock_id == 'cap.27.2a514', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES capelin identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'MFRI 2026 Table 3 reports international catch numbers by age group and total',
    'catch weight for autumn seasons since 1985. The report cautions that catch',
    'samples may not represent population age structure; the official advice is',
    'survey-index based and these fishery compositions are not established as its',
    'catch-at-age likelihood input.'
  ),
  survey_age_evidence = paste(
    'MFRI 2026 Table 6 provides age- and length-specific acoustic stock size for',
    'the 2025 autumn survey, and Table 7 for the January 2026 survey. The current',
    'October 2026 advice uses autumn acoustic estimates, but a multi-year age-specific',
    'survey input series for that latest update was not recovered.'
  ),
  weights_evidence = paste(
    'The 2026 technical report plots survey mean weight at age for immature ages',
    '1-3 and mature ages 1-4 since 1978; values are chart-based. Numerical',
    'production-run weight-at-age inputs were not recovered.'
  ),
  maturity_evidence = paste(
    'MFRI reports maturity classifications and age/length composition in acoustic',
    'survey samples, but a complete numeric maturity-at-age series for the latest',
    'assessment run was not recovered.'
  ),
  mortality_evidence = paste(
    'Advice projects spawning biomass under an HCR and predation model; the',
    'reviewed latest advice does not publish a run-matched age-specific natural-',
    'mortality surface or fitted M-at-age series.'
  ),
  timing_evidence = paste(
    'The MFRI technical report documents autumn surveys in late August-September',
    'and winter surveys in January-February. Survey timing is clear by season, but',
    'the latest October 2026 update has no detailed run-specific input table.'
  ),
  output_evidence = paste(
    'ICES 2026 assessment key 23744 publishes an immature abundance index, aggregate',
    'biomass with uncertainty limits, and total catch through 2026. MFRI October 2026',
    'advice updates the catch recommendation using the autumn 2026 survey. Neither',
    'source provides annual fitted N-at-age, F-at-age, or M-at-age outputs.'
  ),
  detailed_source_url = paste(c(urls, 'https://doi.org/10.17895/ices.pub.23600094'),
    collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The current IEGJM capelin unit is distinct from the DFO capelin stocks in the',
    'canonical database. The latest MFRI/GINR assessment is survey-index based, not',
    'an age-structured population model. Public reports provide age-disaggregated',
    'catch and acoustic survey tables for selected recent years, plus aggregate',
    'historical outputs, but the complete annual age-specific survey inputs, numeric',
    'biology, and run-matched mortality assumptions for the latest update are not',
    'verified. Eligibility remains unresolved pending recovery of those series; no',
    'canonical assessment or numerical data were added.'
  ),
  notes = paste(
    'The MFRI technical report published 2026-06-12 covers the 2025 autumn and',
    'January 2026 acoustic surveys. A later 2026-10-12 MFRI/GINR advice update',
    'uses the autumn 2026 survey, but no detailed run-matched technical report was',
    'located. ICES key 23744 is the June 2026 initial advice graph and should not',
    'be combined with the October update as if it were the same survey vintage.',
    'Source files and SHA-256 checksums are in the ignored cache.'
  )
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES capelin candidate already has a conflicting review.', call. = FALSE)

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
  bytes <- c(before, charToRaw(replacement), ending, after)
  writeBin(bytes, candidate_path)
}

cat('Screened ICES capelin cap.27.2a514; age-data eligibility remains unresolved pending run-matched time series.\n')

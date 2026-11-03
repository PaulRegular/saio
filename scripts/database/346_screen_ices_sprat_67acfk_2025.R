root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_sprat_67acfk_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:spr.27.67a-cf-k'
unit_id <- 'ices_sprat_celtic_seas'
files <- c(
  'ICES_Advice_3838.html',
  'ICES_SAG_source_19352.html',
  '../discovery_ices_sandeel_area_5r_2025/HAWG_2025.pdf',
  '../discovery_ices_sprat_7de_2026/HAWG_2026.pdf'
)
paths <- file.path(cache, files)
urls <- c(
  'https://asd.ices.dk/viewAdvice/3838',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19352',
  'https://ndownloader.figshare.com/files/62333386',
  'https://backend.orbit.dtu.dk/ws/portalfiles/portal/440308463/HAWG_2026_-_Full_Report.pdf'
)
retrieval_dates <- c('2026-10-30', '2026-10-30', '2026-10-25', '2026-10-30')
revisions <- c(
  'ICES 2025 advice record 3838, advice for 2026-2027',
  'ICES Stock Assessment Graphs source data, assessment year 2025, key 19352',
  'ICES HAWG 2025 full report, ICES Scientific Reports 7:20, DOI 10.17895/ices.pub.28389008',
  'ICES HAWG 2026 full report, ICES Scientific Reports 8:16, DOI 10.17895/ices.pub.32790321.v1'
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
  file = files, url = urls, retrieval_date = retrieval_dates, revision = revisions,
  sha256 = unname(vapply(paths, sha256_file, character(1L))),
  stringsAsFactors = FALSE
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
source_data <- paste(readLines(paths[2L], warn = FALSE), collapse = ' ')
if (!all(vapply(c('spr.27.67a-cf-k', '2025', 'Category', '5.2',
    '1792 tonnes in each of the years 2026 and 2027'), grepl, logical(1L),
    x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('spr.27.67a-cf-k', 'Assessment Year', '2025', '19352',
      'Year</th><th scope="col">Catches'), grepl, logical(1L),
      x = source_data, fixed = TRUE)))
  stop('Cached ICES advice or stock-graph data do not match the reviewed assessment.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id) != 1L ||
    candidates$official_stock_id[row] != 'spr.27.67a-cf-k' ||
    candidates$scientific_name[row] != 'Sprattus sprattus' ||
    candidates$inventory_assessment_year[row] != 2025L ||
    any(stocks$authority_stock_id == 'spr.27.67a-cf-k', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES sprat identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2025 ICES Category 5.2 method uses catch/landings data only. ICES Stock',
    'Assessment Graphs for assessment key 19352 contain an annual catch series in',
    'tonnes, with no catch-at-age or age-composition input.'),
  survey_age_evidence = paste(
    'No survey index or age-specific survey information is used in the current',
    'Category 5 advice method.'),
  weights_evidence = paste(
    'No weight-at-age input is used by the current catch-only advice method.'),
  maturity_evidence = paste(
    'No maturity-at-age input is used by the current catch-only advice method.'),
  mortality_evidence = paste(
    'The current advice method does not estimate or use age-specific natural mortality.'),
  timing_evidence = paste(
    'A survey observation time is not applicable to the current catch-only method.'),
  output_evidence = paste(
    'The 2025 advice recommends catches no greater than 1,792 tonnes in each of 2026',
    'and 2027. The published graph contains annual catches only; no SSB, recruitment,',
    'N-at-age, F-at-age, or M-at-age population outputs are reported.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'This West of Scotland/southern Celtic Seas unit is distinct from the Baltic and',
    'English Channel sprat candidates. The latest advice located is the 2025 ICES',
    'Category 5.2 method, described by HAWG as using only landings/catch data. No',
    'age-specific inputs or population outputs are used or reported, so the unit is',
    'ineligible for the age-disaggregated assessment set. No canonical numerical',
    'records were added.'),
  notes = paste(
    'Current advice source: ICES HAWG 2025; the 2026 HAWG report states that the next',
    'biennial advice was provided in 2025. Advice record 3838 covers calendar years',
    '2026 and 2027; Stock Assessment Graphs key 19352 supplies annual catch history',
    'through 2024. The HAWG reports are shared cached files; local source manifests',
    'record their URLs, revisions, retrieval dates and SHA-256 checksums.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column) {
  identical(current[[column]], as.character(review[[column]]))
}, logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started'
if (!is_unreviewed && !same_review)
  stop('ICES sprat candidate already has a conflicting review.', call. = FALSE)
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

cat('Screened ICES Celtic Seas and West of Scotland sprat as catch-only Category 5 advice.\n')

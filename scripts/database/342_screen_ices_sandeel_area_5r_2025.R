root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_sandeel_area_5r_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c('HAWG_2025.pdf', 'ICES_Advice_3828.html', 'SAG_19319.html'),
  url = c(
    'https://ndownloader.figshare.com/files/62333386',
    'https://asd.ices.dk/viewAdvice/3828',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19319'
  ),
  retrieval_date = c('2026-10-25', '2026-10-30', '2026-10-30'),
  revision = c(
    'ICES HAWG 2025 report, Figshare version 5',
    'ICES advice record 3828, assessment year 2025',
    'ICES Stock Assessment Graphs key 19319, assessment year 2025'
  ),
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the reviewed ICES sources before screening.', call. = FALSE)
if (!identical(readBin(paths[1L], 'raw', n = 4L), charToRaw('%PDF')))
  stop('The cached HAWG source is not a PDF.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', shQuote(path), 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
manifest <- transform(sources, bytes = file.info(paths)$size,
  sha256 = unname(vapply(paths, sha256_file, character(1L))))
manifest_path <- file.path(cache, 'sources.csv')
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  rows <- match(previous$file, manifest$file)
  if (anyNA(rows) || !identical(previous$url, manifest$url[rows]) ||
      !identical(previous$revision, manifest$revision[rows]) ||
      !identical(as.numeric(previous$bytes), as.numeric(manifest$bytes[rows])) ||
      !identical(tolower(previous$sha256), manifest$sha256[rows]))
    stop('Cached ICES sources differ from the reviewed files.', call. = FALSE)
}
write.csv(manifest, manifest_path, row.names = FALSE)

advice <- paste(readLines(paths[2L], warn = FALSE), collapse = '\n')
sag <- paste(readLines(paths[3L], warn = FALSE), collapse = '\n')
if (!all(vapply(c('san.sa.5r', '2025', 'Stock Category', 'zero catches'),
    grepl, logical(1L), x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('san.sa.5r', '19319', 'Catches', '1983', '2024'),
      grepl, logical(1L), x = sag, ignore.case = TRUE)))
  stop('Cached ICES advice or stock-graph page does not match the reviewed assessment.',
    call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('ICES:san.sa.5r', candidates$candidate_id)
unit_id <- 'ices_sandeel_area_5r'
if (is.na(i) || sum(candidates$candidate_id == 'ICES:san.sa.5r') != 1L ||
    candidates$official_stock_id[i] != 'san.sa.5r' ||
    candidates$scientific_name[i] != 'Ammodytes' ||
    candidates$inventory_assessment_year[i] != 2025L ||
    (!is.na(candidates$candidate_unit_id[i]) &&
      candidates$candidate_unit_id[i] != unit_id) ||
    any(candidates$candidate_unit_id[-i] == unit_id, na.rm = TRUE) ||
    any(stocks$authority_stock_id == 'san.sa.5r', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id))
  stop('ICES sandeel Area 5r identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2025 HAWG report describes Area 5r under the ICES Category 5.4 method, for which',
    'only catch data are available. The official stock-graph record contains annual catches',
    'for 1983-2024, but no catch-at-age or age-composition series.'),
  survey_age_evidence = paste(
    'No survey index or age-specific survey information is reported for this Category 5.4',
    'assessment. The 2025 stock-graph page lists catches as the only annual fish-data series.'),
  weights_evidence = paste(
    'No weight-at-age input for the Area 5r production advice was located; age-specific',
    'biological inputs are not part of the catch-only advice method.'),
  maturity_evidence = paste(
    'No maturity-at-age input for the Area 5r production advice was located; age-specific',
    'biological inputs are not part of the catch-only advice method.'),
  mortality_evidence = paste(
    'No age-specific natural-mortality input or fitted M surface is reported for this',
    'catch-only advice method.'),
  timing_evidence = paste(
    'No within-year survey timing is applicable to the catch-only advice record; no survey',
    'likelihood is reported.'),
  output_evidence = paste(
    'The 2025 advice recommends zero catches for 2025 and 2026. The 2025 stock-graph record',
    'contains historical catches only; no comparable SSB, recruitment, N-at-age or F-at-age',
    'population outputs were found.'),
  detailed_source_url = paste(
    'https://doi.org/10.17895/ices.pub.28389008.v5;',
    'https://asd.ices.dk/viewAdvice/3828;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19319'),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Screened ineligible for the age-disaggregated assessment set. The latest active ICES',
    'advice located is the 2025 Category 5 record for 2025-2026. The HAWG report describes',
    'the Area 5r method as Category 5.4 using catch data only, and the official stock-graph',
    'series contains catches without age-specific inputs or population outputs. No canonical',
    'assessment or numerical data were added.'),
  notes = paste(
    'Distinct ICES unit san.sa.5r (northern North Sea, Viking and Bergen banks). The HAWG',
    '2025 report was retrieved on 2026-10-25; the advice and stock-graph pages were retrieved',
    'on 2026-10-30. Annual catch values in the graph are reported in tonnes.')
)
for (column in names(review)) candidates[[column]][i] <- review[[column]]

bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
line_feeds <- which(bytes == as.raw(10L))
physical_line <- i + 1L
if (length(line_feeds) < physical_line) stop('Candidate CSV row is out of range.', call. = FALSE)
first <- line_feeds[physical_line - 1L] + 1L
last <- line_feeds[physical_line]
ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
tmp <- tempfile(fileext = '.csv')
write.table(candidates[i, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
  col.names = FALSE, quote = TRUE, na = '')
replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
unlink(tmp)
replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
before <- bytes[seq_len(first - 1L)]
after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
cat('Screened ICES sandeel Area 5r (san.sa.5r); ineligible for age-disaggregated assessment coverage.\n')

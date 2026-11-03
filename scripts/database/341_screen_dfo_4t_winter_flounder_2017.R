root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_dfo_4t_winter_flounder_2019')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')

sources <- data.frame(
  file = c(
    'dfo_2019_026_winter_flounder_assessment.pdf',
    'dfo_2025_010_indicators_to_2024.pdf'
  ),
  url = c(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40804392.pdf',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf'
  ),
  revision = c(
    'DFO Research Document 2019/026; assessment approved 2017, data through 2016',
    'DFO Science Response 2025/010; interim stock indicators through 2024'
  ),
  retrieved_utc = '2026-10-30',
  stringsAsFactors = FALSE
)
paths <- file.path(cache, sources$file)
if (!dir.exists(cache) || any(!file.exists(paths)) || any(file.info(paths)$size <= 0))
  stop('Cache the reviewed DFO sources before screening.', call. = FALSE)
if (any(vapply(paths, function(path) {
  con <- file(path, open = 'rb')
  on.exit(close(con))
  identical(readBin(con, 'raw', n = 4L), charToRaw('%PDF'))
}, logical(1L)) == FALSE))
  stop('A cached DFO source is not a PDF.', call. = FALSE)

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
  previous_rows <- match(previous$file, manifest$file)
  if (anyNA(previous_rows) ||
      !identical(previous$url, manifest$url[previous_rows]) ||
      !identical(previous$revision, manifest$revision[previous_rows]) ||
      !identical(as.numeric(previous$bytes), as.numeric(manifest$bytes[previous_rows])) ||
      !identical(tolower(previous$sha256), manifest$sha256[previous_rows]))
    stop('Cached DFO sources differ from the reviewed files.', call. = FALSE)
}
write.csv(manifest, manifest_path, row.names = FALSE)

candidate <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('DFO:Gulf:Winter Flounder - NAFO 4T', candidate$candidate_id)
if (is.na(i) || sum(candidate$candidate_id == 'DFO:Gulf:Winter Flounder - NAFO 4T') != 1L)
  stop('The expected DFO 4T winter flounder inventory row is missing or duplicated.',
    call. = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
if (any(stocks$scientific_name == 'Pseudopleuronectes americanus' &
    grepl('4T', paste(stocks$area, stocks$region), fixed = TRUE)))
  stop('A canonical NAFO 4T winter flounder stock already exists; review the match first.',
    call. = FALSE)

review <- list(
  candidate_unit_id = 'dfo_sgsl_winter_flounder_4t',
  scientific_name = 'Pseudopleuronectes americanus',
  assessment_area = 'NAFO Division 4T, southern Gulf of St. Lawrence',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'Table 9 reports commercial catch numbers-at-age in thousands of fish for ages 2-12+,',
    '1973-2016; the 2016 estimates are preliminary. The model fits annual number proportions',
    'derived from these counts alongside total landings in tonnes (Table 1).'),
  survey_age_evidence = paste(
    'Table 10 reports September RV trawlable abundance-at-age in thousands of fish for ages',
    '2-12+, 1973-2016. The model fits annual age proportions derived from these counts and an',
    'aggregate survey index shown in Figure 18; the methods list tonnes while the plot reports kg/tow.'),
  weights_evidence = paste(
    'Table 13 reports RV survey weights-at-age in kg/fish for ages 2-12+, 1973-2016. The',
    'methods also mention fishery weights-at-age, but no numeric fishery surface was recovered.'),
  maturity_evidence = paste(
    'Table 12 reports mature proportions-at-age for 1973-2016, derived from survey length-based',
    'maturity curves and the age-length key.'),
  mortality_evidence = paste(
    'The statistical catch-at-age model estimates time-blocked natural mortality, with five-year',
    'blocks and either two age groups (2-4, 5+) or three (2-4, 5-7, 8+). M is not fixed.'),
  timing_evidence = paste(
    'The model places the September RV survey at 0.71 of the annual time step. Fishery catches',
    'are annual totals; no separate within-year fishery observation fraction is used.'),
  output_evidence = paste(
    'The report gives 2016 Model 2 SSB, total abundance, and age-2/age-3 recruitment in prose,',
    'plus a Model 2 q estimate. Annual N/F/M/SSB state surfaces are shown in figures but are',
    'not tabulated; no machine-readable fitted object was located.'),
  detailed_source_url = paste(sources$url, collapse = '; '),
  review_date = '2026-11-03',
  decision_reason = paste(
    'The 2017 full statistical catch-at-age assessment remains the latest detailed model report',
    'located as of 2026-11-03; the 2025/010 report is an interim indicator update. A partial',
    'source import is available. Fishery weights-at-age and annual fitted state output tables',
    'remain unavailable, and the Figure 18 survey-index scale is unresolved.'),
  notes = paste(
    'Distinct from NOAA winter flounder units in Georges Bank, Gulf of Maine, and Southern New',
    'England/Mid-Atlantic. DFO identifies the current unit as NAFO Division 4T. The full report',
    'models one combined-sex population. Models 1-7 were compared; Table 11 gives Model 7 the',
    'lowest AIC, while main inference results are presented for Model 2.')
)
for (column in names(review)) candidate[[column]][i] <- review[[column]]

bytes <- readBin(candidate_path, 'raw', n = file.info(candidate_path)$size)
line_feeds <- which(bytes == as.raw(10L))
physical_line <- i + 1L
if (length(line_feeds) < physical_line) stop('Candidate CSV row is out of range.', call. = FALSE)
first <- line_feeds[physical_line - 1L] + 1L
last <- line_feeds[physical_line]
ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
tmp <- tempfile(fileext = '.csv')
write.table(candidate[i, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
  col.names = FALSE, quote = TRUE, na = '')
replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
unlink(tmp)
replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
before <- bytes[seq_len(first - 1L)]
after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
writeBin(c(before, charToRaw(replacement), ending, after), candidate_path)
cat('Screened DFO NAFO 4T winter flounder; eligible for source curation.\n')

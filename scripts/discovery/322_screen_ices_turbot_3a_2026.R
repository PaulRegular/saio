root <- "."
cache <- file.path(root, 'source_cache', 'ices_turbot_3a_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
source_review_path <- file.path(root, 'discovery', 'source_reviews', 'ices_turbot_3a_2026.md')
manifest_path <- file.path(cache, 'manifest.csv')
candidate_id <- 'ICES:tur.27.3a'
candidate_unit_id <- 'ices_turbot_3a'
required_files <- c('wgnssk_2026_turbot_3a.pdf',
  'ices_advice_2026_turbot_3a.pdf', 'ices_sag_2026_source_data.html')
source_urls <- c(
  'https://ndownloader.figshare.com/files/69947241',
  'https://ndownloader.figshare.com/files/65947886',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22416'
)
if (!all(file.exists(file.path(cache, required_files))) ||
    any(file.info(file.path(cache, required_files))$size <= 0)) {
  stop('Cache the reviewed ICES 2026 chapter, advice PDF, and graph data before screening.', call. = FALSE)
}

hash_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/', mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output,
      value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest <- data.frame(
  file = file.path(cache, required_files),
  url = source_urls,
  retrieved_utc = rep(format(Sys.time(), tz = 'UTC', format = '%Y-%m-%dT%H:%M:%SZ'),
    length(required_files)),
  sha256 = vapply(file.path(cache, required_files), hash_file, character(1L)),
  stringsAsFactors = FALSE
)
if (file.exists(manifest_path)) {
  existing <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(existing$file, manifest$file) || !identical(existing$url, manifest$url) ||
      !identical(existing$sha256, manifest$sha256)) {
    stop('Cached source manifest does not match the reviewed files.', call. = FALSE)
  }
} else {
  write.csv(manifest, manifest_path, row.names = FALSE, na = '')
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- which(candidates$candidate_id == candidate_id)
if (length(i) != 1L || candidates$official_stock_id[i] != 'tur.27.3a' ||
    !grepl('Scophthalmus maximus', candidates$scientific_name[i], fixed = TRUE) ||
    !grepl('Division 3.a', candidates$stock_name[i], fixed = TRUE)) {
  stop('Expected one current ICES turbot 3.a inventory row.', call. = FALSE)
}
if (any(stocks$authority_stock_id == 'tur.27.3a', na.rm = TRUE) ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(candidates$candidate_unit_id[-i] == candidate_unit_id, na.rm = TRUE)) {
  stop('Turbot 3.a conflicts with an existing canonical or candidate identity.', call. = FALSE)
}
if (any(assessments$assessment_id == 'ices_turbot_3a_2026') ||
    any(inputs$assessment_id == 'ices_turbot_3a_2026') ||
    any(outputs$assessment_id == 'ices_turbot_3a_2026')) {
  stop('This source-screening step must not add canonical assessment data.', call. = FALSE)
}

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The current 2026 production assessment uses aggregate catches in tonnes',
    'for 1960-2025 in SPiCT; it does not use catch-at-age.'),
  survey_age_evidence = paste('Three combined exploitable-biomass indices are used: Q1 1983-2025',
    'and Q3/Q4 1991-2025. They are standardized from five surveys using commercial-to-survey',
    'length ratios for 2012-2018; no age-specific abundance series enters SPiCT.'),
  weights_evidence = 'Age-specific weights are not required or reported as inputs to the aggregate biomass-production model.',
  maturity_evidence = 'Maturity-at-age is not an input to the current SPiCT assessment.',
  mortality_evidence = 'Age-specific natural mortality is not an input to the current SPiCT assessment.',
  timing_evidence = 'The model uses separate quarterly index series for Q1, Q3 and Q4 with year-by-quarter standardization; no single annual survey-time fraction applies.',
  output_evidence = paste('The 2026 report gives annual relative exploitable biomass (B/BMSY) and relative',
    'fishing pressure (F/FMSY) with low/high 95% intervals through the terminal assessment years.',
    'The 2026 advice gives a 2027 catch recommendation of 396 tonnes. No population-at-age N/F,',
    'age-specific M or recruitment, or absolute SSB output is reported.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.32676345.v2',
    'https://asd.ices.dk/viewAdvice/5098',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22416', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest 2026 assessment is the revised SPiCT production method, which uses',
    'aggregate catches and quarterly exploitable-biomass indices. It does not use age-disaggregated',
    'assessment inputs or report age-specific population outputs, so it is ineligible for the',
    'age-disaggregated source set. The survey-index construction uses length information, not age-based',
    'likelihood inputs. No canonical stock record uses the official code tur.27.3a.'),
  notes = paste('ICES WGNSSK 2026 reports a connection between Division 3.a and adjacent North Sea and',
    'Baltic populations and says genetic stock identity is still being evaluated. This biological',
    'boundary caveat does not alter the current ICES advice unit. Reviewed assessment chapter, advice',
    'PDF and Standard Graphs source data are cached under source_cache/ices_turbot_3a_2026/.')
)
for (column in names(review)) candidates[[column]][i] <- review[[column]]

replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row_index + 1L
  if (length(line_feeds) < physical_line) stop('CSV row index is out of range: ', path, call. = FALSE)
  first <- if (physical_line == 1L) 1L else line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- if (first > 1L) bytes[seq_len(first - 1L)] else raw(0L)
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}
source_review <- c(
  '# ICES turbot in Division 3.a (`tur.27.3a`)',
  '',
  'Reviewed 2026-10-30. The current ICES management and advice unit is Division 3.a (Skagerrak and Kattegat), a separate unit from North Sea turbot (`tur.27.4`). The latest available production assessment is the 2026 WGNSSK update, using a revised SPiCT model developed in 2025. The 2026 ICES advice is for catches in 2027.',
  '',
  'The current model is not age-disaggregated. It uses an aggregate catch series in tonnes for 1960-2025 and three combined exploitable-biomass indices: Q1 (1983-2025), Q3 and Q4 (1991-2025). The index model combines five surveys and applies length-based vulnerability weighting using commercial and survey length data from 2012-2018. Those length observations help construct an aggregate biomass index; the assessment does not use catch-at-age or an age-specific abundance index.',
  '',
  'Age-specific weights, maturity, and natural mortality are not inputs to the current SPiCT model. The model reports annual relative exploitable biomass (B/BMSY) and relative fishing pressure (F/FMSY), with low/high 95% intervals in the assessment table. It does not report numbers-at-age, F-at-age, M-at-age, absolute SSB, or age-specific recruitment. ICES advises a maximum catch of 396 tonnes in 2027.',
  '',
  'The ICES 2026 WGNSSK report notes that turbot in Division 3.a is connected to North Sea and Baltic populations and that the stock identity is being evaluated with genetic analysis. This uncertainty concerns biological population boundaries; the official ICES assessment and advice unit remains Division 3.a.',
  '',
  'The candidate is screened ineligible for the age-disaggregated input set. It remains a possible source for future aggregate-model comparisons, but this audit step does not create a canonical assessment or import its values.',
  '',
  'Sources:',
  '',
  '- [ICES WGNSSK 2026 report](https://doi.org/10.17895/ices.pub.32676345.v2), Section 19, pp. 1072-1091; assessment chapter updated 12 October 2026.',
  '- [ICES 2026 Advice View](https://asd.ices.dk/viewAdvice/5098), stock key 22416; catch advice for 2027.',
  '- [ICES Standard Graphs source data](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22416), stock key 22416.',
  '',
  'The chapter, advice PDF and Standard Graphs source page are cached in the gitignored `source_cache/ices_turbot_3a_2026/`; `manifest.csv` records source URLs, retrieval time and SHA-256 checksums.'
)
writeLines(source_review, source_review_path, useBytes = TRUE)
replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])
cat('Screened ICES turbot Division 3.a as a new aggregate-only assessment unit, ineligible for the age-disaggregated set.\n')

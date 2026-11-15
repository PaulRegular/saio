root <- "."
cache <- file.path(root, 'source_cache', 'noaa_iccat_tunas_2024_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
review_path <- file.path(root, 'discovery', 'source_reviews',
  'noaa_iccat_atlantic_tunas_2024_2025.md')
manifest_path <- file.path(cache, 'manifest.csv')

files <- c('yft_2024_stock_assessment.pdf', 'yft_2024_data_preparatory.pdf',
  'bet_2025_stock_assessment.pdf', 'bet_2025_data_preparatory.pdf')
urls <- c(
  'https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_YFT_SA_ENG.pdf',
  'https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_YFT_DP_ENG.pdf',
  'https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_BET_SA_ENG.pdf',
  'https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_BET_DP_ENG.pdf')
revisions <- c('ICCAT 2024 Atlantic Yellowfin Tuna Stock Assessment Meeting report',
  'ICCAT 2024 Atlantic Yellowfin Tuna Data Preparatory Meeting report',
  'ICCAT 2025 Atlantic Bigeye Tuna Stock Assessment Meeting report',
  'ICCAT 2025 Atlantic Bigeye Tuna Data Preparatory Meeting report')
paths <- file.path(cache, files)

if (!all(file.exists(paths)) || any(file.info(paths)$size <= 0)) {
  stop('Cache the four cited ICCAT reports before screening.', call. = FALSE)
}
if (!all(vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L)))) {
  stop('A cached ICCAT report is not a PDF.', call. = FALSE)
}

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest <- data.frame(file = paths, url = urls, revision = revisions,
  retrieved_utc = rep(format(Sys.time(), tz = 'UTC', format = '%Y-%m-%dT%H:%M:%SZ'),
    length(paths)), bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha256_file, character(1L)), stringsAsFactors = FALSE)
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(previous$file, manifest$file) || !identical(previous$url, manifest$url) ||
      !identical(previous$revision, manifest$revision) ||
      !identical(previous$sha256, manifest$sha256)) {
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

ids <- c('NOAA:10166', 'NOAA:10169')
indices <- match(ids, candidates$candidate_id)
if (anyNA(indices) || anyDuplicated(indices) ||
    any(candidates$scientific_name[indices] != c('Thunnus albacares', 'Thunnus obesus')) ||
    any(candidates$inventory_assessment_year[indices] != c(2024L, 2025L)) ||
    any(candidates$assessment_area[indices] != 'Atlantic')) {
  stop('Expected the Atlantic yellowfin and bigeye Stock SMART rows.', call. = FALSE)
}
candidate_units <- c('iccat_atlantic_yellowfin_tuna', 'iccat_atlantic_bigeye_tuna')
if (any(stocks$scientific_name %in% candidates$scientific_name[indices]) ||
    any(stocks$authority_stock_id %in% c('10166', '10169'), na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-indices] %in% candidate_units, na.rm = TRUE)) {
  stop('A tuna candidate conflicts with an existing canonical or candidate stock unit.',
    call. = FALSE)
}
if (any(assessments$assessment_id %in% candidate_units) ||
    any(inputs$assessment_id %in% candidate_units) ||
    any(outputs$assessment_id %in% candidate_units)) {
  stop('This inventory screen must not create canonical assessment data.', call. = FALSE)
}

reviews <- list(
  list(candidate_unit_id = candidate_units[1], match_status = 'new',
    screening_status = 'screened', eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2024 Atlantic assessment uses nominal total catches and fleet/year/season length',
      'compositions, not catch-at-age. Conditional age-at-length observations from fleets 13',
      'and 17 in 2007-2021 are included to estimate growth; they are not catch or population',
      'age compositions. Numeric age-at-length and length-composition matrices were not found.'),
    survey_age_evidence = paste(
      'The assessment uses three aggregate abundance indices: joint-CPC Region 2 longline',
      '(1979-2022), seasonal acoustic buoy (2010-2022), and purse-seine free-school',
      '(1993-2022). No age-specific abundance index was identified.'),
    weights_evidence = paste(
      'Weight is calculated from straight fork length using W = 2.1527e-5 * SFL^2.976',
      '(kg; SFL cm). No numerical age-specific weight surface was recovered.'),
    maturity_evidence = paste(
      'Maturity is specified at length, with 50% maturity at 115.1 cm SFL; fecundity is',
      'related to female body weight. A numeric maturity-at-age input was not recovered.'),
    mortality_evidence = paste(
      'The 2024 assessment uses an age-specific M schedule based on a baseline M of 0.30',
      'at age 7 and maximum age 18; uncertainty was evaluated by Monte Carlo resampling.'),
    timing_evidence = paste(
      'The assessment is seasonal, with four seasons and seasonal observations for some',
      'indices. It assigns birth dates to January, April, July, and October; exact fractional',
      'sampling times for every index were not recovered.'),
    output_evidence = paste(
      'The report provides aggregate SSB, exploitation, recruitment and stock-status',
      'trajectories. It does not provide a numeric annual N-at-age or F-at-age output matrix.'),
    detailed_source_url = paste(urls[1:2], collapse = '; '), review_date = '2026-10-30',
    decision_reason = paste(
      'The latest listed Atlantic-wide ICCAT assessment is the 2024 Stock Synthesis run',
      'using data through 2022. Its meeting report describes the results as preliminary',
      'pending SCRS/Commission adoption. Conditional age-at-length observations inform growth,',
      'but the reported population likelihood uses catch and length data with aggregate',
      'abundance indices. Eligibility remains unresolved because the public reports do not',
      'provide numeric age/length inputs needed to determine whether a defensible, limited',
      'catch-at-age reconstruction is possible.'),
    notes = paste(
      'NOAA Stock SMART row 10166 is crosswalked to the single Atlantic-wide ICCAT',
      'yellowfin stock, not treated as a separate U.S. assessment unit. The ICCAT assessment',
      'page lists 2024 as the latest assessment. Source files are cached under',
      'source_cache/noaa_iccat_tunas_2024_2025/; no canonical numerical data were added.')),
  list(candidate_unit_id = candidate_units[2], match_status = 'new',
    screening_status = 'screened', eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2025 Atlantic assessment uses nominal catches and fleet/year/season length',
      'compositions, not catch-at-age. The data-preparation report notes 352 otolith age',
      'readings from Côte d’Ivoire and Senegal for biological growth research; these are',
      'not population age compositions used as an abundance likelihood. Numeric assessment',
      'composition matrices were not found.'),
    survey_age_evidence = paste(
      'The Stock Synthesis model uses aggregate joint longline abundance indices and',
      'quarterly juvenile acoustic-buoy or purse-seine FAD indices in separate uncertainty',
      'runs. The indices are not age-stratified.'),
    weights_evidence = paste(
      'The production specification uses a fixed combined-sex Richards growth curve and',
      'W = 2.396e-5 * SFL^2.9774 (kg; SFL cm) to derive weight from length. The full',
      'seasonal weight-at-age surface was not recovered.'),
    maturity_evidence = paste(
      'Maturity is a logistic function of body size with 50% maturity assumed at 100-110 cm',
      'SFL; fecundity is related to female body weight. Numeric maturity-at-age values were',
      'not recovered.'),
    mortality_evidence = paste(
      'The assessment uses a Lorenzen age-specific M schedule, with adult average M over',
      'ages 4-10 varied across 0.26, 0.32, and 0.39 yr-1 scenarios and weights 0.37, 0.38,',
      'and 0.25 in the final uncertainty grid.'),
    timing_evidence = paste(
      'The Stock Synthesis model is quarterly and spans 1950-2023. Exact within-quarter',
      'timing for each index and fleet was not recovered from the reports.'),
    output_evidence = paste(
      'The report provides SSB and exploitation time series with uncertainty and a derived',
      'age-specific exploitation-rate figure for 2017-2023. These rates are calculated from',
      'predicted catch-at-age divided by estimated numbers-at-age; they are not age-specific',
      'observations or a full annual N/F-at-age output table.'),
    detailed_source_url = paste(urls[3:4], collapse = '; '), review_date = '2026-10-30',
    decision_reason = paste(
      'The latest listed Atlantic-wide ICCAT assessment is the 2025 Stock Synthesis run',
      'using data through 2023. Its meeting report describes the results as preliminary',
      'pending SCRS/Commission adoption. The reference model fits total catches, size compositions and',
      'aggregate abundance indices; age-specific exploitation is derived from fitted states',
      'and does not establish age-disaggregated observation inputs. Eligibility remains',
      'unresolved pending a source-supported age-data reconstruction and run-matched input',
      'arrays.'),
    notes = paste(
      'NOAA Stock SMART row 10169 points to the single Atlantic-wide ICCAT bigeye stock,',
      'not a separate NOAA assessment unit. The 2025 report identifies run 9 as the final',
      'Stock Synthesis reference case and confirms the report results remain preliminary',
      'until SCRS/Commission adoption. Source files are cached under',
      'source_cache/noaa_iccat_tunas_2024_2025/; no canonical numerical data were added.'))
)

replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row_index + 1L
  if (length(line_feeds) < physical_line) stop('CSV row index is out of range: ', path,
    call. = FALSE)
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

for (j in seq_along(indices)) {
  i <- indices[j]
  review <- reviews[[j]]
  if (!candidates$match_status[i] %in% c('unreviewed', 'new') ||
      !candidates$screening_status[i] %in% c('not_started', 'screened')) {
    stop('Tuna inventory row has a conflicting review: ', ids[j], call. = FALSE)
  }
  for (column in names(review)) candidates[[column]][i] <- review[[column]]
  replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])
}

source_review <- c(
  '# NOAA inventory rows for Atlantic yellowfin and bigeye tuna (ICCAT assessments)', '',
  'Reviewed 2026-10-30. NOAA Stock SMART rows 10166 (Atlantic yellowfin) and 10169 (Atlantic bigeye) are inventory records for single Atlantic-wide ICCAT stock units. They are not separate U.S. regional assessment units.', '',
  '## Atlantic yellowfin tuna', '',
  'ICCAT lists the 2024 Stock Synthesis assessment as the latest assessment, using data through 2022. The meeting report says results remain preliminary pending SCRS/Commission adoption. The model uses nominal catches, fleet/year/season length compositions, and three aggregate abundance indices: the Region 2 joint longline series (1979-2022), seasonal acoustic buoy index (2010-2022), and purse-seine free-school index (1993-2022). Conditional age-at-length observations from fleets 13 and 17 in 2007-2021 are included to estimate growth. The report does not describe these as catch-at-age or population age compositions. The assessment uses a length-weight relationship, maturity at length, and age-specific M assumptions. Reported outputs include SSB and aggregate exploitation/stock-status trajectories; numeric annual N-at-age and F-at-age surfaces were not located.', '',
  'Eligibility remains unresolved because the reports do not provide the numeric conditional age-at-length and fleet length-composition arrays needed to determine whether a defensible, limited catch-at-age reconstruction can be made. This uncertainty is separate from the clear fact that age-at-length informs growth rather than serving as an age-specific abundance index.', '',
  '## Atlantic bigeye tuna', '',
  'ICCAT lists the 2025 Stock Synthesis assessment as the latest assessment, using data through 2023. The meeting report says results remain preliminary pending SCRS/Commission adoption. The final reference case is run 9 in a seasonal, one-area, combined-sex model. It uses nominal catch, fleet/year/season length compositions, a Region 2 joint longline index, and a quarterly juvenile index (acoustic buoy or purse-seine FAD in separate uncertainty runs). The fitted observation data are not age-stratified. The data-preparation report specifies growth and weight-length assumptions, maturity at length, and a Lorenzen age-specific M schedule with uncertainty grid scenarios.', '',
  'The assessment report shows derived age-specific exploitation estimates for 2017-2023, calculated from predicted catch-at-age divided by estimated numbers-at-age. These are fitted outputs, not observations. A full annual N-at-age or F-at-age output table and the underlying numerical input matrices were not located. Eligibility remains unresolved pending evidence that the source data support an age-disaggregated input reconstruction.', '',
  '## Sources and local cache', '',
  '- [ICCAT stock assessments](https://www.iccat.int/en/assess.html), latest assessment/model listing for both species.',
  '- [2024 Atlantic yellowfin assessment report](https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_YFT_SA_ENG.pdf).',
  '- [2024 Atlantic yellowfin data-preparation report](https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_YFT_DP_ENG.pdf).',
  '- [2025 Atlantic bigeye assessment report](https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_BET_SA_ENG.pdf).',
  '- [2025 Atlantic bigeye data-preparation report](https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_BET_DP_ENG.pdf).', '',
  'All four PDFs are cached in `source_cache/noaa_iccat_tunas_2024_2025/`. The ignored local `manifest.csv` records each source URL, report revision, retrieval time, byte size, and SHA-256 checksum. No canonical stock, assessment, input, or output records were added.'
)
writeLines(source_review, review_path, useBytes = TRUE)
cat('Screened NOAA Stock SMART Atlantic yellowfin and bigeye inventory rows against the latest ICCAT reports.\n')

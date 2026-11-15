root <- "."
cache <- file.path(root, 'source_cache', 'noaa_yellowedge_sedar85_2023')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
manifest_path <- file.path(cache, 'manifest.csv')

files <- c(
  'sedar85_yellowedge_final_report.pdf',
  'sedar85_wp04_landings_compositions.pdf',
  'sedar85_wp07_commercial_landings.pdf',
  'sedar85_wp08_age_length_review.pdf',
  'sedar85_wp09_bottom_longline_indices.pdf',
  'sedar85_executive_summary.pdf',
  'sedar85_additional_projections.pdf'
)
urls <- c(
  'https://sedarweb.org/documents/sedar-85-gulf-of-mexico-yellowedge-grouper-final-stock-assessment-report/',
  'https://sedarweb.org/documents/sedar-85-wp-04-gulf-of-mexico-yellowedge-grouper-hyporthodus-flavolimbatus-landings-length-and-age-compositions/',
  'https://sedarweb.org/documents/sedar-85-wp-07-commercial-landings-of-gulf-of-mexico-yellowedge-grouper-hyporthodus-flavolimbatus/',
  'https://sedarweb.org/documents/sedar-85-wp-08-a-review-of-the-gulf-of-mexico-yellowedge-grouper-hyporthodus-flavolimbatus-age-length-data-1977-2021/',
  'https://sedarweb.org/documents/sedar-85-wp-09-yellowedge-grouper-abundance-indices-from-nmfs-bottom-longline-surveys-in-the-northern-gulf-of-mexico/',
  'https://sedarweb.org/documents/sedar-85-gulf-of-mexico-yellowedge-grouper-operational-assessment-executive-summary-report/',
  'https://sedarweb.org/documents/sedar-85-gulf-of-mexico-yellowedge-grouper-operational-assessment-additional-projections/'
)
revisions <- c(
  'SEDAR 85 Gulf of Mexico Yellowedge Grouper operational assessment report, November 2023',
  'SEDAR85-WP-04 landings length and age compositions, updated November 3, 2023',
  'SEDAR85-WP-07 commercial landings, July 2023',
  'SEDAR85-WP-08 age-length data review, July 2023',
  'SEDAR85-WP-09 NMFS bottom-longline abundance indices, August 2023',
  'SEDAR 85 executive summary following Gulf SSC review, 2024',
  'SEDAR 85 additional projections based on assessment through 2021, 2024'
)
paths <- file.path(cache, files)

if (!all(file.exists(paths)) || any(file.info(paths)$size <= 0)) {
  stop('Cache the cited SEDAR 85 and NOAA sources before screening.', call. = FALSE)
}
is_pdf <- vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(is_pdf)) stop('A cached Yellowedge source is not a PDF.', call. = FALSE)

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
    stop('Cached Yellowedge source manifest does not match the reviewed files.', call. = FALSE)
  }
} else {
  write.csv(manifest, manifest_path, row.names = FALSE)
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

id <- 'NOAA:10323'
i <- match(id, candidates$candidate_id)
unit_id <- 'noaa_yellowedge_gulf'
if (is.na(i) || sum(candidates$candidate_id == id) != 1L ||
    candidates$scientific_name[i] != 'Epinephelus flavolimbatus' ||
    candidates$assessment_area[i] != 'Gulf of Mexico' ||
    candidates$inventory_assessment_year[i] != 2024L) {
  stop('Expected the NOAA Stock SMART Yellowedge Grouper Gulf row.', call. = FALSE)
}
if (any(stocks$scientific_name %in% c('Epinephelus flavolimbatus',
    'Hyporthodus flavolimbatus')) ||
    any(candidates$candidate_unit_id[-i] == unit_id, na.rm = TRUE)) {
  stop('Yellowedge Grouper conflicts with an existing canonical or candidate unit.',
    call. = FALSE)
}
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE)) {
  stop('This inventory screen must not create canonical assessment data.', call. = FALSE)
}
if (!candidates$match_status[i] %in% c('unreviewed', 'new') ||
    !candidates$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Yellowedge Grouper already has a conflicting review.', call. = FALSE)
}

review <- data.frame(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The November 2023 operational assessment uses annual nominal age compositions',
    'for commercial vertical-line and longline fleets in eastern and western Gulf areas;',
    'sex samples were pooled because of data quality and sample-size limits. Age bins',
    'are 1-year bins with a 40+ group. WP-04 reports annual sample counts and plots age',
    'proportions, but the reviewed public documents do not provide the full numerical',
    'composition arrays or model input file.'),
  survey_age_evidence = paste(
    'The NMFS Bottom Longline Survey provides aggregate eastern and western Gulf abundance',
    'indices for 2000-2021 with CVs and confidence limits, plus survey age compositions',
    'over the same years. WP-09 tabulates the aggregate index values; the numerical age',
    'composition vectors were not recovered. The indices are not age-specific abundance',
    'series.'),
  weights_evidence = paste(
    'The report documents regional von Bertalanffy growth and a fixed gutted-weight to',
    'total-length relationship, so weight-at-age is derivable from the model biology.',
    'The exact run-matched biological parameter and surface files were not located.'),
  maturity_evidence = paste(
    'The assessment retains the SEDAR 22 logistic maturity and protogynous transition',
    'assumptions; all male or transitioning fish are treated as mature. The model input',
    'file needed to verify the exact run-specific maturity values was not located.'),
  mortality_evidence = paste(
    'Natural mortality follows a Lorenzen size-dependent schedule, with the SEDAR 22',
    'reference estimate M = 0.073 retained. Region-specific age schedules depend on',
    'growth; exact model input values were not recovered.'),
  timing_evidence = paste(
    'The assessment is annual and assumes fishing is continuous and homogeneous through',
    'the year. The bottom-longline survey is conducted in August in the eastern Gulf and',
    'September in the western Gulf, but exact within-year timing values from the fitted',
    'model input were not located.'),
  output_evidence = paste(
    'The final report and 2024 executive summary provide annual SSB, recruitment, and',
    'exploitation outputs, including uncertainty summaries. Full numeric annual N-at-age',
    'and F-at-age output arrays were not verified in the reviewed public files.'),
  detailed_source_url = paste(c(
    'https://sedarweb.org/assessments/sedar-85/', urls[1:7],
    'https://www.fisheries.noaa.gov/inport/item/67490/full-list'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The latest official fitted assessment located is SEDAR 85, completed in November',
    '2023 with data through 2021. The 2024 SSC executive summary and additional',
    'projections use that fitted assessment rather than a new population-model run.',
    'The report confirms age compositions, aggregate survey indices, age-based biology,',
    'and comparable population outputs. Eligibility remains unresolved because exact',
    'age-composition vectors, model timing, and run-matched input/output arrays were not',
    'available in the reviewed public sources.'),
  notes = paste(
    'NOAA Stock SMART row 10323 is the Gulf of Mexico management unit; SEDAR 85 treats',
    'the east and west Gulf subregions as model areas within one stock, not separate',
    'candidate stock units. The Stock SMART inventory year 2024 corresponds to the SSC',
    'review of the 2023 operational fit. Source PDFs are cached in the ignored',
    'source_cache/noaa_yellowedge_sedar85_2023/ directory with URL and checksum provenance.'),
  stringsAsFactors = FALSE
)

replace_csv_row <- function(path, row_index, data) {
  bytes <- readBin(path, 'raw', n = file.info(path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row_index + 1L
  if (length(line_feeds) < physical_line) stop('CSV row index is out of range: ', path,
    call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}

for (column in names(review)) candidates[[column]][i] <- review[[column]]
replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])
cat('Screened NOAA Stock SMART Yellowedge Grouper against SEDAR 85 sources.\n')

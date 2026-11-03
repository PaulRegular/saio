root <- "."
cache <- file.path(root, 'source_cache', 'noaa_gag_sedar72_2022')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
manifest_path <- file.path(cache, 'manifest.csv')

files <- c(
  'sedar72_srfs_amendment_2022.pdf',
  'sedar72_final_report_2021.pdf',
  'sedar72_wp17_compositions_2021.pdf',
  'sedar72_executive_summary_2022.pdf',
  'sedar72_ssc_review_2022.pdf'
)
urls <- c(
  'https://sedarweb.org/documents/sedar-72-gulf-of-mexico-gag-grouper-operational-assessment-report-amendment-state-reef-fish-survey-srfs-run/',
  'https://sedarweb.org/documents/sedar-72-gulf-of-mexico-gag-grouper-final-stock-assessment-report_october2021/',
  'https://sedarweb.org/documents/sedar-72-wp-17-gulf-of-mexico-gag-grouper-mycteroperca-microlepis-commercial-and-recreational-length-and-age-compositions/',
  'https://sedarweb.org/documents/sedar-72-gulf-of-mexico-gag-grouper-operational-assessment-executive-summary-report/',
  'https://sedarweb.org/documents/gulf-ssc-review-of-sedar-72-gulf-gag-grouper/'
)
revisions <- c(
  'SEDAR 72 operational assessment report amendment, SRFS run, September 2022',
  'SEDAR 72 final stock assessment report, revised October 2021; data through 2019',
  'SEDAR72-WP-17 commercial and recreational length and age compositions, May 2021',
  'SEDAR 72 operational assessment executive summary following 2022 Gulf SSC review',
  'Gulf SSC review of the SEDAR 72 SRFS run, 2022'
)
paths <- file.path(cache, files)

if (!all(file.exists(paths)) || any(file.info(paths)$size <= 0)) {
  stop('Cache the cited SEDAR 72 sources before screening.', call. = FALSE)
}
is_pdf <- vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(is_pdf)) stop('A cached SEDAR 72 source is not a PDF.', call. = FALSE)

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
    stop('Cached SEDAR 72 source manifest does not match the reviewed files.', call. = FALSE)
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

id <- 'NOAA:10348'
i <- match(id, candidates$candidate_id)
unit_id <- 'noaa_gag_gulf'
if (is.na(i) || sum(candidates$candidate_id == id) != 1L ||
    candidates$scientific_name[i] != 'Mycteroperca microlepis' ||
    candidates$assessment_area[i] != 'Gulf of Mexico' ||
    candidates$inventory_assessment_year[i] != 2026L) {
  stop('Expected the NOAA Stock SMART Gulf Gag Grouper row.', call. = FALSE)
}
if (any(stocks$scientific_name == 'Mycteroperca microlepis', na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-i] == unit_id, na.rm = TRUE)) {
  stop('Gulf Gag Grouper conflicts with an existing canonical or candidate unit.',
    call. = FALSE)
}
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE)) {
  stop('This inventory screen must not create canonical assessment data.', call. = FALSE)
}
if (!candidates$match_status[i] %in% c('unreviewed', 'new') ||
    !candidates$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Gulf Gag Grouper already has a conflicting review.', call. = FALSE)
}

review <- data.frame(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The September 2022 SRFS run provides annual catch and discard totals by fleet,',
    'with inputs in numbers and biomass, and uses commercial and recreational age',
    'composition data through 2019. The SEDAR72-WP-17 report gives annual age-sample',
    'counts and composition figures; digitizing those figures is a documented',
    'source-based reconstruction, not an exact machine-readable input recovery.'),
  survey_age_evidence = paste(
    'The assessment includes standardized fishery CPUE indices and age-0 and video',
    'survey abundance indices with annual uncertainty. The accepted run is an',
    'age-structured Stock Synthesis model with data bins age 0 through 20+; no full',
    'age-specific survey-index matrix was recovered.'),
  weights_evidence = paste(
    'The October 2021 report provides the fixed sex-combined length-weight relationship',
    'and fitted growth curve; age-specific weights can be derived from those documented',
    'inputs. The 2022 SRFS run retains the assessment structure.'),
  maturity_evidence = paste(
    'The October 2021 report documents fixed logistic female maturity (age at 50%',
    'maturity about 3.9 years; slope 2.513) and treats males and transitioning fish as',
    'mature. These assumptions are retained for the 2022 SRFS run.'),
  mortality_evidence = paste(
    'The report supplies a fixed age-specific Lorenzen natural-mortality vector scaled',
    'to the Then et al. (2015) estimate M = 0.159 per year.'),
  timing_evidence = paste(
    'The assessment is annual and assumes fishing and data collection are continuous',
    'and homogeneous through the year, so it does not model seasonal removals. A single',
    'within-year survey fraction is not reported and would be an explicit translation',
    'approximation if needed.'),
  output_evidence = paste(
    'The September 2022 report gives annual SSB, total and exploitable biomass,',
    'exploitable abundance, recruitment, fleet exploitation, parameters, and model fits',
    'for 1963-2019. The report does not provide complete annual N-at-age or F-at-age',
    'arrays in the recovered tables.'),
  detailed_source_url = paste(c(
    'https://sedarweb.org/assessments/sedar-72/',
    'https://sedarweb.org/assessments/sedar-105-gulf-gag-grouper/',
    urls,
    'https://www.fisheries.noaa.gov/bulletin/changes-catch-levels-sector-allocations-recreational-accountability-measures',
    'https://www.fisheries.noaa.gov/bulletin/noaa-fisheries-announces-2026-gag-recreational-season-federal-waters-gulf'),
    collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Eligible for source curation. The latest accepted production run located is the',
    'SEDAR 72 amendment using Florida SRFS private-mode landings, completed in',
    'September 2022 with assessment data through 2019 and reviewed by the Gulf SSC.',
    'SEDAR 105 is underway in 2026, while NOAA continues to identify SEDAR 72 as the',
    'most recent population assessment. Catch totals, age-composition figures and',
    'sample counts, index series, fixed mortality and maturity assumptions, growth and',
    'weight information, and comparable annual outputs are available. Exact numeric',
    'age-composition arrays and run-matched native files were not recovered; the',
    'composition figures can support an explicitly documented digitization.'),
  notes = paste(
    'NOAA Stock SMART row 10348 is Gulf Gag Grouper (Mycteroperca microlepis). Do not',
    'merge it with the distinct South Atlantic Gag unit (row 10349). The October 2021',
    'base report was superseded for management use by the September 2022 SRFS run,',
    'which replaced Florida private-mode MRIP-FES catch inputs with calibrated SRFS',
    'estimates and corrected headboat data. Cache files are kept in the ignored',
    'source_cache/noaa_gag_sedar72_2022/ directory with URL and checksum provenance.'),
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
cat('Screened NOAA Stock SMART Gulf Gag Grouper against SEDAR 72 sources.\n')

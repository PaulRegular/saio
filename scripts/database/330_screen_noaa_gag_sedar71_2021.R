root <- "."
cache <- file.path(root, 'source_cache', 'noaa_gag_sedar71_2021')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
manifest_path <- file.path(cache, 'manifest.csv')

files <- c(
  'sedar71_final_report_2021.pdf',
  'sedar71_wp04_chevron_age_2019.pdf',
  'sedar71_wp03_reproductive_parameters.pdf',
  'sedar71_wp05_recreational_survey.pdf',
  'sedar71_wp02_video_index.pdf'
)
urls <- c(
  'https://sedarweb.org/documents/sedar-71-stock-assessment-report-south-atlantic-gag/',
  'https://sedarweb.org/documents/sedar-71-wp04-gag-fishery-independent-index-of-abundance-and-age-length-compositions-in-us-south-atlantic-waters-based-on-a-chevron-trap-survey-1990-2019/',
  'https://sedarweb.org/documents/sedar-71-wp03-gag-grouper-mycteroperca-microlepis-reproductive-parameters-in-support-of-the-sedar-71-assessment/',
  'https://sedarweb.org/documents/sedar-71-wp05-general-recreational-survey-data-for-gag-in-the-south-atlantic/',
  'https://sedarweb.org/documents/sedar71-wp02-standardized-video-counts-of-southeast-u-s-atlantic-gag-mycteroperca-microlepis-from-the-southeast-reef-fish-survey/'
)
revisions <- c(
  'SEDAR 71 operational assessment report, April 2021; data through 2019',
  'SEDAR 71 WP04, chevron-trap abundance and age/length compositions, 1990-2019',
  'SEDAR 71 WP03, reproductive parameters, 2020',
  'SEDAR 71 WP05, general recreational survey data, 2020',
  'SEDAR 71 WP02, SERFS video index standardization, 2020'
)
paths <- file.path(cache, files)

if (!all(file.exists(paths)) || any(file.info(paths)$size <= 0)) {
  stop('Cache the cited SEDAR 71 sources before screening.', call. = FALSE)
}
is_pdf <- vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(is_pdf)) stop('A cached SEDAR 71 source is not a PDF.', call. = FALSE)

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
    stop('Cached SEDAR 71 source manifest does not match the reviewed files.', call. = FALSE)
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

id <- 'NOAA:10349'
i <- match(id, candidates$candidate_id)
unit_id <- 'noaa_gag_south_atlantic'
if (is.na(i) || sum(candidates$candidate_id == id) != 1L ||
    candidates$scientific_name[i] != 'Mycteroperca microlepis' ||
    candidates$assessment_area[i] != 'Southern Atlantic Coast' ||
    candidates$inventory_assessment_year[i] != 2021L) {
  stop('Expected the NOAA Stock SMART South Atlantic Gag Grouper row.', call. = FALSE)
}
if (any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(stocks$authority == 'NOAA Fisheries' & stocks$authority_stock_id == '10349',
      na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-i] == unit_id, na.rm = TRUE)) {
  stop('South Atlantic Gag Grouper conflicts with an existing canonical or candidate unit.',
    call. = FALSE)
}
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE)) {
  stop('This inventory screen must not create canonical assessment data.', call. = FALSE)
}
if (!candidates$match_status[i] %in% c('unreviewed', 'new') ||
    !candidates$screening_status[i] %in% c('not_started', 'screened')) {
  stop('South Atlantic Gag Grouper already has a conflicting review.', call. = FALSE)
}

review <- data.frame(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'SEDAR 71 reports annual removals by fleet for 1962-2019 and fleet age',
    'compositions through 2019, with observed and fitted age proportions shown',
    'in assessment figures and Tables 4-5 giving fish and trip sample sizes.',
    'Catch-at-age can be reconstructed from source totals and digitized observed',
    'compositions, but exact fishery composition arrays or run-matched native',
    'input files were not recovered.'),
  survey_age_evidence = paste(
    'The fit uses aggregate headboat and SERFS video indices with annual CVs;',
    'the report tabulates them through 2019. SEDAR71-WP04 provides numeric',
    'chevron-trap age counts and proportions for 1990-2019. These age data inform',
    'the fitted selectivity of the video index; the report does not fit a direct',
    'age-specific survey index. Any age-index reconstruction is approximate.'),
  weights_evidence = paste(
    'The assessment report provides age-specific whole weights and separate',
    'population and fishery growth curves; fleet catch-age numbers require the',
    'documented conversion from reported landings and age compositions.'),
  maturity_evidence = paste(
    'The report provides female maturity-at-age and age-specific sex ratio; all',
    'males were treated as mature. Female age at 50% maturity was estimated at',
    'about 4.6 years.'),
  mortality_evidence = paste(
    'Natural mortality is fixed over time and declines with age using the',
    'Lorenzen relationship. The age curve is scaled over fully selected ages 5+',
    'to match survival to age 30 under constant M = 0.15; an age-specific vector',
    'is reported.'),
  timing_evidence = paste(
    'The population model uses annual time steps, with spawning biomass measured',
    'at peak spawning in mid-April. Chevron-trap sampling occurred May-September;',
    'a single within-year survey fraction is not specified in the assessment.'),
  output_evidence = paste(
    'The report gives numeric annual total abundance-at-age and biomass-at-age,',
    'total biomass and SSB, and age-1 recruitment through 2019. Fleet F is shown',
    'by annual figures; full annual F-at-age arrays and associated uncertainty',
    'were not recovered.'),
  detailed_source_url = paste(c(
    'https://sedarweb.org/assessments/sedar-71/',
    'https://sedarweb.org/assessments/sedar-106-south-atlantic-gag-grouper/',
    urls,
    'https://www.fisheries.noaa.gov/inport/item/65068'),
    collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'Eligible for source curation. SEDAR 71 is the latest completed operational',
    'assessment located for this distinct South Atlantic unit, with terminal year',
    '2019. Its report supplies the core annual catch and aggregate index series,',
    'fleet age-composition figures, numeric age-specific outputs, and biological',
    'inputs. Catch-at-age requires a documented reconstruction from totals and',
    'figure-digitized compositions. The planned SEDAR 106 assessment (terminal',
    'year 2024) was delayed and has no replacement schedule posted as of the review',
    'date, so it is not a completed run to substitute.'),
  notes = paste(
    'NOAA Stock SMART row 10349 is the South Atlantic Gag Grouper unit and is',
    'distinct from Gulf Gag Grouper (Stock SMART row 10348; candidate unit',
    'noaa_gag_gulf). The 2021 SEDAR report is a production operational assessment;',
    'SEDAR 106 is a delayed, in-progress successor. Sources are cached under the',
    'ignored source_cache/noaa_gag_sedar71_2021/ directory with URL and checksum',
    'provenance.'),
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
cat('Screened NOAA Stock SMART South Atlantic Gag Grouper against SEDAR 71 sources.\n')

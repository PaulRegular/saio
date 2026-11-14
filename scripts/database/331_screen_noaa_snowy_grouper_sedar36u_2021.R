root <- "."
cache <- file.path(root, 'source_cache', 'noaa_snowy_grouper_sedar36u_2021')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
manifest_path <- file.path(root, 'provenance', 'noaa_snowy_grouper_sedar36u_2021', 'manifest.csv')

files <- c(
  'sedar36u_report_revised_2021.pdf',
  'sedar36u_wp01_recreational_data_2020.pdf',
  'sedar36u_wp02_management_history_2020.pdf'
)
urls <- c(
  'https://sedarweb.org/documents/2020-update-sedar-36-update-assessment-report-south-atlantic-snowy-grouper-revised-january-2021-2/',
  'https://sedarweb.org/documents/2020-sedar36u-wp01-general-recreational-data_satl_snowy_grouper_22apr20/',
  'https://sedarweb.org/documents/2020-sedar-36u-wp02-snowy-grouper-management-history-2-18-2020/'
)
revisions <- c(
  'SEDAR 36 Update assessment report, revised January 2021; data through 2018',
  'SEDAR 36 Update WP01, recreational survey data, submitted April 24, 2020',
  'SEDAR 36 Update WP02, management history, submitted February 18, 2020'
)
paths <- file.path(cache, files)
if (!all(file.exists(paths)) || any(file.info(paths)$size <= 0)) {
  stop('Cache the cited SEDAR 36 Update sources before screening.', call. = FALSE)
}
is_pdf <- vapply(paths, function(path) {
  identical(readBin(path, 'raw', n = 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(is_pdf)) stop('A cached SEDAR 36 Update source is not a PDF.', call. = FALSE)

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
manifest <- data.frame(
  file = paths, url = urls, revision = revisions,
  retrieved_utc = rep(format(Sys.time(), tz = 'UTC', format = '%Y-%m-%dT%H:%M:%SZ'),
    length(paths)),
  bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha256_file, character(1L)),
  stringsAsFactors = FALSE
)
if (file.exists(manifest_path)) {
  previous <- read.csv(manifest_path, stringsAsFactors = FALSE)
  if (!identical(previous$file, manifest$file) ||
      !identical(previous$url, manifest$url) ||
      !identical(previous$revision, manifest$revision) ||
      !identical(previous$sha256, manifest$sha256)) {
    stop('Cached SEDAR 36 Update manifest does not match the reviewed files.',
      call. = FALSE)
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

id <- 'NOAA:10339'
i <- match(id, candidates$candidate_id)
unit_id <- 'noaa_snowy_grouper_south_atlantic'
if (is.na(i) || sum(candidates$candidate_id == id) != 1L ||
    candidates$scientific_name[i] != 'Epinephelus niveatus' ||
    candidates$assessment_area[i] != 'Southern Atlantic Coast' ||
    candidates$inventory_assessment_year[i] != 2021L) {
  stop('Expected the NOAA Stock SMART South Atlantic Snowy Grouper row.',
    call. = FALSE)
}
if (any(stocks$scientific_name %in% c('Epinephelus niveatus', 'Hyporthodus niveatus'),
    na.rm = TRUE) ||
    any(candidates$candidate_unit_id[-i] == unit_id, na.rm = TRUE)) {
  stop('South Atlantic Snowy Grouper conflicts with an existing or candidate unit.',
    call. = FALSE)
}
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE)) {
  stop('This inventory screen must not create canonical assessment data.',
    call. = FALSE)
}
if (!candidates$match_status[i] %in% c('unreviewed', 'new') ||
    !candidates$screening_status[i] %in% c('not_started', 'screened')) {
  stop('South Atlantic Snowy Grouper already has a conflicting review.',
    call. = FALSE)
}

review <- data.frame(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'SEDAR 36 Update fits annual removals through 2018 for commercial handline,',
    'commercial longline, and a combined recreational fleet. Commercial input',
    'removals are in whole weight and recreational removals in numbers; landings',
    'and dead discards are combined. Annual fleet age-composition figures and',
    'sample sizes are reported; age 14 is the composition plus group. Exact',
    'fishery composition arrays were not recovered; catch-at-age requires',
    'documented digitization and reconstruction from removals and compositions.'),
  survey_age_evidence = paste(
    'The assessment fits aggregate headboat, MARMAP chevron-trap, and vertical',
    'longline indices with annual CVs; the two fishery-independent indices cover',
    '1996-2018. Age compositions for chevron trap and vertical longline are also',
    'used, with annual sample sizes. The report shows observed compositions in',
    'figures but does not provide numeric input matrices; an age-specific index',
    'would be a documented reconstruction, not a directly fitted index.'),
  weights_evidence = paste(
    'Table 1 gives age-specific whole weight for model ages 1-25+, with age 25+',
    'as the plus group. External growth and length-weight parameters were treated',
    'as inputs. The report distinguishes population weights from fishery',
    'quantities and documents the discard conversion.'),
  maturity_evidence = paste(
    'Table 1 gives female maturity-at-age and proportion female for ages 1-25.',
    'Female maturity is zero at ages 1-2 and logistic from age 3+, with 50%',
    'maturity at 5.6 years; all males are treated as mature. Spawning biomass is',
    'total mature biomass, evaluated at mid-year peak spawning.'),
  mortality_evidence = paste(
    'Natural mortality is fixed in the base run and age-dependent under the',
    'Charnov relationship, scaled to M = 0.08 at maximum age 56. The MCB',
    'uncertainty analysis draws a scalar M from 0.05-0.12 and rescales the curve.'),
  timing_evidence = paste(
    'The assessment uses annual time steps and assumes peak spawning at mid-year.',
    'Survey series are annual; a more precise within-year survey fraction is not',
    'reported in the assessment sources reviewed.'),
  output_evidence = paste(
    'The revised report includes numeric annual abundance-at-age (Table 6),',
    'biomass-at-age (Table 7), status and SSB (Table 8), total F-at-age (Table',
    '11), and estimated removals-at-age (Tables 12-15) through 2018. Outputs are',
    'base-run point estimates; annual age-specific uncertainty was not located.'),
  detailed_source_url = paste(c(
    'https://sedarweb.org/assessments/sedar-36-update-south-atlantic-snowy-grouper/',
    urls,
    'https://sedarweb.org/assessments/sedar-36/',
    'https://safmc.net/documents/sedar_a2_draft_sow-for-2027-pdf/'),
    collapse = '; '),
  review_date = as.character(Sys.Date()),
  decision_reason = paste(
    'Eligible for source curation. SEDAR 36 Update is the latest completed',
    'assessment located for the current South Atlantic unit, published in 2021',
    'with terminal year 2018; the draft 2027 statement of work still identifies',
    'it as the prior assessment. The report supplies annual removals, aggregate',
    'indices, age compositions, age-specific biology, and numeric abundance,',
    'biomass, recruitment, and fishing-mortality outputs. Fishery age-composition',
    'inputs require figure digitization, so reconstructed catch-at-age must be',
    'identified as approximate.'),
  notes = paste(
    'NOAA Stock SMART row 10339 identifies the South Atlantic unit. The report',
    'uses both the current name Epinephelus niveatus and synonym Hyporthodus',
    'niveatus; neither is present as a canonical stock. Do not conflate with',
    'North Atlantic or Gulf units. SEDAR 36 WP15 contains code/data for the',
    'superseded 2013 assessment only and was not used as a substitute for update',
    'inputs. Update report and two 2020 update working papers are cached locally',
    'with URL, revision, retrieval time, byte-size, and SHA-256 provenance.'),
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
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L)) {
    as.raw(c(13L, 10L))
  } else {
    as.raw(10L)
  }
  tmp <- tempfile(fileext = '.csv')
  write.table(data, tmp, sep = ',', row.names = FALSE, col.names = FALSE,
    quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), path)
}
for (column in names(review)) candidates[[column]][i] <- review[[column]]
replace_csv_row(candidate_path, i, candidates[i, , drop = FALSE])
cat('Screened NOAA South Atlantic Snowy Grouper against SEDAR 36 Update sources.\n')

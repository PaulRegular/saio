root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_pacific_coast_pop_2017')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10545'
unit_id <- 'noaa_pacific_coast_pop_uswc'

files <- c('NOAA_Pacific_Coast_POP_2017_assessment.pdf',
  'NOAA_Pacific_ocean_perch_current_status.html',
  'Pacific_ocean_perch_STAR_panel_2017.pdf')
urls <- c(
  'https://www.pcouncil.org/documents/2017/09/e8_att3_pop_fulldoc_e-only_sept2017bb.pdf',
  'https://www.fisheries.noaa.gov/species/pacific-ocean-perch',
  'https://www.pcouncil.org/documents/2017/06/pacific-ocean-perch-star-panel-report-26-30-june-2017.pdf')
revisions <- c('PFMC 2017 Pacific ocean perch assessment, E.8 Attachment 3',
  'NOAA Fisheries current species page', 'PFMC 2017 Pacific ocean perch STAR panel report')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed NOAA Pacific ocean perch sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), fileEncoding = 'UTF-8-BOM')
source_rows <- match(files, basename(sources$file))
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), urls),
  revisions = identical(as.character(sources$revision[source_rows]), revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
if (anyNA(source_rows) || !all(source_valid))
  stop('Cached NOAA Pacific ocean perch sources differ from the reviewed manifest: ',
    paste(names(source_valid)[!source_valid], collapse = ', '), call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id) != 1L ||
    register$official_stock_id[row] != '10545' ||
    register$scientific_name[row] != 'Sebastes alutus' ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('NOAA Pacific ocean perch inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == '10545', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not duplicate or create canonical Pacific ocean perch records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The latest official assessment located is the 2017 two-sex SS3 model. It fits',
    'annual catch totals and sex-specific age compositions, including commercial fishery samples from',
    '1981-2016. The report provides composition figures and sample summaries, but not a complete numeric',
    'catch-at-age matrix. Appendix D lists the model data file 2017pop.dat; that auxiliary file was not located.'),
  survey_age_evidence = paste('The base model uses aggregate abundance indices from multiple surveys and fits',
    'survey age compositions, including conditional age-at-length data for the NWFSC shelf-slope survey',
    '(2003-2016). Exact numeric composition and survey input files were not recovered.'),
  weights_evidence = paste('The report gives sex-specific weight-at-length relationships and estimated',
    'length-at-age. A weight-at-age surface can be derived, but the numeric auxiliary input file was not located.'),
  maturity_evidence = paste('Maturity is a length-based relationship estimated from 537 samples. A maturity-at-age',
    'surface would require combining this relationship with the assessment growth estimates.'),
  mortality_evidence = 'Natural mortality is fixed at 0.054 per year in the final 2017 base model.',
  timing_evidence = paste('Timing varies across surveys. The report describes the AFSC slope survey in',
    'October-November and the NWFSC slope survey in summer; a single timing value is not supported.'),
  output_evidence = paste('The report provides annual spawning output in millions of eggs, depletion, recruitment,',
    'and uncertainty summaries. Appendix D lists female and male numbers-at-age CSV files, but these outputs',
    'were not located. Spawning output is not SSB in tonnes.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('NOAA Fisheries still identifies the 2017 report as the latest assessment for this',
    'U.S. West Coast unit. The assessment fits age compositions with annual catches, survey indices, and',
    'biological relationships. The numeric native model data and auxiliary N-at-age files were not recovered,',
    'so complete input and output coverage remains unresolved pending further source recovery.'),
  notes = paste('This is a single U.S. West Coast stock unit, separate from British Columbia and Alaska',
    'Pacific ocean perch. Do not treat projections reported for years after 2017 as later assessments.',
    'The base model fixed steepness at 0.72; the report discusses large sensitivity to this assumption.',
    'No canonical records or tinyAM translation were added. Cached source files and checksums are listed in',
    'source_cache/discovery_noaa_pacific_coast_pop_2017/sources.csv.'))

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (!initial && !reviewed)
  stop('NOAA Pacific ocean perch candidate row already has a conflicting review state.', call. = FALSE)

review_matches <- all(vapply(names(review), function(name)
  identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (initial || !review_matches)) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  bytes <- readBin(register_path, 'raw', n = file.info(register_path)$size)
  line_feeds <- which(bytes == as.raw(10L))
  physical_line <- row + 1L
  if (length(line_feeds) < physical_line)
    stop('Candidate CSV row is out of range for ', candidate_id, '.', call. = FALSE)
  first <- line_feeds[physical_line - 1L] + 1L
  last <- line_feeds[physical_line]
  ending <- if (last > first && bytes[last - 1L] == as.raw(13L))
    as.raw(c(13L, 10L)) else as.raw(10L)
  tmp <- tempfile(fileext = '.csv')
  write.table(register[row, , drop = FALSE], tmp, sep = ',', row.names = FALSE,
    col.names = FALSE, quote = TRUE, na = '', qmethod = 'double')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), register_path)
}

cat('Screened NOAA Pacific Coast Pacific ocean perch (2017) as one distinct, eligibility-unresolved candidate.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'discovery_swordfish_north_atlantic_2022')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_ids <- c('NOAA:10953', 'DFO:Maritimes:Swordfish - North Atlantic')
unit_id <- 'iccat_north_atlantic_swordfish'

files <- c('iccat_assessment_catalogue_2026.html',
  'swordfish_2026_meeting_report.pdf', 'swordfish_2022_assessment_report.pdf',
  'swordfish_2022_postdecisional_model.pdf', 'swordfish_2025_scrs_report.pdf')
urls <- c(
  'https://www.iccat.int/en/assess.html',
  'https://www.iccat.int/Documents/CVSP/CV083_2026/n_2/CV08302012.pdf',
  'https://www.iccat.int/Documents/Meetings/Docs/2022/REPORTS/2022_SWO_SA_ENG.pdf',
  'https://www.iccat.int/Documents/CVSP/CV079_2022/n_2/CV079020715.pdf',
  'https://www.iccat.int/Documents/Meetings/Docs/2025/Reports/2025_SCRS_ENG.pdf')
revisions <- c(
  'ICCAT assessment catalogue retrieved 2026-10-30; North Atlantic swordfish last/next assessment listing',
  'SCRS/2026/012, Report of the 2026 ICCAT swordfish stock assessment meeting, 13-17 July 2026',
  'Report of the 2022 ICCAT Atlantic Swordfish Stock Assessment Meeting; data through 2020',
  'SCRS/2022/124, post-decisional North Atlantic swordfish Stock Synthesis assessment',
  'ICCAT 2025 SCRS report; North Atlantic swordfish status assessment identified as 2022')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed ICCAT sources before screening the North Atlantic swordfish unit.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
if (anyNA(source_rows) || !identical(as.character(sources$url[source_rows]), urls) ||
    !identical(as.character(sources$revision[source_rows]), revisions) ||
    !identical(toupper(as.character(sources$sha256[source_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached swordfish sources differ from the reviewed source manifest.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
rows <- match(candidate_ids, register$candidate_id)
if (anyNA(rows) || anyDuplicated(register$candidate_id[rows]) ||
    register$official_stock_id[rows[1L]] != '10953' ||
    register$scientific_name[rows[1L]] != 'Xiphias gladius' ||
    register$stock_name[rows[2L]] != 'Swordfish - North Atlantic' ||
    any(register$candidate_unit_id[-rows] == unit_id, na.rm = TRUE))
  stop('Swordfish inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == '10953', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Xiphias gladius' &
      grepl('North Atlantic', stocks$area, ignore.case = TRUE), na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not duplicate or create canonical swordfish records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2022 Stock Synthesis model fits landings, discards, and fleet',
    'length compositions; observed fishery catch-at-age was not reported.'),
  survey_age_evidence = paste('Five age-specific EU-Spain longline CPUE indices are derived using',
    'ages estimated from length data. These are fishery-dependent indices, not survey abundance-at-age.'),
  weights_evidence = paste('Mean weight observations were used for U.S. and Canadian fleets; an',
    'age-specific weight-at-age series was not located in the reviewed assessment sources.'),
  maturity_evidence = paste('Female maturity is fixed at 50% at age 5 and 100% at older ages;',
    'fecundity is related to body weight.'),
  mortality_evidence = 'Natural mortality is fixed at 0.2 for both sexes across ages in the 2022 Stock Synthesis model.',
  timing_evidence = paste('The model is annual. The age-specific Spanish indices are fishery-dependent',
    'CPUE series, so a separate fractional-year survey timing is not applicable.'),
  output_evidence = paste('The 2022 assessment reports aggregate spawning-biomass and fishing-mortality',
    'status outputs. Annual numeric N-, F-, or M-at-age output arrays were not located.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest detailed North Atlantic assessment located is the 2022 ICCAT',
    'assessment using data through 2020. Although Stock Synthesis is internally age-structured and',
    'uses age-specific fishery CPUE indices, observed catch-at-age is not part of its documented',
    'input set; therefore this stock is ineligible for the age-disaggregated assessment set.'),
  notes = paste('NOAA Stock SMART 10953 and DFO Maritimes Swordfish - North Atlantic are crosswalked',
    'to the same ICCAT North Atlantic stock; the DFO row is not a separate assessment. The 2026 ICCAT',
    'meeting assessed Mediterranean and South Atlantic swordfish and addressed North Atlantic MSE, not',
    'a new North Atlantic stock-status run. Cached URLs, revisions, retrieval date, file sizes, and',
    'SHA-256 checksums are recorded under source_cache/discovery_swordfish_north_atlantic_2022/.',
    'No canonical numerical records or tinyAM translation were added.')
)

initial <- vapply(rows, function(i) register$match_status[i] == 'unreviewed' &&
  register$screening_status[i] == 'not_started' && register$eligibility[i] == 'unresolved' &&
  (is.na(register$candidate_unit_id[i]) || !nzchar(register$candidate_unit_id[i])), logical(1L))
reviewed <- vapply(rows, function(i) register$match_status[i] == 'new' &&
  register$candidate_unit_id[i] == unit_id && register$screening_status[i] == 'screened' &&
  register$eligibility[i] == 'ineligible', logical(1L))
if (!all(initial | reviewed))
  stop('Swordfish candidate rows already have conflicting review states.', call. = FALSE)

review_matches <- vapply(rows, function(i) all(vapply(names(review), function(name)
  identical(as.character(register[[name]][i]), as.character(review[[name]])), logical(1L))),
  logical(1L))
write_rows <- rows[initial | !review_matches]
if (is.na(register$scientific_name[rows[2L]]) ||
    register$scientific_name[rows[2L]] != 'Xiphias gladius')
  write_rows <- unique(c(write_rows, rows[2L]))
needs_update <- length(write_rows) > 0L
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && needs_update) {
  for (name in names(review)) register[[name]][write_rows] <- review[[name]]
  register$scientific_name[rows[2L]] <- 'Xiphias gladius'
  bytes <- readBin(register_path, 'raw', n = file.info(register_path)$size)
  for (row in sort(write_rows, decreasing = TRUE)) {
    line_feeds <- which(bytes == as.raw(10L))
    physical_line <- row + 1L
    if (length(line_feeds) < physical_line)
      stop('Candidate CSV row is out of range for ', register$candidate_id[row], '.', call. = FALSE)
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
    bytes <- c(before, charToRaw(replacement), ending, after)
  }
  writeBin(bytes, register_path)
}

cat('Crosswalked NOAA 10953 and the DFO Maritimes swordfish entry to one ICCAT unit; screened ineligible for observed catch-at-age.\n')

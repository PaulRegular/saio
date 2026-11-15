root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_greenland_halibut_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:ghl.27.561214'
unit_id <- 'ices_greenland_halibut_561214'

files <- c('MFRI_GHL_2026_technical_report.html', 'MFRI_GHL_2026_advice.html',
  'ICES_GHL_2026_standard_graphs.html', 'ICES_GHL_2026_source_data.html',
  'ICES_GHL_2026_advice.html')
urls <- c(
  'https://www.hafogvatn.is/static/extras/images/22_ghl_2026_1_techreport_en.html',
  'https://www.hafogvatn.is/static/extras/images/22_ghl_2026_1_advice_en.html',
  'https://sg.ices.dk/ViewCharts.aspx?key=22559',
  'https://sg.ices.dk/ViewSourceData.aspx?key=22559',
  'https://asd.ices.dk/viewAdvice/7216')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

paths <- file.path(cache, files)
if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed MFRI and ICES sources before screening ', candidate_id, '.',
    call. = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_rows <- match(files, basename(manifest$file))
if (anyNA(manifest_rows) || !identical(as.character(manifest$url[manifest_rows]), urls) ||
    !identical(tolower(as.character(manifest$sha256[manifest_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached MFRI and ICES sources differ from their recorded manifest.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    register$official_stock_id[row] != 'ghl.27.561214' ||
    register$scientific_name[row] != 'Reinhardtius hippoglossoides' ||
    register$inventory_assessment_year[row] != 2026L ||
    any(stocks$authority_stock_id == 'ghl.27.561214', na.rm = TRUE) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Greenland halibut identity conflicts with the inventory or canonical database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2026 GADGET model uses international commercial catches and',
    'length compositions by gear. No commercial catch-at-age likelihood is documented.',
    'The recent Icelandic survey ages do not establish fishery age compositions.'),
  survey_age_evidence = paste('The assessment uses one combined biomass index from the Greenland',
    'deepwater survey (1998-2016 and 2022 onward) and Icelandic autumn bottom-trawl survey',
    '(since 1996). Sex-specific age distributions are available from the Icelandic survey',
    'from 2015 onward; older age readings are considered biased and not representative.'),
  weights_evidence = paste('GADGET derives weight-at-age from a weight-length relationship and',
    'growth; the report does not document supplied weights-at-age for the fitted model.'),
  maturity_evidence = paste('Maturity is based on sparse Icelandic autumn survey observations',
    'at length, and the report considers the maturity scale imprecise. A run-matched',
    'maturity-at-age series is not documented.'),
  mortality_evidence = 'Natural mortality is fixed at M = 0.15.',
  timing_evidence = paste('GADGET uses two equal within-year time steps. A single fractional-year',
    ''),
  output_evidence = paste('ICES 2026 source data report age-5 recruitment and F for ages 9-14,',
    'plus annual total biomass, SSB, catches, and uncertainty bounds. Annual N-at-age and',
    'F-at-age surfaces were not located.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The current GADGET assessment is age-length structured and includes',
    'recent Icelandic survey age distributions, so age structure alone is not treated as',
    'evidence of age-specific observations. The reviewed sources do not establish commercial',
    'catch-at-age or a supported reconstruction across the assessment period, nor a',
    'run-matched age-specific biology series and annual age-specific population outputs.',
    'Keep eligibility unresolved pending review of the native 2026 observation arrays.'),
  notes = paste('ICES ghl.27.561214 is a distinct stock unit covering Iceland and Faroese',
    'grounds, West of Scotland, North of Azores, and East Greenland. It is not a match to',
    'the separate DFO Greenland halibut units; ICES notes unquantified connectivity with',
    'adjacent Northeast Arctic and NAFO stocks. Current MFRI and ICES sources, retrieval',
    'date, revisions, sizes, and SHA-256 checksums are in',
    'source_cache/discovery_ices_greenland_halibut_2026/sources.csv. No canonical numerical',
    'records were added.')
)

is_initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
is_reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (!is_initial && !is_reviewed)
  stop('Greenland halibut candidate already has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && is_initial) {
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
    col.names = FALSE, quote = TRUE, na = '')
  replacement <- readBin(tmp, 'raw', n = file.info(tmp)$size)
  unlink(tmp)
  replacement <- sub('\\r?\\n$', '', rawToChar(replacement), perl = TRUE)
  before <- bytes[seq_len(first - 1L)]
  after <- if (last < length(bytes)) bytes[(last + 1L):length(bytes)] else raw(0L)
  writeBin(c(before, charToRaw(replacement), ending, after), register_path)
}

cat('Screened ICES Greenland halibut ghl.27.561214; age-data eligibility remains unresolved pending native observation arrays.\n')

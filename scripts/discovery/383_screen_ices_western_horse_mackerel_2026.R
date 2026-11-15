root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_western_horse_mackerel_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:hom.27.2a3a4a5b6a7a-ce-k8'
unit_id <- 'ices_western_horse_mackerel_ne_atlantic'

files <- c('WGWIDE_2025_07_WHM.pdf', 'ICES_2026_advice_7226.html',
  'ICES_2026_SAG_source_25892.html')
urls <- c('https://ndownloader.figshare.com/files/58569670',
  'https://asd.ices.dk/viewAdvice/7226',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25892')
revisions <- c(
  'ICES Scientific Report 07:96, DOI 10.17895/ices.pub.30233824.v3; section 7 Western horse mackerel',
  'ICES Advice 2026 for hom.27.2a3a4a5b6a7a-ce-k8; assessment key 25892',
  'ICES Stock Assessment Graphs, assessment year 2026, assessment key 25892')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed ICES horse mackerel sources before screening.', call. = FALSE)
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
  stop('Cached ICES horse mackerel sources differ from the reviewed source manifest: ',
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
    register$official_stock_id[row] != 'hom.27.2a3a4a5b6a7a-ce-k8' ||
    register$scientific_name[row] != 'Trachurus trachurus' ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('ICES horse mackerel inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == 'hom.27.2a3a4a5b6a7a-ce-k8', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not duplicate or create canonical horse mackerel records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The latest detailed report located, WGWIDE 2025 Table 7.3.4.1, reports',
    'catch numbers-at-age for 1982-2024, ages 0-15, in thousands. The 2025 update adds 2024 catch.',
    'The current 2026 catch-at-age input series has not been verified.'),
  survey_age_evidence = paste('The 2025 model uses an age-0 recruitment index (2003-2024, thousands, with CVs),',
    'a combined spring acoustic biomass index from PELACUS/PELGAS/WESPAS, a triennial egg-production',
    'SSB index, and standardized commercial CPUE. The 2026 run-matched index series are unavailable.'),
  weights_evidence = paste('The 2025 report gives catch weight-at-age and assumes stock weights equal catch',
    'weights. The 2026 run-matched weight inputs have not been verified.'),
  maturity_evidence = paste('The 2025 report gives a fixed proportion-mature vector for ages 0-15, inferred',
    'from a length-based maturity ogive and age-length keys. The 2026 vector has not been verified.'),
  mortality_evidence = paste('The 2025 report gives a fixed age-specific natural-mortality vector for ages 0-15',
    'using the Gislason relationship. The 2026 vector has not been verified.'),
  timing_evidence = paste('The 2025 indices span different seasons: MEGS January-July, PELACUS March/April,',
    'PELGAS May, and WESPAS June/July. A single timing fraction is not appropriate for the combined',
    'acoustic index. Exact 2026 timing has not been verified.'),
  output_evidence = paste('The current 2026 SAG table reports age-0 recruitment, SSB, and total F for ages 1-10',
    'with lower and upper bounds, but no N-at-age. The 2025 detailed report gives N-at-age and F-at-age',
    'in Tables 7.7.3.1 and 7.7.3.2; those are not current-run outputs.'),
  detailed_source_url = paste(c(urls,
    'https://doi.org/10.17895/ices.pub.25002482.v2',
    'https://sid.ices.dk/Default.aspx',
    'https://github.com/ices-eg/wg_WGWIDE'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('ICES identifies a 2026 production assessment and publishes current 2026 advice and',
    'summary outputs. The latest detailed run report located is the 2025 update; it establishes a',
    'substantial age-based data set for the previous run but does not verify the current 2026 input arrays.',
    'Eligibility for the latest assessment remains unresolved until run-matched inputs are available.'),
  notes = paste('This is one Northeast Atlantic western horse mackerel unit. The current code includes',
    'Division 3.a and superseded the prior code hom.27.2a4a5b6a7a-ce-k8 in 2024. The database records',
    'for southern horse mackerel in 9.a and North Sea horse mackerel in 4.b/4.c/7.d are distinct units.',
    '2025 report, current advice, SAG source table, retrieval dates, sizes, and SHA-256 hashes are cached',
    'under source_cache/discovery_ices_western_horse_mackerel_2026/. No canonical records or translation',
    'were added; do not use 2025 run values to fill current 2026 gaps.'))

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (!initial && !reviewed)
  stop('ICES horse mackerel candidate row already has a conflicting review state.', call. = FALSE)

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

cat('Screened ICES western horse mackerel (2026 assessment) as one distinct, eligibility-unresolved candidate.\n')
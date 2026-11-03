root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_greenland_halibut_1_2_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:ghl.27.1-2'
unit_id <- 'ices_greenland_halibut_1_2'

files <- c('jrn-afwg-2026-report.html', 'jrn-afwg-ghl-2027-28-advice.html',
  'nea-ghl-gadget-2024.zip')
urls <- c(
  'https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5',
  'https://www.hi.no/en/hi/nettrapporter/imr-vniro-en-2026-4',
  'https://ftp.nmdc.no/nmdc/IMR/GreenlandHalibut/nea-ghl-gadget-2024.zip')
revisions <- c(
  'JRN-AFWG Report 2026, Greenland halibut chapter; published 2026',
  'JRN-AFWG advice for 2027-2028, assessment year 2026',
  'IMR/NMDC source code and selected data archive, dataset released 2024-10-02; archive last modified 2024-12-04')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed JRN-AFWG and NMDC sources before screening ', candidate_id, '.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
if (anyNA(source_rows) || !identical(as.character(sources$url[source_rows]), urls) ||
    !identical(as.character(sources$revision[source_rows]), revisions) ||
    !identical(tolower(as.character(sources$sha256[source_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached source files differ from the reviewed source manifest.', call. = FALSE)

report <- paste(readLines(paths[1L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
report <- gsub('<[^>]+>', ' ', report)
report <- gsub('&[^;]+;', ' ', report)
report <- gsub('[[:space:]]+', ' ', report)
advice <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
advice <- gsub('<[^>]+>', ' ', advice)
advice <- gsub('&[^;]+;', ' ', advice)
advice <- gsub('[[:space:]]+', ' ', advice)
model_root <- file.path(cache, 'nea-ghl-gadget-2024')
likelihood <- readLines(file.path(model_root, '5 likelihood.R'), warn = FALSE)
catch_distribution <- readLines(file.path(model_root, '2-3-2 catch distributions.R'),
  warn = FALSE)
catch_samples <- readRDS(file.path(model_root, 'data', 'Age-length data for catches.rds'))
survey_samples <- readRDS(file.path(model_root, 'data', 'Age-length data for surveys.rds'))

if (!grepl('catch data are split into five aggregated fleets', tolower(report), fixed = TRUE) ||
    !grepl('age data from the norwegian autumn slope survey was used in the tuning',
      tolower(report), fixed = TRUE) ||
    !grepl('one year time-step', tolower(report), fixed = TRUE) ||
    !grepl('advice has been conducted outside ices', tolower(advice), fixed = TRUE) ||
    !grepl('recruitment at age 2', tolower(advice), fixed = TRUE) ||
    !any(grepl('OtherNor_aldist', likelihood, fixed = TRUE) &
      grepl('^\\s*#', likelihood)) ||
    !grepl("'EggaN_aldist_female'", paste(likelihood, collapse = ' '), fixed = TRUE) ||
    !grepl('nor_catch_aldist', paste(catch_distribution, collapse = ' '), fixed = TRUE) ||
    !isTRUE(all.equal(range(catch_samples[['year']], na.rm = TRUE), c(2015, 2021))) ||
    !isTRUE(all.equal(range(survey_samples[['year']], na.rm = TRUE), c(2001, 2023))) ||
    !isTRUE(all.equal(range(survey_samples[['age']], na.rm = TRUE), c(0, 41))))
  stop('Cached report and model archive do not match the reviewed age-data evidence.',
    call. = FALSE)

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
    register$official_stock_id[row] != 'ghl.27.1-2' ||
    register$scientific_name[row] != 'Reinhardtius hippoglossoides' ||
    any(stocks$authority_stock_id == 'ghl.27.1-2', na.rm = TRUE) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Greenland halibut identity conflicts with the register or canonical database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  inventory_assessment_year = 2026L,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2026 report describes catch in tonnes and quarterly',
    'length distributions by fleet and sex through 2020, not a commercial catch-at-age',
    'likelihood. The 2024 source archive contains sampled catch age-length data from',
    '2015-2021, but the OtherNor age-length likelihood is commented out and the archive',
    'is not verified as the exact 2026 run.'),
  survey_age_evidence = paste('The 2026 report says Norwegian autumn slope survey age data',
    'are used in tuning. The 2024 source archive includes EggaN age-length likelihoods',
    'and age-length observations for 2001-2023, ages 0-41; its example omits 2001 and 2007.',
    'Exact 2026 run inputs and expansion basis remain to be confirmed.'),
  weights_evidence = paste('The model estimates sex-specific growth and maturity-at-length;',
    'a run-matched observed stock weight-at-age series was not located.'),
  maturity_evidence = paste('The 2026 report documents maturity-at-length from the',
    'Norwegian slope survey; a run-matched maturity-at-age table was not located.'),
  mortality_evidence = paste('The 2024 source archive fixes M at 0.12 for females and 0.16',
    'for males. The exact link of these parameter values to the 2026 advice run is not verified.'),
  timing_evidence = paste('The model uses one annual time step and quarterly commercial',
    'distributions.'),
  output_evidence = paste('The 2026 advice reports age-2 recruitment, female SSB, biomass',
    'for fish at least 45 cm, harvest rate, and catches. Annual N-at-age and F-at-age',
    'surfaces were not located.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('This is a distinct current unit with survey age information',
    'used in the GADGET age-length assessment and partial sampled catch age-length data.',
    'The current report documents catch totals and fishery length distributions rather',
    'than a full catch-at-age likelihood; the available archive is from 2024 and is not',
    'run-matched to the 2026 advice. Run-specific age inputs, age-specific biology, and',
    'a supported fishery catch-age reconstruction remain unresolved.'),
  notes = paste('The latest detailed advice found is the 2026 JRN-AFWG advice for 2027-2028,',
    'conducted outside ICES under the method agreed at the ICES 2023 benchmark. It is',
    'distinct from ICES ghl.27.561214 and the DFO Greenland halibut units. The 2026 report,',
    'advice, and 2024 IMR/NMDC source-code archive are cached under',
    'source_cache/discovery_ices_greenland_halibut_1_2_2026/sources.csv with retrieval',
    'metadata and SHA-256 checksums. No canonical numerical records',
    'were added.')
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

cat('Screened ICES Greenland halibut ghl.27.1-2; eligibility remains unresolved pending run-matched age-specific inputs.\n')


root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_redtail_parrotfish_2012')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10144'
unit_id <- 'noaa_redtail_parrotfish_caribbean'

files <- c('sedar26_assessment_report.pdf', 'sedar26_project.html',
  'sedar26_cie_review.pdf', 'sedar103_project.html')
urls <- c(
  'https://sedarweb.org/documents/sedar-26-caribbean-redtail-parrotfish-final-stock-assessment-report/',
  'https://sedarweb.org/assessments/sedar-26/',
  'https://www.st.nmfs.noaa.gov/Assets/Quality-Assurance/documents/peer-review-reports/2011/2011_11_04%20Apostolaki%20SEDAR%2026%20queen%20snapper%20silk%20snapper%20redtail%20parrotfish%20assessment%20review%20report.pdf',
  'https://sedarweb.org/assessments/sedar-103-us-caribbean-application-of-alternate-assessment-methods/')
revisions <- c(
  'SEDAR 26 final stock assessment report; PDF served by SEDAR document page',
  'SEDAR 26 project page, accessed 2026-10-30',
  'CIE independent peer-review report, 2011',
  'SEDAR 103 project page, accessed 2026-10-30')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed SEDAR sources before screening Caribbean redtail parrotfish.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, basename(sources$file))
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), urls),
  revisions = identical(as.character(sources$revision[source_rows]), revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
if (anyNA(source_rows) || !all(source_valid))
  stop('Cached redtail parrotfish sources differ from the reviewed source manifest: ',
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
    register$official_stock_id[row] != '10144' ||
    register$scientific_name[row] != 'Sparisoma chrysopterum' ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('Redtail parrotfish inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == '10144', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Sparisoma chrysopterum', na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not duplicate or create canonical redtail parrotfish records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('SEDAR 26 reports that catch-at-age/length was not developed for',
    'Puerto Rico redtail parrotfish. USVI commercial and recreational catch-at-age data were',
    'not available; TIP length samples are not catch numbers-at-age.'),
  survey_age_evidence = paste('No species-specific standardized abundance index was produced.',
    'The assessment relies on fishery-dependent CPUE and Trip Interview Program length',
    'frequency data; no age-specific survey index was reported.'),
  weights_evidence = paste('The methods are length-based. No model weight-at-age input or',
    'age-specific weight series was reported.'),
  maturity_evidence = paste('The assessment interprets length samples relative to size at',
    'maturity; no maturity-at-age input was reported.'),
  mortality_evidence = paste('The assessment uses length-based total-mortality methods, including',
    'Beverton-Holt and SEINE. Species-specific natural mortality-at-age was not estimated.'),
  timing_evidence = paste('No age-specific survey observation or within-year survey timing was',
    'reported; the available indices and length compositions are fishery-dependent.'),
  output_evidence = paste('SEDAR 26 concluded there was no evidence of overfishing, while',
    'overfished status was unknown. It provides no annual numeric N-, F-, M-, or SSB-at-age',
    'series; Puerto Rico SEINE results had convergence and reliability problems.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest completed redtail-specific assessment located is SEDAR 26',
    '(2011; NOAA Stock SMART lists 2012). It is a data-limited, length-based assessment, not an',
    'age-structured assessment with catch-at-age and age-specific abundance inputs. SEDAR 103 is',
    'ongoing methods development and is not a completed redtail stock-status assessment.'),
  notes = paste('NOAA Stock SMART 10144 is one Caribbean management unit. SEDAR 26 reports',
    'regional components for Puerto Rico, St. Thomas/St. John, and St. Croix; these are not counted',
    'as additional candidate units. The detailed report, CIE review, project pages, retrieval date,',
    'file sizes, and SHA-256 checksums are recorded under source_cache/',
    'discovery_noaa_redtail_parrotfish_2012/. No canonical numerical records',
    'were added.'))

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('Redtail parrotfish candidate row already has a conflicting review state.', call. = FALSE)

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

cat('Screened NOAA:10144 once as an ineligible Caribbean redtail parrotfish unit.\n')

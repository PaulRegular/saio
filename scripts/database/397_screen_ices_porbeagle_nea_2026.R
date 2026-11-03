root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_porbeagle_nea_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:por.27.nea'
unit_id <- 'ices_porbeagle_nea'

files <- c('advice_2026.html', 'charts_2026.html', 'source_data_2026.html')
urls <- c(
  'https://asd.ices.dk/viewAdvice/7248',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=26019',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=26019')
revisions <- c(
  'ICES advice for 2027-2030; assessment year 2026; assessment key 26019',
  'ICES Standard Graphs, assessment year 2026, key 26019',
  'ICES Standard Graphs source data, assessment year 2026, key 26019')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the current ICES advice and Standard Graphs pages before screening ', candidate_id, '.',
    call. = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
manifest_rows <- match(files, basename(manifest$file))
if (anyNA(manifest_rows) ||
    !identical(as.character(manifest$url[manifest_rows]), urls) ||
    !identical(as.character(manifest$revision[manifest_rows]), revisions) ||
    !identical(toupper(as.character(manifest$sha256[manifest_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached ICES source files differ from their recorded manifest.', call. = FALSE)

advice <- paste(readLines(paths[1L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
charts <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
source_data <- paste(readLines(paths[3L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!grepl('por.27.nea', advice, fixed = TRUE) ||
    !grepl('Assessment Year</div>', advice, fixed = TRUE) ||
    !grepl('Stock Category</div>', advice, fixed = TRUE) ||
    !grepl('>2.11</div>', advice, fixed = TRUE) ||
    !grepl('185 tonnes', advice, fixed = TRUE) ||
    !grepl('2027&#x2013;2030', advice, fixed = TRUE) ||
    !grepl('lblStockCode', charts, fixed = TRUE) ||
    !grepl('por.27.nea', charts, fixed = TRUE) ||
    !grepl('lblYear', charts, fixed = TRUE) ||
    !grepl('2026', charts, fixed = TRUE) ||
    !grepl('lblStockSizeDescription"></span>', source_data, fixed = TRUE) ||
    !grepl('lblRecruitmentAge">0', source_data, fixed = TRUE) ||
    !grepl('lblFAge"></span>', source_data, fixed = TRUE) ||
    !grepl('<th scope="col">Year</th><th scope="col">Landings</th>', source_data, fixed = TRUE))
  stop('Cached ICES sources do not match the reviewed aggregate-output evidence.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row_index <- match(candidate_id, register$candidate_id)
if (is.na(row_index) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    register$official_stock_id[row_index] != 'por.27.nea' ||
    register$scientific_name[row_index] != 'Lamna nasus' ||
    as.character(register$inventory_assessment_year[row_index]) != '2026' ||
    any(stocks$authority_stock_id == 'por.27.nea', na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Porbeagle identity conflicts with the inventory or canonical database.', call. = FALSE)

review <- data.frame(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The current advice and graph provide aggregate landings in tonnes only; no',
    'age-specific catch or catch-composition series is reported.'),
  survey_age_evidence = 'The current Standard Graphs source data contain no age-specific survey series or aggregate survey index.',
  weights_evidence = 'No weight-at-age input is reported for the current assessment.',
  maturity_evidence = 'No maturity-at-age input is reported for the current assessment.',
  mortality_evidence = 'The current advice does not report an age-structured mortality model or age-specific natural mortality.',
  timing_evidence = 'No survey-index likelihood or fractional within-year timing is reported.',
  output_evidence = paste('The 2026 source data report annual landings only; the age/length fields show recruitment',
    'age zero and blank fishing-mortality age, with no N-, F-, or M-at-age outputs.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest published advice is the 2026 Category 2.11 assessment. The official',
    'source graph contains aggregate landings only, without age-disaggregated likelihood inputs or',
    'population outputs. The unit is therefore ineligible for the age-disaggregated assessment set.'),
  notes = paste('The advice applies to 2027-2030 and is the current 2026 ICES assessment of the Northeast',
    'Atlantic and adjacent-waters porbeagle unit. Current advice and Standard Graphs pages, retrieval',
    'date, revisions, byte sizes, and SHA-256 checksums are recorded under',
    'source_cache/discovery_ices_porbeagle_nea_2026/.',
    'translation were added.'),
  stringsAsFactors = FALSE,
  check.names = FALSE)

initial_state <- register$match_status[row_index] == 'unreviewed' &
  register$screening_status[row_index] == 'not_started' &
  register$eligibility[row_index] == 'unresolved'
reviewed_state <- register$match_status[row_index] == 'new' &
  register$candidate_unit_id[row_index] == unit_id &
  register$screening_status[row_index] == 'screened' &
  register$eligibility[row_index] == 'ineligible'
if (!initial_state && !reviewed_state)
  stop('Porbeagle candidate already has a conflicting review.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  needs_write <- initial_state || !all(vapply(names(review), function(name)
    identical(as.character(register[[name]][row_index]), as.character(review[[name]])), logical(1L)))
  if (needs_write) {
    for (name in names(review)) register[[name]][row_index] <- review[[name]]
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], candidate_id)
  }
}
cat('Screened ICES porbeagle por.27.nea as ineligible for age-disaggregated inputs and outputs.\n')

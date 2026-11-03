root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_ices_whiting_rockall_2024')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

expected <- data.frame(
  file = c('ices_advice_2024.html', 'ices_sag_source_2024.html'),
  sha256 = c('01D2C2266ED9CD1F332811B8C995A7AC3E7D887286893137846DCDB6EA6AD308',
    '6939D20ADA30DD8D9C1373926B1E9B5CC7505D89781856DA36DAEAE846EF292D'),
  stringsAsFactors = FALSE
)
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
for (i in seq_len(nrow(expected))) {
  path <- file.path(cache_dir, expected$file[i])
  row <- match(expected$file[i], manifest$file)
  if (!file.exists(path) || is.na(row) || manifest$sha256[row] != expected$sha256[i] ||
      sha256_file(path) != expected$sha256[i]) {
    stop('A pinned Rockall whiting source is missing or differs from its manifest: ',
      expected$file[i], call. = FALSE)
  }
}

advice <- paste(readLines(file.path(cache_dir, 'ices_advice_2024.html'), warn = FALSE),
  collapse = ' ')
graph <- paste(readLines(file.path(cache_dir, 'ices_sag_source_2024.html'), warn = FALSE),
  collapse = ' ')
if (!grepl('whg.27.6b', advice, fixed = TRUE) ||
    !grepl('Stock Category', advice, fixed = TRUE) || !grepl('6.2', advice, fixed = TRUE) ||
    !grepl('Assessment Year', advice, fixed = TRUE) || !grepl('2024', advice, fixed = TRUE) ||
    !grepl('whg.27.6b', graph, fixed = TRUE) ||
    !grepl('Assessment Year', graph, fixed = TRUE) || !grepl('2024', graph, fixed = TRUE) ||
    !grepl('Fish data.*Year.*Landings.*1975.*12', graph, perl = TRUE)) {
  stop('The cached ICES sources do not match the reviewed Rockall whiting evidence.', call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

candidate_id <- 'ICES:whg.27.6b'
unit_id <- 'ices_whiting_rockall_6b'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$official_stock_id[row] != 'whg.27.6b' ||
    register$scientific_name[row] != 'Merlangius merlangus' ||
    register$inventory_assessment_year[row] != 2024 ||
    any(stocks$authority_stock_id == 'whg.27.6b', na.rm = TRUE)) {
  stop('Rockall whiting candidate identity or current assessment listing changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    unit_id %in% assessments$assessment_id || unit_id %in% inputs$assessment_id ||
    unit_id %in% outputs$assessment_id) {
  stop('Rockall whiting candidate-unit key conflicts with an existing record.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2024 ICES advice classifies whg.27.6b as Category 6.2. The official source-data table reports annual landings for 1975-2023 and no catch-at-age or age-composition observations.',
  survey_age_evidence = 'The official 2024 source-data page provides no survey-index series or age-specific survey observations for this unit.',
  weights_evidence = 'No stock or catch weights-at-age are reported for the current landings-only advice method.',
  maturity_evidence = 'Maturity-at-age is not reported for the current landings-only advice method.',
  mortality_evidence = 'The current Category 6.2 advice does not use an age-structured population model with an age-specific natural-mortality input.',
  timing_evidence = 'No survey observation timing is applicable to the current landings-only advice method.',
  output_evidence = 'The official 2024 Standard Graphs source-data table contains landings only; no numeric SSB, recruitment, N-at-age, or F-at-age output series was recovered.',
  detailed_source_url = paste('https://asd.ices.dk/viewAdvice/3707',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=18912',
    'https://doi.org/10.17895/ices.pub.32625759', sep = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The latest assessment year listed for Rockall whiting is 2024. ICES classifies it as Category 6.2, and the official source-data table contains landings only. It lacks the age-disaggregated inputs and comparable population outputs required for the age-structured inventory.'),
  notes = paste('This is a distinct current ICES unit, separate from whg.27.6a, whg.27.47d, whg.27.7a, and whg.27.89a. The official 2026 WGCSE report lists the Rockall whiting stock annex as last updated May 2013; that report is cached and checksummed in source_cache/discovery_ices_wgbie_2026/sources.csv. The 2024 advice and Standard Graphs pages are cached with retrieval dates and checksums in source_cache/discovery_ices_whiting_rockall_2024/sources.csv. No canonical stock or numerical records were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  grepl('Category 6.2', register$catch_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) stop('Rockall whiting candidate has an unexpected prior review state.',
  call. = FALSE)
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && initial) {
  lines <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(register) + 1L) {
    stop('Candidate register contains multiline rows; refusing an unsafe rewrite.', call. = FALSE)
  }
  tmp <- tempfile(fileext = '.csv')
  write.csv(register[row, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
  unlink(tmp)
  writeLines(lines, register_path, useBytes = TRUE)
}
cat('Screened ICES Rockall whiting whg.27.6b against the 2024 advice and outputs; age-input eligibility is ineligible.\n')

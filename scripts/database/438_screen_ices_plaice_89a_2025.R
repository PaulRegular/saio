root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_plaice_89a_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:ple.27.89a'
unit_id <- 'ices_plaice_89a'
files <- c('wgbie_2025_section13_plaice.pdf',
  'ICES_advice_2025_ple_27_89a.html',
  'ICES_standard_graphs_2025_ple_27_89a.html')
urls <- c('https://ndownloader.figshare.com/files/58805083',
  'https://asd.ices.dk/viewAdvice/3923',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19633')
revisions <- c(
  'ICES WGBIE 2025 report, v4, section 13 (Plaice in Bay of Biscay and Atlantic Iberian waters), pp. 424-431; DOI 10.17895/ices.pub.29390639.v4; Figshare file 58805083',
  'ICES advice record 3923, assessment year 2025, stock category 5; advice record reports 99 tonnes for 2026-2028; DOI 10.17895/ices.advice.27202791',
  'ICES Standard Graphs source data, assessment year 2025, key 19633; aggregate landings only; age-specific F field blank')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)))
  stop('Cache the reviewed ICES WGBIE, advice, and Standard Graphs sources before screening ', id, '.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, sources$file)
if (anyNA(source_rows) || !identical(as.character(sources$url[source_rows]), urls) ||
    !identical(as.character(sources$revision[source_rows]), revisions) ||
    any(sources$retrieved_on[source_rows] != '2026-10-30') ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(toupper(as.character(sources$sha256[source_rows])),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(rawToChar(readBin(paths[1L], 'raw', n = 4L)), '%PDF'))
  stop('Cached ICES source files differ from their provenance manifest.', call. = FALSE)

advice <- paste(readLines(paths[2L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
graph <- paste(readLines(paths[3L], warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
if (!all(vapply(c('ple.27.89a', '27202791', '99 tonnes', '2026, 2027 and 2028'),
    grepl, logical(1L), x = advice, fixed = TRUE)) ||
    !all(vapply(c('<span id="lblStockCode">ple.27.89a</span>',
      '<span id="lblYear">2025</span>', '<span id="lblKey">19633</span>',
      '<span id="lblFAge"></span>', '<th scope="col">Year</th><th scope="col">Landings</th>'),
      grepl, logical(1L), x = graph, fixed = TRUE)))
  stop('Cached ICES advice or Standard Graphs pages do not match the reviewed 2025 record.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != 'ple.27.89a' ||
    candidates$scientific_name[row] != 'Pleuronectes platessa' ||
    candidates$inventory_assessment_year[row] != 2025L ||
    any(tolower(stocks$authority_stock_id) == 'ple.27.89a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('ICES Bay of Biscay plaice identity conflicts with the register or canonical database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The current WGBIE assessment reports aggregate landings and commercial number-at-length data. It explicitly states that there is no analytical assessment; catch-at-age and age-composition model inputs are not reported.'),
  survey_age_evidence = paste('The report states that no commercial index is currently available and that survey or commercial abundance indices are lacking. No age-specific survey abundance series is reported.'),
  weights_evidence = 'The assessment report says biological information still needs to be compiled; age-specific stock or catch weights are not reported.',
  maturity_evidence = 'The current data-limited assessment does not report maturity-at-age inputs.',
  mortality_evidence = 'There is no analytical population model and no age-specific fishing or natural-mortality estimate.',
  timing_evidence = 'No survey index is used in the current assessment, so survey timing is not applicable.',
  output_evidence = paste('The 2025 advice record provides a landings recommendation, while Standard Graphs reports aggregate landings only and leaves the F-at-age field blank. No N-at-age, F-at-age, M-at-age, SSB, or recruitment assessment output is reported. The working-group report states 124 t for 2026-2028, whereas Advice record 3923 states 99 t for those years; this discrepancy is unresolved and does not affect age-structure eligibility.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.29390639.v4;',
    'https://asd.ices.dk/viewAdvice/3923;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19633'),
  review_date = '2026-10-30',
  decision_reason = paste('The latest detailed source located is the 2025 WGBIE report, section 13. It identifies this stock as data-limited category 5.2 and explicitly states there is no analytical assessment. Reported data are landings and commercial numbers-at-length, without an abundance index or age-structured population outputs. The unit is ineligible for this age-disaggregated inventory; no canonical numerical records were added.'),
  notes = paste('The WGBIE section describes a category 5.2 stock with no analytical assessment; biological information and a robust LPUE index are identified as gaps. The official 2025 Advice record 3923 reports 99 t landings advice for 2026-2028, while the WGBIE section states 124 t. Retain both source values as a documented discrepancy; do not import either as a population output. The section 13 PDF, Advice page, and Standard Graphs source page are cached in source_cache/discovery_ices_plaice_89a_2025/ with URLs, retrieval date, revision, size and checksum in sources.csv.'))

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('ICES Bay of Biscay plaice candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row, candidates[row, , drop = FALSE], id)
}

cat('Screened ICES Bay of Biscay plaice as ineligible for age-disaggregated assessment inputs and outputs.\n')

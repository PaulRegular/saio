root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_blue_ling_5b6712_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:bli.27.5b6712'
unit_id <- 'ices_blue_ling_5b6712'

files <- c('ICES_SID_year_2026.json',
  'ICES_standard_graphs_2026_key_22623.html',
  'ICES_source_data_2026_key_22623.html', 'ICES_SAG_22623.xml',
  'ICES_advice_record_6156.html')
urls <- c('https://sid.ices.dk/services/year/2026',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22623',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22623',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/22623',
  'https://asd.ices.dk/viewAdvice/6156')
revisions <- c(
  'ICES SID year 2026 snapshot generated 2026-10-31; bli.27.5b6712 key 22623',
  'ICES Standard Graphs assessment year 2026, bli.27.5b6712 key 22623',
  'ICES Standard Graphs source data, 2026, bli.27.5b6712 key 22623',
  'ICES SAG XML assessment year 2026, bli.27.5b6712 key 22623',
  'ICES Advice and Scenarios Database record 6156, assessment year 2026')
expected_sha256 <- c(
  'c5d9816e40f393ed3664dcb92710b75a47e0dd4961eb29fe3524570ae2cd5efc',
  'b3adf4ab09e3691de1493be98fc84bc4de403f201349d3bd0c819b1d45a42afd',
  '22ddcda8b713701fa176bf2b2664e7c7846ee42b8fa83b6a2c0a988bafa2b744',
  'f8654375d81d31c2d380b16d19e5fe0f85128f248b2442a90e11cbbc37071106',
  'ac965f724b93e5fd1c3f8a2efa9ecdbea1b7a116ddb80f424510da3340446897')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path,
    call. = FALSE)
  tolower(hashes)
}

if (any(!file.exists(paths)))
  stop('Cache the reviewed ICES sources before screening ', candidate_id, '.',
    call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(files, sources$file)
if (nrow(sources) != length(files) || anyNA(source_rows) ||
    !identical(sources$url[source_rows], urls) ||
    !identical(sources$revision[source_rows], revisions) ||
    !identical(sources$retrieved_on[source_rows], rep('2026-10-31', length(files))) ||
    !identical(tolower(sources$sha256[source_rows]), expected_sha256) ||
    !identical(tolower(sources$sha256[source_rows]),
      unname(vapply(paths, sha256_file, character(1L)))) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
  stop('Cached source files differ from the reviewed source manifest.', call. = FALSE)

read_source <- function(file) paste(readLines(file.path(cache, file), warn = FALSE),
  collapse = ' ')
sid <- read_source(files[1L])
graphs <- read_source(files[2L])
source_data <- read_source(files[3L])
sag <- read_source(files[4L])
advice <- read_source(files[5L])
source_checks <- c(
  sid = all(vapply(c('"StockKeyLabel":"bli.27.5b6712"',
    '"ActiveYear":2026', '"YearOfLastAssessment":2026',
    'ATrend from a biomass index and length-based indicato',
    '"AssessmentKey":22623'), grepl, logical(1L), x = sid, fixed = TRUE)),
  graphs = all(vapply(c('bli.27.5b6712', 'id="lblYear" class="text">2026',
    'id="lblKey" class="text">22623', 'B_index', 'Kilograms per hour', 'tonnes'),
    grepl, logical(1L), x = graphs, fixed = TRUE)),
  source_data = all(vapply(c('bli.27.5b6712', 'Assessment Year', '22623',
    'B_index', 'Kilograms per hour', 'Lfm/Lmean'),
    grepl, logical(1L), x = source_data, fixed = TRUE)),
  sag = all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
    '<StockCode>bli.27.5b6712</StockCode>', '<StockCategory>3.2</StockCategory>',
    '<ModelType>DLS</ModelType>', '<ModelName>rfb</ModelName>',
    '<StockSizeDescription>B_index</StockSizeDescription>',
    '<ConfidenceIntervalDefinition>se</ConfidenceIntervalDefinition>',
    '<Year>1966</Year>', '<Year>1996</Year>', '<Year>2025</Year>',
    '<RecruitmentAge></RecruitmentAge>', '<Fage></Fage>', '<Flength></Flength>'),
    grepl, logical(1L), x = sag, fixed = TRUE)) &&
    !grepl('<Age_Data>', sag, fixed = TRUE),
  advice = all(vapply(c('bli.27.5b6712', '3.2', 'Stock Assessment Key',
    '22623', '6 536 tonnes', '2027 and 2028', '12.a and 12.c'),
    grepl, logical(1L), x = advice, fixed = TRUE)))
if (!all(source_checks)) {
  print(source_checks)
  stop('The cached sources do not support the documented blue ling screen.',
    call. = FALSE)
}

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != 'bli.27.5b6712' ||
    candidates$scientific_name[row] != 'Molva dypterygia' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    candidates$assessment_area[row] != 'Celtic Seas, Faroes' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'bli.27.5b6712', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE))
  stop('Blue ling identity conflicts with the candidate register or canonical database.',
    call. = FALSE)
if (any(c(unit_id) %in% assessments$assessment_id, na.rm = TRUE) ||
    any(c(unit_id) %in% inputs$assessment_id, na.rm = TRUE) ||
    any(c(unit_id) %in% outputs$assessment_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The current 2026 assessment is described by ICES SID as a',
    'trend assessment from a biomass index and length-based indicator. The 2026',
    'assessment products report aggregate landings/catches, not catch numbers-at-age;',
    'no age-composition likelihood input was verified for this run.'),
  survey_age_evidence = paste('ICES reports an aggregate B_index in kg/hour for',
    '1996–2025 with standard errors. It is not age-disaggregated, and the reviewed',
    'current-assessment sources provide no index-at-age series.'),
  weights_evidence = paste('No weights-at-age for the current 2026 trend assessment',
    'were identified in the reviewed official sources. This does not establish that',
    'age-specific biological data are absent from other data systems.'),
  maturity_evidence = paste('No maturity-at-age input for the current 2026 trend',
    'assessment was identified in the reviewed official sources. This does not',
    'establish that age-specific biological data are absent from other data systems.'),
  mortality_evidence = paste('The SAG output reports a length-based fishing-pressure',
    'proxy (Lfm/Lmean), not an age-specific F surface; it provides no age-specific M.'),
  timing_evidence = paste('The published B_index is aggregate and the reviewed sources',
    'do not specify an observation fraction within the year.'),
  output_evidence = paste('The 2026 SAG record (key 22623) reports aggregate B_index',
    'mean and standard error for 1996–2025 (kg/hour), landings/catches for 1966–2025',
    '(the graph labels the units tonnes), and a length-based fishing-pressure proxy',
    'for 1984–2025. Recruitment, SSB, N-at-age, F-at-age, and M-at-age outputs are not',
    'reported. B_index is not SSB. ICES advice record 6156 recommends catches of no',
    'more than 6,536 tonnes in each of 2027 and 2028.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste('The latest current-unit assessment is ICES 2026 for',
    'bli.27.5b6712, a trend assessment from an aggregate biomass index and a',
    'length-based indicator (advice category 3.2). The reviewed current-run products',
    'do not provide age-disaggregated observations or population/mortality outputs',
    'needed for the age-structured comparison set. Screen as a new, ineligible',
    'candidate; retain it in discovery and do not substitute an older assessment.'),
  notes = paste('The current stock unit includes subareas 6, 7, 12 and Division 5.b;',
    'the advice applies to 5.b, subareas 6 and 7, and 12.b, not 12.a or 12.c. This is',
    'distinct from the separately registered Icelandic blue ling unit bli.27.5a14.',
    'The current advice page, SID, Standard Graphs, and SAG XML all identify assessment',
    'key 22623. The data reviewed do not establish that age',
    'samples are absent from national source systems. Cached source URLs, revisions,',
    'retrieval dates, sizes and SHA-256 checksums are in',
    'source_cache/discovery_ices_blue_ling_5b6712_2026/sources.csv. No canonical',
    'assessment, input or output records were added was',
    'attempted.')
)

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!is_unreviewed && !same_review)
  stop('Blue ling candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES blue ling bli.27.5b6712 as ineligible for the age-disaggregated set.\n')

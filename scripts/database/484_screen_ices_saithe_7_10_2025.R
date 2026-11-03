root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_saithe_subareas_7_10_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:pok.27.7-10'
unit_id <- 'ices_saithe_subareas_7_10'

files <- c('ices_sid_2026.json', 'ices_standard_graphs_key_19486.html',
  'ices_source_data_key_19486.html', 'ices_sag_19486_pok_27_7_10_2025.xml',
  'ices_advice_record_3935.html')
urls <- c('https://sid.ices.dk/services/year/2026',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=19486',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=19486',
  'https://sag.ices.dk/SAG_API/StockXmlDownload/19486',
  'https://asd.ices.dk/viewAdvice/3935')
revisions <- c(
  'ICES SID year 2026 snapshot; pok.27.7-10 active year 2026, latest assessment 2025',
  'ICES Standard Graphs, assessment year 2025, key 19486',
  'ICES Standard Graphs source data, assessment year 2025, key 19486',
  'ICES SAG XML, assessment year 2025, category 5, key 19486',
  'ICES Advice and Scenarios Database record 3935, assessment year 2025; source record created 2025-06-23')
expected_sha256 <- c(
  '8e78ab53a4b62fe4a18e0f3925a78fdbdd9a5fcf918c8ffc370d8574654feb50',
  '6e02f946b49ffe3bbbcb896e8efe437e51e580a48d04dc185f25767a881d4812',
  'd617bc7a01f38f8dea38d4a762fc1a67427af5545137cf62a53c43934a837a0b',
  '4f9ac5f470cc0391daeea6200e0d345fc3ada4f7ca2342bed90cc66e66fbcb98',
  'a497e4b55d72041899e2cefe420528c22f7f751c12115de9d9646b9d00dba104')
expected_bytes <- c(324088, 115310, 49150, 39184, 31736)
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
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(expected_bytes)) ||
    !identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(tolower(sources$sha256[source_rows]),
      unname(vapply(paths, sha256_file, character(1L)))))
  stop('Cached ICES source files differ from the reviewed source manifest.',
    call. = FALSE)

read_source <- function(file) paste(readLines(file.path(cache, file), warn = FALSE),
  collapse = ' ')
sid <- read_source(files[1L])
graphs <- read_source(files[2L])
source_data <- read_source(files[3L])
sag <- read_source(files[4L])
advice <- read_source(files[5L])
source_checks <- c(
  sid = all(vapply(c('"StockKeyLabel":"pok.27.7-10"', '"ActiveYear":2026',
    '"YearOfLastAssessment":2025', '"AssessmentKey":19486',
    '"DataCategory":"5"'), grepl, logical(1L), x = sid, fixed = TRUE)),
  graphs = all(vapply(c('pok.27.7-10', 'id="lblYear" class="text">2025',
    'id="lblKey" class="text">19486', 'Landings', 'Discards'),
    grepl, logical(1L), x = graphs, fixed = TRUE)),
  source_data = all(vapply(c('pok.27.7-10', 'Assessment Year', '19486',
    'Year', 'Landings', 'Discards', '2003', '2024'),
    grepl, logical(1L), x = source_data, fixed = TRUE)),
  sag = all(vapply(c('<AssessmentYear>2025</AssessmentYear>',
    '<StockCode>pok.27.7-10</StockCode>', '<StockCategory>5</StockCategory>',
    '<ModelType>None</ModelType>', '<ModelName>None</ModelName>',
    '<Year>2003</Year>', '<Year>2024</Year>',
    '<Landings>1474.750200000</Landings>', '<Discards>0.008284000</Discards>',
    '<Fage></Fage>', '<Flength></Flength>', '<RecruitmentAge></RecruitmentAge>',
    '<RecruitmentLength></RecruitmentLength>'), grepl, logical(1L), x = sag,
    fixed = TRUE)) && !grepl('<Age_Data>', sag, fixed = TRUE) &&
    !grepl('<StockSize>[^<]+</StockSize>', sag) &&
    !grepl('<Recruitment>[^<]+</Recruitment>', sag) &&
    !grepl('<FishingPressure>[^<]+</FishingPressure>', sag) &&
    length(gregexpr('<Fish_Data>', sag, fixed = TRUE)[[1L]]) == 22L,
  advice = all(vapply(c('pok.27.7-10', '19486', 'Stock Category',
    '2025', 'value="146"', '2026&#x2013;2028', '146 tonnes'),
    grepl, logical(1L), x = advice, fixed = TRUE)))
if (!all(source_checks)) {
  print(source_checks)
  stop('The cached sources do not support the documented saithe screen.',
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
    candidates$official_stock_id[row] != 'pok.27.7-10' ||
    candidates$scientific_name[row] != 'Pollachius virens' ||
    candidates$inventory_assessment_year[row] != 2025L ||
    candidates$assessment_area[row] != paste('Azores, Bay of Biscay and the Iberian Coast,',
      'Celtic Seas, Greater North Sea, Oceanic Northeast Atlantic') ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'pok.27.7-10', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE))
  stop('ICES saithe identity conflicts with the candidate register or canonical database.',
    call. = FALSE)
if (any(unit_id %in% assessments$assessment_id, na.rm = TRUE) ||
    any(unit_id %in% inputs$assessment_id, na.rm = TRUE) ||
    any(unit_id %in% outputs$assessment_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2025 ICES assessment is category 5. The SAG XML and',
    'source-data page provide only aggregate landings and discards, not catch',
    'numbers-at-age or age-composition likelihood inputs.'),
  survey_age_evidence = paste('The reviewed 2025 SAG record contains no survey index,',
    'age-specific survey information, or Age_Data table. Its stock-size and',
    'recruitment fields are empty.'),
  weights_evidence = paste('No weights-at-age for the current 2025 assessment were',
    'identified in the reviewed official products. This does not establish that',
    'age-specific biological data are absent from all national data systems.'),
  maturity_evidence = paste('No maturity-at-age input for the current 2025 assessment',
    'was identified in the reviewed official products. This does not establish that',
    'age-specific biological data are absent from all national data systems.'),
  mortality_evidence = paste('The current SAG record has empty F-age, F-length, and',
    'fishing-pressure fields and reports no age-specific natural-mortality input.'),
  timing_evidence = paste('The reviewed current-run export contains no survey index',
    'and specifies no within-year observation timing.'),
  output_evidence = paste('The 2025 SAG export provides aggregate landings and',
    'discards for 2003-2024. Stock-size, recruitment, fishing-pressure, and age-data',
    'fields are empty. The 2025 advice record reports a catch limit of 146 tonnes',
    'for 2026-2028; this is management advice, not an age-structured population',
    'output.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste('The latest current-unit ICES assessment is year 2025,',
    'category 5. Its reviewed source products report aggregate catches only and',
    'provide no age-disaggregated observations or age-specific population and',
    'mortality outputs required for the comparison set. Screen as a new, ineligible',
    'candidate; do not substitute another saithe unit or infer missing age data.'),
  notes = paste('The unit is ICES stock code pok.27.7-10, covering subareas 7-10',
    '(Southern Celtic Sea and English Channel, Bay of Biscay, Atlantic Iberian',
    'waters, and Azores grounds). The SID 2026 snapshot, Standard Graphs, SAG XML,',
    'source-data page, and advice record 3935 identify assessment key 19486. The',
    'SAG export contains 22 annual fish-data rows for 2003-2024, with only landings',
    'and discards populated. No canonical assessment, input, or output records were',
    'added and no tinyAM translation was attempted.'))

current <- lapply(names(review), function(column)
  as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!is_unreviewed && !same_review)
  stop('ICES saithe candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') &&
    (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened ICES saithe in subareas 7-10 as ineligible for age-disaggregated inputs and outputs.\n')

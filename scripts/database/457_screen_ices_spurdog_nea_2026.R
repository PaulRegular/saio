root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_spurdog_nea_2026')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:dgs.27.nea'
unit_id <- 'ices_spurdog_nea'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path,
    call. = FALSE)
  tolower(hashes)
}

sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_paths <- file.path(cache, sources$file)
if (nrow(sources) != 11L || any(!file.exists(source_paths)) ||
    any(as.numeric(sources$bytes) != file.info(source_paths)$size) ||
    any(tolower(sources$sha256) != vapply(source_paths, sha256_file, character(1L))))
  stop('Cached ICES sources differ from their manifest.', call. = FALSE)

read_source <- function(file) gsub('[[:space:]]+', ' ',
  paste(readLines(file.path(cache, file), warn = FALSE), collapse = ' '))
sid <- read_source('../discovery_ices_sid/stock_list_2026.json')
advice_2024 <- read_source('ICES_advice_2024_dgs_27_nea.txt')
advice_2027 <- read_source('ICES_advice_record_7197.html')
advice_2028 <- read_source('ICES_advice_record_7198.html')
graphs <- read_source('ICES_standard_graphs_source_data_key_25850.html')
sag <- read_source('ICES_SAG_25850.xml')
wgef_2025 <- read_source('WGEF_2025_spurdog_page45.txt')

source_checks <- c(
  sid = all(vapply(c('"StockKeyLabel":"dgs.27.nea"',
    '"SpeciesScientificName":"Squalus acanthias"', '"ActiveYear":2026',
    '"YearOfLastAssessment":2026', '"AssessmentType":"Age-length and sex-structured model"',
    '"AssessmentKey":25850'), grepl, logical(1L), x = sid, fixed = TRUE)),
  advice_2024 = all(vapply(c('Age-length and sex-structured model',
    'Three GAM-based delta-lognormal survey biomass indices, combined by quarter:',
    'length composition by sex associated with the three combined survey indices',
    'fecundity-at-length; landings; length composition for bottom trawls',
    'gillnets and trammel nets'), grepl, logical(1L), x = advice_2024, fixed = TRUE)),
  advice_2027 = all(vapply(c('dgs.27.nea', 'Assessment Year', '2026',
    'Stock Assessment Key', '25850', '20124', '20 124 tonnes'),
    grepl, logical(1L), x = advice_2027, fixed = TRUE)),
  advice_2028 = all(vapply(c('dgs.27.nea', 'Assessment Year', '2026',
    'Stock Assessment Key', '25850', '20478', '20 478 tonnes'),
    grepl, logical(1L), x = advice_2028, fixed = TRUE)),
  graphs = all(vapply(c('dgs.27.nea', 'Assessment Year', '25850', 'tonnes',
    'thousands', 'Frel', 'SSB', 'id="lblRecruitmentAge">0',
    'id="lblFAge">5-30'), grepl, logical(1L), x = graphs, fixed = TRUE)),
  sag = all(vapply(c('<AssessmentYear>2026</AssessmentYear>',
    '<StockCode>dgs.27.nea</StockCode>', '<StockCategory>1</StockCategory>',
    '<ModelType>AL</ModelType>', '<RecruitmentAge>0</RecruitmentAge>',
    '<Fage>5-30</Fage>', '<StockSizeDescription>SSB</StockSizeDescription>',
    '<TerminalYear>2025</TerminalYear>', '<Year>1905</Year>', '<Year>2025</Year>',
    '<Year>2026</Year>'), grepl, logical(1L), x = sag, fixed = TRUE)) &&
    !grepl('<Age_Data>', sag, fixed = TRUE),
  wgef_2025 = all(vapply(c('The assessment was not updated during WGEF 2025',
    'the next advice for this stock is due in 2026'),
    grepl, logical(1L), x = wgef_2025, fixed = TRUE)))
if (!all(source_checks)) {
  print(source_checks)
  stop('The cached sources do not support the documented spurdog screen.',
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
    candidates$official_stock_id[row] != 'dgs.27.nea' ||
    candidates$scientific_name[row] != 'Squalus acanthias' ||
    candidates$inventory_assessment_year[row] != 2026L ||
    !grepl('subareas 1-10, 12, and 14', candidates$stock_name[row], fixed = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'dgs.27.nea', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE))
  stop('Spurdog identity conflicts with the candidate register or canonical database.',
    call. = FALSE)
if (any(unit_id %in% assessments$assessment_id, na.rm = TRUE) ||
    any(unit_id %in% inputs$assessment_id, na.rm = TRUE) ||
    any(unit_id %in% outputs$assessment_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The latest detailed input description located (ICES 2024',
    'advice Table 5) lists landings and fishery length compositions, not catch',
    'numbers-at-age or age compositions. The 2026 input arrays were not located.'),
  survey_age_evidence = paste('ICES 2024 lists three quarterly GAM-based survey biomass',
    'indices and sex-specific length compositions associated with the indices;',
    'it does not identify survey age compositions or an index-at-age. Current 2026',
    'input arrays were not located.'),
  weights_evidence = paste('The 2024 input summary lists fecundity-at-length but does not',
    'list a weight-at-age input. The age-length model label does not establish a',
    'supplied age-specific weight series; exact 2026 biological arrays were not located.'),
  maturity_evidence = paste('The 2024 input summary lists fecundity-at-length, not a',
    'maturity-at-age vector. Exact 2026 biological inputs were not located.'),
  mortality_evidence = paste('The 2026 SAG reports an aggregate relative harvest rate for',
    'ages 5-30, not F-at-age, and does not report M-at-age. The detailed 2026',
    'natural-mortality specification was not located.'),
  timing_evidence = paste('The latest detailed input summary combines surveys by quarter',
    '(Q1, Q3, Q4) but does not provide within-quarter sampling fractions. Exact 2026',
    'timing settings were not located.'),
  output_evidence = paste('2026 SAG key 25850 reports SSB and total biomass in tonnes,',
    'age-0 pup recruitment (metadata: thousands; graph label: millions), an aggregate',
    'relative harvest rate for ages 5-30, and catches/landings/discards. Historical',
    'series terminate in 2025 and 2026 values are forecasts. N-at-age, F-at-age, and',
    'M-at-age are not present in the published SAG output. Low/high bounds are given,',
    'but their interval definition was not resolved.'),
  detailed_source_url = paste(c('https://sid.ices.dk/services/year/2026',
    'https://asd.ices.dk/viewAdvice/7197', 'https://asd.ices.dk/viewAdvice/7198',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25850',
    'https://sag.ices.dk/SAG_API/StockXmlDownload/25850',
    'https://ices-library.figshare.com/articles/report/Spurdog_Squalus_acanthias_in_Subareas_1-10_12_and_14_the_Northeast_Atlantic_and_adjacent_waters_/25019237',
    'https://ices-library.figshare.com/articles/report/Report_of_the_Working_Group_on_Elasmobranch_Fishes_WGEF_/26935504',
    'https://ices-library.figshare.com/articles/report/Report_of_the_Working_Group_on_Elasmobranch_Fishes_WGEF_/30137623'),
    collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste('The current 2026 assessment output is verified, but its detailed',
    'production-run input arrays and assessment report were not located. The latest',
    'detailed input basis found (2024) documents aggregate catches, biomass indices,',
    'and length compositions, not the age-disaggregated observations needed to establish',
    'tinyAM readiness. Keep age-input eligibility unresolved until 2026 production inputs',
    'or native files are checked; the age-length model label alone is insufficient.'),
  notes = paste('Northeast Atlantic dgs.27.nea is distinct from the NOAA/DFO Northwest',
    'Atlantic spiny dogfish unit despite sharing Squalus acanthias. The 2025 WGEF report',
    'states that the assessment was not updated during that meeting and advice was due',
    'in 2026. The current 2026 SAG has assessment key 25850 and terminal historical year',
    '2025. The 2024 advice text cache is extracted from the original official PDF. The',
    'source manifest points to shared cached WGEF 2024 and 2025 PDFs to avoid duplicate',
    'large files. No canonical records were added and no tinyAM translation was attempted.')
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
  stop('Spurdog candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES dgs.27.nea; age-input eligibility remains unresolved.\n')

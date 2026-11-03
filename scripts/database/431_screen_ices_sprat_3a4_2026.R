root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_sprat_3a4_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:spr.27.3a4'
unit_id <- 'ices_sprat_3a4'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
expected_files <- c('ICES_advice_2026_4079.html',
  'ICES_source_data_2026_key_21311.html', 'ICES_charts_2026_key_21311.html',
  'TAF_data.R', 'TAF_DATA.bib', 'TAF_published_tree.json',
  'TAF_published_commit.json', '../discovery_ices_sprat_7de_2026/HAWG_2026.pdf')
manifest_rows <- match(expected_files, manifest$file)
if (nrow(manifest) != length(expected_files) || anyNA(manifest_rows) ||
    anyDuplicated(manifest$file) || any(manifest$retrieved_on[manifest_rows] != '2026-10-30'))
  stop('The cached source manifest is incomplete or inconsistent.', call. = FALSE)
paths <- file.path(cache, manifest$file[manifest_rows])
if (any(!file.exists(paths)) ||
    !identical(as.numeric(manifest$bytes[manifest_rows]), as.numeric(file.info(paths)$size)) ||
    !identical(manifest$sha256[manifest_rows],
      unname(vapply(paths, sha256_file, character(1L)))))
  stop('Cached ICES sources do not match their manifest.', call. = FALSE)

read_source <- function(name) paste(readLines(file.path(cache, name),
  warn = FALSE, encoding = 'UTF-8'), collapse = ' ')
advice <- read_source('ICES_advice_2026_4079.html')
source_data <- read_source('ICES_source_data_2026_key_21311.html')
charts <- read_source('ICES_charts_2026_key_21311.html')
taf_data <- read_source('TAF_data.R')
taf_bib <- read_source('TAF_DATA.bib')
taf_tree <- read_source('TAF_published_tree.json')

if (!all(vapply(c('spr.27.3a4', '2026', '82 822'), grepl, logical(1L),
    x = advice, ignore.case = TRUE)) ||
    !all(vapply(c('21311', '2026', 'Recruitment', 'SSB', 'Landings',
      'Fishing pressure', 'tonnes', 'thousands'), grepl, logical(1L),
      x = source_data, ignore.case = TRUE)) ||
    !grepl('2025', charts, fixed = TRUE))
  stop('Cached advice and Stock Assessment Graphs do not match the reviewed unit.', call. = FALSE)

required_taf <- c('getDataSMS(wd', 'maxage <- 3', 'years = 1980:2025',
  'survey.age = list(0:3, 1:3, 1:3)',
  'survey.years = list(1982:2025, 1992:2025, 2006:2025)',
  "survey.names = c('IBTS_Q1','IBTS_Q3', 'HERAS')",
  "df_to_matrix(dat[['canum']], season =  1:2)",
  'surveyStart = c(0,0.17,0)', 'surveyEnd =  c(.5,.33,0.17)',
  'surveySeason = c(2,1,1)', "mtrx = dat[['mtrx']]")
if (!all(vapply(required_taf, grepl, logical(1L), x = taf_data, fixed = TRUE)) ||
    !grepl('access     = {Public}', taf_bib, fixed = TRUE) ||
    !grepl('source     = {folder}', taf_bib, fixed = TRUE) ||
    !grepl('2026_spr.27.3a4_assessment/data.R', taf_tree, fixed = TRUE) ||
    grepl('2026_spr.27.3a4_assessment/boot/initial/data/', taf_tree, fixed = TRUE) ||
    grepl('2026_spr.27.3a4_assessment/boot/data/', taf_tree, fixed = TRUE))
  stop('Published TAF code or input-file availability changed; review this screen.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id) != 1L ||
    register$official_stock_id[row] != 'spr.27.3a4' ||
    register$scientific_name[row] != 'Sprattus sprattus' ||
    as.character(register$inventory_assessment_year[row]) != '2026' ||
    register$assessment_area[row] != 'Greater North Sea' ||
    any(tolower(stocks$authority_stock_id) == 'spr.27.3a4', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$assessment_id, inputs$assessment_id,
      outputs$assessment_id), na.rm = TRUE))
  stop('ICES sprat identity conflicts with the candidate register or canonical database.', call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (!initial && !reviewed)
  stop('ICES sprat already has a conflicting prior review.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id, matched_stock_id = '', match_status = 'new',
  screening_status = 'screened', eligibility = 'unresolved', import_status = 'not_started',
  catch_age_evidence = paste(
    'The current 2026 TAF processing script constructs seasonal catch numbers-at-age from the SMS data folder,',
    'for ages 0-3 and years 1980-2025. The published repository contains the script and a DATA.bib entry',
    'declaring a public folder source, but its snapshot has no input-data folder or numeric catch-at-age values;',
    'the observed series and units could not be verified.'),
  survey_age_evidence = paste(
    'The 2026 TAF script specifies age-specific IBTS_Q1 observations for ages 0-3 (1982-2025),',
    'IBTS_Q3 for ages 1-3 (1992-2025), and HERAS for ages 1-3 (2006-2025). Numeric survey inputs',
    'and associated age compositions are absent from the published repository snapshot.'),
  weights_evidence = paste(
    'The script passes an SMS biological matrix containing M, maturity, and weight fields to the model setup.',
    'The numeric matrix is not in the published repository snapshot, so weights, units, and coverage are unverified.'),
  maturity_evidence = paste(
    'The script passes maturity data in the SMS biological matrix, but no numeric maturity-at-age file is',
    'present in the published repository snapshot.'),
  mortality_evidence = paste(
    'The 2026 HAWG report says updated natural mortality from the 2023 multispecies SMS key run revised sprat',
    'reference points. The TAF script passes M in the biological matrix, but the numeric M surface and exact',
    'run-specific values are absent from the published repository snapshot.'),
  timing_evidence = paste(
    'The TAF script declares survey starts 0, 0.17, 0; ends 0.50, 0.33, 0.17; and model seasons 2, 1, 1',
    'for IBTS_Q1, IBTS_Q3, and HERAS. These are script settings; the referenced numeric survey inputs remain',
    'unavailable in that repository snapshot.'),
  output_evidence = paste(
    'The 2026 Stock Assessment Graphs provide annual age-0 recruitment (thousands), SSB (tonnes), landings,',
    'and F for ages 1-2 through 2025, with uncertainty bounds for recruitment, SSB, and F. HAWG reports',
    '2025 SSB 199,809 tonnes and F1-2 1.51. The reviewed graph tables do not report N-at-age or a full',
    'F-at-age surface.'),
  detailed_source_url = paste(
    'https://asd.ices.dk/viewAdvice/4079;',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21311;',
    'https://standardgraphs.ices.dk/ViewCharts.aspx?key=21311;',
    'https://github.com/ices-advice/2026_spr.27.3a4/tree/51bd58e56d3d9623626b6b0a0a47028f095cc0e1/2026_spr.27.3a4_assessment;',
    'https://backend.orbit.dtu.dk/ws/portalfiles/portal/440308463/HAWG_2026_-_Full_Report.pdf',
    sep = ' '),
  review_date = '2026-10-30',
  decision_reason = paste(
    'The current stock is age-assessed and the published TAF script specifies catch-at-age and three age-specific',
    'survey series. However, the public repository snapshot omits its referenced numeric input folder, preventing',
    'verification of source values, units, coverage, and biological matrices. The TAF repository proxy returned',
    'HTTP 401 to unauthenticated file requests. Keep eligibility unresolved until run-specific inputs can be',
    'accessed and checked; do not create canonical numerical records from code or aggregate outputs.'),
  notes = paste(
    'Current ICES assessment year 2026, advice record 4079, Stock Assessment Graphs key 21311. The public TAF',
    'output commit is 51bd58e56d3d9623626b6b0a0a47028f095cc0e1; its data.R script is pinned in the source cache',
    'manifest. The HAWG 2026 report is shared with the English Channel sprat cache to avoid duplicate storage.',
    'Numeric TAF inputs have not been reconstructed. No canonical data were added and no tinyAM translation was attempted.')
)

same_review <- all(vapply(names(review), function(column)
  identical(as.character(register[[column]][row]), as.character(review[[column]])),
  logical(1L)))
if (!initial && !same_review)
  stop('ICES sprat candidate contents conflict with this screen.', call. = FALSE)
for (column in names(review)) register[[column]][row] <- review[[column]]

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened ICES sprat 3.a4 as eligibility unresolved pending numeric TAF input access; no canonical values were added.\n')

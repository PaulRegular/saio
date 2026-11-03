root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_caribbean_queen_triggerfish_2024')
review_date <- '2026-11-02'

spec <- data.frame(
  stock_id = c('15496', '15558', '15649'),
  assessment_id = c('14112', '14110', '12844'),
  assessment_year = c(2024L, 2024L, 2022L),
  last_data_year = c(2019L, 2019L, 2019L),
  area = c('St. Thomas / St. John', 'St. Croix', 'Puerto Rico'),
  unit_id = c('noaa_queen_triggerfish_st_thomas_st_john',
    'noaa_queen_triggerfish_st_croix', 'noaa_queen_triggerfish_puerto_rico'),
  report = c('St. Thomas and St. John 2024 report', 'St. Croix 2024 report',
    'Puerto Rico 2022 report'),
  stringsAsFactors = FALSE
)

expected_files <- c('st_thomas_st_john_queen_triggerfish_sar_2024.pdf',
  'st_croix_queen_triggerfish_sar_2024.pdf',
  'puerto_rico_queen_triggerfish_sar_2022.pdf',
  'queen_triggerfish_framework_action_3_2025.pdf',
  'queen_triggerfish_final_rule_2026.pdf')
expected_hashes <- c(
  'da12fd6f24dabee1150487f7e25f949471e8db317c3f7545d19bc20d7771e2ed',
  'e4f05348dc5b5803629cd681d680e22bc4882677fdf8c011365ca4d63e7cc3ab',
  'd5557da4c477387837d21019516c2d2689c2e0e1ea66c1c259c6f59434b1033b',
  'f01f43d26f9eb95d01badf8e6010ec440074a4ffbdee382b9dff184036cc0ecb',
  '1ec9ff00c407c6483eccc542e7b95f6a5a90a91062c89dc8aa23259fdaeece01'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (nrow(manifest) != length(expected_files) ||
    !identical(manifest$file, expected_files) ||
    !identical(tolower(manifest$sha256), expected_hashes) ||
    any(manifest$retrieval_date != review_date))
  stop('Queen triggerfish source provenance does not match the reviewed snapshot.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached queen triggerfish source.', call. = FALSE)
  hashes
}
for (i in seq_along(expected_files)) {
  path <- file.path(cache, expected_files[i])
  if (!file.exists(path) || !identical(sha256_file(path), expected_hashes[i]))
    stop('A cached queen triggerfish source does not match its manifest: ',
      expected_files[i], call. = FALSE)
  con <- file(path, 'rb')
  header <- readBin(con, 'raw', 5L)
  close(con)
  if (!identical(header, charToRaw('%PDF-')))
    stop('A cached queen triggerfish source is not a PDF: ', expected_files[i], call. = FALSE)
}

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), metadata_env)
stocksmart <- metadata_env$stock_assessment_summary
for (i in seq_len(nrow(spec))) {
  assessment <- stocksmart[as.character(stocksmart$assessment_id) == spec$assessment_id[i], , drop = FALSE]
  if (nrow(assessment) != 1L ||
      as.character(assessment$stock_id) != spec$stock_id[i] ||
      assessment$scientific_name != 'Balistes vetula' ||
      as.integer(assessment$assessment_year) != spec$assessment_year[i] ||
      as.integer(assessment$last_data_year) != spec$last_data_year[i] ||
      assessment$assessment_model != 'SS' ||
      assessment$review_result != 'Full acceptance')
    stop('The pinned NOAA Stock SMART assessment changed for stock ', spec$stock_id[i], '.', call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
if (any(stocks$scientific_name == 'Balistes vetula', na.rm = TRUE))
  stop('Queen triggerfish already has a canonical stock record.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
source_urls <- paste(manifest$url, collapse = '; ')
for (i in seq_len(nrow(spec))) {
  candidate_id <- paste0('NOAA:', spec$stock_id[i])
  row_index <- match(candidate_id, candidates$candidate_id)
  if (is.na(row_index) ||
      candidates$scientific_name[row_index] != 'Balistes vetula' ||
      candidates$assessment_area[row_index] != spec$area[i] ||
      as.integer(candidates$inventory_assessment_year[row_index]) != spec$assessment_year[i])
    stop('Queen triggerfish inventory identity changed for ', candidate_id, '.', call. = FALSE)
  if (any(candidates$candidate_unit_id[-row_index] == spec$unit_id[i], na.rm = TRUE) ||
      any(assessments$assessment_id == spec$unit_id[i], na.rm = TRUE) ||
      any(inputs$assessment_id == spec$unit_id[i], na.rm = TRUE) ||
      any(outputs$assessment_id == spec$unit_id[i], na.rm = TRUE))
    stop('Queen triggerfish unit overlaps an existing candidate or database record.', call. = FALSE)

  row <- candidates[row_index, , drop = FALSE]
  row$candidate_unit_id <- spec$unit_id[i]
  row$matched_stock_id <- ''
  row$match_status <- 'new'
  row$screening_status <- 'screened'
  row$eligibility <- 'ineligible'
  row$import_status <- 'not_started'
  row$catch_age_evidence <- paste0(
    spec$report[i], ' reports aggregate landings/removals, but no fishery age-composition matrix. ',
    'For both USVI stocks, the report states that samples were insufficient for a reliable age-length key or representative population/fleet age compositions. ',
    'For Puerto Rico, the report states historical age-composition samples were not collected. Catch-at-age is therefore unavailable.')
  row$survey_age_evidence <- paste0(
    'The assessment uses aggregate abundance indices and/or reef visual census density with length compositions. ',
    'The reports state no fishery-independent age compositions were available; no age-specific survey index was verified.')
  row$weights_evidence <- paste0(
    'The reports document growth and length-weight inputs used inside Stock Synthesis, but a recoverable annual weight-at-age observation series was not identified. ',
    'This does not supply the missing observed age compositions.')
  row$maturity_evidence <- paste0(
    'Life-history and maturity assumptions are documented in the assessment report; a standalone numeric maturity-at-age input series was not recovered in the public model files.')
  row$mortality_evidence <- paste0(
    'The reports describe fixed natural-mortality assumptions, including an age-dependent Lorenzen schedule for the USVI models; no native model input files were identified.')
  row$timing_evidence <- paste0(
    'The assessment uses annual observations. A within-year timing fraction for the aggregate index observations was not verified.')
  row$output_evidence <- paste0(
    'The reports show estimated biomass/SSB, recruitment, fishing mortality, and predicted numbers at age in figures. ',
    'The age-based outputs are not published as recoverable numerical age-by-year tables in the reviewed report bundle.')
  row$detailed_source_url <- paste(source_urls,
    'https://www.federalregister.gov/documents/2026/03/18/2026-05251/fisheries-of-the-caribbean-gulf-of-america-and-south-atlantic-fishery-management-plans-of-st-croix',
    sep = '; ')
  row$review_date <- review_date
  row$decision_reason <- paste0(
    spec$report[i], ' is the latest fully accepted production assessment listed in NOAA Stock SMART (data through 2019). ',
    if (spec$stock_id[i] == '15649') 'The Puerto Rico assessment was reviewed in 2022 and remains the latest fully accepted production run. ' else 'The USVI 2024 follow-up assessments were found suitable for short-term management advice by the Council SSC in April 2024. ',
    'Although Stock Synthesis estimates age-based population quantities, the reviewed assessments lack age-composition observations and age-specific abundance inputs required for this database. ',
    'Classified ineligible for age-structured source curation.')
  row$notes <- paste0(
    'Keep Puerto Rico, St. Croix, and St. Thomas/St. John as separate management units. ',
    'The earlier 2022 USVI assessment records were not accepted; the 2024 follow-up assessment records are the relevant current USVI production runs. ',
    'No canonical stock, assessment, input, or output records were added.')
  current <- candidates[row_index, names(row), drop = FALSE]
  same <- all(vapply(names(row), function(name) {
    x <- current[[name]]
    y <- row[[name]]
    if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
  }, logical(1L)))
  initial <- candidates$match_status[row_index] == 'unreviewed' &&
    candidates$screening_status[row_index] == 'not_started' &&
    candidates$eligibility[row_index] == 'unresolved' &&
    candidates$import_status[row_index] == 'not_started' &&
    (is.na(candidates$candidate_unit_id[row_index]) ||
      !nzchar(candidates$candidate_unit_id[row_index]))
  reviewed <- candidates$candidate_unit_id[row_index] == spec$unit_id[i] &&
    candidates$match_status[row_index] == 'new' &&
    candidates$screening_status[row_index] == 'screened' &&
    candidates$eligibility[row_index] == 'ineligible' &&
    candidates$import_status[row_index] == 'not_started'
  if (!same && !initial && !reviewed)
    stop('Unexpected existing candidate state for ', candidate_id, '.', call. = FALSE)
  if (!same) {
    for (name in names(row)) candidates[[name]][row_index] <- row[[name]]
    replace_candidate_register_row(register_path, row_index,
      candidates[row_index, , drop = FALSE], candidate_id)
  }
}
source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened three NOAA queen triggerfish management units; all lack age-composition inputs required for age-structured source curation.\n')

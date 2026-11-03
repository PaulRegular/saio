root <- "."
cache <- file.path(root, 'source_cache', 'noaa_far_north_chinook_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$assessment_id) == '13942', , drop = FALSE]
if (nrow(assessment) != 1L ||
    as.character(assessment$stock_id) != '10604' ||
    as.integer(assessment$assessment_year) != 2024L ||
    as.integer(assessment$last_data_year) != 2024L ||
    as.character(assessment$stock_name) !=
      'Chinook salmon - Eastern North Pacific Far North Migrating' ||
    as.character(assessment$assessment_model) != 'Chinook model' ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    as.character(assessment$assessment_type) != 'Operational' ||
    as.character(assessment$jurisdiction) != 'NPFMC' ||
    as.integer(assessment$model_category) != 2L ||
    as.integer(assessment$catch_input_data) != 5L ||
    as.integer(assessment$abundance_input_data) != 5L ||
    as.integer(assessment$biological_input_data) != 3L ||
    as.integer(assessment$composition_input_data) != 0L)
  stop('NOAA Stock SMART metadata do not match the reviewed Far North Migrating Chinook assessment.',
    call. = FALSE)

files <- c('Status_Salmon_Stocks_FMP_2024.pdf',
  'NOAA_Q4_2025_Stock_Status_Tables.pdf', 'StockSMART_DataDictionary.pdf')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (!all(files %in% manifest$file) ||
    !all(file.exists(file.path(cache, files))) ||
    anyNA(manifest$sha256[match(files, manifest$file)]) ||
    !all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])) ||
    anyNA(manifest$url[match(files, manifest$file)]))
  stop('The Far North Migrating Chinook source cache is incomplete.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10604'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one Far North Migrating Chinook Stock SMART row.', call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_chinook_10604',
  assessment_area = 'Eastern North Pacific Far North Migrating',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2024 assessment has catch_input_data = 5, which classifies total-catch completeness,',
    'not catch-at-age. Composition Input Data is 0. The detailed 2024 status report reports',
    'all-gear catch and five-year catch sums, with no catch-at-age or age-composition series.'),
  survey_age_evidence = paste('Stock SMART classifies the assessment as model category 2 (index-based) and gives',
    'abundance_input_data = 5, but no age-specific abundance-index observations are supplied.',
    'The reviewed status report uses escapement and catch aggregates for management status.'),
  weights_evidence = paste('Biological Input Data is rated 3 in Stock SMART, but no annual weight-at-age',
    'surface is reported in the current status assessment sources.'),
  maturity_evidence = paste('No maturity-at-age schedule used by the index-based assessment is reported.'),
  mortality_evidence = paste('The production status analysis reports five-year all-gear catch relative to',
    'catch limits; it does not report age-specific fishing mortality or natural mortality inputs.'),
  timing_evidence = paste('No age-specific survey observation series or within-year survey timing is reported.'),
  output_evidence = paste('The latest detailed report provides management status summaries, including pooled',
    'five-year productive capacity across 22 Pacific Salmon Commission indicator stocks, rather',
    'than a population surface for this Stock SMART unit. The Q4 2025 NOAA status table lists',
    'no overfishing and no overfished status. No N-at-age, F-at-age, or M-at-age output was found.'),
  detailed_source_url = paste(
    'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10339;',
    'https://www.fisheries.noaa.gov/s3/2026-02/FINAL-Q4-2025-Stock-Status-Tables.pdf;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10604;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf'),
  review_date = review_date,
  decision_reason = paste('The latest detailed full-acceptance operational Stock SMART record is assessment',
    '13942 (2024, data through 2024). NOAA classifies it as index-based (model category 2)',
    'with no composition data reported for the assessment. The 2024 detailed report and Q4 2025',
    'status update provide aggregate management-status information, not the age-specific inputs',
    'the unit is ineligible for the age-structured set.'),
  notes = paste('The named Far North Migrating reporting unit is not a single named river stock and',
    'overlaps broadly with multiple transboundary and coastwide Chinook populations; no one-to-one',
    'match to a canonical DFO or NOAA river stock is supported. The detailed 2024 status report',
    'uses East Area pooled Chinook criteria, including productive capacity aggregated across 22',
    'PSC indicator stocks. Stock SMART’s catch and abundance ratings do not provide age-indexed',
    'vectors. No canonical assessment, input, or output rows were added.'),
  stringsAsFactors = FALSE)

current <- candidates[i, names(row), drop = FALSE]
same <- all(vapply(names(row), function(name) {
  x <- current[[name]]
  y <- row[[name]]
  if (is.na(x)) is.na(y) else !is.na(y) &&
    identical(as.character(x), as.character(y))
}, logical(1L)))
if (!same) {
  pristine <- candidates$match_status[i] == 'unreviewed' &&
    candidates$screening_status[i] == 'not_started' &&
    candidates$eligibility[i] == 'unresolved' &&
    candidates$import_status[i] == 'not_started' &&
    (is.na(candidates$candidate_unit_id[i]) ||
      !nzchar(candidates$candidate_unit_id[i]))
  if (!pristine)
    stop('Unexpected existing review state for NOAA:10604.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA Far North Migrating Chinook ID 10604 as ineligible for the age-disaggregated candidate set.\n')
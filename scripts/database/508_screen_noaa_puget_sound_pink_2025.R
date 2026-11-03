root <- "."
cache <- file.path(root, 'source_cache', 'noaa_puget_sound_pink_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$assessment_id) == '14157', , drop = FALSE]
if (nrow(assessment) != 1L ||
    as.character(assessment$stock_id) != '10576' ||
    as.integer(assessment$assessment_year) != 2025L ||
    as.integer(assessment$last_data_year) != 2024L ||
    as.character(assessment$assessment_model) != 'CSA (Collie Sissenwine)' ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    as.character(assessment$assessment_type) != 'Operational' ||
    as.character(assessment$jurisdiction) != 'PFMC' ||
    as.integer(assessment$model_category) != 3L ||
    as.integer(assessment$composition_input_data) != 3L)
  stop('NOAA Stock SMART metadata do not match the reviewed Puget Sound pink salmon assessment.',
    call. = FALSE)

files <- c('Review_2024_Ocean_Salmon_Fisheries.pdf',
  'Preseason_I_2025_Ocean_Salmon_Fisheries.pdf',
  'PFMC_Historical_Escapements_Appendix_B.xlsx')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (!all(files %in% manifest$file) ||
    !all(file.exists(file.path(cache, files))) ||
    anyNA(manifest$sha256[match(files, manifest$file)]) ||
    !all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])))
  stop('The Puget Sound pink salmon source cache is incomplete.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10576'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one Puget Sound pink salmon Stock SMART register row.',
    call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_puget_sound_pink_salmon',
  assessment_area = 'Puget Sound; odd-year pink salmon run',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The PFMC historical Appendix B workbook and 2024 SAFE, Table B-43,',
    'report commercial net catches by odd year, management subregion, hatchery/natural',
    'origin, and total, in numbers of fish. They do not report catch-at-age or an age',
    'composition series for this assessment.'),
  survey_age_evidence = paste('The 2025 Preseason Report I reports total Puget Sound run-size',
    'forecasts and actuals, not an age-specific abundance index. The reviewed sources',
    'do not provide age-specific survey observations.'),
  weights_evidence = paste('The reviewed current assessment sources do not provide an',
    'age-specific weight series or annual weights-at-age input.'),
  maturity_evidence = paste('The reviewed current assessment sources do not provide an',
    'age-specific maturity schedule used in the aggregate assessment.'),
  mortality_evidence = paste('Stock SMART classifies the assessment as model category 3,',
    'aggregate biomass dynamics. The reviewed production sources do not report age-specific',
    'natural or fishing mortality inputs.'),
  timing_evidence = paste('The reported run-size forecast and catch/escapement summaries are',
    'aggregate annual quantities; no within-year timing for an age-specific survey is reported.'),
  output_evidence = paste('The current materials report odd-year aggregate run-size actuals and',
    'forecasts, and subregion-level catch and escapement summaries. Stock SMART reports a',
    '2023 biomass value of 7,222,610 under the basis “Adult Spawners - Natural Escapement”;',
    'the PFMC report gives the same numeric value as total run size, so its basis needs',
    'reconciliation. No N-at-age, F-at-age, or M-at-age outputs were found.'),
  detailed_source_url = paste(
    'https://www.pcouncil.org/documents/2025/02/review-of-2024-ocean-salmon-fisheries.pdf/;',
    'https://www.pcouncil.org/documents/2025/03/2025-preseason-report-i.pdf/;',
    'https://www.pcouncil.org/documents/escapements-to-inland-fisheries-and-spawning-areas-salmon-review-appendix-b-excel-file-format/;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10576;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf'),
  review_date = review_date,
  decision_reason = paste('The latest full-acceptance operational Stock SMART record is',
    'assessment 14157 (2025, data through 2024). NOAA classifies its method as aggregate',
    'biomass dynamics (model category 3), and the available PFMC production materials',
    'report total run-size forecasts and aggregate catch/escapement, not age-disaggregated',
    'assessment inputs or population outputs. It is therefore ineligible for the age-structured',
    'comparison set.'),
  notes = paste('Stock SMART reports composition_input_data = 3, an availability category',
    'for composition information; this does not supply a recoverable age-specific series or',
    'change the aggregate model category. The reported 2023 biomass value has a basis',
    'discrepancy with the PFMC total-run figure and is not imported. No canonical numerical',
    'assessment records were added.'),
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
    stop('Unexpected existing review state for NOAA:10576.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA Puget Sound pink salmon ID 10576 as ineligible for the age-disaggregated candidate set.\n')

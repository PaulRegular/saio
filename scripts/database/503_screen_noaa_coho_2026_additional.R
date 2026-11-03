root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_coho_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_ids <- paste0('NOAA:', c(11869L, 11874L, 11875L))
stock_ids <- c(11869L, 11874L, 11875L)
assessment_ids <- c(14551L, 14537L, 14553L)
unit_ids <- paste0('noaa_coho_', stock_ids)
today <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessments <- stocksmart[as.character(stocksmart$stock_id) %in% as.character(stock_ids) &
  as.character(stocksmart$assessment_id) %in% as.character(assessment_ids), , drop = FALSE]
assessment_order <- match(assessment_ids, as.integer(assessments$assessment_id))
assessments <- assessments[assessment_order, , drop = FALSE]
if (nrow(assessments) != length(stock_ids) || anyNA(assessment_order) ||
    !identical(as.integer(assessments$stock_id), stock_ids) ||
    !identical(as.integer(assessments$assessment_year), rep(2026L, 3L)) ||
    !identical(as.integer(assessments$last_data_year), rep(2025L, 3L)) ||
    !all(assessments$jurisdiction == 'PFMC') ||
    !all(assessments$assessment_model == 'Cohort Analysis') ||
    !all(as.character(assessments$review_result) == 'Full acceptance') ||
    !all(as.integer(assessments$composition_input_data) == 3L))
  stop('NOAA Stock SMART metadata does not match the reviewed coho records.',
    call. = FALSE)

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
required_sources <- c('Preseason_Report_I_2026.pdf',
  'Review_of_2025_Ocean_Salmon_Fisheries.pdf', 'Coho_FRAM_Model_Detail_2023.html')
if (!all(required_sources %in% manifest$file))
  stop('The NOAA coho source cache is incomplete.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (anyDuplicated(candidates$candidate_id) ||
    any(vapply(candidate_ids, function(id) sum(candidates$candidate_id == id) != 1L,
      logical(1L))))
  stop('Expected one unique candidate row for each additional NOAA coho ID.',
    call. = FALSE)

evidence <- list(
  catch_age_evidence = paste0(
    'Stock SMART rates composition-input data at level 3, but the current PFMC coho ',
    'sources do not publish annual fishery age-composition or catch-at-age vectors. ',
    'Coho FRAM represents one adult age class (age 3), not a multi-age assessment.'),
  survey_age_evidence = paste0(
    'The current PFMC reports provide adult-run forecasts and fishery impacts; ',
    'they do not provide a multi-age survey abundance series. Coho FRAM has one ',
    'age-3 cohort and is not a survey-indexed population assessment.'),
  weights_evidence = paste0(
    'The reviewed single-age coho forecast does not provide a multi-age ',
    'weight-at-age surface for an age-structured assessment.'),
  maturity_evidence = paste0(
    'Coho FRAM does not model maturation by age; the reviewed current sources ',
    'do not provide a maturity-at-age surface for a multi-age assessment.'),
  mortality_evidence = paste0(
    'FRAM uses time-period natural mortality for its age-3 fishery accounting; ',
    'it does not report an age-specific population mortality surface.'),
  timing_evidence = paste0(
    'The five FRAM time periods describe fishery accounting periods, not a ',
    'fractional sampling time for an age-specific abundance index.'),
  output_evidence = paste0(
    'The 2026 PFMC reports provide adult-run forecasts, escapement and fishery ',
    'impacts. They do not provide a multi-age N/F/M population output series.'),
  detailed_source_url = paste(
    'https://www.pcouncil.org/documents/2026/03/preseason-report-1-stock-abundance-analysis-and-environmental-assessment-part-1-for-2026-ocean-salmon-fishery-regulations.pdf/;',
    'https://www.pcouncil.org/documents/2026/02/review-of-2025-ocean-salmon-fisheries.pdf/;',
    'https://framverse.github.io/fram_doc/calcs_data_coho.html;',
    'https://framverse.github.io/fram_doc/apps_coho.html'))

for (j in seq_along(candidate_ids)) {
  i <- match(candidate_ids[j], candidates$candidate_id)
  row <- data.frame(
    candidate_unit_id = unit_ids[j], matched_stock_id = NA_character_,
    match_status = 'new', screening_status = 'screened',
    eligibility = 'ineligible', import_status = 'not_started',
    catch_age_evidence = evidence$catch_age_evidence,
    survey_age_evidence = evidence$survey_age_evidence,
    weights_evidence = evidence$weights_evidence,
    maturity_evidence = evidence$maturity_evidence,
    mortality_evidence = evidence$mortality_evidence,
    timing_evidence = evidence$timing_evidence,
    output_evidence = evidence$output_evidence,
    detailed_source_url = evidence$detailed_source_url,
    review_date = today,
    decision_reason = paste0(
      'The latest full-acceptance PFMC coho assessment is the 2026 operational ',
      'run using data through 2025. The current assessment sources and Coho FRAM ',
      'documentation describe one age-3 adult cohort and fishery forecasting, ',
      'not multi-age population inputs and outputs. Stock SMART composition ',
      'scores do not supply the underlying age vectors. Screen ineligible for ',
      'the multi-age assessment set.'),
    notes = paste0('NOAA Stock SMART ID ', stock_ids[j],
      ' remains a separate U.S. coho candidate unit; it is not merged with the ',
      'other NOAA or DFO coho units. No canonical numerical records were added.'),
    stringsAsFactors = FALSE)

  current <- candidates[i, names(row), drop = FALSE]
  same <- all(vapply(names(row), function(n) {
    x <- current[[n]]; y <- row[[n]]
    if (is.na(x)) is.na(y) else !is.na(y) && identical(as.character(x), as.character(y))
  }, logical(1L)))
  if (!same) {
    pristine <- candidates$match_status[i] == 'unreviewed' &&
      candidates$screening_status[i] == 'not_started' &&
      candidates$eligibility[i] == 'unresolved' &&
      (is.na(candidates$candidate_unit_id[i]) ||
        !nzchar(candidates$candidate_unit_id[i]))
    if (!pristine)
      stop('Unexpected existing NOAA coho review state for ', candidate_ids[j], '.',
        call. = FALSE)
    for (n in names(row)) candidates[[n]][i] <- row[[n]]
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, i,
      candidates[i, , drop = FALSE], candidate_ids[j])
    candidates <- read.csv(register_path, stringsAsFactors = FALSE,
      na.strings = c('', 'NA'), check.names = FALSE)
  }
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened three additional NOAA coho rows as single-age forecast units.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_puget_sound_chinook_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
stock_ids <- c(10605L, 10606L, 10607L, 10609L, 10611L, 10612L, 10613L,
  10614L, 10615L, 10616L, 10617L, 10618L, 10620L, 10621L, 10622L,
  10623L, 10624L, 10626L, 10627L, 10628L, 10629L, 10630L, 10631L,
  10632L, 10633L, 10634L, 11034L, 11035L, 11870L, 11872L)
assessment_ids <- c(14490L, 14491L, 14492L, 14505L, 14507L, 14506L,
  14496L, 14493L, 14494L, 14503L, 14495L, 14499L, 14497L, 14498L,
  14500L, 14502L, 14501L, 14521L, 14522L, 14530L, 14526L, 14527L,
  14523L, 14524L, 14528L, 14529L, 14531L, 14532L, 14511L, 14514L)
candidate_ids <- paste0('NOAA:', stock_ids)
unit_ids <- paste0('noaa_chinook_', stock_ids)
today <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessments <- stocksmart[
  as.integer(stocksmart$stock_id) %in% stock_ids &
    as.integer(stocksmart$assessment_id) %in% assessment_ids, , drop = FALSE]
assessment_order <- match(assessment_ids, as.integer(assessments$assessment_id))
assessments <- assessments[assessment_order, , drop = FALSE]
if (nrow(assessments) != length(stock_ids) || anyNA(assessment_order) ||
    !identical(as.integer(assessments$stock_id), stock_ids) ||
    !identical(as.integer(assessments$assessment_year), rep(2026L, 30L)) ||
    !identical(as.integer(assessments$last_data_year), rep(2025L, 30L)) ||
    !all(assessments$jurisdiction == 'PFMC') ||
    !all(as.character(assessments$review_result) == 'Full acceptance') ||
    !all(assessments$final_assessment_report_1 ==
      'REVIEW OF 2025 OCEAN SALMON FISHERIES'))
  stop('NOAA Stock SMART metadata do not match the reviewed PFMC Chinook records.',
    call. = FALSE)

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
required_sources <- c('Preseason_Report_I_2026.pdf', 'Preseason_Report_II_2026.pdf',
  'Preseason_Report_III_2026.pdf', 'Review_of_2025.pdf',
  'StockSMART_DataDictionary.pdf', 'Chinook_FRAM_Model_Detail_2023.html',
  'Chinook_FRAM_Applications_2023.html', 'Chinook_FRAM_Appendices_2023.html')
cached_sources <- file.path(cache, required_sources)
if (!all(required_sources %in% manifest$file) || !all(file.exists(cached_sources)) ||
    anyNA(manifest$sha256[match(required_sources, manifest$file)]) ||
    !all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(required_sources,
      manifest$file)])))
  stop('The NOAA PFMC Chinook source cache is incomplete.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (anyDuplicated(candidates$candidate_id) ||
    any(vapply(candidate_ids, function(id) sum(candidates$candidate_id == id) != 1L,
      logical(1L))))
  stop('Expected one unique candidate row for each PFMC Chinook stock ID.',
    call. = FALSE)

for (j in seq_along(candidate_ids)) {
  i <- match(candidate_ids[j], candidates$candidate_id)
  model <- as.character(assessments$assessment_model[j])
  model_category <- as.character(assessments$model_category[j])
  composition_level <- as.character(assessments$composition_input_data[j])
  catch_level <- as.character(assessments$catch_input_data[j])
  abundance_level <- as.character(assessments$abundance_input_data[j])
  biology_level <- as.character(assessments$biological_input_data[j])
  age_input_evidence <- paste0(
    'NOAA Stock SMART assessment ', assessment_ids[j],
    ' is a full-acceptance PFMC 2026 run using data through 2025. Its model ',
    'label is ', model, ' (Model Category ', model_category,
    '); its composition, catch, abundance, and biological input scores are ',
    composition_level, ', ', catch_level, ', ', abundance_level, ', and ',
    biology_level, '. These are summary scores, not the underlying observation vectors. ',
    'The reviewed public PFMC reports do not publish this unit’s annual catch-at-age vector.')
  survey_evidence <- paste0(
    'The 2026 PFMC reports publish stock forecasts and fishery-management ',
    'indicators, but no annual age-specific survey index was located for this ',
    'unit. The Stock SMART abundance-input score is not the abundance series.')
  biology_evidence <- paste0(
    'The Stock SMART biological-input score is ', biology_level,
    '; no run-specific weight-at-age or maturity-at-age vectors for this unit ',
    'were exposed in the reviewed public reports.')
  mortality_evidence <- paste0(
    'The reviewed PFMC reports do not expose this unit’s run-specific natural-',
    'mortality assumption or age-specific M surface.')
  timing_evidence <- paste0(
    'The reviewed public reports do not describe a within-year sampling time ',
    'for an age-specific abundance index for this unit.')
  output_evidence <- paste0(
    'The current PFMC reports provide official forecast, escapement, and ',
    'fishery-impact information. A complete historical N-at-age, F-at-age, ',
    'and M-at-age population output for this unit was not located.')

  row <- data.frame(
    candidate_unit_id = unit_ids[j], matched_stock_id = NA_character_,
    match_status = 'new', screening_status = 'screened',
    eligibility = 'unresolved', import_status = 'not_started',
    catch_age_evidence = age_input_evidence,
    survey_age_evidence = survey_evidence,
    weights_evidence = biology_evidence,
    maturity_evidence = biology_evidence,
    mortality_evidence = mortality_evidence,
    timing_evidence = timing_evidence,
    output_evidence = output_evidence,
    detailed_source_url = paste(
      'https://www.pcouncil.org/documents/2026/03/preseason-report-1-stock-abundance-analysis-and-environmental-assessment-part-1-for-2026-ocean-salmon-fishery-regulations.pdf/;',
      'https://www.pcouncil.org/documents/2026/03/2026-preseason-report-2.pdf/;',
      'https://www.pcouncil.org/documents/2026/04/preseason-report-iii-2026.pdf/;',
      'https://www.pcouncil.org/documents/2026/02/review-of-2025-ocean-salmon-fisheries.pdf/;',
      'https://framverse.github.io/fram_doc/calcs_data_chin.html'),
    review_date = today,
    decision_reason = paste0(
      'The latest full-acceptance Stock SMART record is assessment ',
      assessment_ids[j], ', a PFMC 2026 run through 2025. Public sources ',
      'provide official forecasts and fishery-management results, while the ',
      'Stock SMART input scores and model category do not provide numeric ',
      'age-specific observations or fitted population outputs. The reviewed ',
      'sources do not resolve whether the underlying age-disaggregated inputs ',
      'for this unit can be recovered; eligibility remains unresolved.'),
    notes = paste0('NOAA Stock SMART ID ', stock_ids[j],
      ' is retained as a distinct U.S. PFMC Chinook candidate unit. No ',
      'canonical numerical records were added.'),
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
      stop('Unexpected existing NOAA PFMC Chinook review state for ',
        candidate_ids[j], '.', call. = FALSE)
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
cat('Screened 30 PFMC Chinook candidates; age-input eligibility remains unresolved.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'noaa_cook_inlet_salmon_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
stock_ids <- 17337:17341
assessment_ids <- c(14570L, 14575L, 14574L, 14573L, 14572L)
review_date <- '2026-11-01'

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
    !identical(as.integer(assessments$assessment_year), rep(2026L, 5L)) ||
    !identical(as.integer(assessments$last_data_year), rep(2024L, 5L)) ||
    !all(assessments$jurisdiction == 'NPFMC') ||
    !all(as.character(assessments$review_result) == 'Full acceptance') ||
    !all(assessments$final_assessment_report_1 ==
      'Stock Assessment and Fishery Evaluation Report for the Salmon Fisheries of the Cook Inlet Exclusive Economic Zone Area 2026 Final Salmon SAFE'))
  stop('NOAA Stock SMART metadata do not match the reviewed Cook Inlet salmon records.',
    call. = FALSE)

files <- c('CookInletSalmon_2026_Final_SAFE.pdf',
  'FMS24-01_UCI_salmon_escapement_goals.pdf',
  'FMR25-05_UCI_commercial_annual_2023.pdf')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
checksums <- manifest$sha256[match(files, manifest$file)]
if (!all(files %in% manifest$file) ||
    !all(file.exists(file.path(cache, files))) || anyNA(checksums) ||
    !all(grepl('^[[:xdigit:]]{64}$', checksums)))
  stop('The Cook Inlet salmon source cache is incomplete.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_ids <- paste0('NOAA:', stock_ids)
rows <- match(candidate_ids, candidates$candidate_id)
if (anyNA(rows) || anyDuplicated(candidates$candidate_id))
  stop('Expected one candidate-register row per Cook Inlet salmon Stock SMART ID.',
    call. = FALSE)

assessment_areas <- c(
  'Cook Inlet EEZ; Upper Cook Inlet aggregate',
  'Cook Inlet EEZ; Kenai River late run',
  'Cook Inlet EEZ; Kasilof River',
  'Cook Inlet EEZ; aggregate other sockeye',
  'Cook Inlet EEZ; aggregate coho')
candidate_units <- paste0('noaa_uci_salmon_', stock_ids)
eligibility <- c('unresolved', 'unresolved', 'unresolved', 'ineligible',
  'ineligible')
decision_reasons <- c(
  paste('The current final 2026 Cook Inlet SAFE describes an aggregate Tier 3',
    'Chinook assessment based on EEZ harvest and indicator escapement, while',
    'Stock SMART labels its 2026 record Cohort Analysis. The assessment-run',
    'and age-input mapping are unresolved; the SAFE does not report a complete',
    'age-specific population series.'),
  paste('The current official SAFE uses an AR-1 forecast of total Kenai late-run',
    'sockeye returns, not an age-structured population model. ADF&G reports',
    'age compositions and brood tables, but the reviewed sources do not provide',
    'the full annual age-specific observation series and biological/mortality',
    'inputs needed to establish eligibility.'),
  paste('The current official SAFE uses an AR-1 forecast of total Kasilof sockeye',
    'returns, not an age-structured population model. ADF&G reports age',
    'compositions and brood tables, but the reviewed sources do not provide the',
    'full annual age-specific observation series and biological/mortality',
    'inputs needed to establish eligibility.'),
  paste('The current official assessment is a Tier 3 aggregate harvest and',
    'indicator-escapement screen. Age and genetic samples exist for commercial',
    'harvest and some tributaries, but no stock-complex-wide age-specific',
    'abundance series, mortality surface, or age-based population outputs were',
    'located; this unit is not eligible for the age-structured candidate set.'),
  paste('The current official assessment is a Tier 3 aggregate harvest and',
    'indicator-escapement screen; recent indicator escapements are incomplete',
    'and no total run size is estimated. The stock complex lacks a verified',
    'age-specific population input series or age-based outputs and is not',
    'eligible for the age-structured candidate set.'))

source_url <- paste(
  'https://files.npfmc.org/SAFE/2026/CookInletSalmon.pdf;',
  'https://www.adfg.alaska.gov/FedAidPDFs/FMS24-01.pdf;',
  'https://www.adfg.alaska.gov/FedAidPDFs/FMR25-05.pdf')

for (j in seq_along(candidate_ids)) {
  i <- rows[j]
  assessment <- assessments[j, , drop = FALSE]
  stock_name <- as.character(assessment$stock_name)
  model <- as.character(assessment$assessment_model)
  assessment_id <- as.character(assessment$assessment_id)
  catch_evidence <- if (stock_ids[j] %in% c(17338L, 17339L)) {
    paste('The 2026 SAFE reports stock-specific harvest, age-composition data,',
      'and brood tables. FMR25-05 Appendix A13 reports sockeye passage age',
      'composition for 2023 only. A complete annual stock-specific catch-at-age',
      'series was not recovered. Stock SMART assessment', assessment_id,
      'is recorded as', model, 'and uses total-run forecasts.')
  } else if (stock_ids[j] == 17340L) {
    'The SAFE reports age and genetic samples for commercial harvests and age estimates for several tributaries, but not an annual age-specific catch series for the aggregate stock complex.'
  } else if (stock_ids[j] == 17341L) {
    'The SAFE reports aggregate harvest estimates and some age/sex information from ADF&G sources; no complete annual stock-specific catch-at-age series was recovered for this aggregate complex.'
  } else {
    'The SAFE reports aggregate EEZ harvest and data for contributing Chinook stocks, but not an annual age-specific catch series for this aggregate complex; it also notes poor attribution of EEZ catch to contributing stocks.'
  }
  survey_evidence <- if (stock_ids[j] %in% c(17338L, 17339L)) {
    'ADF&G brood tables report total brood-year escapement and returns; FMR25-05 Appendix A13 gives age composition of 2023 sockeye passage. These do not provide a recovered multi-year age-specific abundance-index series.'
  } else if (stock_ids[j] == 17340L) {
    'The SAFE reports escapement data for indicator tributaries and age estimates for some tributaries, but no aggregate stock-complex-wide age-specific abundance series.'
  } else if (stock_ids[j] == 17341L) {
    'The SAFE relies on indicator escapement estimates that are incomplete in recent years and does not estimate total run size; no age-specific abundance index was recovered.'
  } else {
    'The SAFE uses indicator-stock escapements for Tier 3 status determinations; it does not provide an age-specific abundance index for the aggregate complex.'
  }
  biology_evidence <- if (stock_ids[j] %in% c(17338L, 17339L)) {
    'FMR25-05 Appendix A14 reports average fish weights by area, not weight-at-age. No maturity-at-age vector was found in the reviewed current assessment sources.'
  } else {
    'The reviewed current assessment sources do not provide a stock-complex-specific weight-at-age or maturity-at-age input vector.'
  }
  mortality_evidence <- paste('The current SAFE describes total-run forecasts,',
    'stock-recruit analyses, harvest rates, or Tier 3 indicators; it does not',
    'report an age-specific natural-mortality assumption or M surface for this unit.')
  timing_evidence <- paste('The reviewed reports describe seasonal harvest and',
    'river passage observations but do not provide an age-specific marine',
    'abundance-index sampling fraction suitable for an age-structured model.')
  output_evidence <- if (stock_ids[j] %in% c(17338L, 17339L)) {
    'The 2026 SAFE reports total run-size histories and forecasts, spawner-recruit results, and fishery specifications. It does not report annual N-at-age, F-at-age, or M-at-age.'
  } else {
    'The 2026 SAFE reports harvest, indicator escapement, and federal status/catch specifications. It does not report annual N-at-age, F-at-age, or M-at-age for this aggregate unit.'
  }

  row <- data.frame(
    candidate_unit_id = candidate_units[j],
    assessment_area = assessment_areas[j],
    matched_stock_id = NA_character_,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = eligibility[j],
    import_status = 'not_started',
    catch_age_evidence = catch_evidence,
    survey_age_evidence = survey_evidence,
    weights_evidence = biology_evidence,
    maturity_evidence = biology_evidence,
    mortality_evidence = mortality_evidence,
    timing_evidence = timing_evidence,
    output_evidence = output_evidence,
    detailed_source_url = source_url,
    review_date = review_date,
    decision_reason = decision_reasons[j],
    notes = paste0('NOAA Stock SMART ID ', stock_ids[j], ' (assessment ',
      assessment_id, ', assessment year 2026, inventory last-data year 2024) ',
      'is screened against the final 2026 Cook Inlet SAFE, which reports the ',
      '2025 fishery and 2026 harvest specifications. Stock SMART metadata are ',
      'retained as inventory metadata; the final SAFE is the run-specific ',
      'source for this screen. No canonical numerical records were added.'),
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
      stop('Unexpected existing review state for ', candidate_ids[j], '.',
        call. = FALSE)
    for (name in names(row)) candidates[[name]][i] <- row[[name]]
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, i,
      candidates[i, , drop = FALSE], candidate_ids[j])
    candidates <- read.csv(register_path, stringsAsFactors = FALSE,
      na.strings = c('', 'NA'), check.names = FALSE)
  }
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened five Cook Inlet salmon candidates; three remain unresolved and two are ineligible for the age-structured candidate set.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'noaa_auke_creek_coho_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$assessment_id) == '13939', , drop = FALSE]
if (nrow(assessment) != 1L ||
    as.character(assessment$stock_id) != '10580' ||
    as.integer(assessment$assessment_year) != 2024L ||
    as.integer(assessment$last_data_year) != 2024L ||
    as.character(assessment$assessment_model) != 'Slanted Hockey Stock Model' ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    as.character(assessment$assessment_type) != 'Operational' ||
    as.character(assessment$jurisdiction) != 'NPFMC' ||
    as.integer(assessment$composition_input_data) != 0L)
  stop('NOAA Stock SMART metadata do not match the reviewed Auke Creek update.',
    call. = FALSE)

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
required_sources <- c('Status_Deter_SE_AK_2024.pdf',
  'FMS24-04_Southeast_Alaska_Salmon_Escapement_Goals.pdf',
  'StockSMART_DataDictionary.pdf')
if (!all(required_sources %in% manifest$file) ||
    !all(file.exists(file.path(cache, required_sources))))
  stop('The Auke Creek source cache is incomplete.', call. = FALSE)
for (name in required_sources) {
  row <- manifest[manifest$file == name, , drop = FALSE]
  if (nrow(row) != 1L || !file.exists(file.path(cache, name)) ||
      !grepl('^[[:xdigit:]]{64}$', row$sha256))
    stop('A cached Auke Creek source is missing provenance: ', name, call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10580'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one Auke Creek Stock SMART register row.', call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_auke_creek_coho_southeast_alaska',
  assessment_area = 'Auke Creek and Auke Lake, Southeast Alaska',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The official 2024 status report uses estimated total run,',
    'escapement, and fishery removals; it does not present catch numbers-at-age or',
    'age-composition likelihood inputs. Stock SMART classifies composition input as',
    'level 0 for this run.'),
  survey_age_evidence = paste('The assessment uses weir counts and coded-wire-tag',
    'recoveries to estimate total run and exploitation, not an age-specific survey',
    'abundance index. Auke Creek research reports contain age-specific smolt samples,',
    'but these are not multi-age population inputs in the assessed model.'),
  weights_evidence = paste('The research-station report describes age-specific smolt',
    'weights, but the current assessment does not use or report an annual adult',
    'weight-at-age surface.'),
  maturity_evidence = paste('The reviewed current assessment materials do not provide',
    'an age-specific maturity input; returning adults are assessed through total run',
    'and escapement estimates.'),
  mortality_evidence = paste('Stock SMART reports an exploitation-rate estimate, not',
    'age-specific fishing mortality or a natural-mortality surface. The status report',
    'calculates fishing mortality relative to a maximum rate from total run and',
    'escapement goals.'),
  timing_evidence = paste('Annual weir counts and coded-wire-tag recovery records are',
    'used to estimate total run. A within-year timing fraction for an age-specific',
    'abundance index is not applicable or reported.'),
  output_evidence = paste('Stock SMART reports 2024 natural adult spawners of 2,439 and',
    'an exploitation rate of 0.154. The status report provides annual aggregate',
    'productive capacity and fishing-rate statistics through 2024, not N-at-age,',
    'F-at-age, M-at-age, or age-structured SSB outputs.'),
  detailed_source_url = paste(
    'https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10339;',
    'https://www.adfg.alaska.gov/static/regulations/regprocess/fisheriesboard/pdfs/2024-2025/se/fms24-04.pdf;',
    'https://repository.library.noaa.gov/view/noaa/72414/noaa_72414_DS1.pdf;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf'),
  review_date = review_date,
  decision_reason = paste('The latest full-acceptance operational Stock SMART record is',
    'assessment 13939 (2024, data through 2024). The assessment reports an aggregate',
    'indicator-stock status analysis based on total run, escapement, and exploitation.',
    'Although independent Auke Creek research data include age-specific samples, the',
    'current assessment does not establish age-disaggregated population inputs or',
    'outputs required for the comparison set.'),
  notes = paste('NOAA Stock SMART ID 10580 is a distinct Auke Creek coho indicator',
    'stock; it was not matched to a canonical assessment unit or other coho inventory',
    'row. NOAA Stock SMART reports the latest run as Slanted Hockey Stock Model,',
    'model version 2023, full acceptance, operational, and composition-input level 0.',
    'No canonical numerical assessment records were added.'),
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
    stop('Unexpected existing review state for NOAA:10580.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA Auke Creek coho ID 10580 as ineligible for the age-disaggregated candidate set.\n')

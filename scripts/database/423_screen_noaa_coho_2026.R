root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_coho_2026')

stock_ids <- c(10581:10593, 10596:10600)
expected_models <- c('Cohort Analysis', 'Escapement Index', rep('Cohort Analysis', 3),
  'Index Method', rep('Cohort Analysis', 7), 'Cohort Analysis', rep('Cohort Analysis', 4))
expected_categories <- c(2, 2, 4, 4, 4, 2, 4, 4, 2, 4, 3, 4, 4, 4, 4, 4, 4, 4)
expected_catch <- c(1, 1, 4, 4, 4, 2, rep(4, 12))
expected_abundance <- c(rep(3, 13), 4, 3, 3, 3, 3)
expected_biology <- c(0, 0, rep(3, 16))
expected_composition <- c(0, 0, rep(3, 16))

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
if (nrow(manifest) != 8L || anyDuplicated(manifest$file) ||
    any(manifest$retrieved_on != '2026-10-30'))
  stop('The NOAA Coho source cache manifest is incomplete.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached NOAA Coho source.', call. = FALSE)
  hashes
}
for (i in seq_len(nrow(manifest))) {
  path <- file.path(cache, manifest$file[i])
  if (!file.exists(path) || !identical(sha256_file(path), tolower(manifest$sha256[i])))
    stop('A cached NOAA Coho source does not match its manifest: ', manifest$file[i], call. = FALSE)
}

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = metadata_env)
metadata <- metadata_env$stock_assessment_summary
metadata <- metadata[order(metadata$stock_id, -as.numeric(metadata$assessment_year),
  -as.numeric(metadata$assessment_id), na.last = TRUE), , drop = FALSE]
metadata <- metadata[!duplicated(metadata$stock_id), , drop = FALSE]
latest <- metadata[match(stock_ids, metadata$stock_id), , drop = FALSE]
if (nrow(latest) != length(stock_ids) || anyNA(latest$stock_id) ||
    any(latest$scientific_name != 'Oncorhynchus kisutch') ||
    any(latest$assessment_year != 2026) || any(latest$last_data_year != 2025) ||
    any(latest$review_result != 'Full acceptance') ||
    any(as.character(latest$assessment_model) != expected_models) ||
    any(as.integer(latest$model_category) != expected_categories) ||
    any(as.integer(latest$catch_input_data) != expected_catch) ||
    any(as.integer(latest$abundance_input_data) != expected_abundance) ||
    any(as.integer(latest$biological_input_data) != expected_biology) ||
    any(as.integer(latest$composition_input_data) != expected_composition))
  stop('The pinned 2026 NOAA Coho Stock SMART records changed.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))

candidate_ids <- paste0('NOAA:', stock_ids)
unit_ids <- paste0('noaa_coho_', stock_ids)
rows <- match(candidate_ids, register$candidate_id)
if (anyNA(rows) || anyDuplicated(rows) || anyDuplicated(unit_ids) ||
    any(register$official_stock_id[rows] != as.character(stock_ids)) ||
    any(register$scientific_name[rows] != 'Oncorhynchus kisutch'))
  stop('NOAA Coho inventory identities do not match the pinned Stock SMART records.', call. = FALSE)

if (any(stocks$scientific_name == 'Oncorhynchus kisutch', na.rm = TRUE) ||
    any(as.character(stock_ids) %in% stocks$authority_stock_id, na.rm = TRUE))
  stop('A NOAA Coho unit now overlaps a canonical stock identity.', call. = FALSE)
if (any(unit_ids %in% c(register$candidate_unit_id[-rows], assessments$assessment_id,
    inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('A NOAA Coho unit key conflicts with an existing register or database record.', call. = FALSE)

initial <- register$match_status[rows] == 'unreviewed' &
  register$screening_status[rows] == 'not_started' &
  register$eligibility[rows] == 'unresolved' &
  (is.na(register$candidate_unit_id[rows]) | !nzchar(register$candidate_unit_id[rows]))
reviewed <- register$match_status[rows] == 'new' &
  register$candidate_unit_id[rows] == unit_ids &
  register$screening_status[rows] == 'screened' &
  register$eligibility[rows] == 'ineligible'
if (any(!initial & !reviewed))
  stop('A NOAA Coho candidate has a conflicting prior review.', call. = FALSE)

source_urls <- paste(
  'https://www.pcouncil.org/documents/2026/03/preseason-report-1-stock-abundance-analysis-and-environmental-assessment-part-1-for-2026-ocean-salmon-fishery-regulations.pdf/',
  'https://www.pcouncil.org/documents/2026/02/review-of-2025-ocean-salmon-fisheries.pdf/',
  'https://framverse.github.io/fram_doc/calcs_data_coho.html',
  'https://framverse.github.io/fram_doc/apps_coho.html',
  'https://framverse.github.io/fram_doc/calcs_appendices.html',
  'https://framverse.github.io/fram_doc/user_prereq.html',
  'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf',
  sep = '; ')

forecast_text <- c(
  'The 2026 PFMC report provides no Central California Coast coho age-structured population series; Stock SMART reports no time series for this unit.',
  'The 2026 PFMC report describes the SONCC ESU harvest control rule and age-3 adult exploitation limits, not a multi-age population assessment series.',
  'The 2026 PFMC report forecasts Oregon Coastal Natural coho as adult ocean age-3 abundance; river and lake components are forecast separately.',
  'The 2026 PFMC report derives the OPIH aggregate forecast and partitions it into early/late and coastal components using recent proportions; it does not report age-specific population surfaces.',
  'The 2026 PFMC report derives the OPIH aggregate forecast and partitions it into early/late and coastal components using recent proportions; it does not report age-specific population surfaces.',
  'The 2026 PFMC report gives Lower Columbia natural coho adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report and 2025 fisheries review report Willapa Bay adult-run, escapement, and fishery-impact quantities, not multi-age population surfaces.',
  'The 2026 PFMC report gives Grays Harbor adult-run forecasts and escapement-derived quantities, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Quinault adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Queets adult-run forecasts and escapement-derived quantities, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Hoh adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Quillayute fall adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Quillayute summer hatchery adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report describes Hood Canal adult-run forecast methods and reports forecast outputs, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Skagit adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Stillaguamish adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report gives Snohomish adult-run forecasts, but not a multi-age population output surface.',
  'The 2026 PFMC report gives South Puget Sound hatchery adult-run forecasts, but not a multi-age population output surface.')

for (j in seq_along(rows)) {
  i <- rows[j]
  stock_id <- stock_ids[j]
  composition <- latest$composition_input_data[j]
  model_note <- paste0('Stock SMART classifies the 2026 assessment as "',
    latest$assessment_model[j], '" (Model Category ', latest$model_category[j],
    ', Composition Input Data ', composition, '). Its dictionary says the composition rating reflects size/age composition used, but it does not publish the underlying age vectors. ')
  register$candidate_unit_id[i] <- unit_ids[j]
  register$matched_stock_id[i] <- ''
  register$match_status[i] <- 'new'
  register$screening_status[i] <- 'screened'
  register$eligibility[i] <- 'ineligible'
  register$import_status[i] <- 'not_started'
  register$catch_age_evidence[i] <- paste0(model_note,
    'The 2026 PFMC report publishes fishery-management forecasts and impacts; it does not provide multi-age catch-at-age likelihood vectors. Catch Input Data level ',
    latest$catch_input_data[j], ' describes catch-data completeness, not an age dimension.')
  register$survey_age_evidence[i] <- paste0(
    'The 2026 PFMC report describes spawner/smolt, coded-wire-tag, and adult-run forecasting methods; no repeated age-specific survey index series was found. Coho FRAM uses a single adult age-3 cohort rather than a multi-age abundance surface.')
  register$weights_evidence[i] <- paste0(
    'The reviewed 2026 production report and coho FRAM documentation do not provide weights-at-age for a multi-age assessment. The operational model tracks only age-3 adults.')
  register$maturity_evidence[i] <- paste0(
    'The reviewed 2026 production report and coho FRAM documentation do not provide maturity-at-age for a multi-age assessment. The operational model tracks only age-3 adults.')
  register$mortality_evidence[i] <- paste0(
    'Coho FRAM calculates natural and fishery mortality across five within-year time steps for the single age-3 cohort; natural mortality is common across stocks and years. Published exploitation/mortality outputs are fishery-specific and not multi-age F-at-age or M-at-age series.')
  register$timing_evidence[i] <- paste0(
    'FRAM has five within-year fishery time steps (Jan-Jun, July, August, September, Oct-Dec), but the 2026 assessment has no age-specific survey likelihood with a survey sampling-time parameter.')
  register$output_evidence[i] <- paste0(forecast_text[j],
    ' Published adult ocean abundance/run-size outputs are commonly expressed in thousands of age-3 fish; they are not N-at-age surfaces spanning multiple ages.')
  register$detailed_source_url[i] <- paste0(source_urls,
    '; https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=', stock_id)
  register$review_date[i] <- '2026-10-30'
  register$decision_reason[i] <- paste0(
    'Ineligible for the age-disaggregated assessment set. The latest operational record is the 2026 Coho assessment using data through 2025. The accessible 2026 PFMC report and joint FRAM documentation describe annual forecasting and fishery accounting for one adult age class (age 3), not the multi-age population process and inputs required for tinyAM. Some Stock SMART metadata indicate size/age composition data were used, but no multi-age likelihood vectors or population surfaces are published. The FRAM run database and supporting files are password-protected; their absence from public sources is recorded as a source limitation, not proof that underlying biological samples do not exist.')
  register$notes[i] <- paste0(
    'NOAA Stock SMART stock ID ', stock_id, ' is a distinct U.S. coho management unit (Oncorhynchus kisutch), not a one-to-one match to the DFO Interior Fraser or North Coast coho candidates. Several NOAA forecast components share a broader OPI or regional forecast and remain distinct inventory units. Source PDFs and FRAM documentation are cached under source_cache/discovery_noaa_coho_2026/sources.csv with retrieval dates and SHA-256 checksums. FRAM documentation states only age-3 fish are modeled; annual run database files are hosted in a password-protected NWIFC section. No canonical assessment or numerical records were added.')
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  for (i in rows)
    replace_candidate_register_row(register_path, i, register[i, , drop = FALSE],
      register$candidate_id[i])
}

cat('Screened 18 current NOAA coho inventory units as ineligible for the multi-age assessment set; no canonical numerical records were added.\n')

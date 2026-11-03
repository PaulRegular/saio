root <- "."
cache <- file.path(root, 'source_cache', 'noaa_klamath_spring_chinook_2013')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$assessment_id) == '7879', , drop = FALSE]
if (nrow(assessment) != 1L ||
    as.character(assessment$stock_id) != '10610' ||
    as.integer(assessment$assessment_year) != 2013L ||
    as.integer(assessment$last_data_year) != 2010L ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    as.character(assessment$assessment_model) != 'Escapement Index' ||
    as.character(assessment$model_version) != 'Geometric Mean of Escapement' ||
    as.character(assessment$jurisdiction) != 'PFMC' ||
    as.character(assessment$fmp) != 'Pacific Coast Salmon' ||
    as.character(assessment$science_center) != 'NWFSC / SWFSC' ||
    as.integer(assessment$composition_input_data) != 1L ||
    as.integer(assessment$biological_input_data) != 0L ||
    as.integer(assessment$b_year) != 2010L ||
    as.numeric(assessment$estimated_b) != 4082)
  stop('NOAA Stock SMART metadata do not match the reviewed Klamath spring Chinook assessment.',
    call. = FALSE)

files <- c('NOAA_TM_NMFS_SWFSC_502_2013.pdf',
  'NOAA_Q4_FY2025_Appendix_E_Assessment_Data_Gaps.pdf',
  'NOAA_Q4_2025_Stock_Status_Tables.pdf',
  'CDFW_Klamath_Spring_Chinook_Megatable_1980-2022.pdf',
  'CDFW_Klamath_Spring_Chinook_Megatable_1980-2023.pdf')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (!all(files %in% manifest$file) ||
    !all(file.exists(file.path(cache, files))) ||
    anyNA(manifest$sha256[match(files, manifest$file)]) ||
    !all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])))
  stop('The Klamath spring Chinook source cache is incomplete.', call. = FALSE)

pdf_headers <- vapply(file.path(cache, files), function(path) {
  con <- file(path, 'rb')
  on.exit(close(con))
  identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(pdf_headers))
  stop('A cached Klamath spring Chinook source is not a PDF.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10610'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one Klamath spring Chinook Stock SMART register row.',
    call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_klamath_spring_chinook',
  assessment_area = 'Northern California Coast: Klamath River Spring',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('CDFW spring-run tables report annual harvest in grilse,',
    'adult, and total bins, while the 2013 NOAA review uses aggregate adult',
    'escapement. No full catch-at-age input or age composition used by the',
    'identified assessment was located.'),
  survey_age_evidence = paste('The 2013 assessment is an Escapement Index based on',
    'aggregate adult spawner counts and five-year geometric means. CDFW tables',
    'report aggregate run-size and grilse/adult bins, not an age-specific',
    'abundance-index series.'),
  weights_evidence = paste('No stock-specific weights-at-age used by the 2013',
    'assessment were found in the reviewed official sources.'),
  maturity_evidence = paste('No stock-specific maturity-at-age inputs used by the',
    '2013 assessment were found in the reviewed official sources.'),
  mortality_evidence = paste('The assessment is an aggregate escapement index, not an',
    'age-structured mortality model. The 2013 NOAA review says ocean exploitation',
    'information was unavailable for spring-run fish; no age-specific F or M inputs',
    'were located.'),
  timing_evidence = paste('The assessment uses annual aggregate spawner counts rather',
    'than a within-year age-specific survey index; no survey timing fraction is',
    'reported for an index of that kind.'),
  output_evidence = paste('Stock SMART reports 4,082 adult spawners (hatchery and natural)',
    'for 2010 on a five-year-geometric-mean basis. This aggregate value does not',
    'match a recoverable age-specific output; its correspondence to the component',
    'estimates in the NOAA review remains unresolved. No N-at-age, F-at-age, or',
    'M-at-age outputs were located.'),
  detailed_source_url = paste(
    'https://swfsc-publications.fisheries.noaa.gov/publications/TM/SWFSC/NOAA-TM-NMFS-SWFSC-502.pdf;',
    'https://www.fisheries.noaa.gov/s3/2026-03/Appendix-E.pdf;',
    'https://www.fisheries.noaa.gov/s3/2026-02/FINAL-Q4-2025-Stock-Status-Tables.pdf;',
    'https://nrm.dfg.ca.gov/FileHandler.ashx?DocumentID=161145;',
    'https://casalmon.org/wp-content/uploads/2024/08/FINAL-2023-Spring-Chinook-Megatable-v.28-Mar-2024.pdf;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10610;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/StockSMART_DataDictionary.pdf'),
  review_date = review_date,
  decision_reason = paste('NOAA Stock SMART assessment 7879 is a 2013 full-acceptance',
    'benchmark using an Escapement Index / Geometric Mean of Escapement method;',
    'NOAA Q4 FY2025 Appendix E still lists 2013 as the last assessment. The',
    'reviewed assessment and CDFW aggregate tables do not provide the age-specific',
    'inputs, biology, mortality assumptions, or population outputs required for',
    'The stock is ineligible for the age-structured candidate set.'),
  notes = paste('The NOAA 2013 review characterizes recent abundance using adult',
    '(age > 2) spawner escapement, geometric means, and log-linear trends. CDFW',
    '1980-2023 tables separate grilse, adults, and totals, not a full age series.',
    'Stock SMART composition_input_data = 1 is an availability score, not an',
    'observation series. Its reported 2010 aggregate value is not imported because',
    'its correspondence to the NOAA component table is unresolved. No canonical',
    'numerical assessment records were added.'),
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
    stop('Unexpected existing review state for NOAA:10610.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA Klamath River spring Chinook ID 10610 as ineligible for the age-disaggregated candidate set.\n')

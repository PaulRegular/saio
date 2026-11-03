root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_yellowtail_snapper_sedar96_2025')

stock_id <- 11081L
assessment_id <- 14156L
candidate_id <- paste0('NOAA:', stock_id)
unit_id <- paste0('noaa_yellowtail_snapper_', stock_id)

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
expected_hashes <- c(
  'c2a7b04f08f51082bf27d318e985095ba0eab11a8ac036bdd207b0a062ec5943',
  '3e2d514d467a820d8d1b0ad1afba13e9f303d5e726d7303a14f1e4b7d7a837aa',
  '45d15d92a545ddf87a242fa87c7e855411611d177fdb1484ca323ad93738514e')
if (nrow(manifest) != 3L || anyDuplicated(manifest$file) ||
    any(manifest$retrieved_on != '2026-10-30') ||
    !identical(tolower(manifest$sha256), expected_hashes))
  stop('The yellowtail snapper source manifest is incomplete or changed.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached yellowtail source.', call. = FALSE)
  hashes
}
for (i in seq_len(nrow(manifest))) {
  path <- file.path(cache, manifest$file[i])
  if (!file.exists(path) || !identical(sha256_file(path), expected_hashes[i]))
    stop('A cached yellowtail source does not match its manifest: ', manifest$file[i], call. = FALSE)
}

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), metadata_env)
metadata <- metadata_env$stock_assessment_summary
latest <- metadata[metadata$assessment_id == assessment_id, , drop = FALSE]
if (nrow(latest) != 1L || latest$stock_id != stock_id ||
    latest$scientific_name != 'Ocyurus chrysurus' ||
    latest$assessment_year != 2025 || latest$last_data_year != 2023 ||
    latest$assessment_type != 'Operational' || latest$assessment_model != 'SS' ||
    latest$model_category != 6 || latest$review_result != 'Full acceptance' ||
    latest$catch_input_data != 3 || latest$abundance_input_data != 3 ||
    latest$biological_input_data != 3 || latest$composition_input_data != 4)
  stop('The pinned 2025 NOAA yellowtail snapper Stock SMART record changed.', call. = FALSE)

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

row <- match(candidate_id, register$candidate_id)
if (is.na(row) || register$scientific_name[row] != 'Ocyurus chrysurus' ||
    register$assessment_area[row] != 'Southern Atlantic Coast / Gulf of Mexico' ||
    register$inventory_assessment_year[row] != 2025)
  stop('The NOAA yellowtail snapper inventory identity changed.', call. = FALSE)
if (any(stocks$scientific_name == 'Ocyurus chrysurus', na.rm = TRUE) ||
    any(register$candidate_id[-row] == candidate_id) ||
    any(unit_id %in% c(register$candidate_unit_id[-row], assessments$assessment_id,
      inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('The yellowtail snapper candidate overlaps another stock or record.', call. = FALSE)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (!initial && !reviewed) stop('The yellowtail snapper candidate has a conflicting review.', call. = FALSE)

register$candidate_unit_id[row] <- unit_id
register$matched_stock_id[row] <- ''
register$match_status[row] <- 'new'
register$screening_status[row] <- 'screened'
register$eligibility[row] <- 'unresolved'
register$import_status[row] <- 'not_started'
register$catch_age_evidence[row] <- paste0(
  'The accepted 2025 operational SEDAR 96 assessment is an age- and size-structured Stock Synthesis model, ages 0-20. It reports age compositions for headboat and MRIP landings during 1981-2023, raised with annual landings to weighted landings-at-age; commercial ages from 1992-2023 are configured as conditional age-at-length data. The numerical compositions are shown in figures, and the reviewed public files did not include the model-ready input vectors.')
register$survey_age_evidence[row] <- paste0(
  'The model uses four aggregate abundance indices (commercial CPUE, MRIP CPUE, Reef Fish Visual Census Florida Keys, and Dry Tortugas). RVC index compositions are length-based; the additional fishery-independent conditional age-at-length data are not linked to an index. The public materials therefore do not verify an index-specific age distribution for reconstructing the RVC series at age.')
register$weights_evidence[row] <- paste0(
  'The assessment uses a fixed length-weight relationship, weight = 2.574e-5 * fork_length_cm^2.8797, and estimated growth within Stock Synthesis. Model weight-at-age is consequently derived within the model; a numeric weight-at-age input vector was not found in the public document bundle.')
register$maturity_evidence[row] <- paste0(
  'Maturity-at-age is fixed using the schedule adopted in SEDAR 64: 50% mature at age 1.7 and all mature by age 4, extended through age 20. The 2025 report references the schedule but the reviewed public files do not include the model input vector.')
register$mortality_evidence[row] <- paste0(
  'Natural mortality-at-age is fixed, constant through time, and derived from the Lorenzen relationship using the external growth model. The reviewed report describes the assumption but the public document bundle did not include the numeric model input vector.')
register$timing_evidence[row] <- paste0(
  'The assessment is annual (January-December); surveys, compositions, and conditional age-at-length observations are configured at mid-year (July 1). The Dry Tortugas RVC index itself samples May-July in listed survey years.')
register$output_evidence[row] <- paste0(
  'The report says the fitted model estimates a full N-at-age time series (1,000s of fish), biomass, female SSB, age-0 recruitment, and fishing mortality. It tabulates annual total/SSB and recruitment and age-4/apical F, but the exact N-at-age surface is not provided as a numerical table or native model output in the reviewed public document bundle.')
register$detailed_source_url[row] <- paste(
  paste(manifest$url, collapse = '; '),
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11081',
  sep = '; ')
register$review_date[row] <- '2026-10-30'
register$decision_reason[row] <- paste0(
  'The latest official assessment found is the fully accepted 2025 SEDAR 96 operational assessment (data through 2023), which is genuinely age-structured and has age-based catch compositions, fixed biological assumptions, and age-specific population outputs. Eligibility remains unresolved for the age-disaggregated comparison: the public bundle does not contain model-ready annual age vectors, the fishery-independent indices have length rather than index-specific age compositions, and the numerical N-at-age surface is not published as a table or native output file. Do not construct age-specific survey observations or population outputs from unrelated compositions or figures without recovering and documenting the underlying data.')
register$notes[row] <- paste0(
  'NOAA Stock SMART ID 11081 is the single Southeastern U.S. Yellowtail Snapper management stock shared by South Atlantic and Gulf councils; SEDAR 96 models one Florida population area and ages 0-20. The 2025 SAR and SEDAR96-WP-07 are cached locally under source_cache/discovery_noaa_yellowtail_snapper_sedar96_2025/sources.csv. No canonical stock, assessment, input, or output records were added.')

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)

cat('Screened NOAA Southeastern U.S. yellowtail snapper (Stock SMART 11081; SEDAR 96, 2025); source availability leaves age-disaggregated eligibility unresolved. No canonical numerical records were added.\n')

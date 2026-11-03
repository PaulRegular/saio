root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache <- file.path(root, 'source_cache', 'discovery_noaa_goa_shallow_flatfish_2016_2026')
review_date <- '2026-11-02'
candidate_id <- 'NOAA:11009'

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
expected_files <- c(
  'goa_rock_sole_full_assessment_2015.pdf',
  'goa_shallow_flatfish_harvest_projection_2026.pdf',
  'goa_shallow_flatfish_safe_2021.pdf',
  'goa_shallow_flatfish_safe_2024.pdf',
  'goa_shallow_flatfish_safe_2026.pdf',
  'groundfish_assessment_priorities_2026.pdf',
  'noaa_stocksmart_11009_2016_source.html')
expected_hashes <- c(
  'eafabd5cf061c4cf8116711f1de997d90dbff29e8427f53ee95f11ce0d91d0a2',
  '52d4496a97ed3248f098a01b239081a9436f4185e300cf39d24cf9a6a4313b0e',
  '245d0fa63aefafb27950ec4a7efd4cffe1df4b93be742e151083202a3ad6b979',
  'c8a45eeba1db8678e2defdc3696db471570e64850b8930c14f36826687ef750e',
  '83f24b23f7a19f28aceedfaa6e699acadabd62af85b88214bb2c653c729bacd0',
  'b8d15fcc1607600b1912eeb931a1c8b2ed4f1c188e494352343b45d6bc183b31',
  'a9e79a128b37a3caa7598a46b6841f967b87122af9cb3209d157dc8a986cb2e3')
if (nrow(manifest) != length(expected_files) ||
    !identical(manifest$file, expected_files) ||
    !identical(tolower(manifest$sha256), expected_hashes) ||
    any(manifest$retrieval_date != review_date))
  stop('GOA shallow-flatfish source provenance does not match the reviewed snapshot.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = '\\', mustWork = TRUE)
  result <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    result, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify a cached GOA shallow-flatfish source.', call. = FALSE)
  hashes
}
for (i in seq_along(expected_files)) {
  path <- file.path(cache, expected_files[i])
  if (!file.exists(path) || !identical(sha256_file(path), expected_hashes[i]))
    stop('A cached GOA shallow-flatfish source does not match its manifest: ',
      expected_files[i], call. = FALSE)
  if (grepl('\\.pdf$', expected_files[i], ignore.case = TRUE)) {
    con <- file(path, 'rb')
    header <- readBin(con, 'raw', 5L)
    close(con)
    if (!identical(header, charToRaw('%PDF-')))
      stop('A cached GOA shallow-flatfish source is not a PDF: ', expected_files[i], call. = FALSE)
  }
}

metadata_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), metadata_env)
stocksmart <- metadata_env$stock_assessment_summary
history <- stocksmart[as.character(stocksmart$stock_id) == '11009', , drop = FALSE]
current_record <- history[as.character(history$assessment_id) == '9489', , drop = FALSE]
last_full <- history[as.character(history$assessment_id) == '9486', , drop = FALSE]
if (nrow(current_record) != 1L || current_record$stock_name !=
    'Gulf of Alaska Shallow Water Flatfish Complex' ||
    as.integer(current_record$assessment_year) != 2016L ||
    as.integer(current_record$last_data_year) != 2016L ||
    current_record$review_result != 'Full acceptance' ||
    current_record$assessment_model != 'Stock Synthesis' ||
    current_record$assessment_type != 'Partial Update' ||
    nrow(last_full) != 1L || as.integer(last_full$assessment_year) != 2015L ||
    last_full$assessment_type != 'Benchmark')
  stop('The pinned NOAA Stock SMART history changed for stock 11009.', call. = FALSE)

page <- paste(readLines(file.path(cache, 'noaa_stocksmart_11009_2016_source.html'),
  warn = FALSE, encoding = 'UTF-8'), collapse = '\n')
if (!grepl('last full assessment in', page, fixed = TRUE) ||
    !grepl('Turnock et al. 2016', page, fixed = TRUE) ||
    !grepl('A’mar et al. 2015', page, fixed = TRUE))
  stop('The cached NOAA 2016 source page no longer identifies the prior full assessment.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
row_index <- match(candidate_id, candidates$candidate_id)
if (is.na(row_index)) stop('NOAA:11009 is missing from the discovery register.', call. = FALSE)
related <- candidates[candidates$candidate_id %in% c(
  'NOAA:11803', 'NOAA:10836', 'NOAA:15412', 'NOAA:15413',
  'NOAA:10040', 'NOAA:15414', 'NOAA:15415'), , drop = FALSE]
expected_units <- c(
  'noaa_goa_other_shallow_water_flatfish_complex',
  'noaa_goa_northern_rock_sole', 'noaa_goa_southern_rock_sole')
if (nrow(related) != 7L || !all(expected_units %in% related$candidate_unit_id) ||
    any(related$screening_status != 'screened'))
  stop('The current successor screens for the broad 2016 complex are incomplete.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
row <- candidates[row_index, , drop = FALSE]
row$candidate_unit_id <- ''
row$scientific_name <- paste(c(
  'Pleuronectes quadrituberculatus', 'Isopsetta isolepis', 'Parophrys vetulus',
  'Psettichthys melanostictus', 'Platichthys stellatus', 'Limanda aspera',
  'Lepidopsetta polyxystra', 'Lepidopsetta bilineata'), collapse = '; ')
row$assessment_area <- 'Gulf of Alaska'
row$matched_stock_id <- ''
row$match_status <- 'ambiguous'
row$screening_status <- 'screened'
row$eligibility <- 'ineligible'
row$import_status <- 'not_started'
row$catch_age_evidence <- paste0(
  'The old broad complex is no longer one current assessment unit. The 2021 SAFE describes age-structured ',
  'catch-at-age models only for northern and southern rock sole; the other six species use Tier 5 survey-biomass ',
  'methods. Current component records are screened separately.')
row$survey_age_evidence <- paste0(
  'The 2021 SAFE describes GOA bottom-trawl survey biomass and length data. Rock-sole models also use survey ',
  'biomass, length composition, and conditional age-at-length; the other six species rely on survey biomass. ',
  'Aging of GOA flatfish has been sporadic.')
row$weights_evidence <- paste0(
  'The broad complex has no single weight-at-age series. The 2021 report says age-length samples are few or ',
  'absent for several Tier 5 species; age-specific biology belongs to the separately screened rock-sole units.')
row$maturity_evidence <- paste0(
  'No common maturity-at-age input applies to this broad complex. The current rock-sole assessments are tracked ',
  'as separate units; the Tier 5 remainder is not age-structured.')
row$mortality_evidence <- paste0(
  'Mortality is not common across the former complex: the 2021 report uses M = 0.2 for other shallow-water ',
  'flatfish and separate area- and sex-specific fixed values for the northern and southern rock soles.')
row$timing_evidence <- paste0(
  'The source describes biennial bottom-trawl surveys but does not specify a within-year timing fraction for ',
  'a single age-structured assessment spanning the old complex.')
row$output_evidence <- paste0(
  'Current outputs are split across the rock-sole age-structured assessments and Tier 5 survey-biomass models. ',
  'The 2026 priority schedule deferred a full SWF assessment and called for a harvest projection; the broad ',
  '2016 identifier is not a separate current output series.')
row$detailed_source_url <- paste(manifest$url, collapse = '; ')
row$review_date <- review_date
row$decision_reason <- paste0(
  'NOAA identifies the 2016 record as a partial-update/off-year product and says the last full rock-sole ',
  'assessment was in 2015. The present complex comprises distinct northern rock sole, southern rock sole, and ',
  'other shallow-water-flatfish assessment units. NOAA’s 2021 SAFE documents the age-structured rock-sole models ',
  'and a survey-biomass random-effects approach for the other six species. The 2026 assessment-priority document ',
  'deferred a full SWF assessment in favor of a harvest projection. Under the current-unit-only scope, this broad ',
  'legacy record is ambiguous and ineligible as a separate candidate; its component records remain separate.')
row$notes <- paste0(
  'Crosswalk one-to-many to NOAA:11803 (other shallow-water flatfish complex), NOAA:10836/15412/15413 ',
  '(northern rock sole), and NOAA:10040/15414/15415 (southern rock sole). Do not count this legacy aggregate ',
  'as another stock unit or combine the component assessment data. No canonical database rows were added.')

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
  (is.na(candidates$candidate_unit_id[row_index]) || !nzchar(candidates$candidate_unit_id[row_index]))
reviewed <- candidates$match_status[row_index] == 'ambiguous' &&
  candidates$screening_status[row_index] == 'screened' &&
  candidates$eligibility[row_index] == 'ineligible' &&
  candidates$import_status[row_index] == 'not_started'
if (!same && !initial && !reviewed)
  stop('Unexpected existing candidate state for NOAA:11009.', call. = FALSE)
if (!same) {
  for (name in names(row)) candidates[[name]][row_index] <- row[[name]]
  replace_candidate_register_row(register_path, row_index,
    candidates[row_index, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Reconciled NOAA:11009 as an ambiguous legacy complex; current component units remain separately screened.\n')

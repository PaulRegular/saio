root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_quillback_oregon_washington_2021')
register_path <- file.path(root, 'discovery', 'candidates.csv')

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected_hashes <- c(
  oregon_quillback_assessment_2021.pdf = '45612f226813caebc50551ff2eb28153d44900eb680f4b81bcbe68dd8d3c4934',
  washington_quillback_assessment_2021.pdf = '3ec59f0077fa640233bd15bff552a42bccf6e28a920044685fa9aa5d70c02d5e',
  quillback_rockfish_model_files_2021.zip = 'bb03206474b32b656593f729d7b3f6cc049dfa8d4df286b57467039fe1922e7d'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The quillback source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-11-01' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached quillback source differs from its manifest: ', file, call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (any(c('noaa_quillback_rockfish_oregon', 'noaa_quillback_rockfish_washington') %in% stocks$stock_id) ||
    any(c('noaa_quillback_rockfish_oregon', 'noaa_quillback_rockfish_washington') %in% assessments$assessment_id) ||
    any(c('noaa_quillback_rockfish_oregon', 'noaa_quillback_rockfish_washington') %in% inputs$assessment_id) ||
    any(c('noaa_quillback_rockfish_oregon', 'noaa_quillback_rockfish_washington') %in% outputs$assessment_id))
  stop('A canonical quillback record exists; recheck the current-unit crosswalk.', call. = FALSE)

make_review <- function(candidate_id, candidate_unit_id, stock_id, area, report_file,
                        age_evidence) {
  row <- match(candidate_id, candidates$candidate_id)
  if (is.na(row) || candidates$official_stock_id[row] != stock_id ||
      candidates$scientific_name[row] != 'Sebastes maliger' ||
      candidates$assessment_area[row] != area ||
      candidates$inventory_assessment_year[row] != '2021')
    stop('The NOAA quillback inventory identity changed: ', candidate_id, call. = FALSE)
  report_url <- manifest$url[match(report_file, manifest$file)]
  list(
    candidate_unit_id = candidate_unit_id,
    match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = age_evidence,
    survey_age_evidence = paste0(
      'The native model data file has no survey fleet or abundance-index observations. ',
      'The assessment reports state fishery-independent indices were not selected ',
      'because available samples were inadequate.'),
    weights_evidence = paste0(
      'Coastwide biological weight and age samples informed fixed life-history inputs; ',
      'the report gives weight-at-age assumptions, but no annual age-specific catch weights.'),
    maturity_evidence = paste0(
      'Maturity and fecundity were estimated outside the model and fixed as biological ',
      'inputs; no annual maturity-at-age series is an observation.'),
    mortality_evidence = paste0(
      'Natural mortality is fixed at 0.057 per year using a maximum age of 95 years; ',
      'it is not an estimated M-at-age output.'),
    timing_evidence = paste0(
      'The base model has one annual season and no abundance index. The report and model ',
      'archive do not provide survey timing for an index series.'),
    output_evidence = paste0(
      'The native Stock Synthesis archive includes Report.sso with fitted numbers-at-age ',
      'and fishing mortality at age, plus spawning-output and recruitment results.'),
    detailed_source_url = report_url, review_date = '2026-11-01',
    decision_reason = paste0(
      'The 2021 state-area assessment is a catch-and-length Stock Synthesis model. ',
      'The native data file has length-composition likelihoods; age-composition rows ',
      'are commented out and the report says ages inform fixed biological parameters ',
      'rather than the likelihood. No abundance index is available. The source therefore ',
      'does not meet the age-disaggregated input criteria despite providing age-specific ',
      'population outputs.'),
    notes = paste0(
      'Separate ', area, ' component of the 2021 assessment; do not pool with the other ',
      'state model or California. Amendment 31 defined state-specific units. The 2026 ',
      'Amendment 37 Council recommendation lists a Washington-only quillback stock in ',
      'the federal FMP; verify final federal status before changing current-unit identity. ',
      'Screening only; no canonical records or numerical values added.'))
}

reviews <- list(
  make_review('NOAA:15340', 'noaa_quillback_rockfish_oregon', '15340', 'Oregon',
    'oregon_quillback_assessment_2021.pdf', paste0(
      'The base model uses total commercial/recreational catch and length compositions. ',
      'Age samples from fisheries and the WCGBTS informed fixed biology, not an age ',
      'likelihood. The native OR data file labels its age-composition rows as exploratory ',
      'and comments them out; no annual catch-at-age series is fitted.')),
  make_review('NOAA:15341', 'noaa_quillback_rockfish_washington', '15341', 'Washington',
    'washington_quillback_assessment_2021.pdf', paste0(
      'The base model uses total commercial/recreational catch and length compositions. ',
      'Age samples from fisheries and the WCGBTS informed fixed biology, not an age ',
      'likelihood. The native WA data file comments out its age-composition rows; no ',
      'annual catch-at-age series is fitted.'))
)

for (review in reviews) {
  candidate_id <- if (review$candidate_unit_id == 'noaa_quillback_rockfish_oregon')
    'NOAA:15340' else 'NOAA:15341'
  row <- match(candidate_id, candidates$candidate_id)
  pristine <- candidates$match_status[row] == 'unreviewed' &&
    candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' &&
    (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
  already_reviewed <- all(vapply(names(review), function(column)
    identical(as.character(candidates[[column]][row]), as.character(review[[column]])),
    logical(1L)))
  if (!(pristine || already_reviewed))
    stop('Conflicting NOAA quillback candidate review: ', candidate_id, call. = FALSE)
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
    candidates <- read.csv(register_path, stringsAsFactors = FALSE,
      na.strings = c('', 'NA'), check.names = FALSE)
  }
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened NOAA Oregon and Washington quillback 2021 as ineligible for age-disaggregated curation.\n')

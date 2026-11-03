root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_goliath_grouper_2016')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_ids <- c('NOAA:10315', 'NOAA:11042')
candidate_unit_id <- 'noaa_goliath_grouper_southeastern_us_2016'
report_url <- paste0(
  'https://sedarweb.org/documents/',
  'sedar-47-final-stock-assessment-report-southeastern-u-s-goliath-grouper/')

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected_sources <- data.frame(
  file = c('sedar47_final_report_2016.pdf',
    'noaa_cie_kahn_sedar47_review_2016.pdf',
    'fwc_goliath_population_assessment_page_2026-10-31.html'),
  url = c(
    'https://safmc.net/wp-content/uploads/2022/05/B04b_S47_Final_SAR.pdf',
    paste0('https://www.st.nmfs.noaa.gov/Assets/Quality-Assurance/documents/',
      'peer-review-reports/2016/2016_07_05%20Kahn%20SEDAR%2047%20Goliath%20Grouper%20review%20report.pdf'),
    'https://myfwc.com/fishing/saltwater/recreational/goliath/'),
  retrieved_on = '2026-10-31',
  bytes = c(13600025, 535265, 198918),
  sha256 = c(
    '08d9240039db792070bc2106221a663a8aaca2079f8061526a503d011b73e31a',
    'f2d1ebbcdc8d5127a236129fe00bfbed181b46dfe3d3a7ac0df09d276edef1d9',
    '44f544e1ff7a09d57b27b5faa5caa7421c8fa963447baa0fb43d736437b74419'),
  stringsAsFactors = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (!identical(names(manifest), names(expected_sources)) ||
    nrow(manifest) != nrow(expected_sources) || anyDuplicated(manifest$file) ||
    !identical(manifest$file, expected_sources$file) ||
    !identical(manifest$url, expected_sources$url) ||
    !identical(manifest$retrieved_on, expected_sources$retrieved_on) ||
    !identical(as.numeric(manifest$bytes), as.numeric(expected_sources$bytes)) ||
    !identical(tolower(manifest$sha256), expected_sources$sha256))
  stop('The goliath grouper source manifest is incomplete or changed.', call. = FALSE)
for (i in seq_len(nrow(expected_sources))) {
  path <- file.path(cache, expected_sources$file[i])
  if (!file.exists(path) || file.info(path)$size != expected_sources$bytes[i] ||
      sha256_file(path) != expected_sources$sha256[i])
    stop('Cached goliath grouper source differs from the manifest: ',
      expected_sources$file[i], call. = FALSE)
}

fwc_html <- paste(readLines(file.path(cache,
  'fwc_goliath_population_assessment_page_2026-10-31.html'), warn = FALSE),
  collapse = ' ')
if (!grepl('without conducting a full-scale traditional fisheries stock assessment',
    fwc_html, fixed = TRUE))
  stop('The current FWC population-assessment statement is missing.', call. = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
gulf_2016 <- stocksmart[as.character(stocksmart$stock_id) == '10315' &
  as.character(stocksmart$assessment_year) == '2016', , drop = FALSE]
combined_2016 <- stocksmart[as.character(stocksmart$stock_id) == '11042' &
  as.character(stocksmart$assessment_year) == '2016', , drop = FALSE]
combined_2010 <- stocksmart[as.character(stocksmart$stock_id) == '11042' &
  as.character(stocksmart$assessment_year) == '2010', , drop = FALSE]
if (nrow(gulf_2016) != 1L || nrow(combined_2016) != 1L ||
    nrow(combined_2010) != 1L || gulf_2016$assessment_id != 6915 ||
    combined_2016$assessment_id != 12476 || combined_2010$assessment_id != 2929 ||
    !grepl('Reject', gulf_2016$review_result, fixed = TRUE) ||
    !grepl('Reject', combined_2016$review_result, fixed = TRUE) ||
    !grepl('Partial acceptance', combined_2010$review_result, fixed = TRUE))
  stop('NOAA Stock SMART run identity or review status changed.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
rows <- match(candidate_ids, candidates$candidate_id)
if (anyNA(rows) || any(candidates$official_stock_id[rows] != c('10315', '11042')) ||
    any(candidates$scientific_name[rows] != 'Epinephelus itajara') ||
    !identical(candidates$assessment_area[rows],
      c('Gulf of Mexico', 'Southern Atlantic Coast / Gulf of Mexico')) ||
    any(candidates$inventory_assessment_year[rows] != '2016'))
  stop('NOAA goliath grouper inventory identities changed.', call. = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (any(stocks$scientific_name == 'Epinephelus itajara', na.rm = TRUE) ||
    any(assessments$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == candidate_unit_id, na.rm = TRUE))
  stop('A canonical goliath grouper record exists; recheck its identity.', call. = FALSE)

shared_note <- paste0(
  'Stock SMART IDs 10315 and 11042 point to the same 2016 SEDAR 47 assessment ' ,
  'family; the assessed population is Southeastern U.S., not two independent ' ,
  'Gulf-only and coastwide model units. The older 2010 Stock SMART row for ' ,
  '11042 is separate and was only partially accepted for status determinations. ' ,
  'This is a discovery screen only; no canonical data have been imported.')
review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste0(
    'The independent review states that the 2016 assessment had no age structure ' ,
    'in catch data. The assessment used an age composition from only 22 adult ' ,
    'research-fishery fish, which is not an annual fishery catch-at-age series.'),
  survey_age_evidence = paste0(
    'The four abundance indices are aggregate: three recreational catch-per-trip ' ,
    'series and one SCUBA visual index. No age-specific survey series is reported; ' ,
    'the small research age sample is not an index-at-age.'),
  weights_evidence = paste0(
    'The SEDAR report tabulates modeled mid-year weight-at-age in kg for ages 0-40. ' ,
    'This is a model-derived biological curve, not a complete annual observed ' ,
    'weight-at-age input series.'),
  maturity_evidence = paste0(
    'The report describes strong assumptions in reproductive functions and says ' ,
    'age/size at maturity and fecundity information are insufficient across the ' ,
    'stock range; no complete observed maturity-at-age input series was located.'),
  mortality_evidence = paste0(
    'The 2016 models use constant natural mortality despite documented episodic ' ,
    'cold-kill events; the review identifies this as a structural concern. No ' ,
    'supported time-varying M series was located.'),
  timing_evidence = paste0(
    'The reviewed report presents aggregate annual indices but does not specify ' ,
    'fractional-year survey timing. The current FWC monitoring framework uses ' ,
    'alternative population indicators rather than a full-scale traditional ' ,
    'age-structured assessment.'),
  output_evidence = paste0(
    'SEDAR 47 reports outputs from two age-structured production models, but the ' ,
    'review panel concluded they were not adequate for status inferences or ' ,
    'management advice; NOAA Stock SMART records both 2016 entries as rejected. ' ,
    'These are not accepted comparable official outputs for this audit.'),
  detailed_source_url = report_url,
  review_date = '2026-10-31',
  decision_reason = paste0(
    'Ineligible for the age-disaggregated source set. The latest detailed 2016 ' ,
    'SEDAR 47 benchmark was rejected as too uncertain for management use. Its ' ,
    'catch data have no age structure, and the only reported adult age sample ' ,
    'contains 22 research-fishery fish; aggregate indices do not supply ' ,
    'age-specific abundance observations. FWC now uses alternative management ' ,
    'goals and indicators rather than a full-scale traditional assessment.'),
  notes = shared_note)

pristine <- all(candidates$match_status[rows] == 'unreviewed' &
  candidates$screening_status[rows] == 'not_started' &
  candidates$eligibility[rows] == 'unresolved' &
  (is.na(candidates$candidate_unit_id[rows]) | !nzchar(candidates$candidate_unit_id[rows])))
already_reviewed <- all(vapply(names(review), function(column)
  all(as.character(candidates[[column]][rows]) == as.character(review[[column]])),
  logical(1L)))
if (!(pristine || already_reviewed))
  stop('The NOAA goliath grouper inventory rows have a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (i in seq_along(rows)) {
    for (column in names(review)) candidates[[column]][rows[i]] <- review[[column]]
    replace_candidate_register_row(register_path, rows[i],
      candidates[rows[i], , drop = FALSE], candidate_ids[i])
  }
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened the overlapping NOAA goliath grouper 2016 entries as one ineligible Southeastern U.S. unit.\n')

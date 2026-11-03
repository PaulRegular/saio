root <- "."
cache <- file.path(root, 'source_cache',
  'discovery_noaa_red_hind_sedar35_2014')
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
  NOAA_InPort_SEDAR_35.html = '02985097b604ec8828a86374283eec1fd59d50373bde80f1269a4f6adf981fe2',
  NOAA_SEDAR_91_lobster_scope.html = '348f25da759f3b54e6e563cb54a30d101d8cb648cc7879b8f2db801c3a44895a',
  SEDAR_103_project.html = 'effd82ca396f1804934cbbd41d355f1e64283d48681ed2c521efb0c8909acb94',
  SEDAR_35_project.html = '828cc067e75f9552cc94eb9a83dbac34a354101d3656b0030cb7780dc26bceb5',
  SEDAR_35_red_hind_report.pdf = 'e48d1ec231c3362624ae924938ac293fe48bb053e358b954bb3ab00d6656272c',
  SEDAR_46_data_limited_report.pdf = '10b549e47aaefd8f254513c45a0b728017c9261d6ef5bbe87944cede5019ece1',
  SEDAR_46_length_mortality_methods.pdf = '4a090a4cfb74d42ddacb838b843fb2864591122694c7ecb764aa5374da801c92',
  SEDAR_46_project.html = 'd80a02cfc2da6a5da5ca9fd0ce63d2038ce63bc014ed20b61d203be2fcab0596')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The red-hind source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached red-hind source differs from its manifest: ', file, call. = FALSE)
}

read_source <- function(file) paste(readLines(file.path(cache, file), warn = FALSE),
  collapse = ' ')
sedar35 <- read_source('SEDAR_35_project.html')
inport <- read_source('NOAA_InPort_SEDAR_35.html')
sedar46 <- read_source('SEDAR_46_project.html')
sedar91 <- read_source('NOAA_SEDAR_91_lobster_scope.html')
sedar103 <- read_source('SEDAR_103_project.html')
if (!grepl('SEDAR 35', sedar35, fixed = TRUE) ||
    !grepl('Caribbean Red Hind', sedar35, fixed = TRUE) ||
    !grepl('2014', inport, fixed = TRUE) ||
    !grepl('Completed', inport, fixed = TRUE) ||
    !grepl('SEDAR 46', sedar46, fixed = TRUE) ||
    !grepl('SEDAR 91 US Caribbean Spiny Lobster', sedar91, fixed = TRUE) ||
    !grepl('Actual Dissemination Date', sedar91, fixed = TRUE) ||
    !grepl('SEDAR 103 US Caribbean Application of Alternate Assessment Methods',
      sedar103, fixed = TRUE) ||
    !grepl('November 2026 through March 2027', sedar103, fixed = TRUE))
  stop('Cached official sources do not support the red-hind assessment identity.', call. = FALSE)
for (file in c('SEDAR_35_red_hind_report.pdf', 'SEDAR_46_data_limited_report.pdf',
    'SEDAR_46_length_mortality_methods.pdf')) {
  if (!identical(rawToChar(readBin(file.path(cache, file), 'raw', n = 4L)), '%PDF'))
    stop('Cached source is not a PDF: ', file, call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)

candidate_id <- 'NOAA:10327'
candidate_unit_id <- 'noaa_caribbean_red_hind'
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != '10327' ||
    candidates$scientific_name[row] != 'Epinephelus guttatus' ||
    candidates$stock_name[row] != 'Red hind - Caribbean' ||
    !candidates$assessment_area[row] %in% c('Caribbean',
      'U.S. Caribbean: Puerto Rico and U.S. Virgin Islands') ||
    any(candidates$candidate_unit_id[-row] == candidate_unit_id, na.rm = TRUE) ||
    any(as.character(stocks$authority_stock_id) == '10327', na.rm = TRUE) ||
    any(stocks$stock_id == candidate_unit_id) ||
    any(assessments$stock_id == candidate_unit_id) ||
    any(inputs$assessment_id == candidate_unit_id) ||
    any(outputs$assessment_id == candidate_unit_id))
  stop('Red-hind identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'U.S. Caribbean: Puerto Rico and U.S. Virgin Islands',
  catch_age_evidence = paste('SEDAR 35 (2014) uses fishery landings, effort, and annual length-frequency data. The report does not provide catch-at-age observations; age is used only to construct life-history and per-recruit calculations.'),
  survey_age_evidence = paste('SEDAR 35 reports standardized fishery CPUE and a SEAMAP-C relative-abundance index from southwest Puerto Rico, plus spawning-aggregation density series. These indices are aggregate and not age-specific abundance observations.'),
  weights_evidence = paste('Published length-weight relationships support per-recruit sensitivity analyses. The report does not document a model-ready annual weight-at-age input for an age-structured population model.'),
  maturity_evidence = paste('The SEDAR 35 spawner-per-recruit analysis assumes knife-edge maturity at age 3. This is a reference-point calculation, not an age-specific maturity surface used in a population time-series model.'),
  mortality_evidence = paste('Current total mortality is estimated from length data using a mean-length mortality estimator; fishing mortality is derived as Z minus natural mortality. Natural mortality is based on a maximum-age method. SEDAR 46 later applies length-based methods to six different Caribbean species-island units, not red hind.'),
  timing_evidence = paste('The assessment reports annual fishery CPUE and aggregate SEAMAP-C abundance observations. It does not specify timing for an age-specific survey index.'),
  output_evidence = paste('SEDAR 35 reports CPUE indices, length-based mortality estimates, and per-recruit reference-point calculations. It does not provide annual abundance-at-age, fishing mortality-at-age, natural mortality-at-age, recruitment, or spawning-biomass series for comparison.'),
  detailed_source_url = paste('https://sedarweb.org/assessments/sedar-35/;',
    'https://sedarweb.org/documents/sedar-35-caribbean-red-hind-final-stock-assessment-report/;',
    'https://www.fisheries.noaa.gov/inport/item/35718;',
    'https://sedarweb.org/assessments/sedar-46/;',
    'https://sedarweb.org/documents/sedar-46-final-stock-assessment-report-caribbean-data-limited-species/;',
    'https://sedarweb.org/documents/sedar-46-rw-01-estimating-total-mortality-rates-and-calculating-overfishing-limits-from-length-observations-for-six-u-s-caribbean-stocks/;',
    'https://www.noaa.gov/information-technology/sedar-91-us-caribbean-spiny-lobster;',
    'https://sedarweb.org/assessments/sedar-103-us-caribbean-application-of-alternate-assessment-methods/'),
  review_date = '2026-10-31',
  decision_reason = paste('SEDAR 35 (2014) is the latest completed red-hind-specific assessment located. SEDAR 46 (2016) reviewed 36 candidate species-island units but assessed six different units; red hind was not among them. The newer SEDAR 91 reports disseminated in 2025 concern US Caribbean spiny lobster, not red hind. SEDAR 35 is length-based and neither it nor the later projects located supplies the age-disaggregated inputs and annual population outputs required for this comparison.'),
  notes = paste('NOAA Stock SMART ID 10327 represents Caribbean red hind. SEDAR 35 contains Puerto Rico and U.S. Virgin Islands information, and SEDAR 46 considered Caribbean island units separately; these subareas are not separate Stock SMART entries for this candidate. This discovery screen creates no canonical stock, assessment, input, or output records.'))

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
already_reviewed <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) ||
    !nzchar(candidates$candidate_unit_id[row]))
if (!pristine && !already_reviewed)
  stop('Red-hind candidate already has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && !already_reviewed) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA Caribbean red hind as ineligible for age-disaggregated source curation.\n')

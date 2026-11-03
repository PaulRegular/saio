root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_herring_7ef_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:her.27.7ef'
unit_id <- 'ices_herring_7ef'
source_manifest <- file.path(cache, 'sources.csv')
report_excerpt <- file.path(cache, 'HAWG_2026_pages_414_419.txt')

manifest <- read.csv(source_manifest, stringsAsFactors = FALSE)
report_row <- match('source_cache/ck_ices_hawg_harengus_cs6_a_s_7b_c/HAWG_2026_full_report.pdf', manifest$file)
if (is.na(report_row)) stop('Source manifest is missing the current HAWG report.', call. = FALSE)
report_path <- file.path(root, manifest$file[report_row])
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
if (!file.exists(report_path) || !file.exists(report_excerpt) ||
    file.info(report_path)$size != manifest$bytes[report_row] ||
    sha256_file(report_path) != tolower(manifest$sha256[report_row]))
  stop('Cached HAWG 2026 report does not match its source manifest.', call. = FALSE)

excerpt <- gsub('[[:space:]]+', ' ', paste(readLines(report_excerpt, warn = FALSE), collapse = ' '))
required_evidence <- c(
  'only a landings time series is available',
  'There is no information on catches in number or weight',
  'There is no information on mean weight, maturity and natural mortality at age',
  'There is currently no assessment for herring in divisions 7.e-f',
  'Category 5, landing')
if (any(!vapply(required_evidence, grepl, logical(1L), x = excerpt, fixed = TRUE)))
  stop('Cached HAWG excerpt is missing evidence used for this screen.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L)
  stop('Expected exactly one ICES herring 7.e-f inventory row.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == 'her.27.7ef', na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical herring 7.e-f records.', call. = FALSE)

review <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = unit_id,
  organization = 'ICES',
  official_stock_id = 'her.27.7ef',
  scientific_name = 'Clupea harengus',
  stock_name = 'Herring (Clupea harengus) in divisions 7.e and 7.f (western English Channel and Bristol Channel).',
  assessment_area = 'Celtic Seas',
  inventory_assessment_year = 2026L,
  inventory_url = 'https://sid.ices.dk/services/year/2026',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2026 HAWG report says no catch numbers or weights are available for the stock; the advice method uses only a landings time series.',
  survey_age_evidence = 'The report describes exploratory groundfish and acoustic survey information, but no age-specific survey series is used in the current advice method. The report says the Category 5 method applies when only landings are available.',
  weights_evidence = 'The 2026 HAWG report explicitly states that mean weight-at-age information is unavailable.',
  maturity_evidence = 'The 2026 HAWG report explicitly states that maturity-at-age information is unavailable.',
  mortality_evidence = 'The 2026 HAWG report explicitly states that natural mortality-at-age information is unavailable.',
  timing_evidence = 'The report describes October groundfish and acoustic surveys, but they are not inputs to the current landings-only advice; no age-index timing is applicable.',
  output_evidence = 'The 2026 HAWG report states that there is no assessment and stock status is unknown. Category 5 advice is based on mean 2015–2024 landings with a 20% precautionary buffer; no population or age-specific outputs are reported.',
  detailed_source_url = 'https://doi.org/10.17895/ices.pub.31424315',
  review_date = '2026-10-30',
  decision_reason = 'The latest 2026 HAWG report says there is no assessment for this unit and that advice follows the landings-only Category 5 method. It explicitly reports no catch numbers, catch weights, mean weight-at-age, maturity-at-age, or natural mortality-at-age. The available advice and evidence do not support an age-disaggregated assessment record, so the unit is ineligible for the age-structured set.',
  notes = 'The ICES 2026 stock list originally recorded assessment year 2025; the 2026 HAWG report is the latest detailed source and describes the first advice for this unit. The report is cached once as a shared HAWG source at source_cache/ck_ices_hawg_harengus_cs6_a_s_7b_c/HAWG_2026_full_report.pdf; the candidate-specific cache manifest records its path, URL, retrieval date, revision, size, and checksum, and a local excerpt covers pages 414–419. No canonical assessment data or tinyAM translation were added.',
  stringsAsFactors = FALSE,
  check.names = FALSE
)

initial_state <- register$match_status[row] == 'unreviewed' &
  register$screening_status[row] == 'not_started' & register$eligibility[row] == 'unresolved'
reviewed_state <- register$match_status[row] == 'new' &
  register$candidate_unit_id[row] == unit_id & register$screening_status[row] == 'screened' &
  register$eligibility[row] == 'ineligible' &
  as.character(register$inventory_assessment_year[row]) == '2026'
if (register$official_stock_id[row] != review$official_stock_id ||
    register$scientific_name[row] != review$scientific_name ||
    (!initial_state && !reviewed_state))
  stop('ICES herring 7.e-f identity or review state conflicts with the source screen.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  needs_write <- initial_state || !all(vapply(names(review), function(name)
    identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
  if (needs_write) {
    for (name in names(review)) register[[name]][row] <- review[[name]]
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
  }
}
cat('Screened ICES herring her.27.7ef as ineligible for age-disaggregated assessment data.\n')

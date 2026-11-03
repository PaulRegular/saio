root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_thornback_ray_7e_2024')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:rjc.27.7e'
unit_id <- 'ices_thornback_ray_7e'
source_manifest <- file.path(cache, 'sources.csv')
advice_text <- file.path(cache, 'ICES_Advice_2024_text.txt')
wgef_text <- file.path(cache, 'WGEF_2024_pages_484-486_and_survey.txt')

manifest <- read.csv(source_manifest, stringsAsFactors = FALSE)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
verify_source <- function(relative_path) {
  row <- match(relative_path, manifest$file)
  if (is.na(row)) stop('Source manifest is missing ', relative_path, call. = FALSE)
  path <- file.path(root, relative_path)
  if (!file.exists(path) || file.info(path)$size != manifest$bytes[row] ||
      sha256_file(path) != tolower(manifest$sha256[row]))
    stop('Cached source does not match its manifest: ', relative_path, call. = FALSE)
  invisible(path)
}

verify_source('source_cache/discovery_ices_thornback_ray_7e_2024/rjc.27.7e_ICES_Advice_2024.pdf')
verify_source('source_cache/discovery_ices_thornback_ray_7e_2024/WGEF_2024_full_report.pdf')
advice <- gsub('[[:space:]]+', ' ', paste(readLines(advice_text, warn = FALSE), collapse = ' '))
wgef <- gsub('[[:space:]]+', ' ', paste(readLines(wgef_text, warn = FALSE), collapse = ' '))
if (!all(vapply(c('Assessment type No assessment', 'Input data Landings data',
  'There is no assessment for thornback ray in this area'), grepl, logical(1L),
  x = advice, fixed = TRUE)) ||
  !all(vapply(c('18.9.6 Thornback ray Raja clavata in Division 7.e',
    'Category 5 stock, using landings data', 'qualitative assessments',
    'not considered in the advice process in 2022 or 2024'), grepl, logical(1L),
    x = wgef, fixed = TRUE)))
  stop('Cached ICES sources are missing evidence used for this screen.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, register$candidate_id)
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L)
  stop('Expected exactly one ICES thornback ray 7.e inventory row.', call. = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
if (any(tolower(stocks$authority_stock_id) == 'rjc.27.7e', na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical thornback ray 7.e records.', call. = FALSE)

review <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = unit_id,
  organization = 'ICES',
  official_stock_id = 'rjc.27.7e',
  scientific_name = 'Raja clavata',
  stock_name = 'Thornback ray (Raja clavata) in Division 7.e (western English Channel)',
  assessment_area = 'Celtic Seas, Greater North Sea',
  inventory_assessment_year = 2024L,
  inventory_url = 'https://sid.ices.dk/services/year/2026',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2024 advice identifies the assessment type as no assessment and the input data as landings; no catch-at-age series is used or reported.',
  survey_age_evidence = 'The Q1SWECOS/UK-Q1-SWBeam survey provides preliminary biomass and length-frequency information, but WGEF calls it qualitative and says it was not considered in the 2022 or 2024 advice process; no age-specific index is used.',
  weights_evidence = 'The current advice is not based on an age-structured model; it reports no model weights-at-age.',
  maturity_evidence = 'The current advice is not based on an age-structured model; it reports no maturity-at-age input.',
  mortality_evidence = 'The current advice is not based on an age-structured model; it reports no natural-mortality-at-age input.',
  timing_evidence = 'The cited Q1 survey is exploratory and is not used quantitatively in advice; no assessment observation timing applies.',
  output_evidence = 'The 2024 advice reports landings-based precautionary advice through 2028, but no assessed population or age-specific outputs; stock status relative to reference points is not assessed.',
  detailed_source_url = 'https://doi.org/10.17895/ices.advice.25019522; https://doi.org/10.17895/ices.pub.26935504',
  review_date = '2026-10-30',
  decision_reason = 'Ineligible for the age-disaggregated assessment set. The latest advice is Category 5 and explicitly states no assessment, with landings as input data. The Q1 survey is described as qualitative information, not a quantitative input to advice; no age-specific population or mortality outputs are reported.',
  notes = 'The 2024 advice covers 2025–2028 and remains the latest official advice listed for this unit in the 2026 ICES inventory. WGEF reports that stock boundaries are unclear but provides advice separately for Division 7.e. Its exploratory beam-trawl survey does not change the assessment classification. No canonical records or tinyAM translation were added. Full advice and WGEF report are cached locally with source manifests.',
  stringsAsFactors = FALSE,
  check.names = FALSE
)

initial_state <- register$match_status[row] == 'unreviewed' &
  register$screening_status[row] == 'not_started' & register$eligibility[row] == 'unresolved'
reviewed_state <- register$match_status[row] == 'new' &
  register$candidate_unit_id[row] == unit_id & register$screening_status[row] == 'screened' &
  register$eligibility[row] == 'ineligible' & as.character(register$inventory_assessment_year[row]) == '2024'
if (register$official_stock_id[row] != review$official_stock_id ||
    register$scientific_name[row] != review$scientific_name ||
    (!initial_state && !reviewed_state))
  stop('ICES thornback ray 7.e identity or review state conflicts with the source screen.', call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  needs_write <- initial_state || !all(vapply(names(review), function(name)
    identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
  if (needs_write) {
    for (name in names(review)) register[[name]][row] <- review[[name]]
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
  }
}
cat('Screened ICES thornback ray rjc.27.7e as ineligible for age-disaggregated assessment data.\n')

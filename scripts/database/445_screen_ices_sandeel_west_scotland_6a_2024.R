root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_sandeel_6a_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:san.27.6a'
unit_id <- 'ices_sandeel_west_scotland_6a'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
expected <- c(
  HAWG_report_2025.pdf = 'd04e0246df5f474ee7320e3996f5d78bfc24a3ec5c4b0d0f29a5a57e7c2679fe',
  ICES_2024_advice.html = '3de8528b28c81241b962e716ae52e8187b3a6f2a7ac6248ac2010c6f1af59926'
)
if (nrow(manifest) != length(expected) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected)))
  stop('The sandeel source manifest is incomplete.', call. = FALSE)
for (file in names(expected)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected[[file]] ||
      sha256_file(path) != expected[[file]])
    stop('Cached sandeel source differs from its manifest: ', file, call. = FALSE)
}

advice <- paste(readLines(file.path(cache, 'ICES_2024_advice.html'), warn = FALSE),
  collapse = ' ')
report <- readBin(file.path(cache, 'HAWG_report_2025.pdf'), 'raw', n = 4L)
if (!all(vapply(c('san.27.6a', 'Assessment Year', '2024', 'Stock Category',
    'zero catches in each of the years 2024, 2025, and 2026'), grepl, logical(1L),
    x = advice, fixed = TRUE)) || rawToChar(report) != '%PDF')
  stop('The cached ICES advice does not match sandeel Division 6.a.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != 'san.27.6a' ||
    candidates$scientific_name[row] != 'Ammodytes' ||
    !candidates$assessment_area[row] %in% c('Celtic Seas, Greater North Sea',
      'Division 6.a (West of Scotland)') ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'san.27.6a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('ICES sandeel identity conflicts with the register or canonical database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'Division 6.a (West of Scotland)',
  catch_age_evidence = 'The current ICES advice is category 6 and the latest HAWG report describes zero-catch advice under that data-limited method. The reviewed current-unit sources do not identify a catch-at-age likelihood or age-composition input.',
  survey_age_evidence = 'No age-specific survey abundance series or age-composition input was identified for the current category-6 advice. No age-structured population assessment is reported for this unit in the reviewed current sources.',
  weights_evidence = 'No age-structured production model requiring weights-at-age was identified for the current advice.',
  maturity_evidence = 'No age-structured production model requiring maturity-at-age was identified for the current advice.',
  mortality_evidence = 'The reviewed current advice is category 6; no quantitative age-specific natural-mortality assumption or age-structured production model was identified.',
  timing_evidence = 'No survey index entering an age-structured production model was identified; within-year survey timing is not applicable to the reviewed advice method.',
  output_evidence = 'ICES advice provides a zero-catch recommendation for 2024-2026. The reviewed current sources do not provide recruitment, SSB, N-at-age, F-at-age, or other fitted population trajectories for this unit.',
  detailed_source_url = paste(
    'https://asd.ices.dk/viewAdvice/3544;',
    'https://doi.org/10.17895/ices.advice.25019645;',
    'https://orbit.dtu.dk/en/publications/herring-assessment-working-group-for-the-area-south-of-62-north-h/;',
    'https://github.com/ices-eg/wg_HAWG'),
  review_date = '2026-10-31',
  decision_reason = 'The latest official advice located is assessment year 2024, with advice through 2026, and is classified by ICES as category 6. The 2025 HAWG report confirms zero-catch advice under that data-limited method. No current age-disaggregated inputs or fitted population outputs were identified, so this is not eligible for the age-structured source-curation set.',
  notes = 'The HAWG repository was checked; its published stock folders do not include a Division 6.a sandeel production assessment (the VIa folder is the Malin herring work). A TAF search found only the distinct historical san.sa.6 unit, not san.27.6a. The full 2025 HAWG report and ICES advice page are cached with provenance under source_cache/discovery_ices_sandeel_6a_2025. No canonical stock, assessment, input, or output records were added.'
)

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('ICES sandeel candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES sandeel in Division 6.a as ineligible for age-structured source curation.\n')

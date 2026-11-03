root <- "."
candidate_id <- 'NOAA:11728'
unit_id <- 'wcpfc_wcpo_silky_shark'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == candidate_id, , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == unit_id, , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
pifsc <- noaa[noaa$source_region == 'PIFSC', , drop = FALSE]
cache <- file.path(root, 'source_cache', 'discovery_noaa_wcpfc_silky_shark_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('WCPFC_SC20-SA-WP-04_2024_Rev2.pdf',
  'WCPFC21-2024-27_Status_of_fisheries_and_stocks_Rev02.pdf',
  'WCPFC_SC14-SA-WP-08a_2018_silky_shark_addendum.pdf',
  'WPFMC_Pelagic_FEP_SAFE_Report_2024.pdf')
source_rows <- manifest[match(required, manifest$file), , drop = FALSE]
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
e <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), e)
s <- e$stock_assessment_summary
latest <- s[as.character(s$stock_id) == '11728', , drop = FALSE]
latest <- latest[which.max(as.integer(latest$assessment_year)), , drop = FALSE]
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(nrow(candidate) == 1L,
  candidate$match_status == 'new',
  candidate$candidate_unit_id == unit_id,
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  candidate$review_date == '2026-11-02',
  grepl('catch-at-length', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not age-specific', candidate$survey_age_evidence, fixed = TRUE),
  grepl('experimental', candidate$output_evidence, fixed = TRUE),
  grepl('Full acceptance', candidate$notes, fixed = TRUE),
  grepl('2018 assessment as a reference', candidate$notes, fixed = TRUE),
  nrow(unit) == 1L,
  unit$match_status == 'new',
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  unit$import_status == 'not_started',
  unit$candidate_ids == candidate_id,
  nrow(latest) == 1L,
  latest$assessment_id == 13564L,
  latest$assessment_year == 2024L,
  latest$last_data_year == 2022L,
  latest$science_center == 'PIFSC',
  latest$assessment_model == 'SS',
  latest$model_version == 'V.30.22.1',
  latest$review_result == 'Full acceptance',
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(pifsc) == 1L,
  pifsc$screening_complete == 45L,
  pifsc$screening_not_started == 0L,
  nrow(source_rows) == length(required),
  all(file.exists(file.path(cache, required))),
  all(file.info(file.path(cache, required))$size == as.numeric(source_rows$bytes)),
  all(grepl('^[[:xdigit:]]{64}$', source_rows$sha256)),
  all(vapply(file.path(cache, required), sha256_file, character(1)) ==
    tolower(source_rows$sha256)),
  file.exists(file.path(root, 'discovery', 'source_reviews', 'noaa_wcpfc_silky_shark_2024.md')),
  !any(stocks$scientific_name == 'Carcharhinus falciformis', na.rm = TRUE),
  !any(grepl(unit_id, assessments$assessment_id, fixed = TRUE)),
  !any(grepl(unit_id, inputs$assessment_id, fixed = TRUE)),
  !any(grepl(unit_id, outputs$assessment_id, fixed = TRUE)))
cat('NOAA 11728 WCPO silky shark identity, source, eligibility and no-import checks passed.\n')

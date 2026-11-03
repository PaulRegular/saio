root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_roundnose_grenadier_oceanic_2023')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:rng.27.5a10b12ac14b'
unit_id <- 'ices_roundnose_grenadier_oceanic'

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
expected_hash <- 'ad8e9a851a2beba5fb5816f7b124535a8fafe4b1c0fac3321a3cc40a1f27493d'
source_file <- 'ICES_2023_advice.html'
source_path <- file.path(cache, source_file)
source_row <- match(source_file, manifest$file)
if (nrow(manifest) != 1L || is.na(source_row) || !file.exists(source_path) ||
    manifest$retrieved_on[source_row] != '2026-10-31' ||
    as.numeric(manifest$bytes[source_row]) != file.info(source_path)$size ||
    tolower(manifest$sha256[source_row]) != expected_hash ||
    sha256_file(source_path) != expected_hash)
  stop('Cached roundnose-grenadier advice differs from its manifest.', call. = FALSE)

advice <- paste(readLines(source_path, warn = FALSE), collapse = ' ')
if (!all(vapply(c('rng.27.5a10b12ac14b', 'Assessment Year', '2023',
    'Stock Category', 'Oceanic Northeast Atlantic and northern Reykjanes Ridge',
    'no more than 459 tonnes', 'cannot quantify the corresponding catches'),
    grepl, logical(1L), x = advice, fixed = TRUE)))
  stop('Cached ICES advice does not match the roundnose-grenadier stock.', call. = FALSE)

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
    candidates$official_stock_id[row] != 'rng.27.5a10b12ac14b' ||
    candidates$scientific_name[row] != 'Coryphaenoides rupestris' ||
    !candidates$assessment_area[row] %in% c('Oceanic Northeast Atlantic',
      'Oceanic Northeast Atlantic and northern Reykjanes Ridge') ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(tolower(stocks$authority_stock_id) == 'rng.27.5a10b12ac14b', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id),
      na.rm = TRUE))
  stop('ICES roundnose-grenadier identity conflicts with the register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  assessment_area = 'Oceanic Northeast Atlantic and northern Reykjanes Ridge',
  catch_age_evidence = 'The 2023 ICES advice is category 5 and sets a landings limit of 459 tonnes for 2024-2027, while explicitly stating that corresponding catches cannot be quantified. The reviewed current-unit sources do not identify catch-at-age or age-composition inputs.',
  survey_age_evidence = 'No age-specific survey index or age composition is reported in the reviewed current advice record. ICES category 5 is defined as landings-only in its advice framework.',
  weights_evidence = 'No age-structured assessment inputs or weights-at-age were identified in the reviewed current advice record.',
  maturity_evidence = 'No age-structured assessment inputs or maturity-at-age were identified in the reviewed current advice record.',
  mortality_evidence = 'The reviewed current advice record does not report an age-structured model or quantitative natural-mortality assumption.',
  timing_evidence = 'The reviewed current advice record does not report a survey index used for age-structured assessment; survey timing is not applicable to the reported advice.',
  output_evidence = 'The reviewed current advice record reports a landings limit and says corresponding catches cannot be quantified. It does not report fitted SSB, recruitment, N-at-age, F-at-age, or other population trajectories.',
  detailed_source_url = paste('https://asd.ices.dk/viewAdvice/3416;',
    'https://doi.org/10.17895/ices.advice.21828432;',
    'https://www.ices.dk/about-ICES/Documents/Cooperation%20agreements/EU/2023_Grant_DGMARE-ICES_web.pdf'),
  review_date = '2026-10-31',
  decision_reason = 'The latest official advice record located is assessment year 2023, active for 2024-2027, and identifies the stock as category 5. ICES defines category 5 as landings-only stocks. The advice says corresponding catches cannot be quantified and provides no population trajectories. This does not meet the age-disaggregated input and output screen.',
  notes = 'No matching current stock exists in the canonical database. Review is limited to the official advice record and ICES category definition; no separate detailed assessment report or model files were identified. The advice page is cached with provenance under source_cache/discovery_ices_roundnose_grenadier_oceanic_2023. No canonical stock, assessment, input, or output records were added.'
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
  stop('ICES roundnose-grenadier candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES oceanic roundnose grenadier as ineligible for age-structured source curation.\n')

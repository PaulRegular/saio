root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_dogfish_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:syc.27.3a47d'
unit_id <- 'ices_lesser_spotted_dogfish_3a47d'
file <- 'wgef_2025.pdf'
url <- 'https://literatur.thuenen.de/digbib_extern/dn070539.pdf'
revision <- paste('ICES. 2025. Working Group on Elasmobranch Fishes (WGEF), ICES Scientific Reports 7(92),',
  '934 pp.; DOI 10.17895/ices.pub.30137623. Stock section 15.9.5 (printed pp. 291-294), section 21 (printed pp. 596-647), section 22 (printed pp. 648-669), section 23 (printed pp. 670-674), section 25.6.1 (printed pp. 697-698), section 25.9.2 (printed pp. 705-709), section 25.9.3 (printed pp. 710-713), and section 25.9.5 (printed pp. 716-722).')
path <- file.path(cache, file)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (!file.exists(path) || !file.exists(file.path(cache, 'sources.csv')))
  stop('Cache the reviewed WGEF report before screening ', id, '.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_row <- match(file, sources$file)
if (is.na(source_row) || sources$url[source_row] != url ||
    sources$revision[source_row] != revision || sources$retrieved_on[source_row] != '2026-10-30' ||
    as.numeric(sources$bytes[source_row]) != file.info(path)$size ||
    toupper(sources$sha256[source_row]) != sha256_file(path) ||
    !identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'))
  stop('Cached WGEF report differs from its reviewed source manifest.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
row <- match(id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != 'syc.27.3a47d' ||
    candidates$scientific_name[row] != 'Scyliorhinus canicula' ||
    candidates$inventory_assessment_year[row] != 2025L ||
    any(tolower(stocks$authority_stock_id) == 'syc.27.3a47d', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('ICES lesser-spotted dogfish identity conflicts with the register or canonical database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2025 Category 3 rfb assessment uses landings and length-based catch indicators; it reports no catch-at-age or age-composition likelihood.',
  survey_age_evidence = 'The stock indicator is a combined total-biomass index standardized with a Tweedie GAM from five trawl surveys; no survey numbers-at-age or age composition are used.',
  weights_evidence = 'The assessment uses aggregate biomass indices and does not use or report weight-at-age.',
  maturity_evidence = 'The Category 3 rfb rule does not use maturity-at-age inputs.',
  mortality_evidence = 'The assessment derives a length-based fishing-pressure proxy using LF=M and external life-history information; it does not estimate age-specific F or M.',
  timing_evidence = 'The combined stock indicator uses NS-IBTS Q1 and Q3, FR-CGFS Q4, BTS-BEL Q3, and BTS-Eng Q3 biomass surveys.',
  output_evidence = 'The 2025 rfb assessment reports a 2004-2024 relative biomass index and catch advice of 2765 tonnes for 2026-2027, not N-at-age, F-at-age, M-at-age, SSB, or recruitment.',
  detailed_source_url = 'https://doi.org/10.17895/ices.pub.30137623',
  review_date = '2026-10-30',
  decision_reason = 'The latest detailed 2025 WGEF source identifies this as an ICES Category 3 rfb assessment based on aggregate survey biomass and length-based catch indicators. No age-disaggregated assessment inputs or population outputs are reported, so the unit is ineligible for the age-disaggregated set.',
  notes = 'Section 25.6.1 documents the five-survey biomass index; section 25.9.2 gives the Category 3 rfb rule, annual relative indices and 2026-2027 advice. Life-history parameters are cited from vertebral samples collected in the Irish Sea, but are not a stock-specific age-structured assessment likelihood. No canonical numerical records or tinyAM translation were added. The WGEF report is cached in source_cache/discovery_ices_dogfish_2025/sources.csv.')

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('ICES lesser-spotted dogfish candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row, candidates[row, , drop = FALSE], id)
}

cat('Screened ICES lesser-spotted dogfish as ineligible for age-disaggregated assessment inputs and outputs.\n')

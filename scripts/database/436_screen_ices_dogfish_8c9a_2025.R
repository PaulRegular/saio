root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_dogfish_2025')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:syc.27.8c9a'
unit_id <- 'ices_lesser_spotted_dogfish_8c9a'
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
  stop('Cache the reviewed 2025 WGEF report before screening ', candidate_id, '.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_row <- match(file, sources$file)
if (is.na(source_row) || sources$url[source_row] != url ||
    sources$revision[source_row] != revision || sources$retrieved_on[source_row] != '2026-10-30' ||
    as.numeric(sources$bytes[source_row]) != file.info(path)$size ||
    toupper(sources$sha256[source_row]) != sha256_file(path) ||
    !identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'))
  stop('Cached WGEF source differs from its provenance manifest.', call. = FALSE)

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
if (is.na(row) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    register$official_stock_id[row] != 'syc.27.8c9a' ||
    register$scientific_name[row] != 'Scyliorhinus canicula' ||
    any(tolower(stocks$authority_stock_id) == 'syc.27.8c9a', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) || any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('Iberian dogfish identity conflicts with the candidate register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2025 WGEF report gives landings and Spanish/Portuguese commercial landings',
    'length-frequency data, but does not describe catch numbers-at-age or an age-composition likelihood.'),
  survey_age_evidence = paste('The assessment combines normalized biomass indices from four trawl survey series',
    'for 1993-2024; these are aggregate survey indices, not age-specific abundance observations.'),
  weights_evidence = paste('The length-based indicator uses life-history growth parameters (Linf 70 cm and',
    'k = 0.15); the reviewed assessment does not report age-specific weights.'),
  maturity_evidence = 'The reviewed length-based assessment does not report maturity-at-age inputs.',
  mortality_evidence = paste('The length-based fishing-pressure proxy uses the length at which F = M, derived',
    'from growth parameters; the report does not describe an age-specific natural-mortality process.'),
  timing_evidence = paste('The combined index uses the Portuguese Q4 survey, Spanish Gulf of Cadiz Q1 and Q4',
    'surveys, and Northern Spanish Q4 survey. These are quarter-specific aggregate indices, not timed age-structured observations.'),
  output_evidence = paste('The 2025 report provides a normalized aggregate biomass index, length-based fishing-pressure',
    'indicators, and an RFB calculation. It reports no N-at-age, F-at-age, M-at-age, SSB, or recruitment series; advice for 2026-2027 was not requested.'),
  detailed_source_url = paste('https://doi.org/10.17895/ices.pub.30137623;',
    'https://literatur.thuenen.de/digbib_extern/dn070539.pdf;',
    'https://asd.ices.dk/viewAdvice/3507'),
  review_date = '2026-10-30',
  decision_reason = paste('The latest detailed assessment located is in the 2025 WGEF report. It updates the',
    'length-based assessment using 2023-2024 length observations and aggregate survey biomass indices. The production assessment does not use age-disaggregated inputs or report age-specific population outputs, so this unit is ineligible for the age-disaggregated set. This does not establish that age samples are absent outside the assessment.'),
  notes = paste('The 2025 WGEF report explicitly states that a new assessment was done for this stock in',
    '2025. ICES did not receive a request for fishing-opportunity advice for 2026-2027; the report presents the assessment indicators and rule-based calculation. The candidate is a distinct ICES unit and has no exact match in the canonical stock table. The report PDF is cached under source_cache/discovery_ices_dogfish_2025/ with retrieval date and SHA-256 in sources.csv. No canonical data or tinyAM translation were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' && register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' && register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('Iberian dogfish candidate already has a conflicting review state.', call. = FALSE)

review_matches <- all(vapply(names(review), function(name)
  identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (initial || !review_matches)) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
}

cat('Screened ICES lesser spotted dogfish in divisions 8.c and 9.a as ineligible for age-disaggregated inputs and outputs.\n')

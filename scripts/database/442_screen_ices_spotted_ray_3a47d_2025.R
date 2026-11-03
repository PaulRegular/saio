root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_dogfish_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:rjm.27.3a47d'
unit_id <- 'ices_spotted_ray_3a47d'
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
    candidates$official_stock_id[row] != 'rjm.27.3a47d' ||
    candidates$scientific_name[row] != 'Raja montagui' ||
    candidates$inventory_assessment_year[row] != 2025L ||
    any(tolower(stocks$authority_stock_id) == 'rjm.27.3a47d', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('ICES spotted ray identity conflicts with the register or canonical database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2025 SPiCT assessment uses reported and reconstructed landings and dead discards as total catches. The report provides no catch-at-age or age-composition likelihood.'),
  survey_age_evidence = paste('The assessment combines two seasonal aggregate biomass indices using a Delta-lognormal GAM across multiple trawl surveys. The indices are not survey numbers-at-age or age compositions.'),
  weights_evidence = 'The survey inputs are aggregate biomass indices, not weight-at-age.',
  maturity_evidence = 'No maturity-at-age inputs are used by the continuous-time surplus production model.',
  mortality_evidence = paste('SPiCT estimates aggregate relative fishing pressure and biomass; no age-specific F or M estimates are reported.'),
  timing_evidence = paste('The assessment combines NS-IBTS-Q1 with FR-CGFS-Q4 into one seasonal index and combines the Q3 survey series into a second aggregate index.'),
  output_evidence = paste('The converged 2025 SPiCT assessment reports relative biomass and relative fishing pressure, retrospective and hindcast diagnostics, and catch advice for 2026-2027. It does not report N-at-age, F-at-age, M-at-age, SSB, or recruitment.'),
  detailed_source_url = 'https://doi.org/10.17895/ices.pub.30137623',
  review_date = '2026-10-30',
  decision_reason = paste('The latest 2025 WGEF report documents a converged continuous-time SPiCT surplus-production assessment using total catches and aggregate seasonal survey-biomass indices. It contains no catch-at-age, age-composition likelihood, or age-specific population outputs. The unit is ineligible for the age-disaggregated set.'),
  notes = paste('WGEF reports the assessment used total catch (landings plus dead discards), two aggregate survey indices, and a length-derived fishing proxy; the reported relative biomass and fishing pressure are not SSB or F-at-age. The 2025 assessment informs advice for 2026-2027. No canonical numerical records were added. The report PDF is shared in source_cache/discovery_ices_dogfish_2025/sources.csv; its manifest revision includes section 15.9.5.'))

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('ICES spotted ray candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row, candidates[row, , drop = FALSE], id)
}

cat('Screened ICES spotted ray as ineligible for age-disaggregated assessment inputs and outputs.\n')

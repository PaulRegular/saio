root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_dogfish_2025')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
id <- 'ICES:sdv.27.nea'
unit_id <- 'ices_smooth_hounds_nea'
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
    candidates$official_stock_id[row] != 'sdv.27.nea' ||
    candidates$scientific_name[row] != 'Mustelus asterias' ||
    candidates$inventory_assessment_year[row] != 2025L ||
    any(tolower(stocks$authority_stock_id) == 'sdv.27.nea', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(unit_id %in% c(assessments$stock_id, inputs$assessment_id, outputs$assessment_id), na.rm = TRUE))
  stop('ICES smooth-hounds identity conflicts with the register or canonical database.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new', screening_status = 'screened', eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('WGEF reports commercial length compositions for recent years, but no catch-at-age or age-composition likelihood. The current rule uses length data only to calculate a fishing-pressure proxy.'),
  survey_age_evidence = paste('The 2025 assessment combines four equal-weighted fishery-independent survey biomass indices (using a >=50 cm LT size threshold) after standardization. These are aggregate size-based indices, not survey numbers-at-age.'),
  weights_evidence = paste('Survey stock-size indicators are aggregate biomass; some use on-board catch weights and others use a length-weight relationship. No assessment weights-at-age are reported.'),
  maturity_evidence = paste('The report summarizes maturity-at-length and age-and-growth studies for Mustelus asterias, but these are not annual maturity-at-age inputs to the current rfb rule.'),
  mortality_evidence = paste('The rule uses a length-based fishing proxy f, not estimated fishing mortality; the report gives no age-specific F or M estimates.'),
  timing_evidence = paste('The assessment combines NS-IBTS-Q1 and Q3 with EVHOE-WIBTS-Q4, FR-CGFS, and IE-IGFS-WIBTS-Q4 survey series. The combined indices are aggregate biomass trends, not age-specific observations.'),
  output_evidence = paste('The 2025 rfb rule reports survey-based stock-size indicators and fishing-proxy inputs, and advises landings of no more than 6,395 t in each of 2026 and 2027. It does not report N-at-age, F-at-age, M-at-age, SSB, or recruitment.'),
  detailed_source_url = 'https://doi.org/10.17895/ices.pub.30137623',
  review_date = '2026-10-30',
  decision_reason = paste('The 2025 WGEF report documents a current category-3 rfb assessment based on aggregate survey biomass trends and recent commercial length data. It does not use catch-at-age, annual age compositions, or age-specific abundance indices and reports no age-structured population outputs. The unit is ineligible for the age-disaggregated set.'),
  notes = paste('The ICES advice unit is smooth-hounds (Mustelus spp.), while the fishery-independent survey signal is primarily starry smooth-hound (Mustelus asterias) and commercial data may include other Mustelus species. Preserve this species-composition caveat if the assessment is later curated for non-age-structured use. The 2025 advice applies to 2026-2027. No canonical numerical records or tinyAM translation were added. The WGEF report PDF is shared in source_cache/discovery_ices_dogfish_2025/sources.csv; its manifest revision now includes sections 21, 22, 23, 25.9.3 and 25.9.5.'))

is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
if (!is_unreviewed && !same_review)
  stop('ICES smooth-hounds candidate already has a conflicting review.', call. = FALSE)
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (is_unreviewed || !same_review)) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row, candidates[row, , drop = FALSE], id)
}

cat('Screened ICES Northeast Atlantic smooth-hounds as ineligible for age-disaggregated assessment inputs and outputs.\n')

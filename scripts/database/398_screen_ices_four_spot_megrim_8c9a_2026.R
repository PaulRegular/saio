root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_four_spot_megrim_8c9a_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'ICES:ldb.27.8c9a'
unit_id <- 'ices_four_spot_megrim_8c9a'

files <- c(
  'four_spot_megrim_stock_annex_2026.pdf',
  'four_spot_megrim_sag_2026.html',
  'four_spot_megrim_advice_2026.html')
urls <- c(
  'https://ndownloader.figshare.com/files/66953591',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=26018',
  'https://asd.ices.dk/viewAdvice/7266')
revisions <- c(
  'ICES Stock Annex revision 2, published 2026-07-24; DOI 10.17895/ices.pub.23261030.v2',
  'ICES Standard Graphs source data, assessment year 2026, key 26018',
  'ICES advice record 7266; assessment year 2026; assessment key 26018')
paths <- file.path(cache, files)
manifest_path <- file.path(cache, 'sources.csv')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 100L))
  stop('Cache the reviewed four-spot megrim sources before screening.', call. = FALSE)
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
source_rows <- match(files, manifest$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed source.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(manifest$url[source_rows]), urls),
  revisions = identical(as.character(manifest$revision[source_rows]), revisions),
  hashes = identical(toupper(as.character(manifest$sha256[source_rows])),
    unname(vapply(paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(manifest$bytes[source_rows]), as.numeric(file.info(paths)$size)))
if (!all(source_valid)) stop('Cached four-spot megrim source manifest check failed: ',
  paste(names(source_valid)[!source_valid], collapse = ', '), call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

row_index <- match(candidate_id, register$candidate_id)
if (is.na(row_index) || sum(register$candidate_id == candidate_id, na.rm = TRUE) != 1L)
  stop('Expected exactly one ICES four-spot megrim candidate row.', call. = FALSE)
if (any(tolower(stocks$authority_stock_id) == tolower('ldb.27.8c9a'), na.rm = TRUE) ||
    any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical four-spot megrim records.', call. = FALSE)

review <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = unit_id,
  organization = 'ICES',
  official_stock_id = 'ldb.27.8c9a',
  scientific_name = 'Lepidorhombus boscii',
  stock_name = 'Four-spot megrim in divisions 8.c and 9.a',
  assessment_area = 'Southern Bay of Biscay and Atlantic Iberian waters East',
  inventory_assessment_year = 2026L,
  inventory_url = 'https://sid.ices.dk/services/year/2026',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The 2026 Stock Annex documents landings-at-age and discards-at-age in numbers for ages 0–6+ from 1986 onward. Landings age compositions use Spanish annual age-length keys from 1990; a survey key combined with the annual key is used for 1986–1989. The numeric run-matched matrices remain to be recovered.'),
  survey_age_evidence = paste('The 2026 Stock Annex documents Spanish SpGFS-WIBTS-Q4 (G2784) and Portuguese PT-CTS-UWTV-FU 28–29 age-specific indices. The Portuguese fitted series is 1997–2018, ages 1–6. The Spanish survey is available from 1983, but the model input table starts the fitted series in 1990 and lists ages 0–6; its survey summary lists ages 1–6. Resolve this source inconsistency and recover the run-matched matrix.'),
  weights_evidence = 'The 2026 Stock Annex states that catch weights-at-age are also used as stock weights-at-age, ages 0–6+, from 1986 onward.',
  maturity_evidence = 'The 2026 Stock Annex documents a time-invariant female maturity ogive for ages 0, 1, 2, 3, 4, and 5+ of 0, 0.05, 0.32, 0.83, 0.98, and 1.',
  mortality_evidence = 'Natural mortality is fixed at M = 0.2 for all ages and years.',
  timing_evidence = 'Both age-specific indices are fourth-quarter surveys. Exact fractional-year timing is not stated in the 2026 Stock Annex.',
  output_evidence = paste('The current 2026 ICES Standard Graphs source data (key 26018) report historical age-0 recruitment, SSB, total biomass, landings, discards, and F for ages 2–4 through 2025, with reported low/high bounds for recruitment, SSB, and F. The 2026 row is a projection. Numeric historical N-at-age and F-at-age surfaces were not found.'),
  detailed_source_url = paste(c(
    'https://doi.org/10.17895/ices.pub.23261030.v2',
    'https://doi.org/10.17895/ices.pub.32790321.v1',
    'https://asd.ices.dk/viewAdvice/7266',
    'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=26018'), collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('The current 2026 ICES assessment is an age-structured a4a model documented in the July 2026 Stock Annex, and its current Standard Graphs entry provides annual recruitment, SSB, and F ages 2–4 outputs with reported bounds. The stock is eligible for source curation. Numeric run-matched catch and survey age matrices and exact survey timing remain follow-ups; eligibility does not mean every input matrix has been recovered.'),
  notes = paste('This is a new current ICES stock unit with no canonical database record. The Spanish survey coverage differs between the Annex narrative and its input tables and needs follow-up. The 2026 output row is a projection, not a fitted terminal year. The Stock Annex, current advice and Standard Graphs source data are cached with provenance under source_cache/discovery_ices_four_spot_megrim_8c9a_2026/. No canonical values were added.'),
  stringsAsFactors = FALSE,
  check.names = FALSE)

initial_state <- register$match_status[row_index] == 'unreviewed' &
  register$screening_status[row_index] == 'not_started' &
  register$eligibility[row_index] == 'unresolved'
reviewed_state <- register$match_status[row_index] == 'new' &
  register$candidate_unit_id[row_index] == unit_id &
  register$screening_status[row_index] == 'screened' &
  register$eligibility[row_index] == 'eligible'
expected_identity <- register$official_stock_id[row_index] == review$official_stock_id &
  register$scientific_name[row_index] == review$scientific_name &
  as.character(register$inventory_assessment_year[row_index]) ==
    as.character(review$inventory_assessment_year)
if (!expected_identity || (!initial_state && !reviewed_state))
  stop('Four-spot megrim candidate identity or review state conflicts with the source review.',
    call. = FALSE)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  needs_write <- initial_state || !all(vapply(names(review), function(name)
    identical(as.character(register[[name]][row_index]), as.character(review[[name]])), logical(1L)))
  if (needs_write) {
    for (name in names(review)) register[[name]][row_index] <- review[[name]]
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], candidate_id)
  }
}
cat('Screened ICES four-spot megrim ldb.27.8c9a as eligible for age-disaggregated source curation.\n')

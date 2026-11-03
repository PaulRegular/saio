root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_data_moderate_2013_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10428'
candidate_unit_id <- 'noaa_pacific_stripetail_rockfish'
source_files <- c('data_moderate_rockfish_2013.pdf',
  'pacific_groundfish_safe_july_2025.pdf',
  'preliminary_2027_assessment_recommendations_2026.pdf',
  'amendment_37_stock_definition_analysis_2026.pdf')
source_urls <- c(
  'https://www.pcouncil.org/documents/2015/01/data-moderate-stock-assessments-for-brown-china-copper-sharpchin-stripetail-and-yellowtail-rockfishes-and-english-and-rex-soles-in-2013-published-january-2015.pdf',
  'https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/',
  'https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf/',
  'https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf')
source_revisions <- c('2013 data-moderate assessment, published January 2015',
  'July 2025 Pacific Coast Groundfish SAFE',
  'February 2026 preliminary NMFS recommendations for 2027 assessments',
  'February 2026 NOAA/PFMC Amendment 37 Phase 2 stock-definition analysis')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 1000L))
  stop('Cache the reviewed NOAA Stripetail sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed PDF.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (!all(source_valid)) stop('Cached NOAA Stripetail source manifest check failed: ',
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
if (sum(register$candidate_id == candidate_id) != 1L)
  stop('Expected one NOAA Pacific Coast Stripetail inventory row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10428', na.rm = TRUE) ||
    any(assessments$assessment_id == 'noaa_pacific_stripetail_rockfish_2013', na.rm = TRUE) ||
    any(inputs$assessment_id == 'noaa_pacific_stripetail_rockfish_2013', na.rm = TRUE) ||
    any(outputs$assessment_id == 'noaa_pacific_stripetail_rockfish_2013', na.rm = TRUE))
  stop('Screening must not create canonical Stripetail assessment records.', call. = FALSE)

row <- match(candidate_id, register$candidate_id)
initial_state <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved'
current_state <- register$candidate_unit_id[row] == candidate_unit_id &&
  register$match_status[row] == 'new' && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (register$scientific_name[row] != 'Sebastes saxicola' ||
    register$inventory_assessment_year[row] != 2013 ||
    register$stock_name[row] != 'Stripetail rockfish - Pacific Coast' ||
    (!initial_state && !current_state))
  stop('NOAA Stripetail inventory identity or review state conflicts with the source review.', call. = FALSE)

all_urls <- c('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10428',
  source_urls)
screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = 'NOAA',
  official_stock_id = '10428',
  scientific_name = 'Sebastes saxicola',
  stock_name = 'Stripetail rockfish - Pacific Coast',
  assessment_area = 'Pacific Coast',
  inventory_assessment_year = '2013',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10428',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2013 run uses annual catch totals in biomass units; its native data file explicitly specifies zero age-composition observations. Internal 38-age population structure does not supply observed catch-at-age.',
  survey_age_evidence = 'The run uses three aggregate fishery-independent trawl biomass indices; its data file specifies zero age-composition observations and zero mean-size-at-age observations.',
  weights_evidence = 'The exSSS run includes sex-specific growth and weight-length settings, but the reviewed run does not provide the age-specific observation inputs required for this screen.',
  maturity_evidence = 'The exSSS run includes maturity model parameters; no observed age-composition or maturity-at-age input series was identified in the run data.',
  mortality_evidence = 'The model file includes natural-mortality settings, but no accepted annual M-at-age output was identified.',
  timing_evidence = 'The model file sets fishery and survey fleet timing to 0.5 within the season. This model setting is not a verified survey-specific calendar timing, and the model has no age-specific survey likelihood.',
  output_evidence = 'Stock SMART classifies the 2013 exSSS run as partially accepted for status determinations only. The report presents depletion and fishing-intensity profiles but says stock scale is highly uncertain; no accepted numeric N-at-age, F-at-age, or M-at-age surface was located.',
  detailed_source_url = paste(all_urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'NOAA Stock SMART 10428 is one coastwide U.S. Pacific unit with no canonical stock match. The latest detailed assessment is the 2013 data-moderate run (published 2015), still identified as latest in the 2025 SAFE. Although the model has 38 internal ages, the run file explicitly contains zero age-composition observations and zero mean-size-at-age observations; it uses catch totals and aggregate survey indices and was accepted only for status determination. Do not substitute earlier methods or infer age observations from model structure.',
  notes = 'Screened ineligible for the age-disaggregated set. The 2013 report, 2025 SAFE, 2026 preliminary assessment recommendations, and 2026 Amendment 37 analysis are cached with checksums under source_cache/discovery_noaa_data_moderate_2013_2026/. See discovery/source_reviews/noaa_stripetail_rockfish_2013.md. No canonical records were added.',
  stringsAsFactors = FALSE, check.names = FALSE)

needs_write <- initial_state || (current_state && !all(vapply(names(screened), function(name)
  identical(as.character(register[[name]][row]), as.character(screened[[name]])), logical(1L))))
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && needs_write)
  replace_candidate_register_row(register_path, row, screened, candidate_id)
cat('Screened NOAA:10428 as one distinct U.S. Pacific Coast unit, ineligible for age-disaggregated comparison.\n')

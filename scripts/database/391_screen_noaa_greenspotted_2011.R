root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_greenspotted_2011')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10437'
candidate_unit_id <- 'noaa_pacific_greenspotted_rockfish'
source_files <- c('greenspotted_rockfish_2011_assessment.pdf',
  'greenspotted_rockfish_2011_star_panel.pdf')
source_urls <- c(
  'https://www.pcouncil.org/documents/2011/09/status-of-greenspotted-rockfish-sebastes-chlorostictus-in-u-s-waters-off-california-september-2011.pdf',
  'https://www.pcouncil.org/documents/2011/08/greenspotted-rockfish-star-panel-report-august-2011.pdf')
source_revisions <- c('2011 accepted assessment; assessment data through 2010',
  'August 2011 STAR panel report')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 1000L))
  stop('Cache the reviewed NOAA Greenspotted sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed PDF.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (!all(source_valid)) stop('Cached NOAA Greenspotted source manifest check failed: ',
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
  stop('Expected one NOAA Pacific Coast Greenspotted inventory row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10437', na.rm = TRUE) ||
    any(assessments$assessment_id == 'noaa_pacific_greenspotted_rockfish_2011', na.rm = TRUE) ||
    any(inputs$assessment_id == 'noaa_pacific_greenspotted_rockfish_2011', na.rm = TRUE) ||
    any(outputs$assessment_id == 'noaa_pacific_greenspotted_rockfish_2011', na.rm = TRUE))
  stop('Screening must not create canonical Greenspotted assessment records.', call. = FALSE)

row <- match(candidate_id, register$candidate_id)
initial_state <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved'
current_state <- register$candidate_unit_id[row] == candidate_unit_id &&
  register$match_status[row] == 'new' && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (register$scientific_name[row] != 'Sebastes chlorostictus' ||
    register$inventory_assessment_year[row] != 2011 ||
    register$stock_name[row] != 'Greenspotted rockfish - Pacific Coast' ||
    (!initial_state && !current_state))
  stop('NOAA Greenspotted inventory identity or review state conflicts with the source review.', call. = FALSE)

all_urls <- c(
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10437',
  source_urls,
  'https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf')
screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = 'NOAA',
  official_stock_id = '10437',
  scientific_name = 'Sebastes chlorostictus',
  stock_name = 'Greenspotted rockfish - Pacific Coast',
  assessment_area = 'Pacific Coast',
  inventory_assessment_year = '2011',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10437',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = 'The accepted 2011 model uses annual fishery catch in metric tonnes and length compositions, not catch-at-age. Age compositions are available for selected fishery/survey samples; reconstructing catch-at-age would require a documented model-based conversion.',
  survey_age_evidence = 'The assessment includes survey biomass indices and age observations. NWFSC trawl survey ages from 2005, 2007 and 2009 were expanded by survey biomass; these are compositions rather than annual age-specific abundance indices.',
  weights_evidence = 'The assessment uses growth and length-weight relationships in Stock Synthesis. A run-matched numeric weight-at-age vector was not identified as a native input.',
  maturity_evidence = 'Maturity is modelled as a length-based logistic, with approximate female L50 values of 26 cm north and 22 cm south of Point Conception. A standalone observed maturity-at-age vector was not identified.',
  mortality_evidence = 'Natural mortality is fixed at M = 0.065 per year in both areas; the report presents 0.056 and 0.074 sensitivities and the STAR panel identifies M as a major uncertainty.',
  timing_evidence = 'The Stock Synthesis data files set all fishery and survey timing to 0.5. This is the model setting and does not establish actual survey timing.',
  output_evidence = 'Appendix K reports annual numbers-at-age for the northern and southern models, 1916-2010, in thousands of fish, with reported age columns 0-33. The tables provide no uncertainty; no annual F-at-age surface was located.',
  detailed_source_url = paste(all_urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'NOAA Stock SMART 10437 is not matched to a canonical tinyAM record. Its latest detailed assessment is fully accepted and uses data through 2010, but the model fits two independent California components separated at Point Conception. Amendment 37 adopts a coastwide stock definition and notes that the area north of 42 degrees N was not assessed by the 2011 model. The source provides age samples and numeric N-at-age but not catch-at-age; retain eligibility as unresolved until the legacy-boundary fallback and a documented catch-at-age reconstruction are reviewed.',
  notes = 'Screened; no canonical database records added. The accepted assessment and STAR panel PDFs are locally cached with checksums in source_cache/discovery_noaa_greenspotted_2011/. The 2026 Amendment 37 analysis is cached in discovery_noaa_data_moderate_2013_2026/. See discovery/source_reviews/noaa_greenspotted_rockfish_2011.md.',
  stringsAsFactors = FALSE, check.names = FALSE)

needs_write <- initial_state || (current_state && !all(vapply(names(screened), function(name)
  identical(as.character(register[[name]][row]), as.character(screened[[name]])), logical(1L))))
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && needs_write)
  replace_candidate_register_row(register_path, row, screened, candidate_id)
cat('Screened NOAA:10437 as a distinct coastwide rockfish candidate with a legacy two-component assessment; eligibility remains unresolved.\n')

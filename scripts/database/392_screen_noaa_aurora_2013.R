root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_aurora_2013')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10547'
candidate_unit_id <- 'noaa_pacific_aurora_rockfish'
source_files <- c(
  'aurora_rockfish_2013_assessment.pdf',
  'aurora_rockfish_2013_star_panel.pdf',
  'assessment_plan_2025_recommendations.pdf',
  'pacific_groundfish_safe_2025.pdf',
  'nmfs_assessment_priorities_2027.pdf')
source_urls <- c(
  'https://www.pcouncil.org/documents/2014/08/stock-assessment-of-aurora-rockfish-in-2013-published-december-27-2013.pdf',
  'https://www.pcouncil.org/documents/2014/01/star-panel-report-for-aurora-rockfish-july-2013.pdf',
  'https://www.pcouncil.org/documents/2024/03/agenda-item-f-3-a-supplemental-gmt-report-1-groundfish-management-team-report-on-initial-stock-assessment-plan-and-terms-of-reference.pdf/',
  'https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/',
  'https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf/')
source_revisions <- c(
  'STAR-accepted 2013 production assessment; data through 2012; Stock Synthesis 3.24o',
  'July 2013 STAR panel review',
  '2024 groundfish assessment plan; reports Aurora last assessed in 2013',
  '2024 Groundfish SAFE published July 2025; management quantities identify 2013 assessment',
  'February 2026 preliminary NMFS assessment priorities; lists Aurora last assessed in 2013')
source_paths <- file.path(cache, source_files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(source_paths)) || any(file.info(source_paths)$size < 1000L))
  stop('Cache the reviewed NOAA Aurora sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed PDF.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (!all(source_valid)) stop('Cached NOAA Aurora source manifest check failed: ',
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
  stop('Expected one NOAA Pacific Coast Aurora inventory row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10547', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Sebastes aurora', na.rm = TRUE) ||
    any(assessments$assessment_id == 'noaa_pacific_aurora_rockfish_2013', na.rm = TRUE) ||
    any(inputs$assessment_id == 'noaa_pacific_aurora_rockfish_2013', na.rm = TRUE) ||
    any(outputs$assessment_id == 'noaa_pacific_aurora_rockfish_2013', na.rm = TRUE))
  stop('Screening must not create canonical Aurora assessment records.', call. = FALSE)

row <- match(candidate_id, register$candidate_id)
initial_state <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved'
current_state <- register$candidate_unit_id[row] == candidate_unit_id &&
  register$match_status[row] == 'new' && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'unresolved'
if (register$scientific_name[row] != 'Sebastes aurora' ||
    register$inventory_assessment_year[row] != 2013 ||
    register$stock_name[row] != 'Aurora rockfish - Pacific Coast' ||
    (!initial_state && !current_state))
  stop('NOAA Aurora inventory identity or review state conflicts with the source review.', call. = FALSE)

all_urls <- c(
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10547',
  source_urls,
  'https://www.pcouncil.org/actions/phase-2-identification-of-groundfish-in-need-of-conservation-and-defining-their-stocks/',
  'https://www.federalregister.gov/d/2026-02291')
screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = 'NOAA',
  official_stock_id = '10547',
  scientific_name = 'Sebastes aurora',
  stock_name = 'Aurora rockfish - Pacific Coast',
  assessment_area = 'Pacific Coast',
  inventory_assessment_year = '2013',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10547',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = 'The accepted 2013 assessment uses commercial landings in metric tons and fishery length compositions, not annual catch-at-age. Conditional age-at-length samples are available for the domestic trawl fishery only in 2003, 2008 and 2009. Annual catch-at-age reconstruction needs a verified age-length key and biomass-to-numbers conversion; using fitted growth to create observations is not justified.',
  survey_age_evidence = 'Four aggregate trawl-survey indices are used. NWFSC shelf-slope conditional age-at-length observations are available in 2003, 2005, 2007 and 2009-2012. These are not direct annual age-specific abundance indices.',
  weights_evidence = 'The assessment specifies sex-specific growth and length-weight relationships; an observed annual weight-at-age series is not reported. An age-specific conversion would require an explicitly documented source transformation.',
  maturity_evidence = 'Maturity is represented by a length-based relationship; a standalone observed maturity-at-age series is not reported.',
  mortality_evidence = 'Natural mortality is fixed at 0.0350 per year for females and 0.0371 for males.',
  timing_evidence = 'The Stock Synthesis input sets all fishery and survey timing values to 0.5. This is the model setting, not verified calendar sampling timing.',
  output_evidence = 'Table 13 reports annual total/summary biomass, spawning biomass, depletion, age-0 recruitment (thousands of fish) and exploitation rate for 1916-2012. The reviewed report does not provide numeric N-at-age or F-at-age tables; the 2025 SAFE repeats quantities from the same 2013 assessment.',
  detailed_source_url = paste(all_urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'The latest assessment used for management remains the fully accepted 2013 coastwide Stock Synthesis run with data through 2012; the Council defines Aurora as coastwide under Amendment 37 and NMFS review was pending. Source evidence includes age-at-length observations, but fishery samples occur only in 2003, 2008 and 2009. Eligibility remains unresolved until an observation-based, source-supported annual catch-at-age reconstruction is shown to be defensible without fitted population states or unsupported extrapolation.',
  notes = 'Screened; no canonical database records added. Source PDFs and checksums are in gitignored source_cache/discovery_noaa_aurora_2013/. See discovery/source_reviews/noaa_aurora_rockfish_2013.md.',
  stringsAsFactors = FALSE, check.names = FALSE)

needs_write <- initial_state || (current_state && !all(vapply(names(screened), function(name)
  identical(as.character(register[[name]][row]), as.character(screened[[name]])), logical(1L))))
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && needs_write)
  replace_candidate_register_row(register_path, row, screened, candidate_id)
cat('Screened NOAA:10547 as a new Pacific Coast Aurora candidate with a 2013 accepted assessment; age-input eligibility remains unresolved.\n')
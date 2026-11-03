root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_data_moderate_2013_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10546'
candidate_unit_id <- 'noaa_pacific_brown_rockfish'
source_files <- c('data_moderate_rockfish_2013.pdf',
  'pacific_groundfish_safe_july_2025.pdf', 'preliminary_2027_assessment_recommendations_2026.pdf',
  'amendment_37_stock_definition_analysis_2026.pdf')
source_urls <- c(
  'https://www.pcouncil.org/documents/2015/01/data-moderate-stock-assessments-for-brown-china-copper-sharpchin-stripetail-and-yellowtail-rockfishes-and-english-and-rex-soles-in-2013-published-january-2015.pdf',
  'https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/',
  'https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf/',
  'https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf')
source_revisions <- c(
  '2013 data-moderate assessment, published January 2015',
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
  stop('Cache the reviewed NOAA Brown rockfish sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
source_rows <- match(source_files, sources$file)
if (anyNA(source_rows)) stop('Source manifest is missing a reviewed PDF.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), source_urls),
  revisions = identical(as.character(sources$revision[source_rows]), source_revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(source_paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(source_paths)$size)))
if (!all(source_valid)) stop('Cached NOAA Brown rockfish source manifest check failed: ',
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
  stop('Expected one NOAA Pacific Coast Brown rockfish inventory row.', call. = FALSE)
if (any(stocks$authority_stock_id == '10546', na.rm = TRUE) ||
    any(stocks$scientific_name == 'Sebastes auriculatus', na.rm = TRUE) ||
    any(assessments$assessment_id == 'noaa_pacific_brown_rockfish_2013', na.rm = TRUE) ||
    any(inputs$assessment_id == 'noaa_pacific_brown_rockfish_2013', na.rm = TRUE) ||
    any(outputs$assessment_id == 'noaa_pacific_brown_rockfish_2013', na.rm = TRUE))
  stop('Screening must not create canonical Brown rockfish assessment records.', call. = FALSE)

row <- match(candidate_id, register$candidate_id)
initial_state <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved'
current_state <- register$candidate_unit_id[row] == candidate_unit_id &&
  register$match_status[row] == 'new' && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (register$scientific_name[row] != 'Sebastes auriculatus' ||
    register$inventory_assessment_year[row] != 2013 ||
    register$stock_name[row] != 'Brown rockfish - Pacific Coast' ||
    (!initial_state && !current_state))
  stop('NOAA Brown rockfish inventory identity or review state conflicts with the source review.', call. = FALSE)

all_urls <- c(
  'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10546',
  source_urls,
  'https://www.pcouncil.org/actions/phase-2-identification-of-groundfish-in-need-of-conservation-and-defining-their-stocks/',
  'https://www.federalregister.gov/d/2026-02291')
screened <- data.frame(
  candidate_id = candidate_id,
  candidate_unit_id = candidate_unit_id,
  organization = 'NOAA',
  official_stock_id = '10546',
  scientific_name = 'Sebastes auriculatus',
  stock_name = 'Brown rockfish - Pacific Coast',
  assessment_area = 'Pacific Coast',
  inventory_assessment_year = '2013',
  inventory_url = 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10546',
  retrieved_on = '2026-10-28',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The fully accepted 2013 benchmark uses aggregate removals in metric tons, not catch-at-age. The Brown rockfish XDB-SRA input file sets age-composition, length-composition and mean-size-at-age observation counts to zero.',
  survey_age_evidence = 'The XDB-SRA fit uses four aggregate fishery-dependent CPFV observer and RecFIN abundance indices. It has no age-specific survey observations or survey age compositions.',
  weights_evidence = 'The selected assessment is an aggregate XDB-SRA model and has no observed weight-at-age likelihood input.',
  maturity_evidence = 'The selected assessment does not use an age-specific maturity-at-age series as an age-structured likelihood input.',
  mortality_evidence = 'The selected XDB-SRA assessment reports aggregate biomass and exploitation quantities; it does not estimate an annual age-specific natural mortality surface.',
  timing_evidence = 'The selected aggregate indices are fishery-dependent; no within-year survey timing fraction applies.',
  output_evidence = 'The report provides aggregate total and spawning biomass, depletion, exploitation, MSY and OFL outputs. No numeric annual N-at-age or F-at-age surfaces were located.',
  detailed_source_url = paste(all_urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = 'NOAA Stock SMART 10546 is a distinct new Pacific Coast stock unit. Its latest fully accepted assessment is the 2013 coastwide XDB-SRA benchmark with data through 2012; the 2025 SAFE still lists 2013 as the most recent assessment. The selected model uses aggregate removals and aggregate fishery-dependent indices, and its input file sets age, length and mean-size-at-age observations to zero. It is ineligible for the age-disaggregated assessment set despite life-history age information in the source report.',
  notes = 'Screened ineligible; no canonical database records added. The report and supporting documents are cached under gitignored source_cache/discovery_noaa_data_moderate_2013_2026/. See discovery/source_reviews/noaa_brown_rockfish_pacific_coast_2013.md.',
  stringsAsFactors = FALSE, check.names = FALSE)

needs_write <- initial_state || (current_state && !all(vapply(names(screened), function(name)
  identical(as.character(register[[name]][row]), as.character(screened[[name]])), logical(1L))))
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && needs_write)
  replace_candidate_register_row(register_path, row, screened, candidate_id)
cat('Screened NOAA:10546 as a new Pacific Coast Brown rockfish candidate; ineligible for age-disaggregated assessment data.\n')
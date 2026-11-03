root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_greenstriped_rockfish_2009')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10566'
unit_id <- 'noaa_pacific_greenstriped_rockfish_coastwide'
files <- c('assessment.pdf', 'star_review.pdf', 'stock_structure_review_2025.pdf',
  'assessment_priorities_2026.pdf', 'groundfish_safe_2025.pdf')
urls <- c(
  'https://www.pcouncil.org/documents/2009/10/status-of-greenstriped-rockfish-sebastes-elongatus-along-the-outer-coast-of-california-oregon-and-washington-october-27-2009.pdf',
  'https://www.pcouncil.org/documents/2009/08/greenstriped-rockfish-star-panel-report-august-2009.pdf',
  'https://www.pcouncil.org/documents/2025/02/h-6-attachment-3-stock-structure-literature-review.pdf',
  'https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf',
  'https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/')
revisions <- c(
  'PFMC final 2009 assessment; model data through 2008',
  'PFMC STAR review, 2009-08-03 to 2009-08-06',
  'PFMC stock-structure literature review, 2025-02',
  'Preliminary NMFS recommendations for 2027 groundfish assessments, 2026-02',
  'PFMC Pacific Coast Groundfish SAFE, July 2025')
paths <- file.path(cache, files)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}
if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed NOAA greenstriped rockfish sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
source_rows <- match(files, sources$file)
if (anyNA(source_rows)) stop('A cached NOAA source is missing from its manifest.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), urls),
  revisions = identical(as.character(sources$revision[source_rows]), revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)),
  dates = all(sources$retrieved_on[source_rows] == '2026-10-31'))
if (!all(source_valid)) stop('Cached NOAA source manifest failed verification.', call. = FALSE)

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (!file.exists(stocksmart_path)) stop('The cached Stock SMART inventory is required.', call. = FALSE)
stocksmart <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart)
metadata <- stocksmart$stock_assessment_summary
metadata <- metadata[metadata$stock_id == 10566, , drop = FALSE]
if (nrow(metadata) != 1L || metadata$scientific_name != 'Sebastes elongatus' ||
    metadata$assessment_year != 2009L || metadata$last_data_year != 2008L ||
    metadata$review_result != 'Full acceptance' || metadata$model_version != 'SS2_v3.03a')
  stop('Cached Stock SMART metadata no longer confirms the reviewed 2009 run.', call. = FALSE)

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
if (is.na(row) || sum(register$candidate_id == candidate_id) != 1L ||
    register$official_stock_id[row] != '10566' ||
    register$scientific_name[row] != 'Sebastes elongatus' ||
    register$assessment_area[row] != 'Pacific Coast' ||
    register$inventory_assessment_year[row] != 2009L ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('NOAA greenstriped rockfish inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == '10566', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(assessments$stock_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical greenstriped rockfish records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The accepted 2009 SS2 assessment uses reconstructed fishery removals and length compositions.',
    'The report says age observations were available only from the NWFSC survey; 1995 triennial and Oregon landing',
    'ages were not available to this assessment. No fishery age composition or catch-at-age series is reported;',
    'fishery catch totals and length compositions therefore do not support',
    'a source-based catch-at-age reconstruction.'),
  survey_age_evidence = paste('Three aggregate biomass index series are used: early triennial (1980-1992), late triennial',
    '(1995-2004), and NWFSC shelf-slope (2003-2008). NWFSC age observations are conditional age-at-length by sex/year,',
    'age bins 1-45 with a 45+ group, about 3,472 fish. They are not a directly fitted age-specific abundance index.'),
  weights_evidence = paste('The report provides weight-length relationships in kg and cm from Love et al. (1990),',
    'Shaw and Gunderson (2006), and the NWFSC survey (2003-2008), plus sex-specific growth. Weight-at-age would be',
    'derived from those model relationships, not taken from a standalone observed weight-at-age series.'),
  maturity_evidence = paste('The assessment documents size-based maturity and fecundity relationships; the model fixes the',
    'maturity ogive and fecundity parameters and specifies first mature age 2. It does not provide an observed annual',
    'maturity-at-age input series.'),
  mortality_evidence = 'Natural mortality is fixed at 0.08 per year for both sexes; it is not estimated as an age-specific process.',
  timing_evidence = paste('The model table sets fishery timing to 0.5, early triennial survey timing to 0.6, late triennial',
    'timing to 0.5, and NWFSC survey timing to 0.5. These are model settings; survey operating dates varied among years.'),
  output_evidence = paste('The report includes an annual numbers-at-age matrix and aggregate spawning output, depletion, and',
    'exploitation results. Numbers-at-age are fitted outputs, not observed inputs; no annual F-at-age table was verified.'),
  detailed_source_url = paste(c('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10566', urls),
    collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste('The latest official run located for the current coastwide unit is the fully accepted 2009',
    'assessment using data through 2008. The 2025 stock-structure review also identifies 2009 as the only benchmark;',
    '2026 NMFS material lists 2009 as last assessed and only proposes greenstriped rockfish as a possible 2027 benchmark.',
    'The source has fitted age-specific outputs and survey conditional age-at-length but no fishery age input, so catch-at-age',
    'cannot be reconstructed from accepted-run observations without unsupported assumptions.'),
  notes = paste('The 2009 assessment models one homogeneous coastwide stock; regional fisheries and survey strata do not',
    'create separate stock units. The assessment area excludes Puget Sound. No canonical stock, assessment, input, or output',
    'records were added was attempted. Official PDFs and provenance are cached in',
    'source_cache/discovery_noaa_greenstriped_rockfish_2009/sources.csv.'))

initial <- register$match_status[row] == 'unreviewed' && register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' && register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' && register$eligibility[row] == 'ineligible' &&
  register$import_status[row] == 'not_started'
if (!initial && !reviewed) stop('NOAA greenstriped rockfish candidate row has a conflicting review state.', call. = FALSE)

for (name in names(review)) register[[name]][row] <- review[[name]]
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts/database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
}
cat('Screened NOAA Pacific Coast greenstriped rockfish as ineligible for age-disaggregated source curation; canonical data remain unchanged.\n')
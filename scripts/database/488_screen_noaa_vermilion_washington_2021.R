root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_vermilion_rockfish_washington_2021')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:15339'
unit_id <- 'noaa_vermilion_rockfish_or_wa'
files <- c('washington_vermilion_assessment_2021.pdf',
  'washington_vermilion_model_files_2021.zip', 'pfmc_june_2025_meeting_record.pdf',
  'nmfs_preliminary_2027_assessment_recommendations.pdf')
urls <- c(
  'https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-washington-state-coast-in-2021.pdf/',
  'https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-wa-zip-file/',
  'https://www.pcouncil.org/documents/2026/01/june-2025-meeting-record.pdf/',
  'https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf/')
revisions <- c(
  'PFMC 2021 final Washington component assessment; data through 2020',
  'PFMC accepted Washington component Stock Synthesis 3.30.16 model archive',
  'PFMC June 2025 final meeting record; retains Vermilion rockfish (OR/WA)',
  'NMFS February 2026 preliminary recommendations; identifies 2021 as last benchmark')
paths <- file.path(cache, files)
sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}
if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed NOAA Washington vermilion sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source_rows <- match(files, sources$file)
if (anyNA(source_rows)) stop('A cached NOAA source is missing from its manifest.', call. = FALSE)
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), urls),
  revisions = identical(as.character(sources$revision[source_rows]), revisions),
  hashes = identical(tolower(as.character(sources$sha256[source_rows])),
    unname(vapply(paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)),
  dates = all(sources$retrieved_on[source_rows] == '2026-10-31'))
if (!all(source_valid)) stop('Cached NOAA source manifest failed verification.', call. = FALSE)

archive <- paths[match('washington_vermilion_model_files_2021.zip', files)]
members <- utils::unzip(archive, list = TRUE)$Name
required_members <- c('data.ss_new', 'SS_LB.dat', 'Report.sso')
if (!all(required_members %in% basename(members)))
  stop('The Washington model archive lacks accepted input or output files.', call. = FALSE)
report_member <- members[basename(members) == 'Report.sso'][1]
report_lines <- readLines(unz(archive, report_member), warn = FALSE)
output_sections <- c('NUMBERS_AT_AGE', 'CATCH_AT_AGE', 'F_AT_AGE')
if (!all(vapply(output_sections, function(section)
  any(grepl(section, report_lines, fixed = TRUE)), logical(1L))))
  stop('The Washington model report lacks verified age-specific outputs.', call. = FALSE)

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (!file.exists(stocksmart_path)) stop('The cached Stock SMART inventory is required.', call. = FALSE)
stocksmart <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart)
metadata <- stocksmart$stock_assessment_summary
metadata <- metadata[metadata$stock_id == 15339, , drop = FALSE]
if (nrow(metadata) != 1L || metadata$scientific_name != 'Sebastes miniatus' ||
    metadata$assessment_year != 2021L || metadata$last_data_year != 2020L ||
    metadata$stock_area != 'Washington' || metadata$review_result != 'Full acceptance' ||
    metadata$model_version != '3.30.16.00')
  stop('Cached Stock SMART metadata no longer confirms the reviewed 2021 run.', call. = FALSE)

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
  check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
row <- match(candidate_id, register$candidate_id)
oregon_row <- match('NOAA:15338', register$candidate_id)
if (is.na(row) || is.na(oregon_row) || sum(register$candidate_id == candidate_id) != 1L ||
    register$official_stock_id[row] != '15339' ||
    register$scientific_name[row] != 'Sebastes miniatus' ||
    register$assessment_area[row] != 'Washington' ||
    register$inventory_assessment_year[row] != 2021L ||
    register$candidate_unit_id[oregon_row] != unit_id ||
    any(stocks$authority_stock_id %in% c('15338', '15339'), na.rm = TRUE) ||
    unit_id %in% stocks$stock_id || unit_id %in% assessments$stock_id ||
    unit_id %in% inputs$assessment_id || unit_id %in% outputs$assessment_id)
  stop('NOAA vermilion identity, component crosswalk, or canonical records conflict.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste0(
    'The accepted 2021 Washington component has one recreational fishery and annual removals in thousands of fish, ' ,
    'with length compositions and conditional age-at-length observations in the Stock Synthesis archive. The report ' ,
    'describes age samples from 1998-2020 (none in 2003, generally 3-150 aged structures per year, most from ' ,
    '2015-2020). These source data support age-specific catch reconstruction only in years with compatible length ' ,
    'and age samples; they are not direct catch-at-age observations across the 1949-2020 removals history.'),
  survey_age_evidence = paste0(
    'The Washington component has no abundance index. The report considered the WDFW Nearshore Rockfish Survey ' ,
    'but did not use it because methods were not yet reviewed and data were not robust. The Oregon component has ' ,
    'an aggregate recreational CPUE index (2001-2020); its age-specific form is approximate and not identical to ' ,
    'the standardized index sample.'),
  weights_evidence = paste0(
    'The Washington model fixes sex-specific weight-at-length relationships (female 1.36e-05 L^3.1 and male ' ,
    '2.38e-05 L^2.96, kg with length in cm). The archive includes age-specific biology outputs, but weight-at-age ' ,
    'is derived from weight-at-length and estimated growth rather than an observed annual input series.'),
  maturity_evidence = paste0(
    'Maturity-at-length is fixed using Oregon samples, with L50 = 39.4 cm and an assumed 95% maturity length of ' ,
    '48 cm (logistic slope -0.34). The assessment does not provide an observed maturity-at-age series.'),
  mortality_evidence = paste0(
    'Sex-specific natural mortality is estimated with a lognormal prior (median 0.1, log-scale SD 0.438); the ' ,
    'reference estimates are 0.085 female and 0.087 male per year.'),
  timing_evidence = paste0(
    'The Washington run has one annual season and no index observations, so it has no survey timing fraction. ' ,
    'The Oregon ORBS index is based on summer trips (May-September); its report and model-file month code do not ' ,
    'establish a verified fractional-year conversion.'),
  output_evidence = paste0(
    'The accepted Washington archive contains Report.sso with NUMBERS_AT_AGE, CATCH_AT_AGE and F_AT_AGE, as well ' ,
    'as biomass-at-age and annual spawning output, recruitment and exploitation summaries. The Oregon component ' ,
    'has its own accepted model outputs; the two area models are not a single pooled fit.'),
  detailed_source_url = paste(c('https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=15339',
    as.character(sources$url[source_rows])), collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste0(
    'Eligible for source curation as one current Vermilion rockfish (OR/WA) stock, represented by separate Oregon ' ,
    'and Washington 2021 benchmark models. Both accepted component archives provide catch, length and conditional ' ,
    'age-at-length data and age-specific outputs. Catch-at-age is reconstructable only for compatible sampled years; ' ,
    'the Washington component has no independent abundance index. Preserve the component distinction and these ' ,
    'limits; eligibility does not imply a pooled assessment or ready.'),
  notes = paste0(
    'The June 2025 Council meeting record retains the current managed stock as Vermilion rockfish (OR/WA); the ' ,
    '2021 production assessments separately modeled Oregon (Stock SMART 15338) and Washington (15339), with ' ,
    'distinct state-area data and population outputs. They are linked as one candidate_unit_id and are not counted ' ,
    'as separate current stock units. Council and NMFS material identifies 2021 as the latest benchmark through ' ,
    'the reviewed 2026 recommendations. This is an inventory screen only.' ,
    'translation were added. Washington sources and provenance are cached in ' ,
    'source_cache/discovery_noaa_vermilion_rockfish_washington_2021/sources.csv.'))

initial <- register$match_status[row] == 'unreviewed' && register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- all(vapply(names(review), function(column)
  identical(as.character(register[[column]][row]), as.character(review[[column]])), logical(1L)))
if (!initial && !reviewed)
  stop('NOAA Washington vermilion candidate row has a conflicting review state.', call. = FALSE)

for (column in names(review)) register[[column]][row] <- review[[column]]
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened NOAA Vermilion rockfish (OR/WA) as one eligible candidate with separate Oregon and Washington source components.\n')

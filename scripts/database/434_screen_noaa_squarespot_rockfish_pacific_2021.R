root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_squarespot_rockfish_pacific_2021')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10442'
unit_id <- 'noaa_squarespot_rockfish_california'

files <- c('squarespot_2021_assessment.pdf', 'squarespot_2021_model_files.zip')
urls <- c(
  'https://www.pcouncil.org/documents/2021/10/stock-assessment-of-the-squarespot-rockfish-sebastes-hopkinsi-along-the-california-u-s-west-coast-in-2021-using-catch-length-and-fishery-independent-abundance-data.pdf/',
  'https://www.pcouncil.org/documents/squarespot-rockfish-2021-model-files-zip-file/')
revisions <- c('PFMC 2021 squarespot rockfish assessment, data through 2020',
  'PFMC Squarespot Rockfish 2021 Stock Synthesis model archive')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed NOAA squarespot sources before screening.', call. = FALSE)
sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), fileEncoding = 'UTF-8-BOM')
source_rows <- match(files, basename(sources$file))
source_valid <- c(
  urls = identical(as.character(sources$url[source_rows]), urls),
  revisions = identical(as.character(sources$revision[source_rows]), revisions),
  hashes = identical(toupper(as.character(sources$sha256[source_rows])),
    unname(vapply(paths, sha256_file, character(1L)))),
  sizes = identical(as.numeric(sources$bytes[source_rows]), as.numeric(file.info(paths)$size)))
if (anyNA(source_rows) || !all(source_valid))
  stop('Cached NOAA squarespot sources differ from the reviewed manifest: ',
    paste(names(source_valid)[!source_valid], collapse = ', '), call. = FALSE)

model_dir <- file.path(cache, 'model_files', 'Squarespot_rockfish_2021_Model_For_Devore')
data_path <- file.path(model_dir, 'SS_LB.dat')
report_path <- file.path(model_dir, 'Report.sso')
if (!all(file.exists(c(data_path, report_path))))
  stop('The cached Squarespot archive must be expanded before screening.', call. = FALSE)
dat <- readLines(data_path, warn = FALSE)
report <- readLines(report_path, warn = FALSE)
if (!any(grepl('^41[[:space:]]+#_Nages', dat)) ||
    !any(grepl('#_Catch data', dat, fixed = TRUE)) ||
    !any(grepl('#_CPUE_and_surveyabundance_observations', dat, fixed = TRUE)) ||
    !any(grepl('#_lencomp', dat, fixed = TRUE)) ||
    any(grepl('^#_agecomp', dat, ignore.case = TRUE)) ||
    !all(vapply(c('NUMBERS_AT_AGE', 'F_AT_AGE', 'CATCH_AT_AGE'),
      function(section) any(grepl(section, report, fixed = TRUE)), logical(1L))))
  stop('The cached Squarespot files differ from the reviewed age-data and output structure.',
    call. = FALSE)

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (!file.exists(stocksmart_path)) stop('The cached Stock SMART inventory is required.', call. = FALSE)
stocksmart <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart)
metadata <- stocksmart$stock_assessment_summary
metadata <- metadata[metadata$stock_id == 10442, , drop = FALSE]
if (nrow(metadata) != 2L || max(metadata$assessment_year, na.rm = TRUE) != 2021L ||
    !any(metadata$assessment_year == 2021 & metadata$review_result == 'Full acceptance' &
      metadata$assessment_id == 11658 & metadata$model_version == '3.30.16.00'))
  stop('Stock SMART metadata no longer confirms the 2021 accepted assessment as latest.', call. = FALSE)

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
    register$official_stock_id[row] != '10442' ||
    register$scientific_name[row] != 'Sebastes hopkinsi' ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('NOAA squarespot inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == '10442', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(assessments$stock_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical Squarespot records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The accepted 2021 Stock Synthesis model uses annual catch totals and length compositions,',
    'not catch-at-age. The assessment explicitly states that age observations were used externally to inform',
    'life-history parameters, not as assessment data; no age-composition likelihood is present in SS_LB.dat.'),
  survey_age_evidence = paste('The base model uses one aggregate biomass index from the NWFSC Hook-and-Line survey',
    'with survey length compositions, not an age-specific abundance index or survey age-composition likelihood.'),
  weights_evidence = paste('Sex-specific length-weight relationships were estimated outside the model. Weights-at-age',
    'would need to be derived from those functions and the fitted growth relationship.'),
  maturity_evidence = paste('The assessment uses a length-based maturity ogive with L50 = 14 cm and an assumed',
    'slope of -0.95; no observed maturity-at-age likelihood input is reported.'),
  mortality_evidence = paste('The control file estimates sex-specific natural-mortality parameters using the',
    'composite life-history prior; the report gives a median M of 0.133 per year and CV 0.22.'),
  timing_evidence = paste('The native model has one annual season and places Hook-and-Line index observations in',
    'season 9, while fleet timing is coded -1. The report does not establish a fractional-year conversion.'),
  output_evidence = paste('The accepted Report.sso contains annual numbers-at-age, fishing mortality-at-age, and',
    'catch-at-age outputs. The assessment reports spawning output in millions of eggs and total biomass; age-indexed',
    'fitted outputs do not supply missing age-disaggregated input likelihoods.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('NOAA Stock SMART lists the 2021 full-acceptance Stock Synthesis assessment as latest,',
    'with data through 2020. The report defines the category-2 inputs as removals, length compositions, and',
    'fishery-independent abundance; it says age observations inform life-history parameters outside the assessment.',
    'The native input has catch totals, an aggregate survey index, and length compositions but no age-composition',
    'likelihood. The unit is therefore ineligible for the age-disaggregated source set despite age-indexed outputs.'),
  notes = paste('NOAA Stock SMART labels the stock Pacific Coast; the detailed assessment is titled for the California',
    'U.S. West Coast and discusses northern and southern management complexes divided at 40 degrees 10 minutes N.',
    'The model uses two sexes, 41 ages, deterministic recruitment, one removal fleet and one abundance-index fleet.',
    'No canonical records or tinyAM translation were added. The PDF and native model archive are cached in',
    'source_cache/discovery_noaa_squarespot_rockfish_pacific_2021/sources.csv.'))

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible'
if (!initial && !reviewed)
  stop('NOAA squarespot candidate row already has a conflicting review state.', call. = FALSE)

review_matches <- all(vapply(names(review), function(name)
  identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (initial || !review_matches)) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
}
cat('Screened NOAA Pacific Coast Squarespot rockfish as ineligible for the age-disaggregated source set; canonical data remain unchanged.\n')

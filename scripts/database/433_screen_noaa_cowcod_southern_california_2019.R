root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_cowcod_southern_california_2019')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10443'
unit_id <- 'noaa_cowcod_southern_california'

files <- c('cowcod_2019_assessment.pdf', 'cowcod_2019_model_files.zip',
  'cowcod_2019_star_panel.pdf')
urls <- c(
  'https://www.pcouncil.org/documents/2019/10/status-of-cowcod-sebastes-levis-in-2019-october-24-2019.pdf',
  'https://www.pcouncil.org/documents/cowcod-2019-ss-model-files-zip-file/',
  'https://www.pcouncil.org/documents/2019/10/cowcod-star-panel-report-july-22-26-2019.pdf')
revisions <- c('PFMC 2019 cowcod assessment, dated 2019-10-24',
  'PFMC Cowcod 2019 Stock Synthesis model files archive',
  'PFMC Cowcod 2019 STAR panel report, 2019-07-22 to 2019-07-26')
paths <- file.path(cache, files)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

if (any(!file.exists(paths)) || any(file.info(paths)$size < 1000L))
  stop('Cache the reviewed NOAA cowcod sources before screening.', call. = FALSE)
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
  stop('Cached NOAA cowcod sources differ from the reviewed manifest: ',
    paste(names(source_valid)[!source_valid], collapse = ', '), call. = FALSE)

model_dir <- file.path(cache, 'model_files')
model_paths <- file.path(model_dir, c('cowcod2019.dat', 'cowcod2019.ctl', 'Report.sso'))
if (any(!file.exists(model_paths)))
  stop('The cached cowcod archive must be expanded before screening.', call. = FALSE)
dat <- readLines(model_paths[1L], warn = FALSE)
report <- readLines(model_paths[3L], warn = FALSE)
if (!any(grepl('^60[[:space:]]+#_Nages', dat)) ||
    !any(grepl('#_CPUE_and_surveyabundance_observations', dat, fixed = TRUE)) ||
    !any(grepl('#_N_age_bins', dat, fixed = TRUE)) ||
    !all(vapply(c('NUMBERS_AT_AGE', 'F_AT_AGE', 'CATCH_AT_AGE'),
      function(section) any(grepl(section, report, fixed = TRUE)), logical(1L))))
  stop('The cached native model files do not contain the reviewed age-indexed input/output sections.',
    call. = FALSE)

stocksmart_path <- file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda')
if (!file.exists(stocksmart_path)) stop('The cached Stock SMART inventory is required.', call. = FALSE)
stocksmart <- new.env(parent = emptyenv())
load(stocksmart_path, envir = stocksmart)
metadata <- stocksmart$stock_assessment_summary
metadata <- metadata[metadata$stock_id == 10443, , drop = FALSE]
if (nrow(metadata) != 5L || max(metadata$assessment_year, na.rm = TRUE) != 2019L ||
    !any(metadata$assessment_year == 2019 & metadata$review_result == 'Full acceptance' &
      metadata$model_version == '3.30.13.09'))
  stop('Stock SMART metadata no longer confirms the 2019 accepted assessment as latest.', call. = FALSE)

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
    register$official_stock_id[row] != '10443' ||
    register$scientific_name[row] != 'Sebastes levis' ||
    any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE))
  stop('NOAA cowcod inventory identity conflicts with the register.', call. = FALSE)
if (any(stocks$authority_stock_id == '10443', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(assessments$stock_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical cowcod records.', call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The accepted 2019 Stock Synthesis input archive provides annual catch by fishery,',
    'length compositions, and conditional age-at-length observations. These are not direct catch numbers-at-age;',
    'a source-based age reconstruction is possible only for years and fleets where the length and age-at-length',
    'samples can be paired and requires documenting that relationship.'),
  survey_age_evidence = paste('The model input archive contains aggregate abundance observations for multiple surveys,',
    'survey length compositions, and conditional age-at-length samples for the NWFSC WCGBT and Hook-and-Line',
    'surveys. These data can support age-specific reconstruction in overlapping survey years, but they are not',
    'direct age-specific index observations.'),
  weights_evidence = paste('The assessment reports a weight-length relationship in kg whole weight and cm fork length;',
    'age-specific weights are available through the assessment growth and weight-at-length structure, not as a',
    'standalone observed catch-at-age table.'),
  maturity_evidence = paste('The report documents maturity observations for 174 females and length-based biological',
    'and functional maturity ogives. An age-specific maturity series would require applying the model growth',
    'relationship and preserving which ogive is used.'),
  mortality_evidence = 'The accepted base model estimates natural mortality; its 2019 point estimate is 0.088 per year, informed by a prior.',
  timing_evidence = paste('The native SS3 data file records observation months by fleet and year. Survey timing is',
    'fleet-specific; a common timing value should not be inferred.'),
  output_evidence = paste('The official Report.sso includes annual numbers-at-age, fishing mortality-at-age, catch-at-age,',
    'and biomass-at-age tables. The report also gives spawning output, depletion, deterministic recruitment, and',
    'aggregate uncertainty; spawning output is eggs, not SSB tonnes.'),
  detailed_source_url = paste(urls, collapse = '; '),
  review_date = '2026-10-30',
  decision_reason = paste('NOAA Stock SMART lists the 2019 full-acceptance SS3 assessment as the latest assessment',
    'for this unit. The official model archive includes paired length-composition and conditional age-at-length',
    'inputs plus age-indexed fitted outputs, making a documented age reconstruction supportable for overlapping',
    'sample years. This is eligible for source curation, while not a direct catch-at-age likelihood.'),
  notes = paste('This candidate is the U.S. Southern California Bight unit south of Point Conception and is distinct',
    'from any stock north of the boundary or in Mexican waters. The model is one-sex with a 60+ accumulator age,',
    'deterministic recruitment, and a 2018 terminal data year; 2019 output is the assessment estimate. No canonical',
    'records were added. Cached reports and the native model archive are listed in',
    'source_cache/discovery_noaa_cowcod_southern_california_2019/sources.csv.'))

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' && register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id && register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'eligible'
if (!initial && !reviewed)
  stop('NOAA cowcod candidate row already has a conflicting review state.', call. = FALSE)

review_matches <- all(vapply(names(review), function(name)
  identical(as.character(register[[name]][row]), as.character(review[[name]])), logical(1L)))
if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && (initial || !review_matches)) {
  source(file.path(root, 'scripts/database/candidate_register_io.R'))
  replace_candidate_register_row(register_path, row, register[row, , drop = FALSE], candidate_id)
}
cat('Screened NOAA cowcod (Southern California, 2019) as eligible for source curation; canonical data remain unchanged.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'noaa_northwest_atlantic_porbeagle_2020')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$assessment_id) == '11387', , drop = FALSE]
model <- if (nrow(assessment) == 1L) as.character(assessment$assessment_model) else ''
if (nrow(assessment) != 1L ||
    as.character(assessment$stock_id) != '10654' ||
    as.integer(assessment$assessment_year) != 2021L ||
    as.integer(assessment$last_data_year) != 2018L ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    !grepl('Incidental Catch Model', model, fixed = TRUE) ||
    !grepl('SAFE', model, fixed = TRUE))
  stop('NOAA Stock SMART metadata do not match the reviewed 2021 porbeagle record.',
    call. = FALSE)

files <- c('ICCAT_2020_Porbeagle_assessment_meeting.pdf',
  'ICCAT_2024_2025_Porbeagle_executive_summary.pdf')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (!all(files %in% manifest$file) ||
    !all(file.exists(file.path(cache, files))) ||
    anyNA(manifest$sha256[match(files, manifest$file)]) ||
    !all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])))
  stop('The Northwest Atlantic porbeagle source cache is incomplete.', call. = FALSE)
pdf_headers <- vapply(file.path(cache, files), function(path) {
  con <- file(path, 'rb')
  on.exit(close(con))
  identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(pdf_headers))
  stop('A cached porbeagle source is not a PDF.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10654'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one Northwest Atlantic porbeagle Stock SMART row.', call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_northwest_atlantic_porbeagle',
  assessment_area = 'Northwestern Atlantic',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The latest detailed run uses reconstructed annual removals and catch totals. No',
    'catch-numbers-at-age input is reported or used by the production model.'),
  survey_age_evidence = paste('The accepted ICM does not fit an age-specific survey index. Japanese longline',
    'CPUE is discussed as context, while SAFE uses aggregate fleet exposure and mortality.'),
  weights_evidence = paste('A complete fitted stock weight-at-age surface is not reported for the current',
    'production assessment; the ICM uses life-history and size information to construct aggregate dynamics.'),
  maturity_evidence = paste('The ICM examines reproductive-cycle and productivity assumptions, but the reviewed',
    'production sources do not provide a run-specific maturity-at-age vector.'),
  mortality_evidence = paste('The assessment uses life-history assumptions and SAFE mortality proxies; no complete',
    'fitted natural-mortality-at-age surface is reported.'),
  timing_evidence = paste('The accepted production model does not fit an age-specific survey index, so no',
    'within-year timing for such an observation is specified.'),
  output_evidence = paste('The 2024-2025 summary reports aggregate relative biomass and fishing mortality, with',
    'Northwest stock status based on 2018. No annual N-at-age, F-at-age or M-at-age output surface was found.'),
  detailed_source_url = paste(
    'https://www.iccat.int/Documents/CVSP/CV077_2020/n_6/CV077060001.pdf;',
    'https://www.iccat.int/Documents/SCRS/ExecSum/POR_ENG.pdf;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10654'),
  review_date = review_date,
  decision_reason = paste('NOAA Stock SMART lists the latest full-acceptance record as assessment 11387,',
    'a 2021 ICM/SAFE review through 2018. The detailed ICCAT 2020 report and 2024-2025',
    'summary show aggregate removals and status outputs, not catch-at-age or an',
    'age-specific abundance-index likelihood. The ICM constructs an assumed',
    'age-structured population from life-history information but does not fit',
    'age-disaggregated observations; age-based biological and output surfaces needed',
    'for tinyAM were not verified.'),
  notes = paste('ICCAT identifies the Northwest Atlantic status estimates as based on 2018, even though',
    'the 2024-2025 summary carries catch information through 2024. The Northeast',
    'Atlantic ICES unit is distinct. No canonical numerical records were added.'),
  stringsAsFactors = FALSE)

current <- candidates[i, names(row), drop = FALSE]
same <- all(vapply(names(row), function(name) {
  x <- current[[name]]
  y <- row[[name]]
  if (is.na(x)) is.na(y) else !is.na(y) &&
    identical(as.character(x), as.character(y))
}, logical(1L)))
if (!same) {
  pristine <- candidates$match_status[i] == 'unreviewed' &&
    candidates$screening_status[i] == 'not_started' &&
    candidates$eligibility[i] == 'unresolved' &&
    candidates$import_status[i] == 'not_started' &&
    (is.na(candidates$candidate_unit_id[i]) ||
      !nzchar(candidates$candidate_unit_id[i]))
  if (!pristine)
    stop('Unexpected existing review state for NOAA:10654.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA Northwestern Atlantic porbeagle ID 10654 as ineligible for the age-disaggregated candidate set.\n')
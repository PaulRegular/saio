root <- "."
cache <- file.path(root, 'source_cache', 'noaa_shortfin_mako_north_atlantic_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
review_date <- '2026-11-01'

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment <- stocksmart[
  as.character(stocksmart$assessment_id) == '7878', , drop = FALSE]
if (nrow(assessment) != 1L ||
    as.character(assessment$stock_id) != '10657' ||
    as.integer(assessment$assessment_year) != 2017L ||
    as.integer(assessment$last_data_year) != 2015L ||
    as.character(assessment$review_result) != 'Full acceptance' ||
    !grepl('SS3', as.character(assessment$assessment_model), fixed = TRUE))
  stop('NOAA Stock SMART metadata do not match the reviewed 2017 shortfin mako record.',
    call. = FALSE)

files <- c('ICCAT_2026_North_Atlantic_shortfin_mako_meeting_report.pdf',
  'ICCAT_2026_North_Atlantic_shortfin_mako_SS3_runs.pdf')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (!all(files %in% manifest$file) ||
    !all(file.exists(file.path(cache, files))) ||
    anyNA(manifest$sha256[match(files, manifest$file)]) ||
    !all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])))
  stop('The 2026 shortfin mako source cache is incomplete.', call. = FALSE)
pdf_headers <- vapply(file.path(cache, files), function(path) {
  con <- file(path, 'rb')
  on.exit(close(con))
  identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
}, logical(1L))
if (!all(pdf_headers))
  stop('A cached 2026 shortfin mako source is not a PDF.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:10657'
i <- match(candidate_id, candidates$candidate_id)
if (is.na(i) || anyDuplicated(candidates$candidate_id))
  stop('Expected one North Atlantic shortfin mako Stock SMART register row.',
    call. = FALSE)

row <- data.frame(
  candidate_unit_id = 'noaa_north_atlantic_shortfin_mako',
  assessment_area = 'North Atlantic',
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The latest ICCAT SS3 run uses catch data through 2024, but no complete',
    'catch-numbers-at-age series was verified. CAAL samples from Portuguese and U.S.',
    'fleets may support reconstruction for some fleet-years, but the necessary',
    'year/fleet expansion data have not been established.'),
  survey_age_evidence = paste('The model uses CPUE indices and length compositions. No annual',
    'age-specific CPUE/index series was identified. CAAL records are described as',
    'growth data rather than age compositions for each index year.'),
  weights_evidence = paste('',
    'reconstruction was not verified in the reviewed 2026 source documents.'),
  maturity_evidence = paste('The assessment uses biological scenarios, including fecundity',
    ''),
  mortality_evidence = paste('The 2026 assessment evaluates alternative biological scenarios',
    'with different age-specific natural-mortality assumptions.'),
  timing_evidence = paste('The model uses annual CPUE indices; no within-year timing for an',
    'age-specific abundance index was identified.'),
  output_evidence = paste('The final agreed 2026 SS3 run reports recruitment, spawning-stock',
    'fecundity, and fishing-mortality/status trajectories through 2024. Full N-at-age,',
    'F-at-age, and M-at-age output tables were not verified.'),
  detailed_source_url = paste(
    'https://www.iccat.int/Documents/CVSP/CV083_2026/n_7/CV08307009.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV083_2026/n_7/CV08307143.pdf;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10657'),
  review_date = review_date,
  decision_reason = paste('The latest assessment is ICCAT 2026, not the 2017 NOAA Stock SMART',
    'record, and is a length-based age-structured SS3 model. It uses catches, CPUE,',
    'length compositions, and in some runs conditional age-at-length samples. Those',
    'CAAL data may support a documented reconstruction for some fleets, but available',
    'evidence does not establish complete annual catch-at-age or age-specific index',
    'series; eligibility remains unresolved pending recovery of row-level data and',
    'expansion information.'),
  notes = paste('The ICCAT 2026 assessment covers 1950-2024 and includes three biological',
    'scenarios. The 2026 meeting report states no new length-composition data were',
    'presented; the SS3 paper documents the composition inputs and selected CAAL',
    'runs. No canonical numerical records were added.'),
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
    stop('Unexpected existing review state for NOAA:10657.', call. = FALSE)
  for (name in names(row)) candidates[[name]][i] <- row[[name]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, i,
    candidates[i, , drop = FALSE], candidate_id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened NOAA North Atlantic shortfin mako ID 10657; eligibility remains unresolved pending age-data reconstruction evidence.\n')
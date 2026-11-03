root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_iccat_west_sailfish_2023')
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10180'
unit_id <- 'iccat_west_atlantic_sailfish'

expected_sources <- data.frame(
  source_id = 'iccat_west_sailfish_assessment_2023',
  file = '2023_SAI_ENG.pdf',
  url = 'https://iccat.int/Documents/Meetings/Docs/2023/REPORTS/2023_SAI_ENG.pdf',
  retrieved_at = '2026-10-31',
  bytes = 9337213L,
  sha256 = '735C29F76676D99B2EAC3413B75229C5C6CA14CD61042806672E81BA5233DFBA',
  pinned_revision = 'ICCAT Sailfish Data Preparatory and Stock Assessment Meeting report, 5-10 June 2023',
  stringsAsFactors = FALSE
)

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path)), 'SHA256'), stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE))
  if (length(hashes) != 1L)
    stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
if (!identical(manifest$source_id, expected_sources$source_id) ||
    !identical(manifest$file, expected_sources$file) ||
    !identical(manifest$url, expected_sources$url) ||
    !identical(manifest$retrieved_at, expected_sources$retrieved_at) ||
    !identical(as.integer(manifest$bytes), expected_sources$bytes) ||
    !identical(toupper(manifest$sha256), expected_sources$sha256) ||
    !identical(manifest$pinned_revision, expected_sources$pinned_revision))
  stop('Cached ICCAT sailfish manifest differs from the reviewed source.', call. = FALSE)

path <- file.path(cache, expected_sources$file)
if (!file.exists(path) || file.info(path)$size != expected_sources$bytes ||
    !identical(sha256_file(path), expected_sources$sha256) ||
    !identical(rawToChar(readBin(path, 'raw', n = 4L)), '%PDF'))
  stop('Cached ICCAT sailfish report differs from its manifest.', call. = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
run <- stocksmart[stocksmart$stock_id == 10180 &
  stocksmart$assessment_year == 2023, , drop = FALSE]
if (nrow(run) != 1L || run$assessment_id != 12971L ||
    run$last_data_year != 2021L || run$assessment_model != 'BSP' ||
    run$review_result != 'Full acceptance' ||
    run$assessment_type != 'Operational' ||
    run$stock_name != 'Sailfish - Western Atlantic')
  stop('NOAA Stock SMART metadata differs from the screened ICCAT assessment.', call. = FALSE)

candidates <- read.csv(candidate_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != '10180' ||
    candidates$scientific_name[row] != 'Istiophorus platypterus' ||
    candidates$stock_name[row] != 'Sailfish - Western Atlantic' ||
    candidates$assessment_area[row] != 'Western Atlantic' ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(stocks$stock_id == unit_id, na.rm = TRUE) ||
    any(stocks$authority_stock_id == '10180', na.rm = TRUE) ||
    any(grepl('sailfish', stocks$common_name, ignore.case = TRUE), na.rm = TRUE))
  stop('ICCAT western sailfish identity conflicts with the candidate register or database.',
    call. = FALSE)
if (any(assessments$assessment_id == unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == unit_id, na.rm = TRUE))
  stop('Screening must not create canonical assessment, input, or output records.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2023 assessment uses fleet catches and annual length compositions.',
    'The Stock Synthesis report explicitly states that no age data were included.'
  ),
  survey_age_evidence = paste(
    'The west-stock model uses eight aggregate abundance indices, all fishery CPUE.',
    'No age-specific survey indices or population age compositions were identified.'
  ),
  weights_evidence = paste(
    'The report gives a length-weight relationship and growth assumptions, which',
    'could support derived weight-at-age values. No run-matched weight-at-age',
    'input matrix was identified.'
  ),
  maturity_evidence = paste(
    'Maturity is described as a logistic function of age with first maturity at age 1.',
    'No sampled maturity-at-age input series was identified.'
  ),
  mortality_evidence = paste(
    'Natural mortality was fixed at 0.35 per year and assumed equal across ages.',
    'Age bins and age-based selectivity do not represent age-composition data.'
  ),
  timing_evidence = paste(
    'The abundance inputs are fishery CPUE indices rather than seasonal surveys,',
    'so a within-year survey timing fraction is not applicable.'
  ),
  output_evidence = paste(
    'The selected western JABBA scenario reports aggregate B/BMSY and F/FMSY;',
    'the alternative Stock Synthesis report gives aggregate relative SSB, F and',
    'recruitment trajectories. Annual N-at-age and F-at-age surfaces were not found.'
  ),
  detailed_source_url = paste(c(
    expected_sources$url,
    'https://www.iccat.int/en/assess.html'
  ), collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste(
    'NOAA Stock SMART 10180 is the western Atlantic sailfish management unit.',
    'The 2023 operational full-acceptance run is identified as BSP in Stock SMART;',
    'ICCAT selected JABBA S5 for west-stock advice and also evaluated Stock Synthesis.',
    'The SS report explicitly says no age data were used; the observations are catches,',
    'aggregate CPUE and length compositions, with no annual N/F-at-age outputs.'
  ),
  notes = paste(
    'NOAA uses the scientific-name label Istiophorus platypterus while the ICCAT',
    '2023 report uses Istiophorus albicans for Atlantic sailfish. The candidate-unit',
    'crosswalk is based on the matching common name and western Atlantic area; this',
    'screen does not assert that the names are taxonomic synonyms. No canonical',
    'values were added and no tinyAM translation was attempted. The report is cached',
    'under source_cache/discovery_noaa_iccat_west_sailfish_2023/.'
  )
)

current <- lapply(names(review), function(column)
  as.character(candidates[[column]][row]))
names(current) <- names(review)
same_review <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
is_unreviewed <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) ||
    !nzchar(candidates$candidate_unit_id[row]))
if (!is_unreviewed && !same_review)
  stop('ICCAT western sailfish candidate already has a conflicting review state.',
    call. = FALSE)
if (is_unreviewed || !same_review) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(candidate_path, row,
    candidates[row, , drop = FALSE], candidate_id)
}

cat('Screened NOAA:10180 as a new but ineligible ICCAT western Atlantic sailfish unit.\n')

root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_wreckfish_2014')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10369'
candidate_unit_id <- 'noaa_south_atlantic_wreckfish'

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected_sources <- data.frame(
  file = c('noaa_wreckfish_species_page_2026-10-31.html',
    'safmc_ssc_april_2026_report.pdf',
    'wreckfish_preliminary_assessment_april_2026.pdf',
    'wreckfish_sar_2014.pdf', 'wreckfish_ssc_review_april_2014.pdf'),
  url = c(
    'https://www.fisheries.noaa.gov/species/wreckfish',
    'https://safmc.net/documents/ssc_apr2026_report_final/',
    'https://safmc.net/documents/8b_wreckfish-stock-assessment-update-april-2026-pdf/',
    'https://safmc.net/documents/12c_wreckfish_sar_april2014_final-pdf/',
    'https://safmc.net/documents/12d_ssc_apr2014_report_final_rev1-pdf/'),
  retrieved_on = '2026-10-31',
  bytes = c(167923, 1654763, 1952419, 1687836, 264701),
  sha256 = c(
    '279d8c58a5605879181b79c8940e64e5804b3ea4ad91b70f6046889dbc3c874c',
    'b7ae3047061668dc756353b36d0087423ceb5e926961360a4f1d0165a701d811',
    '4e68133db6b6ec354272445d67e8cfcbd3575d0189814ff5f049c0721f804e8e',
    '2875690434b57404e43639b21052dfdb2f9ea5988e66dda69d17b08eac3a9713',
    '61b8cfe7bb6a4faa5144e60e5c468fc280d337edf30cecbdabb9a5728fb0178d'),
  stringsAsFactors = FALSE)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (!identical(names(manifest), names(expected_sources)) ||
    nrow(manifest) != nrow(expected_sources) || anyDuplicated(manifest$file) ||
    !identical(manifest$file, expected_sources$file) ||
    !identical(manifest$url, expected_sources$url) ||
    !identical(manifest$retrieved_on, expected_sources$retrieved_on) ||
    !identical(as.numeric(manifest$bytes), as.numeric(expected_sources$bytes)) ||
    !identical(tolower(manifest$sha256), expected_sources$sha256))
  stop('The wreckfish source manifest is incomplete or changed.', call. = FALSE)
for (i in seq_len(nrow(expected_sources))) {
  path <- file.path(cache, expected_sources$file[i])
  if (!file.exists(path) || file.info(path)$size != expected_sources$bytes[i] ||
      sha256_file(path) != expected_sources$sha256[i])
    stop('Cached wreckfish source differs from the manifest: ',
      expected_sources$file[i], call. = FALSE)
}

noaa_page <- paste(readLines(file.path(cache,
  'noaa_wreckfish_species_page_2026-10-31.html'), warn = FALSE), collapse = ' ')
if (!grepl('support by 2014 stock assessment', noaa_page, fixed = TRUE))
  stop('NOAA current status page no longer supports the 2014 assessment.', call. = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
smart_row <- stocksmart[as.character(stocksmart$stock_id) == '10369', , drop = FALSE]
if (nrow(smart_row) != 1L || as.character(smart_row$assessment_year) != '2014' ||
    smart_row$assessment_id != 4671 ||
    !grepl('Full acceptance', smart_row$review_result, fixed = TRUE))
  stop('NOAA Stock SMART wreckfish assessment identity changed.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || candidates$official_stock_id[row] != '10369' ||
    candidates$scientific_name[row] != 'Polyprion americanus' ||
    candidates$inventory_assessment_year[row] != '2014' ||
    candidates$assessment_area[row] != 'Southern Atlantic Coast')
  stop('NOAA wreckfish inventory identity changed.', call. = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (any(stocks$scientific_name == 'Polyprion americanus', na.rm = TRUE) ||
    any(assessments$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == candidate_unit_id, na.rm = TRUE))
  stop('A canonical wreckfish record exists; recheck its identity.', call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste0(
    'The accepted 2014 production assessment (data through 2010) fits commercial ' ,
    'catch-at-length, not observed annual catch-at-age. The April 2026 preliminary ' ,
    'update reports port-sampled age material from 1991-2012, but says age ' ,
    'compositions will first be compared as marginal data and considered for the ' ,
    'likelihood only after representativeness checks; numerical annual age ' ,
    'frequencies were not recovered.'),
  survey_age_evidence = paste0(
    'The 2014 assessment uses an aggregate fishery-dependent CPUE index. The 2026 ' ,
    'update states that wreckfish are not regularly caught by NOAA surveys and ' ,
    'there is no fishery-independent survey index; its commercial LPUE index is ' ,
    'aggregate, with no age-specific abundance series.'),
  weights_evidence = paste0(
    'The 2014 model derives weight-at-age from a growth curve and length-weight ' ,
    'relationship. The 2026 preliminary report supplies growth and length-weight ' ,
    'parameters, but the current length-only base fit does not provide a complete ' ,
    'annual observed weight-at-age input matrix.'),
  maturity_evidence = paste0(
    'The 2014 assessment models maturity at length and converts it to age through ' ,
    'the age-length distribution. The 2026 report lists length-based maturity ' ,
    'parameters; no annual observed maturity-at-age input series was located.'),
  mortality_evidence = paste0(
    'The 2014 reference case estimates age-independent M (0.0366 per year); the ' ,
    '2026 preliminary model uses life-history M of 0.037 per year with SD 0.00407. ' ,
    'The April 2026 SSC report notes that M is not estimable from the available ' ,
    'data. No annual age-specific M surface was reported.'),
  timing_evidence = paste0(
    'The abundance inputs are aggregate annual fishery-dependent indices, not ' ,
    'seasonally timed survey series. Wreckfish commercial fishing years run ' ,
    'April 15-January 15, but a fractional-year observation timing for the CPUE ' ,
    'likelihood was not specified.'),
  output_evidence = paste0(
    'The accepted 2014 assessment reports stock biomass, recruitment, fishing ' ,
    'mortality and reference-point outputs. The 2026 preliminary length-only model ' ,
    'reports SSB with 95% confidence intervals and aggregate F/recruitment trends, ' ,
    'but remains under development and is not the production assessment NOAA cites ' ,
    'for current status.'),
  detailed_source_url = paste0(
    'https://safmc.net/documents/12c_wreckfish_sar_april2014_final-pdf/ ',
    'https://safmc.net/documents/8b_wreckfish-stock-assessment-update-april-2026-pdf/'),
  review_date = '2026-10-31',
  decision_reason = paste0(
    'Eligibility remains unresolved for the age-disaggregated expansion. The ' ,
    'latest accepted production run fits catch-at-length and an aggregate CPUE ' ,
    'index. The 2026 preliminary update identifies fishery age samples from ' ,
    '1991-2012, but says they have not yet been validated as representative or ' ,
    'entered into the assessment likelihood; complete numerical age compositions ' ,
    'and a final accepted current run were not located. Revisit if the age ' ,
    'frequencies or final model files become public.'),
  notes = paste0(
    'NOAA Stock SMART 10369 has no canonical database match. NOAA still cites ' ,
    'the 2014 assessment for status; SAFMC described the 2026 assessment as ' ,
    'preliminary and under development. The 2026 working update is documented ' ,
    'separately and does not replace the accepted production-run identity. ' ,
    'Discovery screen only; no canonical values were imported.'))

already_reviewed <- all(vapply(names(review), function(column)
  identical(as.character(candidates[[column]][row]), as.character(review[[column]])),
  logical(1L)))
pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!(pristine || already_reviewed))
  stop('NOAA wreckfish inventory row has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened NOAA wreckfish; age-input eligibility remains unresolved pending the 2026 age-composition work.\n')

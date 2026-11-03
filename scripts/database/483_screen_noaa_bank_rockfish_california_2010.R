root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_bank_rockfish_california')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10448'
candidate_unit_id <- 'noaa_bank_rockfish_california'

expected_sources <- data.frame(
  file = c('noaa_swfsc_tm460_dbsra_2010.pdf',
    'pfmc_2022_bank_rockfish_data_summary.pdf',
    'noaa_2026_amendment37_stock_definitions_analysis.pdf'),
  url = c(
    'https://www.pcouncil.org/documents/2010/06/estimates-of-sustainable-yield-for-50-data-poor-stocks-in-the-pacific-coast-groundfish-fishery-management-plan-noaa-technical-memorandum-noaa-tm-nmfs-swfsc-460-june-2010.pdf/',
    'https://www.pcouncil.org/documents/2022/05/f-3-attachment-4-detailed-summary-of-available-data-to-support-west-coast-groundfish-stock-assessments-in-2023-electronic-only.pdf/',
    'https://www.fisheries.noaa.gov/s3/2026-02/am-37-fpa-analysis-01-2026.pdf'),
  revision = c('NOAA-TM-NMFS-SWFSC-460, June 2010; DB-SRA data through 2009',
    'PFMC Agenda Item F.3 Attachment 4, 2022; data status for 2023 assessments',
    'Analysis for Amendment 37 Phase 2 Stock Definitions, 2026'),
  retrieved_on = '2026-10-31',
  bytes = c(1194496, 7732525, 2610432),
  sha256 = c(
    '7427c0547ddc2ee628267e465e4e7958aba1f63a95aa07d693fb4183033cfe78',
    '7a8c62af8dee5e77daf269879c6e2ae126fe857fbf1ac6c711aeae4ce23cfb09',
    '7241ff01f9f2f56b4da7dced43a318ca38dd172de7bbe44bd140918e8bd8ba0d'),
  stringsAsFactors = FALSE)

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L)
    stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

if (!dir.exists(cache) || any(!file.exists(file.path(cache, expected_sources$file))))
  stop('Cache the listed official bank rockfish sources before screening.', call. = FALSE)
manifest_path <- file.path(cache, 'sources.csv')
if (!file.exists(manifest_path))
  write.csv(expected_sources, manifest_path, row.names = FALSE)
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
if (!identical(names(manifest), names(expected_sources)) ||
    nrow(manifest) != nrow(expected_sources) || anyDuplicated(manifest$file) ||
    !identical(manifest$file, expected_sources$file) ||
    !identical(manifest$url, expected_sources$url) ||
    !identical(manifest$revision, expected_sources$revision) ||
    !identical(manifest$retrieved_on, expected_sources$retrieved_on) ||
    !identical(as.numeric(manifest$bytes), as.numeric(expected_sources$bytes)) ||
    !identical(tolower(manifest$sha256), expected_sources$sha256))
  stop('The bank rockfish source manifest is incomplete or changed.', call. = FALSE)
for (i in seq_len(nrow(expected_sources))) {
  path <- file.path(cache, expected_sources$file[i])
  if (!file.exists(path) || file.info(path)$size != expected_sources$bytes[i] ||
      sha256_file(path) != expected_sources$sha256[i])
    stop('Cached bank rockfish source differs from the manifest: ',
      expected_sources$file[i], call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
smart_row <- stocksmart[as.character(stocksmart$stock_id) == '10448', , drop = FALSE]
if (nrow(smart_row) != 1L || smart_row$assessment_id != 11866L ||
    smart_row$assessment_year != 2010L || smart_row$last_data_year != 2009L ||
    smart_row$assessment_model != 'DB-SRA' ||
    !grepl('Full acceptance', smart_row$review_result, fixed = TRUE))
  stop('NOAA Stock SMART bank rockfish assessment identity changed.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || candidates$official_stock_id[row] != '10448' ||
    candidates$scientific_name[row] != 'Sebastes rufus' ||
    candidates$stock_name[row] != 'Bank rockfish - California' ||
    candidates$assessment_area[row] != 'California' ||
    candidates$inventory_assessment_year[row] != '2010')
  stop('NOAA California bank rockfish inventory identity changed.', call. = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (any(stocks$scientific_name == 'Sebastes rufus', na.rm = TRUE) ||
    any(assessments$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == candidate_unit_id, na.rm = TRUE))
  stop('A canonical bank rockfish record exists; recheck its unit identity.', call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'NOAA Stock SMART assessment 11866 is a 2010 DB-SRA run based on aggregate',
    'catch history; it does not fit annual catch-at-age or age-composition',
    'likelihoods. PFMC reports 5,064 commercial age readings across all available',
    'years, but no age readings collected in California since 2000; those sample',
    'totals are not annual model inputs.'),
  survey_age_evidence = paste(
    'The 2010 DB-SRA uses catch history and prior distributions, not an abundance',
    'index or age-specific survey observations. The earlier California stock',
    'assessment is described as lacking a reliable survey.'),
  weights_evidence = paste(
    'No weights-at-age series enter the 2010 DB-SRA. Catch and harvest limits are',
    'reported in metric tonnes; weight-at-age would not be a fitted observation.'),
  maturity_evidence = paste(
    'The DB-SRA uses a scalar age-at-maturity (13 years) as a life-history input',
    'to its time-lagged productivity prior, not a maturity-at-age curve.'),
  mortality_evidence = paste(
    'The DB-SRA uses maximum age 73 and a point M estimate of 0.080 per year to',
    'define a prior distribution for natural mortality. It does not estimate an',
    'age-specific M surface.'),
  timing_evidence = paste(
    'The 2010 DB-SRA uses catch history and has no survey observation timing.'),
  output_evidence = paste(
    'The 2010 report presents DB-SRA catch and OFL outputs, including 2008-2009',
    'average catch of 94.3 mt, median 2010 OFL of 585.0 mt, and a 0.09 probability',
    'that recent catch exceeds the 2010 OFL. It does not report annual N-at-age,',
    'F-at-age, recruitment or spawning biomass from an age-structured fit.'),
  detailed_source_url = paste(c(expected_sources$url,
    'http://www.pcouncil.org/wp-content/uploads/Bank_Rockfish_2000_Assessment.pdf'),
    collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste(
    'Ineligible for the age-disaggregated source set. The current NOAA Stock SMART',
    'run is the accepted 2010 DB-SRA, which models aggregate catch and life-history',
    'priors rather than age-specific observations. The age readings documented in',
    'the PFMC data inventory were not used as annual assessment inputs. The 2010',
    'report provides catch/OFL results but no age-structured population outputs.'),
  notes = paste(
    'Run history is not completely consistent across official sources: NOAA Stock',
    'SMART identifies a full-acceptance 2010 DB-SRA (assessment 11866, data through',
    '2009), and PFMC’s 2022 detailed data summary calls 2010 the latest data-limited',
    'assessment. NOAA’s 2026 Amendment 37 analysis separately cites a 2000',
    'California-only stock assessment. The 2000 assessment PDF link referenced in',
    'NOAA/PFMC materials returned 404 on 2026-10-31, so its detailed input structure',
    'could not be checked. This does not change the 2010 run’s ineligible age-input',
    'screen. Discovery only; no canonical values were imported.'))

already_reviewed <- all(vapply(names(review), function(column)
  identical(as.character(candidates[[column]][row]), as.character(review[[column]])),
  logical(1L)))
pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!(pristine || already_reviewed))
  stop('NOAA bank rockfish inventory row has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened NOAA California bank rockfish as ineligible for age-disaggregated inputs.\n')

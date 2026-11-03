root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_oregon_vermilion_2021')
register_path <- file.path(root, 'discovery', 'candidates.csv')

sha256_file <- function(path) {
  output <- system2('certutil.exe',
    c('-hashfile', shQuote(normalizePath(path, winslash = '\\', mustWork = TRUE)), 'SHA256'),
    stdout = TRUE)
  hashes <- tolower(trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$',
    output, value = TRUE)))
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  hashes
}

expected_hashes <- c(
  oregon_vermilion_assessment_2021.pdf = '468585b4c657924f65e217c00349f46019de9154b699ed6181f3c0205555eb5a',
  oregon_vermilion_model_files_2021.zip = 'cad184ba420ca0fe1390ad064dd08ae423e716c83b9823e1967d1f8e7d1fc9d5',
  vermilion_sunset_star_panel_2021.pdf = '098c6c07c5f1e85fcc3088a33f1cde64059e5e84447d0f7d40a4f9cab367a8b1',
  pfmc_september_2021_meeting_record.pdf = '6fb21be9aa5b27f77c3707a315f0adb149cf3b43322a2559ff9127b8adbd6273'
)
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The Oregon vermilion source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached Oregon vermilion source differs from its manifest: ', file, call. = FALSE)
}

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
candidate_id <- 'NOAA:15338'
candidate_unit_id <- 'noaa_vermilion_rockfish_or_wa'
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || candidates$official_stock_id[row] != '15338' ||
    candidates$scientific_name[row] != 'Sebastes miniatus' ||
    candidates$stock_name[row] != 'Vermilion rockfish - Oregon' ||
    candidates$assessment_area[row] != 'Oregon' ||
    candidates$inventory_assessment_year[row] != '2021')
  stop('The NOAA Oregon vermilion inventory identity changed.', call. = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (candidate_unit_id %in% stocks$stock_id || candidate_unit_id %in% assessments$assessment_id ||
    candidate_unit_id %in% inputs$assessment_id || candidate_unit_id %in% outputs$assessment_id)
  stop('A canonical Oregon vermilion record exists; recheck the current-unit crosswalk.', call. = FALSE)

report_url <- manifest$url[match('oregon_vermilion_assessment_2021.pdf', manifest$file)]
review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste0(
    'The 2021 Stock Synthesis input archive contains commercial and recreational ' ,
    'conditional age-at-length observations (896 and 1,180 aged fish, respectively) ' ,
    'alongside annual length compositions and catch histories. Ages are sampled in ' ,
    '2004-2020, not throughout the 1892-2020 catch series. Catch-at-age is therefore ' ,
    'reconstructable only for supported periods or through an explicitly documented ' ,
    'age-length-key extension; no fitted-state reconstruction is acceptable.'),
  survey_age_evidence = paste0(
    'The assessment includes an aggregate Oregon Recreational Boat Survey dockside ' ,
    'CPUE index for 2001-2020, standardized from summer (May-September) trips in the ' ,
    'southern Oregon subregion. Recreational age samples cover 2005-2020, but the report ' ,
    'does not establish that their composition exactly matches the standardized index ' ,
    'sample. An age-specific index would be a documented approximation and would lack ' ,
    'age information in 2001-2004.'),
  weights_evidence = paste0(
    'The assessment archive includes fitted age-specific biology and a weight-at-age ' ,
    'output file. The report documents sex-specific growth and length-weight ' ,
    'relationships; these permit source-based age-weight derivation.'),
  maturity_evidence = paste0(
    'Maturity is specified at length and converted through the sex-specific growth ' ,
    'model; age-specific maturity is available from the model output, not as a direct ' ,
    'annual observed series.'),
  mortality_evidence = paste0(
    'Female and male natural mortality are estimated separately with lognormal priors; ' ,
    'the reference estimates are 0.080 and 0.073 per year.'),
  timing_evidence = paste0(
    'The index is standardized using summer trips from May through September. The ' ,
    'annual SS input file encodes the index observation with month code 7; the report ' ,
    'does not state a fractional-year timing value, so any conversion requires checking ' ,
    'the model-file convention and documenting the approximation.'),
  output_evidence = paste0(
    'The official model archive includes the accepted Stock Synthesis input files and ' ,
    'Report.sso outputs, including numbers-at-age, catch-at-age and F-at-age; the report ' ,
    'also tabulates annual index values and reference population quantities.'),
  detailed_source_url = report_url,
  review_date = '2026-10-31',
  decision_reason = paste0(
    'Eligible for source curation. The latest Oregon-specific production assessment ' ,
    'located is the Council-adopted 2021 benchmark, with its report and native model ' ,
    'archive publicly available. Age-at-length, annual lengths, catch and an aggregate ' ,
    'index support documented age-specific reconstruction, but age coverage is sparse ' ,
    'and index-at-age is approximate; these limits must remain explicit.'),
  notes = paste0(
    'The Council identifies the current managed stock as Vermilion rockfish (OR/WA). ' ,
    'Stock SMART ID 15338 is its Oregon component. Oregon and Washington were fitted ' ,
    'as separate 2021 assessment areas and remain separate source components; they are ' ,
    'not counted as two current stock units. The Oregon model uses one annual season, ' ,
    'two removal fleets, and ages 0-65. This is an inventory screen only; no canonical ' ,
    'assessment or values have been imported.'))

pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
already_reviewed <- all(vapply(names(review), function(column)
  identical(as.character(candidates[[column]][row]), as.character(review[[column]])),
  logical(1L)))
previously_screened <- candidates$match_status[row] == 'new' &&
  candidates$candidate_unit_id[row] == 'noaa_vermilion_rockfish_oregon_2021' &&
  candidates$screening_status[row] == 'screened' &&
  candidates$eligibility[row] == 'eligible' &&
  candidates$import_status[row] == 'not_started'
if (!(pristine || previously_screened || already_reviewed))
  stop('The NOAA Oregon vermilion candidate has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened NOAA Oregon vermilion rockfish as eligible for source curation, with sparse age coverage and approximate index-at-age caveats.\n')

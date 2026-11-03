root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_greenland_cod_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)

expected_sources <- data.frame(
  file = c('cod_21_1_osc_advice_2026.html', 'cod_21_1_isc_advice_2026.html',
    'cod_21_27_1_14_advice_2026.html', 'nwwg_2026_west_greenland_cod.pdf',
    'nwwg_2026_southwest_greenland_cod.pdf',
    'nwwg_2026_northwest_greenland_inshore_cod.pdf',
    'nwwg_2026_east_greenland_iceland_offshore_cod.pdf'),
  url = c('https://asd.ices.dk/viewAdvice/5088', 'https://asd.ices.dk/viewAdvice/5089',
    'https://asd.ices.dk/viewAdvice/5091',
    'https://ndownloader.figshare.com/files/65495862',
    'https://ndownloader.figshare.com/files/65495868',
    'https://ndownloader.figshare.com/files/65495871',
    'https://ndownloader.figshare.com/files/65495874'),
  sha256 = c('00D8178973EED0C0DF11A31F028DDDF2E625937B5CD76C60AB6A3B36B369F88D',
    'FC507BE682CABB81871A268C4E13BCFA23BC6C960713422FEA56123D2222D9E3',
    '0BA90E534EC69D47294998CE7E6A9CD7AE150D3933B7F12415BA99D7C2BF9B05',
    'AA905234DF5792401A83CBB6AEECE710143FC4F8B3A8A16DBF0DC8959642EC46',
    'B1486382F7456DF8DDF71BF29409BA004E1B180BB8CEC916F58FDE955CFC7137',
    'FF4F837590C8115E496F9C002BF296363DE3E458C76361FBBC9BFBB9692952F5',
    'D32EBED8DB3F91B0E2F13C1F2FCEE286AC3F93B6C039A51ACFEE1ADC00C16EB1'),
  stringsAsFactors = FALSE
)
source_rows <- match(expected_sources$file, manifest$file)
if (anyNA(source_rows) || anyDuplicated(manifest$file))
  stop('The Greenland cod source manifest is incomplete or duplicated.', call. = FALSE)

sha256_file <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(digest::digest(file = path, algo = 'sha256'))
  executable <- if (.Platform$OS.type == 'windows') 'certutil' else 'sha256sum'
  output <- system2(executable,
    c(if (.Platform$OS.type == 'windows') '-hashfile' else NULL,
      normalizePath(path, winslash = '/', mustWork = TRUE),
      if (.Platform$OS.type == 'windows') 'SHA256' else NULL),
    stdout = TRUE)
  hashes <- grep('^[[:xdigit:]]{64}$', gsub('[[:space:]]', '', output), value = TRUE)
  if (length(hashes) != 1L) stop('Could not verify source checksum: ', path, call. = FALSE)
  tolower(hashes)
}

for (i in seq_len(nrow(expected_sources))) {
  path <- file.path(cache, expected_sources$file[i])
  row <- source_rows[i]
  if (!file.exists(path) || manifest$url[row] != expected_sources$url[i] ||
      tolower(manifest$sha256[row]) != tolower(expected_sources$sha256[i]) ||
      tolower(sha256_file(path)) != tolower(expected_sources$sha256[i]) ||
      as.numeric(manifest$bytes[row]) != file.info(path)$size ||
      manifest$retrieved_on[row] != '2026-11-01')
    stop('Cached ICES source failed validation: ', expected_sources$file[i], call. = FALSE)
}

report_url <- 'https://doi.org/10.17895/ices.pub.32414577'
reviews <- list(
  'ICES:cod.21.1.osc' = list(
    candidate_unit_id = 'ices_cod_west_greenland_offshore', match_status = 'new',
    matched_stock_id = NA_character_, screening_status = 'screened', eligibility = 'eligible',
    import_status = 'not_started',
    catch_age_evidence = paste0('NWWG 2026 chapter 13, section 13.2.1.3, reports annual catch-at-age ',
      'calculated from commercial catches; the numerical data are cited in Buch et al. (2026b). ',
      'The assessment covers 2000-2025. Exact input age coverage and source rows remain for curation.'),
    survey_age_evidence = paste0('Chapter 13, section 13.2.1.7, describes relative abundance indices at age ',
      'derived from Greenland Groundfish Survey G2064 and German Groundfish Survey G4355 using an ',
      'INLA spatial model. An additional combined gillnet CPUE series covers 2002-2025. Exact age/year ',
      'rows and units remain for curation.'),
    weights_evidence = paste0('Annual catch weights-at-age are calculated from commercial catches; stock ',
      'weights-at-age are calculated from the Greenland bottom-trawl survey (chapter 13, section 13.2.1.4; ',
      'Buch et al. 2026b).'),
    maturity_evidence = 'Maturity-at-age is fixed between years (chapter 13, section 13.2.1.5); exact values remain for curation.',
    mortality_evidence = 'Natural mortality is fixed at 0.2 for all ages (chapter 13, Table 13.7.1).',
    timing_evidence = paste0('The report identifies the summer-autumn survey seasons but does not specify ',
      'the fractional-year timing used in SAM. A tinyAM timing value remains unresolved.'),
    output_evidence = paste0('The 2026 SAM production run is identified as NWWG26_WOSC_v1. Chapter 13 ',
      'reports recruitment at age 2 (thousands), SSB (tonnes), catch (tonnes), and F for ages 5-8 ',
      'through 2025, with uncertainty intervals. The run directory and source tables require curation.'),
    detailed_source_url = paste(report_url,
      'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NWWG26_WOSC_v1/', sep = '; '),
    review_date = '2026-11-01',
    decision_reason = paste0('Eligible for source curation: the current 2026 Category 1 assessment uses ',
      'SAM with commercial catch-at-age, age-specific survey indices, age-based biology and fixed M, ',
      'and reports comparable population and fishing-mortality outputs.'),
    notes = paste0('Current unit cod.21.1.osc is the West Greenland offshore spawning stock. The official ',
      '2026 NWWG report describes a 2000-2025 SAM run and identifies NWWG26_WOSC_v1. The report and ',
      'stock-specific chapter are cached under source_cache/discovery_ices_greenland_cod_2026/. Exact ',
      'input matrices, index timing fractions, and fitted age-surface extraction remain unverified; no ',
      'canonical data or tinyAM translation was added.')),
  'ICES:cod.21.1.isc' = list(
    candidate_unit_id = 'ices_cod_west_greenland_inshore', match_status = 'new',
    matched_stock_id = NA_character_, screening_status = 'screened', eligibility = 'eligible',
    import_status = 'not_started',
    catch_age_evidence = paste0('The official inshore advice code cod.21.1.isc covers two separately ',
      'reported model components. N-WISC (cod.21.1a-c) uses annual commercial catch-at-age; S-WISC ',
      '(cod.21.1d-f) has catch-at-age calculated but the 2026 chapter says it is not used in the assessment.'),
    survey_age_evidence = paste0('N-WISC uses an annual multimesh gillnet survey in NAFO 1B, designed ',
      'to target ages 2-3; exact index age structure and rows remain for curation. The S-WISC 1D survey ',
      'index was excluded from assessment after a progressive timing shift raised catchability concerns.'),
    weights_evidence = paste0('N-WISC catch weights-at-age use commercial and gillnet samples; stock ',
      'weights-at-age use the Greenland gillnet survey. S-WISC has corresponding weights calculated, ',
      'but the 2026 chapter says they are not used in its assessment.'),
    maturity_evidence = 'Maturity-at-age is fixed between years in both inshore component chapters; exact values remain for curation.',
    mortality_evidence = 'For the N-WISC forecast, natural mortality is fixed at 0.2 for all ages (chapter 15, Table 15.7.1).',
    timing_evidence = paste0('N-WISC gillnet timing fraction is not stated in the report. S-WISC survey timing ',
      'shift is documented as a reason its index is not used; do not infer a tinyAM timing fraction.'),
    output_evidence = paste0('The 2026 report gives age-2 recruitment, SSB, catch, and F ages 5-8 output ',
      'tables for the inshore advice components. N-WISC remains a Category 1 SAM assessment. S-WISC was ',
      'not accepted as a robust assessment in 2026 and advice is catch-based; preserve this distinction.'),
    detailed_source_url = report_url,
    review_date = '2026-11-01',
    decision_reason = paste0('Eligible for partial source curation as the current cod.21.1.isc advice unit ',
      'contains a current Category 1 N-WISC SAM assessment with age-based inputs and comparable outputs. ',
      'The unit must retain separate N-WISC and S-WISC assessment components; S-WISC is not an accepted ',
      'age-based model for 2026 advice.'),
    notes = paste0('Do not count N-WISC and S-WISC as separate additional inventory stocks: ICES gives ',
      'advice under cod.21.1.isc, but documents two separate assessment components (cod.21.1a-c and ',
      'cod.21.1d-f). N-WISC retains the Category 1 SAM assessment; S-WISC was changed to Category 5, ',
      'its 2026 updated model was not accepted, and its catch-at-age, weights-at-age, and gillnet series ',
      'are not used for advice. N-WISC output reference in the report is NWWG25_N-WISC despite 2026 ',
      'assessment reporting; verify exact run/data revision during curation. Source chapters are cached ',
      'under source_cache/discovery_ices_greenland_cod_2026/. No canonical data or translation added.')),
  'ICES:cod.21.27.1.14' = list(
    candidate_unit_id = 'ices_cod_east_greenland_iceland_offshore', match_status = 'new',
    matched_stock_id = NA_character_, screening_status = 'screened', eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste0('Chapter 16 describes stock-split commercial catch data and age-based ',
      'survey indices, but the assessment model failed to fit observed catches for some ages (up to 92%).'),
    survey_age_evidence = paste0('Age-specific survey indices were derived from Greenland and German ',
      'bottom-trawl surveys using an INLA spatial model; the SAM assessment was not considered robust.'),
    weights_evidence = 'Stock and catch weights-at-age are referenced as data sources; current numerical matrices were not reviewed.',
    maturity_evidence = 'Current maturity-at-age assumptions were not identified in the 2026 chapter.',
    mortality_evidence = 'Current natural mortality assumption for an accepted fit was not identified; no robust age-based fit is used for advice.',
    timing_evidence = 'Survey dates vary across the May-October Greenland and September-November German bottom-trawl surveys; model timing fractions were not identified.',
    output_evidence = paste0('ICES changed this stock to Category 5. The 2026 advice is based on catch in 2022 with ',
      'a 20% precautionary buffer. The 2023-benchmarked SAM model could not fit the observed data and is ',
      'not considered robust for advice; no comparable accepted population or F output was identified.'),
    detailed_source_url = report_url,
    review_date = '2026-11-01',
    decision_reason = paste0('Ineligible for the age-based comparison batch: although age-disaggregated ',
      'source data and an analytical SAM model exist, the model failed to fit observed catches (up to 92% ',
      'for some ages) and is not the robust basis for current advice. The 2026 advice is catch-based.'),
    notes = paste0('Keep as a distinct current unit; this is not an identity rejection. Source recovery may ',
      'still preserve verified current-unit inputs or partial outputs under PROTOCOL.md, but the reported ',
      'assessment does not provide defensible comparable model outputs for the proposed age-based batch. ',
      'NWWG 2026 chapter 16 and the official advice page are cached under ',
      'source_cache/discovery_ices_greenland_cod_2026/. No canonical data or translation added.'))
)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
for (candidate_id in names(reviews)) {
  row <- match(candidate_id, candidates$candidate_id)
  review <- reviews[[candidate_id]]
  if (is.na(row) || sum(candidates$candidate_id == candidate_id) != 1L ||
      candidates$candidate_unit_id[row] != review$candidate_unit_id ||
      candidates$match_status[row] != 'new' ||
      (!is.na(candidates$matched_stock_id[row]) && nzchar(candidates$matched_stock_id[row])))
    stop('Greenland cod identity changed before source screening: ', candidate_id, call. = FALSE)
  already_reviewed <- all(vapply(names(review), function(column)
    identical(as.character(candidates[[column]][row]), as.character(review[[column]])), logical(1L)))
  initial <- candidates$screening_status[row] == 'not_started' &&
    candidates$eligibility[row] == 'unresolved' && candidates$import_status[row] == 'not_started'
  if (!initial && !already_reviewed)
    stop('Conflicting Greenland cod screening state: ', candidate_id, call. = FALSE)
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    for (column in names(review)) candidates[[column]][row] <- review[[column]]
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, candidates[row, , drop = FALSE], candidate_id)
    candidates <- read.csv(register_path, stringsAsFactors = FALSE,
      na.strings = c('', 'NA'), check.names = FALSE)
  }
}

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened three distinct ICES Greenland cod advice units; two are eligible for source curation and one is ineligible for the age-based comparison batch.\n')

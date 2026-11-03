root <- "."
cache <- file.path(root, 'source_cache', 'discovery_noaa_gulf_tilefish_sedar22_2011')
register_path <- file.path(root, 'discovery', 'candidates.csv')
candidate_id <- 'NOAA:10383'
candidate_unit_id <- 'noaa_gulf_golden_tilefish'

sources <- data.frame(
  file = c(
    'noaa_golden_tilefish_resources_2026-10-31.html',
    'sedar22_gulf_tilefish_assessment_2011.pdf',
    'sedar22_gulf_tilefish_ssc_review_2011.pdf',
    'sedar22_dw01_golden_tilefish_age_growth_reproduction_2010.pdf',
    'sedar22_aw01_commercial_tilefish_index_1992-2009.pdf',
    'sefsc01_wp04_recreational_tilefish_length_age_2026.pdf',
    'sefsc01_wp05_commercial_tilefish_length_age_2026.pdf',
    'sefsc01_wp06_golden_tilefish_age_data_1985-2024.pdf'),
  url = c(
    'https://www.fisheries.noaa.gov/species/golden-tilefish/resources',
    'https://sedarweb.org/documents/sedar-22-final-stock-assessment-report-gulf-of-mexico-tilefish/',
    'https://sedarweb.org/documents/report-of-the-gulf-of-mexico-ssc-review-of-the-sedar-22-tilefish-assessment/',
    'https://sedarweb.org/documents/s22dw01-golden-tilefish-lopholatilus-chamaeleonticeps-age-growth-and-reproduction-from-the-northeastern-gulf-of-mexico-19851997-2009/',
    'https://sedarweb.org/documents/s22aw01-united-states-commercial-longline-vessel-standardized-catch-rates-of-golden-and-blueline-tilefish-in-the-gulf-of-mexico-1992-2009-revised/',
    'https://sedarweb.org/documents/sefsc01-wp-04-gulf-of-america-tilefish-lopholatilus-chamaeleonticeps-caulolatilus-microps-and-caulolatilus-chrysops-length-and-age-compositions-from-the-u-s-recreational-fishery/',
    'https://sedarweb.org/documents/sefsc01-wp-05-gulf-of-america-tilefish-complex-length-and-age-compositions-for-the-commercial-handline-and-longline-fisheries/',
    'https://sedarweb.org/documents/sefsc01-wp-06-a-review-of-golden-tilefish-lopholatilus-chamaeleonticeps-length-and-age-data-collected-from-the-gulf-of-america-from-1985-to-2024/'),
  revision = c(
    'NOAA golden tilefish resources page retrieved 2026-10-31; identifies 2011 as latest Gulf stock assessment',
    'SEDAR 22 final stock assessment report; July 2011; data through 2009',
    'Gulf SSC review of SEDAR 22 Tilefish; May 17-19, 2011',
    'SEDAR 22 DW-01; March 2010; age, growth and reproduction',
    'SEDAR 22 AW-01 revised; commercial longline index series 1992-2009',
    'SEFSC01-WP-04; July 2026; preliminary recreational length and age compositions',
    'SEFSC01-WP-05; 2026 data-triage working paper on commercial compositions',
    'SEFSC01-WP-06; 2026 data-triage working paper reviewing age data 1985-2024'),
  bytes = c(232062, 13676098, 71267, 2200978, 1570784, 1307577, 4286342, 1579606),
  sha256 = c(
    'a38bcf83be1bc68eeeffae07876a8ee21ccb3b09a8b2b46174acb8bea2187182',
    '08c1929d0cdbb332149d331cfe720285ee8cac1dc6372f8a278b9425a6c99694',
    'dcbb3e370f987b53225705aaefa17bd085040b13c23ce02f2ec9a4784a516b69',
    '767c37223296809383d2dbe8bc050daa846bf5a46c69f4edea0e88cc7b31d9c2',
    'bad021f8e71212cbade2d015b334b8b8e5747af9540fb08327a28d68898c1d52',
    '7545dd323866626bfe9de639dd3cdb37744e61e3ad52c50c4bd5fb77a6e3d2ce',
    '4d2b6907ab6b9714af594228636bc0e78b11ac2e45612b35cf0664fae289ab7e',
    '398b2b32462b1754d26718483fdb2c6e511c846aac384b7a6fec108bcecd75fd'),
  stringsAsFactors = FALSE)
sources$retrieved_on <- '2026-10-31'
sources <- sources[, c('file', 'url', 'revision', 'retrieved_on', 'bytes', 'sha256')]
manifest_path <- file.path(cache, 'sources.csv')
if (!dir.exists(cache) || any(!file.exists(file.path(cache, sources$file))))
  stop('Cache the listed official tilefish sources before screening.', call. = FALSE)

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = if (.Platform$OS.type == 'windows') '\\' else '/',
    mustWork = TRUE)
  if (.Platform$OS.type == 'windows') {
    output <- system2('certutil.exe', c('-hashfile', path, 'SHA256'), stdout = TRUE)
    hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  } else {
    output <- system2('sha256sum', shQuote(path), stdout = TRUE)
    hashes <- sub('[[:space:]].*$', '', output[1L])
  }
  if (length(hashes) != 1L)
    stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

paths <- file.path(cache, sources$file)
if (!identical(as.numeric(file.info(paths)$size), as.numeric(sources$bytes)) ||
    !identical(unname(vapply(paths, sha256_file, character(1L))), sources$sha256))
  stop('Cached tilefish sources differ from the reviewed files.', call. = FALSE)
if (!file.exists(manifest_path)) write.csv(sources, manifest_path, row.names = FALSE)
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
if (!identical(names(manifest), names(sources)) || nrow(manifest) != nrow(sources) ||
    !identical(manifest$file, sources$file) || !identical(manifest$url, sources$url) ||
    !identical(manifest$revision, sources$revision) ||
    !identical(manifest$retrieved_on, sources$retrieved_on) ||
    !identical(as.numeric(manifest$bytes), as.numeric(sources$bytes)) ||
    !identical(tolower(manifest$sha256), sources$sha256))
  stop('The tilefish source manifest differs from the reviewed files.', call. = FALSE)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
smart_row <- stocksmart[stocksmart$stock_id == 10383, , drop = FALSE]
if (nrow(smart_row) != 1L || smart_row$assessment_id != 3057L ||
    smart_row$assessment_year != 2011L || smart_row$last_data_year != 2009L ||
    smart_row$assessment_model != 'SS3' ||
    smart_row$review_result != 'Partial acceptance - Status determinations only')
  stop('NOAA Stock SMART Gulf tilefish assessment metadata changed.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || candidates$official_stock_id[row] != '10383' ||
    candidates$scientific_name[row] != 'Lopholatilus chamaeleonticeps' ||
    candidates$stock_name[row] != 'Tilefish - Gulf of Mexico' ||
    candidates$assessment_area[row] != 'Gulf of Mexico' ||
    candidates$inventory_assessment_year[row] != '2011')
  stop('NOAA Gulf tilefish inventory identity changed.', call. = FALSE)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
if (any(stocks$scientific_name == 'Lopholatilus chamaeleonticeps', na.rm = TRUE) ||
    any(assessments$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(inputs$assessment_id == candidate_unit_id, na.rm = TRUE) ||
    any(outputs$assessment_id == candidate_unit_id, na.rm = TRUE))
  stop('A canonical Gulf golden tilefish record exists; recheck its unit identity.',
    call. = FALSE)

review <- list(
  candidate_unit_id = candidate_unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'SEDAR 22 used landings, length compositions, and age compositions conditional',
    'on 2-cm length bin. Appendix B reports year, length bin, sample size and',
    'counts at ages 2-30+ by fishery/survey and region; the assessment age data',
    'are not direct catch numbers-at-age. Catch-at-age can be reconstructed from',
    'these age-at-length counts, matching length compositions and removals, with',
    'the reconstruction documented as approximate.'),
  survey_age_evidence = paste(
    'The model fits commercial longline and NMFS bottom-longline survey indices',
    'for east and west Gulf regions. NMFS survey age compositions are provided',
    'conditional on length in Appendix B, so age-specific survey values can be',
    'reconstructed by combining the index with the matched length-age samples;',
    'the report does not supply a direct age-specific abundance index.'),
  weights_evidence = paste(
    'The assessment fixed its weight-length and region/gender growth inputs from',
    'the SEDAR 22 Data Workshop life-history sources. DW-01 reports observed',
    'size-at-age and growth information; a model-compatible weight-at-age surface',
    'can be reproduced from the documented growth and weight-length inputs.'),
  maturity_evidence = paste(
    'The model fixed the maturity schedule from the Data Workshop. The assessment',
    'report gives a female age-maturity logistic with 50% maturity at age 2 and',
    'uses gonad weight for its spawning-biomass output; preserve this biological',
    'definition rather than treating it as ordinary mature somatic biomass.'),
  mortality_evidence = paste(
    'The central SS run fixes the reference M parameter at 0.137 at age 4 and',
    'uses region- and gender-specific Lorenzen curves derived from growth.',
    'Alternative M assumptions were explored in sensitivity runs.'),
  timing_evidence = paste(
    'The fitted indices are annual commercial and NMFS bottom-longline series.',
    'The reviewed assessment sources do not specify a fractional within-year',
    'observation time for the indices.'),
  output_evidence = paste(
    'SEDAR 22 Table 3.7 reports annual east, west and Gulf total biomass and',
    'gonad-weight spawning biomass, age-0 recruitment and fishing mortality for',
    'the central SS run. These are aggregate model outputs; numeric annual',
    'N-at-age and F-at-age surfaces were not located in the reviewed report.'),
  detailed_source_url = paste(c(sources$url[1:5],
    'https://sedarweb.org/assessments/sedar-22/',
    'https://sedarweb.org/documents/sedar-22-final-document-list/'),
    collapse = '; '),
  review_date = '2026-10-31',
  decision_reason = paste(
    'Eligible for source curation: the latest detailed official assessment has',
    'age-composition counts by year and length bin, matched length compositions,',
    'annual removals, biology and aggregate population/mortality outputs, so',
    'age-specific inputs are reconstructable with an explicit length-age',
    'expansion. Keep the severe advice limitation prominent: NOAA Stock SMART',
    'records only partial acceptance for status determinations; the Gulf SSC',
    'said the model did not capture stock dynamics well enough for useful advice,',
    'and the OFL/ABC advice was based on historical landings. Age-based model',
    'outputs are therefore a cautious comparison reference, not an endorsed',
    'quantitative advice series.'),
  notes = paste(
    'NOAA identifies Gulf, South Atlantic and Mid-Atlantic golden tilefish as',
    'separate management units; no canonical Gulf tilefish record exists.',
    'Stock SMART assessment 3057 is the latest run used for Gulf status, with',
    'data through 2009 and review result Partial acceptance - Status',
    'determinations only. NOAA and SEDAR list 2026 SEFSC01 work as data triage',
    'and preliminary composition documentation, not a completed replacement',
    'assessment. Do not mix those 2026 data with SEDAR 22 inputs. Discovery',
    'screen only; no canonical values were imported.'))

already_reviewed <- all(vapply(names(review), function(column)
  identical(as.character(candidates[[column]][row]), as.character(review[[column]])),
  logical(1L)))
pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!(pristine || already_reviewed))
  stop('NOAA Gulf tilefish inventory row has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  replace_candidate_register_row(register_path, row,
    candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened NOAA Gulf golden tilefish; age-based inputs are reconstructable, with major official-advice limitations.\n')

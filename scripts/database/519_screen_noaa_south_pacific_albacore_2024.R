root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_south_pacific_albacore_2024')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  toupper(hashes)
}

manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
expected <- c(
  'south_pacific_albacore_assessment_2024_rev3.pdf',
  'south_pacific_albacore_data_inputs_2024.pdf',
  'south_pacific_albacore_longline_length_data_2024.pdf',
  'alb.frq', 'alb.age_length', 'alb.ini', 'mfcl_09.par',
  'taf_input_length_comps.csv', 'taf_input_otoliths.csv', 'taf_input_cpue.csv',
  'taf_output_biology.csv', 'taf_output_biomass.csv', 'taf_output_natage.csv',
  'taf_output_f_annual.csv', 'taf_output_summary.csv'
)
for (file in expected) {
  i <- match(file, manifest$file)
  path <- file.path(cache_dir, file)
  if (!file.exists(path) || is.na(i) || !grepl('^[[:xdigit:]]{64}$', manifest$sha256[i]) ||
      sha256_file(path) != toupper(manifest$sha256[i])) {
    stop('A pinned South Pacific albacore source is missing or differs from its manifest: ',
      file, call. = FALSE)
  }
}
repo_revision <- 'e9640087a9831dece824062a338c21bf81414044'
repo_urls <- manifest$url[grepl(
  'raw.githubusercontent.com/PacificCommunity/ofp-sam-alb-2024-diagnostic',
  manifest$url, fixed = TRUE)]
if (length(repo_urls) == 0L || !all(grepl(repo_revision, repo_urls, fixed = TRUE))) {
  stop('The public diagnostic-model files are not pinned to the reviewed repository revision.',
    call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11688' &
  as.integer(stocksmart$assessment_year) == 2024, , drop = FALSE]
if (nrow(stocksmart) != 1L || stocksmart$last_data_year != 2022L ||
    stocksmart$science_center != 'PIFSC' ||
    stocksmart$assessment_id != 13990L) {
  stop('The Stock SMART snapshot no longer identifies the 2024 South Pacific albacore run.',
    call. = FALSE)
}

length_comps <- read.csv(file.path(cache_dir, 'taf_input_length_comps.csv'))
otoliths <- read.csv(file.path(cache_dir, 'taf_input_otoliths.csv'))
cpue <- read.csv(file.path(cache_dir, 'taf_input_cpue.csv'))
fisheries <- read.csv(file.path(cache_dir, 'taf_input_fisheries.csv'))
biology <- read.csv(file.path(cache_dir, 'taf_output_biology.csv'))
natage <- read.csv(file.path(cache_dir, 'taf_output_natage.csv'))
f_annual <- read.csv(file.path(cache_dir, 'taf_output_f_annual.csv'))
if (nrow(otoliths) != 654L || !identical(range(otoliths$age), c(1L, 10L)) ||
    !identical(range(length_comps$year), c(1965L, 2022L)) ||
    length(unique(length_comps$fishery)) != 17L ||
    length(unique(cpue$fishery)) != 3L || nrow(fisheries) != 20L ||
    !identical(range(natage$year), c(1954L, 2022L)) ||
    !identical(range(natage$age), c(1L, 12L)) ||
    length(unique(natage$area)) != 2L ||
    !identical(range(f_annual$year), c(1954L, 2022L)) ||
    !all(c('weight', 'maturity', 'natmort') %in% names(biology))) {
  stop('The pinned TAF input/output coverage no longer matches the reviewed assessment.',
    call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate_id <- 'NOAA:11688'
unit_id <- 'wcpfc_south_pacific_albacore'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$scientific_name[row] != 'Thunnus alalunga' ||
    register$inventory_assessment_year[row] != 2024L ||
    any(stocks$scientific_name == 'Thunnus alalunga' &
      grepl('South Pacific', paste(stocks$area, stocks$region), ignore.case = TRUE),
      na.rm = TRUE)) {
  stop('South Pacific albacore candidate identity or canonical matching changed.',
    call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE)) {
  stop('South Pacific albacore candidate-unit key conflicts with another candidate.',
    call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('No native catch-at-age likelihood is used. The pinned MFCL inputs contain fishery catches and catch-reweighted length compositions, while the official CAAL input contains 654 otolith age-length observations. These source quantities support a downstream, approximate catch-numbers-at-age reconstruction; it must be labelled reconstructed and must not be confused with the MFCL likelihood input or fitted population output.'),
  survey_age_evidence = paste('The diagnostic input contains three fishery CPUE index series, not an age-specific survey index. The aggregate indices can be retained as such; age-specific abundance would require a separate reconstruction and is not supplied.'),
  weights_evidence = paste('The pinned model inputs include the fork-length/weight relationship, and the TAF output provides model-derived weights-at-age for ages 1-12. Preserve the growth-derived output separately from any directly observed biological input.'),
  maturity_evidence = paste('The assessment uses a reproductive-potential ogive specified at length from the product of sex ratio and maturity-at-length, then converted internally to an age surface using estimated growth. The pinned model configuration and TAF output expose the age-specific surface; retain its spawning-biomass purpose and do not relabel it as a simple maturity proportion without checking the model definition.'),
  mortality_evidence = paste('The diagnostic case specifies Lorenzen age-dependent natural mortality scaled to an average M of 0.36 year-1 over mature ages 4-12+, with an assumed maximum age of 15. The assessment ensemble varies average M; keep the diagnostic assumption distinct from ensemble uncertainty.'),
  timing_evidence = paste('The model has quarterly time steps and three aggregate fishery CPUE index series with source season codes. The public model files support resolving their seasonal placement; there is no age-specific survey timing to report. Any tinyAM fractional-year timing must be documented from those codes and the source calendar.'),
  output_evidence = paste('The public TAF export provides diagnostic-model annual recruitment, biomass/SSB, numbers-at-age (ages 1-12, two areas) and fishing mortality-at-age through 2022. This is the single diagnostic run, not the 100-model ensemble used for management advice.'),
  detailed_source_url = paste(
    'https://meetings.wcpfc.int/node/23119',
    'https://meetings.wcpfc.int/node/23128',
    'https://meetings.wcpfc.int/node/23127',
    'https://github.com/PacificCommunity/ofp-sam-alb-2024-diagnostic/tree/e9640087a9831dece824062a338c21bf81414044',
    'https://noaa-edab.github.io/stocksmart/news/index.html',
    sep = '; '),
  review_date = '2026-11-02',
  decision_reason = paste('Eligible for source curation because the exact public diagnostic-model input files, age-length observations, and age-specific outputs are available. The assessment does not fit catch-at-age directly; eligibility rests on a documented approximate reconstruction from source catches, catch-reweighted length compositions, and conditional age-at-length data. This does not imply that the MFCL and tinyAM likelihoods are equivalent.'),
  notes = paste('NOAA Stock SMART ID 11688 refers to the South Pacific albacore stock assessed jointly across the WCPFC-CA and IATTC EPO by SPC/IATTC; it is distinct from the North Pacific albacore candidate and no matching canonical South Pacific stock row exists. The latest full assessment is the 2024 diagnostic model through 2022. The public SPC model repository is pinned at e9640087a9831dece824062a338c21bf81414044; its inputs and TAF outputs, along with WCPFC assessment and data-input reports, are cached with checksums in source_cache/discovery_noaa_south_pacific_albacore_2024/sources.csv. No canonical database records were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'eligible' &&
  grepl('approximate catch-numbers-at-age reconstruction',
    register$catch_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) {
  stop('South Pacific albacore candidate has an unexpected prior review state.',
    call. = FALSE)
}
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE],
      candidate_id)
  }
}
cat('Screened NOAA 11688 / WCPFC South Pacific albacore as eligible for source curation via an explicit, approximate age reconstruction.\n')



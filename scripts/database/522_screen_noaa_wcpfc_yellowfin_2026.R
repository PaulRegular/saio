root <- "."
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_wcpo_yellowfin_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

expected <- c(
  'WCPFC-SC22-2026-SA-WP05_Rev01_YFT_2026.pdf',
  'WCPFC-SC22-2026-SA-IP03_Rev01_BET_YFT_inputs.pdf',
  'SPC_README.md', 'TAF_data.R', 'MFCL_12.par', 'MFCL_yft.age_length',
  'MFCL_yft.frq', 'MFCL_yft.ini', 'MFCL_yft.reg_scaling', 'MFCL_yft.tag',
  'TAF_data_cpue.csv', 'TAF_data_fisheries.csv', 'TAF_data_length_comps.csv',
  'TAF_data_otoliths.csv', 'TAF_data_reg_scale.csv', 'TAF_data_tag_recaptures.csv',
  'TAF_data_tag_releases.csv', 'TAF_output_batage.csv', 'TAF_output_biology.csv',
  'TAF_output_biomass.csv', 'TAF_output_catch.csv', 'TAF_output_cpue.csv',
  'TAF_output_f_annual.csv', 'TAF_output_natage.csv', 'TAF_output_summary.csv'
)
for (file in expected) {
  i <- match(file, manifest$file)
  path <- file.path(cache_dir, file)
  if (!file.exists(path) || is.na(i) || !grepl('^[[:xdigit:]]{64}$', manifest$sha256[i]) ||
      sha256_file(path) != tolower(manifest$sha256[i]) ||
      file.info(path)$size != as.numeric(manifest$bytes[i])) {
    stop('A pinned WCPO yellowfin source is missing or differs from its manifest: ',
      file, call. = FALSE)
  }
}

repo_revision <- 'b00a02f3537ef54520b219488f899188ea6eff3f'
repo_urls <- manifest$url[grepl(
  paste0('raw.githubusercontent.com/PacificCommunity/ofp-sam-yft-2026-diagnostic/',
    repo_revision, '/'), manifest$url, fixed = TRUE)]
if (length(repo_urls) < 20L) {
  stop('The SPC diagnostic files are not pinned to the reviewed repository revision.',
    call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11694', , drop = FALSE]
latest <- stocksmart[which.max(as.integer(stocksmart$assessment_year)), , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_id != 13365L ||
    latest$assessment_year != 2023L || latest$last_data_year != 2021L ||
    latest$science_center != 'PIFSC' || latest$review_result != 'Full acceptance') {
  stop('The Stock SMART snapshot no longer identifies NOAA:11694 as reviewed.', call. = FALSE)
}

otoliths <- read.csv(file.path(cache_dir, 'TAF_data_otoliths.csv'))
length_comps <- read.csv(file.path(cache_dir, 'TAF_data_length_comps.csv'))
cpue <- read.csv(file.path(cache_dir, 'TAF_data_cpue.csv'))
natage <- read.csv(file.path(cache_dir, 'TAF_output_natage.csv'))
f_annual <- read.csv(file.path(cache_dir, 'TAF_output_f_annual.csv'))
biology <- read.csv(file.path(cache_dir, 'TAF_output_biology.csv'))
summary <- read.csv(file.path(cache_dir, 'TAF_output_summary.csv'))
if (nrow(otoliths) != 1873L || !identical(range(otoliths$year), c(2006L, 2024L)) ||
    length(unique(otoliths$year)) != 17L || !identical(range(otoliths$age), c(1L, 40L)) ||
    !identical(range(otoliths$season), c(1L, 4L)) || length(unique(otoliths$area)) != 5L ||
    nrow(length_comps) != 297920L || !identical(range(length_comps$year), c(1956L, 2024L)) ||
    length(unique(length_comps$fishery)) != 36L || nrow(cpue) != 1452L ||
    !identical(range(cpue$year), c(1952L, 2024L)) || length(unique(cpue$fishery)) != 5L ||
    length(unique(cpue$season)) != 4L || nrow(natage) != 58400L ||
    !identical(range(natage$year), c(1952L, 2024L)) ||
    !identical(range(natage$age), c(1L, 40L)) || length(unique(natage$area)) != 5L ||
    length(unique(natage$season)) != 4L || nrow(f_annual) != 17520L ||
    !identical(range(f_annual$year), c(1952L, 2024L)) ||
    !identical(range(f_annual$age), c(1L, 40L)) ||
    !all(c('age', 'length', 'weight', 'maturity', 'natmort') %in% names(biology)) ||
    !identical(range(biology$age), c(1L, 40L)) || nrow(summary) != 73L ||
    !identical(range(summary$year), c(1952L, 2024L))) {
  stop('The pinned TAF input/output coverage differs from the reviewed assessment.',
    call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_id <- 'NOAA:11694'
unit_id <- 'wcpfc_wcpo_yellowfin'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$scientific_name[row] != 'Thunnus albacares' ||
    any(stocks$scientific_name == 'Thunnus albacares', na.rm = TRUE)) {
  stop('WCPO yellowfin candidate identity or canonical matching changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE)) {
  stop('WCPO yellowfin candidate-unit key conflicts with another candidate.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('No direct catch-at-age likelihood is used. The pinned 2026 MFCL files and TAF inputs contain catch and length compositions, plus 1,873 conditional age-at-length observations sampled in 17 years from 2006-2024 across five areas and four quarters. The age samples inform growth rather than marginal catch-at-age. Combining them with length compositions can support approximate age-composition reconstruction only where age-length keys overlap; pooling across unsampled years, fleets or areas must be explicit.'),
  survey_age_evidence = paste('Five regional longline CPUE series are aggregate relative-abundance indices at quarterly resolution from 1952-2024, not age-specific indices. The public inputs also include 1,873 otolith age-length observations for growth; they do not provide a direct age-specific abundance index.'),
  weights_evidence = paste('The assessment uses length compositions and internally estimated growth; fitted TAF biology provides model-derived weight-at-age for ages 1-40. The public files do not establish an independent observed weight-at-age likelihood input.'),
  maturity_evidence = paste('The fitted TAF biology table contains maturity-at-age for ages 1-40. This is an internally configured/model-derived biological surface, not a separate annual maturity observation series.'),
  mortality_evidence = paste('The fitted biology output includes natural mortality at ages 1-40; the report describes an internally estimated Lorenzen age-dependent form. This is a fitted surface, not a fixed input schedule.'),
  timing_evidence = paste('The assessment uses quarterly time steps and age classes; CPUE and population outputs are tabulated by quarter. Preserve quarter-specific timing in the source representation; annual fractional-year timing in tinyAM would be an approximation.'),
  output_evidence = paste('Pinned TAF outputs provide numbers-at-age by year, quarter and five areas (1952-2024; ages 1-40), annual fishing mortality-at-age, biology at age, and annual summaries including recruitment, total biomass, spawning biomass, depletion and F. These are outputs from a diagnostic shortcut fit copied from the archived full-model results, not posterior or uncertainty-grid summaries.'),
  detailed_source_url = paste('https://meetings.wcpfc.int/node/32678', 'https://meetings.wcpfc.int/file/22577/download', 'https://meetings.wcpfc.int/file/21826/download', 'https://github.com/PacificCommunity/ofp-sam-yft-2026-diagnostic/tree/b00a02f3537ef54520b219488f899188ea6eff3f', 'https://www.wcpfc.int/node/244', 'https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=11694', sep = '; '),
  review_date = '2026-11-02',
  decision_reason = paste('Eligible for source curation from the latest detailed production assessment located, the 2026 WCPFC report and pinned SPC TAF/MFCL files. The report states that SC22 did not review this assessment for management advice and deferred review to SC23; therefore the latest accepted advice basis remains NOAA Stock SMART assessment 13365 (2023, data through 2021). Public age-at-length and length-composition data support an approximate age-composition reconstruction where sampled strata overlap, but that reconstruction is not the MFCL likelihood.'),
  notes = paste('NOAA Stock SMART ID 11694 maps to the WCPFC Western and Central Pacific yellowfin unit and is distinct from Eastern Pacific and Indian Ocean yellowfin. No matching canonical Thunnus albacares stock record exists. The 2026 SPC diagnostic repository is pinned to commit b00a02f3537ef54520b219488f899188ea6eff3f; report, supporting input paper, MFCL and TAF inputs/outputs are cached with hashes in source_cache/discovery_noaa_wcpo_yellowfin_2026/sources.csv. The 2026 run is detailed but awaiting SC23 advice review; the 2023 run remains the latest accepted advice basis. This is a discovery screen only; no canonical assessment data were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'eligible' &&
  grepl('1,873 conditional age-at-length observations',
    register$catch_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) {
  stop('WCPO yellowfin candidate has an unexpected prior review state.', call. = FALSE)
}
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE],
      candidate_id)
  }
}
cat('Screened NOAA 11694 as eligible for source curation; 2026 advice review is deferred to SC23.\n')

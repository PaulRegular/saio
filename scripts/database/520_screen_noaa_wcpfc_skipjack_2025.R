root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_wcpfc_skipjack_2025')

sha256_file <- function(path) {
  output <- system2('certutil.exe', c('-hashfile', shQuote(normalizePath(path)), 'SHA256'),
    stdout = TRUE)
  hashes <- trimws(grep('^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$', output, value = TRUE))
  if (length(hashes) != 1L) stop('Could not calculate SHA-256 for ', path, call. = FALSE)
  tolower(hashes)
}

manifest <- read.csv(file.path(cache_dir, 'sources.csv'), stringsAsFactors = FALSE)
expected <- c(
  'wcpfc_sc21_skipjack_assessment_2025_rev3.pdf',
  'wcpfc_sc21_skipjack_background_inputs_2025_rev1.pdf',
  'wcpfc_sc21_summary_report_2025.pdf',
  'TAF__data__cpue.csv', 'TAF__data__fisheries.csv',
  'TAF__data__length_comps.csv', 'TAF__data__tag_releases.csv',
  'TAF__data__tag_recaptures.csv', 'TAF__output__biology.csv',
  'TAF__output__biomass.csv', 'TAF__output__cpue.csv',
  'TAF__output__f_annual.csv', 'TAF__output__natage.csv',
  'TAF__output__summary.csv'
)
for (file in expected) {
  i <- match(file, manifest$file)
  path <- file.path(cache_dir, file)
  if (!file.exists(path) || is.na(i) || !grepl('^[[:xdigit:]]{64}$', manifest$sha256[i]) ||
      sha256_file(path) != tolower(manifest$sha256[i])) {
    stop('A pinned WCPO skipjack source is missing or differs from its manifest: ',
      file, call. = FALSE)
  }
}

repo_revision <- 'f33de3a9d6f3acb02a0717340c1cc325f89f2eb6'
repo_urls <- manifest$url[grepl(
  paste0('raw.githubusercontent.com/PacificCommunity/ofp-sam-skj-2025-diagnostic/',
    repo_revision, '/'), manifest$url, fixed = TRUE)]
if (length(repo_urls) < 11L) {
  stop('The TAF diagnostic files are not pinned to the reviewed repository revision.',
    call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11691' &
  as.integer(stocksmart$assessment_year) == 2022, , drop = FALSE]
if (nrow(stocksmart) != 1L || stocksmart$last_data_year != 2021L ||
    stocksmart$science_center != 'PIFSC' || stocksmart$assessment_id != 13027L) {
  stop('The Stock SMART snapshot no longer identifies NOAA:11691 as reviewed.',
    call. = FALSE)
}

length_comps <- read.csv(file.path(cache_dir, 'TAF__data__length_comps.csv'))
cpue <- read.csv(file.path(cache_dir, 'TAF__data__cpue.csv'))
natage <- read.csv(file.path(cache_dir, 'TAF__output__natage.csv'))
f_annual <- read.csv(file.path(cache_dir, 'TAF__output__f_annual.csv'))
biology <- read.csv(file.path(cache_dir, 'TAF__output__biology.csv'))
summary <- read.csv(file.path(cache_dir, 'TAF__output__summary.csv'))
cpue_anomaly <- cpue[cpue$year == 36, , drop = FALSE]
if (nrow(length_comps) != 132894L ||
    !identical(range(length_comps$year), c(1972L, 2024L)) ||
    length(unique(length_comps$fishery)) != 42L ||
    nrow(cpue) != 1337L || length(unique(cpue$fishery)) != 10L ||
    nrow(cpue_anomaly) != 1L || !isTRUE(all.equal(cpue_anomaly$season, 14.3333333333333)) ||
    !identical(range(natage$year), c(1972L, 2024L)) ||
    !identical(range(natage$age), c(1L, 16L)) ||
    length(unique(natage$area)) != 8L || length(unique(natage$season)) != 4L ||
    !identical(range(f_annual$year), c(1972L, 2024L)) ||
    !identical(range(f_annual$age), c(1L, 16L)) ||
    !setequal(unique(f_annual$area), c(as.character(1:8), 'all')) ||
    !identical(range(biology$age), c(1L, 16L)) ||
    !identical(range(summary$year), c(1972L, 2024L))) {
  stop('The pinned TAF input/output coverage differs from the reviewed assessment.',
    call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
candidate_id <- 'NOAA:11691'
unit_id <- 'wcpfc_wcpo_skipjack'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$scientific_name[row] != 'Katsuwonus pelamis' ||
    any(stocks$scientific_name == 'Katsuwonus pelamis', na.rm = TRUE)) {
  stop('WCPO skipjack candidate identity or canonical matching changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE)) {
  stop('WCPO skipjack candidate-unit key conflicts with another candidate.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste('The accepted 2025 MULTIFAN-CL assessment is catch-conditioned and uses fishery catches plus length-frequency observations, not observed catch-at-age. The pinned TAF input archive contains 132,894 length-composition rows in 2-cm fork-length bins for 1972-2024, but no age compositions or age-length key used as an observation likelihood. Length-only compositions do not support a verified catch-at-age reconstruction.'),
  survey_age_evidence = paste('The assessment uses 10 fishery CPUE index series as aggregate relative-abundance likelihoods; none is an age-specific abundance index. The pinned TAF CPUE input also contains one anomalous row with year 36 and season 14.333, which needs clarification before those inputs are reused.'),
  weights_evidence = paste('The model derives weights-at-age from internally estimated length-at-age and a specified weight-length relationship. The public TAF biology surface is a model-derived output, not an observed weight-at-age input.'),
  maturity_evidence = paste('Age-specific maturity and reproductive potential are computed internally from a maturity-at-length ogive, growth, and a body-size fecundity adjustment. The public age-specific biology surface is derived by the model, not an observed maturity-at-age input.'),
  mortality_evidence = paste('Natural mortality-at-age follows an inverse-length Lorenzen pattern with its asymptotic scale estimated internally and assumed invariant across time and region. The ensemble varies natural mortality and other structural assumptions.'),
  timing_evidence = paste('The population model is quarterly from 1972 through 2024. The 10 CPUE index fisheries are aggregate relative-abundance series; no age-specific survey timing can be mapped into tinyAM.'),
  output_evidence = paste('The pinned diagnostic TAF outputs provide annual recruitment, biomass and spawning biomass, N-at-age for ages 1-16 across eight regions, and annual F-at-age through 2024. These are fitted outputs; they do not supply the missing age-disaggregated observation inputs.'),
  detailed_source_url = paste(
    'https://meetings.wcpfc.int/node/26679',
    'https://meetings.wcpfc.int/system/files/2025-08/SC21-SA-IP-03_SKJ_background_paper_rev1-Teears_et_al.pdf',
    'https://meetings.wcpfc.int/file/19534/download',
    'https://github.com/PacificCommunity/ofp-sam-skj-2025-diagnostic/tree/f33de3a9d6f3acb02a0717340c1cc325f89f2eb6',
    'https://github.com/PacificCommunity/ofp-sam-skj-2025-ensemble',
    sep = '; '),
  review_date = '2026-11-02',
  decision_reason = paste('The 2025 assessment is the latest accepted production run and has public fitted outputs, but its observation likelihoods are catch, length frequency, aggregate CPUE, and tagging. It does not use observed age compositions or an age-specific abundance index. The assessment is internally age-structured, but that does not provide tinyAM-ready age-disaggregated observations; screen this unit as ineligible.'),
  notes = paste('NOAA Stock SMART ID 11691 identifies the Western and Central Pacific skipjack management unit assessed by SPC for WCPFC. The NOAA inventory snapshot still lists the 2022 assessment through 2021; WCPFC accepted the 2025 assessment through 2024 as the latest run. Its 2025 diagnostic TAF archive is pinned to commit f33de3a9d6f3acb02a0717340c1cc325f89f2eb6 and cached with the official assessment report, background data-input report, acceptance record, and SHA-256 manifest in source_cache/discovery_noaa_wcpfc_skipjack_2025. The raw TAF CPUE file has one anomalous year/season row noted above. No canonical stock or numerical assessment records were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'ineligible' &&
  grepl('10 fishery CPUE index series', register$survey_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) {
  stop('WCPO skipjack candidate has an unexpected prior review state.', call. = FALSE)
}
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE],
      candidate_id)
  }
}
cat('Screened NOAA 11691 against the accepted 2025 WCPO skipjack assessment; age-disaggregated inputs are not used.\n')

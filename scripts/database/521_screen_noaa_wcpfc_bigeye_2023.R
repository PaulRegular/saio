root <- "."
cache_dir <- file.path(root, 'source_cache', 'discovery_noaa_wcpfc_bigeye_2026')
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
  'SC19-SA-WP-05_BET_2023_Rev02.pdf', 'SC19_Outcomes_2023.pdf',
  'BETDiagnosticCompFits_2023.zip', 'WCPFC-BMW02-2026-IP03_BET_Rev02_2026-10-01.pdf',
  'WCPFC-SC22-2026-SA-IP03_Rev01_2026-08-14.pdf',
  'WCPFC-SC22-2026-SA-IP08_2026-07-14.pdf',
  'WCPFC23-2026-10_SC22_Outcomes_2026-10-29.pdf', 'WCPFC_SC22_results_2026.html',
  'SPC__README.md', 'SPC__TAF__data.R', 'SPC_MFCL__11.par',
  'SPC_MFCL__bet.age_length', 'SPC_MFCL__bet.frq', 'SPC_MFCL__bet.ini',
  'SPC_MFCL__bet.tag', 'TAF__data__cpue.csv', 'TAF__data__fisheries.csv',
  'TAF__data__length_comps.csv', 'TAF__data__otoliths.csv',
  'TAF__data__tag_recaptures.csv', 'TAF__data__tag_releases.csv',
  'TAF__data__weight_comps.csv', 'TAF__output__biology.csv',
  'TAF__output__biomass.csv', 'TAF__output__catch.csv', 'TAF__output__cpue.csv',
  'TAF__output__f_annual.csv', 'TAF__output__natage.csv', 'TAF__output__summary.csv'
)
for (file in expected) {
  i <- match(file, manifest$file)
  path <- file.path(cache_dir, file)
  if (!file.exists(path) || is.na(i) || !grepl('^[[:xdigit:]]{64}$', manifest$sha256[i]) ||
      sha256_file(path) != tolower(manifest$sha256[i]) ||
      file.info(path)$size != as.numeric(manifest$bytes[i])) {
    stop('A pinned WCPO bigeye source is missing or differs from its manifest: ',
      file, call. = FALSE)
  }
}

repo_revision <- '81fc412ad1f36416f78f84ef6bd2d5dff68d14c8'
repo_urls <- manifest$url[grepl(
  paste0('raw.githubusercontent.com/PacificCommunity/ofp-sam-bet-2023-diagnostic/',
    repo_revision, '/'), manifest$url, fixed = TRUE)]
if (length(repo_urls) != 21L) {
  stop('The SPC diagnostic files are not pinned to the reviewed repository revision.',
    call. = FALSE)
}

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11684', , drop = FALSE]
latest <- stocksmart[which.max(as.integer(stocksmart$assessment_year)), , drop = FALSE]
if (nrow(latest) != 1L || latest$assessment_id != 13363L ||
    latest$assessment_year != 2023L || latest$last_data_year != 2021L ||
    latest$science_center != 'SWFSC / PIFSC') {
  stop('The Stock SMART snapshot no longer identifies NOAA:11684 as reviewed.',
    call. = FALSE)
}

otoliths <- read.csv(file.path(cache_dir, 'TAF__data__otoliths.csv'))
length_comps <- read.csv(file.path(cache_dir, 'TAF__data__length_comps.csv'))
weight_comps <- read.csv(file.path(cache_dir, 'TAF__data__weight_comps.csv'))
cpue <- read.csv(file.path(cache_dir, 'TAF__data__cpue.csv'))
natage <- read.csv(file.path(cache_dir, 'TAF__output__natage.csv'))
f_annual <- read.csv(file.path(cache_dir, 'TAF__output__f_annual.csv'))
biology <- read.csv(file.path(cache_dir, 'TAF__output__biology.csv'))
summary <- read.csv(file.path(cache_dir, 'TAF__output__summary.csv'))
if (nrow(otoliths) != 1010L || !identical(range(otoliths$year), c(1990L, 2018L)) ||
    length(unique(otoliths$year)) != 14L || !identical(range(otoliths$age), c(1L, 40L)) ||
    !identical(range(otoliths$season), c(1L, 4L)) || length(unique(otoliths$area)) != 8L ||
    nrow(length_comps) != 96235L || !identical(range(length_comps$year), c(1965L, 2021L)) ||
    length(unique(length_comps$fishery)) != 18L ||
    nrow(weight_comps) != 707200L || !identical(range(weight_comps$year), c(1952L, 2021L)) ||
    length(unique(weight_comps$fishery)) != 24L || nrow(cpue) != 2520L ||
    !identical(range(cpue$year), c(1952L, 2021L)) || length(unique(cpue$fishery)) != 9L ||
    length(unique(cpue$area)) != 9L || length(unique(cpue$season)) != 4L ||
    nrow(natage) != 100800L || !identical(range(natage$year), c(1952L, 2021L)) ||
    !identical(range(natage$age), c(1L, 40L)) || length(unique(natage$area)) != 9L ||
    length(unique(natage$season)) != 4L || nrow(f_annual) != 28000L ||
    !identical(range(f_annual$year), c(1952L, 2021L)) ||
    !identical(range(f_annual$age), c(1L, 40L)) ||
    !setequal(unique(f_annual$area), c(as.character(1:9), 'all')) ||
    !all(c('age', 'length', 'weight', 'maturity', 'natmort') %in% names(biology)) ||
    !identical(range(biology$age), c(1L, 40L)) || !('year' %in% names(summary))) {
  stop('The pinned TAF input/output coverage differs from the reviewed assessment.',
    call. = FALSE)
}

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate_id <- 'NOAA:11684'
unit_id <- 'wcpfc_wcpo_bigeye'
row <- which(register$candidate_id == candidate_id)
if (length(row) != 1L || register$scientific_name[row] != 'Thunnus obesus' ||
    any(stocks$scientific_name == 'Thunnus obesus', na.rm = TRUE)) {
  stop('WCPO bigeye candidate identity or canonical matching changed.', call. = FALSE)
}
if (any(register$candidate_unit_id[-row] == unit_id, na.rm = TRUE)) {
  stop('WCPO bigeye candidate-unit key conflicts with another candidate.', call. = FALSE)
}

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste('No direct catch-at-age likelihood is used. The accepted 2023 model inputs include catch and length/weight frequencies in the native MFCL files and 1,010 conditional age-at-length observations from 1990-2018 across 14 sampled years, four quarters and eight regions. These age samples inform growth. Combining sampled age-length keys with the matching size compositions supports an approximate catch-at-age reconstruction in supported strata; extending it to unsampled years or areas requires explicit pooling assumptions. MFCL uses 40 quarterly age classes, not 40 annual ages.'),
  survey_age_evidence = paste('The assessment uses nine regional standardized longline CPUE index series at quarterly resolution as aggregate relative-abundance likelihoods. They cover 1952-2021 but are not age-specific. Any age-specific index would require a separate, labelled reconstruction from the available age and size composition data.'),
  weights_evidence = paste('Native inputs include length and weight compositions. Weight-at-age is derived from internally estimated growth and the configured length-weight relationship; the TAF biology output contains model-derived weight-at-age, not an independent observed weight-at-age input.'),
  maturity_evidence = paste('Spawning potential is calculated from maturity, sex ratio and fecundity. The TAF biology output contains an age-specific maturity surface, but it is model-derived and should not be treated as a stand-alone observed maturity-at-age input.'),
  mortality_evidence = paste('Natural mortality is estimated internally with a Lorenzen age-dependent form. The TAF biology output provides the fitted natural-mortality-at-age surface; this is not a fixed input schedule.'),
  timing_evidence = paste('The 2023 assessment uses quarterly time steps and the nine regional CPUE indices are tabulated by quarter for 1952-2021. Preserve the quarterly source timing; an annual fractional-year timing would be a downstream approximation.'),
  output_evidence = paste('Pinned TAF diagnostic outputs provide numbers-at-age by year, quarter and region (1952-2021; ages 1-40 quarterly classes; nine regions), annual F-at-age by region, and annual summary quantities including recruitment and biomass. These are diagnostic-fit outputs; official status advice was based on the 54-model uncertainty grid. The reported spawning potential definition should be retained rather than relabelled conventional SSB.'),
  detailed_source_url = paste('https://meetings.wcpfc.int/node/19353', 'https://meetings.wcpfc.int/system/files/2024-07/SC19%20Outcomes%20Document%20%2828Nov2923%29-Att%201%2C7%20fixed_0.pdf', 'https://github.com/PacificCommunity/ofp-sam-bet-2023-diagnostic/tree/81fc412ad1f36416f78f84ef6bd2d5dff68d14c8', 'https://meetings.wcpfc.int/node/33590', 'https://meetings.wcpfc.int/taxonomy/term/2845?order=field_doc_symbol&sort=desc', 'https://meetings.wcpfc.int/file/21268/download', 'https://www.wcpfc.int/node/244', sep = '; '),
  review_date = '2026-11-02',
  decision_reason = paste('Eligible for source curation from the latest assessment accepted for WCPFC status advice. The 2023 source files provide catches, size compositions, conditional age-at-length observations, aggregate CPUE and fitted age-specific outputs. An approximate catch-at-age reconstruction is supportable only where the sampled age-length keys can be applied; pooling for unsampled years/areas must be explicit. The newer 2026 assessment report was reviewed at SC22, but WCPFC reported no consensus on its uncertainty grid, so it is not treated as the accepted basis for advice.'),
  notes = paste('NOAA Stock SMART ID 11684 maps to the WCPO bigeye unit assessed by SPC for WCPFC. It is distinct from NOAA:10169 (Atlantic bigeye) and NOAA:11685 (Eastern Pacific bigeye). No matching canonical Thunnus obesus stock record exists. The 2023 diagnostic repository is pinned to commit 81fc412ad1f36416f78f84ef6bd2d5dff68d14c8; its relevant MFCL inputs and TAF inputs/outputs, official 2023 assessment and SC19 outcomes, and later 2026 assessment sources are cached with SHA-256 values in source_cache/discovery_noaa_wcpfc_bigeye_2026/sources.csv. This is a discovery screen only; no canonical assessment data were added.')
)

initial <- register$match_status[row] == 'unreviewed' &&
  register$screening_status[row] == 'not_started' &&
  register$eligibility[row] == 'unresolved' &&
  (is.na(register$candidate_unit_id[row]) || !nzchar(register$candidate_unit_id[row]))
reviewed <- register$match_status[row] == 'new' &&
  register$candidate_unit_id[row] == unit_id &&
  register$screening_status[row] == 'screened' &&
  register$eligibility[row] == 'eligible' &&
  grepl('1,010 conditional age-at-length observations',
    register$catch_age_evidence[row], fixed = TRUE)
if (!initial && !reviewed) {
  stop('WCPO bigeye candidate has an unexpected prior review state.', call. = FALSE)
}
if (initial) {
  for (name in names(review)) register[[name]][row] <- review[[name]]
  if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1')) {
    source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
    replace_candidate_register_row(register_path, row, register[row, , drop = FALSE],
      candidate_id)
  }
}
cat('Screened NOAA 11684 as eligible for source curation with an approximate age-reconstruction caveat.\n')
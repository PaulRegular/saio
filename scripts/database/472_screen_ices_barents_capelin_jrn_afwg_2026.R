root <- "."
cache <- file.path(root, 'source_cache', 'discovery_ices_barents_capelin_2026')
register_path <- file.path(root, 'discovery', 'candidates.csv')
archive <- file.path(cache,
  'bifrost-4d4a30aa35db71e0bc3a9ad819ac3a89ad7b189f')

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
  JRN_AFWG_2026_report.html = 'f44265683e88a18b0f3fcb0e7379efff0c91a6ec8c134769e684ced15d1e85ea',
  capelin_2027_advice.html = 'dca765be3d2d82316b7b607020cb3aa6005c3f239c27bed4109dab34ac31aa16',
  WKCAPELIN_2023.pdf = '70b60d17e6fecc152fa5b92c150b2c512097bfa321cccec71b299da31f43a0d4',
  bifrost_4d4a30aa.zip = 'c06b683ca6230a839b123c4885ba6f595dea5717ab96266d09f78947b01fded1',
  JRN_AFWG_2026_overview.html = 'd86c12ebe2b89f7272d4074a82d26d80b5411ddfbc96d95fb1d4f98d2ee0a3dd')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  check.names = FALSE)
if (nrow(manifest) != length(expected_hashes) || anyDuplicated(manifest$file) ||
    !setequal(manifest$file, names(expected_hashes)))
  stop('The Barents capelin source manifest is incomplete.', call. = FALSE)
for (file in names(expected_hashes)) {
  source_row <- match(file, manifest$file)
  path <- file.path(cache, file)
  if (!file.exists(path) || manifest$retrieved_on[source_row] != '2026-10-31' ||
      as.numeric(manifest$bytes[source_row]) != file.info(path)$size ||
      tolower(manifest$sha256[source_row]) != expected_hashes[[file]] ||
      sha256_file(path) != expected_hashes[[file]])
    stop('Cached Barents capelin source differs from its manifest: ', file, call. = FALSE)
}

report <- paste(readLines(file.path(cache, 'JRN_AFWG_2026_report.html'), warn = FALSE),
  collapse = ' ')
advice <- paste(readLines(file.path(cache, 'capelin_2027_advice.html'), warn = FALSE),
  collapse = ' ')
overview <- paste(readLines(file.path(cache, 'JRN_AFWG_2026_overview.html'), warn = FALSE),
  collapse = ' ')
if (!grepl('JRN-AFWG', report, fixed = TRUE) ||
    !grepl('2026', report, fixed = TRUE) ||
    !grepl('Table 10.3', report, fixed = TRUE) ||
    !grepl('Table 10.4', report, fixed = TRUE) ||
    !grepl('StoX', report, fixed = TRUE) ||
    !grepl('Bifrost', report, fixed = TRUE) ||
    !grepl('5 tonnes', report, fixed = TRUE) ||
    !grepl('2027', advice, fixed = TRUE) ||
    !grepl('since 2022', overview, fixed = TRUE) ||
    !grepl('capelin assessments have been conducted outside of ICES', overview, fixed = TRUE) ||
    !grepl('maturing biomass', advice, fixed = TRUE))
  stop('Cached current assessment sources do not support the screening evidence.', call. = FALSE)

load_data <- function(file, object) {
  path <- file.path(archive, 'data', file)
  if (!file.exists(path)) stop('Missing pinned Bifrost data: ', file, call. = FALSE)
  env <- new.env(parent = emptyenv())
  load(path, envir = env)
  get(object, envir = env, inherits = FALSE)
}
catch <- load_data('catch.rda', 'catch')
cap <- load_data('cap.rda', 'cap')
maturity <- load_data('maturityInitialParameters.rda', 'maturityInitialParameters')
catch_docs <- paste(readLines(file.path(archive, 'man', 'catch.Rd'), warn = FALSE),
  collapse = ' ')
cap_docs <- paste(readLines(file.path(archive, 'man', 'cap.Rd'), warn = FALSE),
  collapse = ' ')
if (!grepl('million tons', catch_docs, fixed = TRUE) ||
    !grepl('meanweight of fish in grams', cap_docs, fixed = TRUE) ||
    !grepl('age 5 and older', cap_docs, fixed = TRUE))
  stop('Pinned Bifrost data documentation does not match the source review.', call. = FALSE)
if (nrow(catch) != 240L || !setequal(unique(catch$age), 1:5) ||
    !setequal(unique(catch$year), 1972:2019) ||
    anyDuplicated(catch[c('year', 'age')]) ||
    nrow(cap) != 1536L || !setequal(unique(cap$year), 1972:2019) ||
    !all(c(as.character(1:5), 'sum(10e9)', 'biomass(10e3t)',
      'meanweight(g)', 'meanlength(cm)') %in% names(cap)) ||
    nrow(maturity) != 94L || !setequal(unique(maturity$year), 1972:2018) ||
    !setequal(unique(maturity$agegr), c('2-3', '3-4')) ||
    !all(c('p1', 'p2', 'p3', 'nu') %in% names(maturity)))
  stop('Pinned Bifrost data dimensions or coverage do not match the review.', call. = FALSE)

candidates <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

candidate_id <- 'ICES:cap.27.1-2'
unit_id <- 'jrn_afwg_barents_capelin'
row <- match(candidate_id, candidates$candidate_id)
if (is.na(row) || sum(candidates$candidate_id == candidate_id, na.rm = TRUE) != 1L ||
    candidates$official_stock_id[row] != 'cap.27.1-2' ||
    candidates$scientific_name[row] != 'Mallotus villosus' ||
    !grepl('Barents Sea capelin', candidates$stock_name[row], ignore.case = TRUE) ||
    any(candidates$candidate_unit_id[-row] == unit_id, na.rm = TRUE) ||
    any(as.character(stocks$authority_stock_id) == 'cap.27.1-2', na.rm = TRUE) ||
    any(stocks$stock_id == unit_id) || any(assessments$stock_id == unit_id) ||
    any(inputs$assessment_id == unit_id) || any(outputs$assessment_id == unit_id))
  stop('Barents capelin identity conflicts with the discovery register or canonical database.',
    call. = FALSE)

review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste('The pinned public IMRpelagic/bifrost data archive contains seasonal age-specific catch for ages 1-5 in 1972-2019, measured in million tonnes. This historical dataset does not provide run-matched catch-at-age through 2026; the 2026 JRN-AFWG report gives only total catch of 5 tonnes, all Russian bycatch.'),
  survey_age_evidence = paste('The 2026 JRN-AFWG report Table 10.3 gives StoX acoustic stock numbers by age groups 1-5, total stock biomass and maturing biomass at 1 October. Table 10.4 gives age-specific CVs for 2004-2026. These are estimated acoustic stock outputs; the reviewed sources do not include the underlying current-run survey input arrays.'),
  weights_evidence = paste('The pinned Bifrost cap data provide acoustic abundance by length group and age, mean weight in grams and mean length in centimetres for 1972-2019. The 2026 report shows weight-at-age in Figure 10.2 but gives no numeric table; run-matched numeric weights after 2019 remain unrecovered.'),
  maturity_evidence = paste('Bifrost maturityInitialParameters provides initial maturation-model parameters for age groups 2-3 and 3-4 in 1972-2018; these are model parameters, not a direct maturity-at-age matrix. The 2026 forecast uses a maturation model, but the current run-specific parameter values and age-specific maturity surface were not recovered.'),
  mortality_evidence = paste('The 2026 report states that survey mortality for ages 2-3 after 1987 parameterizes natural mortality from 1 October to 1 January in the forecast model. The forecast also includes cod predation and predicted cod numbers and weights at age. The full 2026 parameter inputs and current run files were not recovered.'),
  timing_evidence = paste('The acoustic stock estimate is associated with the autumn Barents Sea survey and is reported at 1 October; the report says the survey is completed by the beginning of October. The Bifrost forecast projects maturing biomass from 1 October to 1 April. A precise fractional-year survey timing is not stated.'),
  output_evidence = paste('The 2026 report publishes age-specific acoustic stock numbers and CVs, total and maturing biomass at 1 October, and annual recruitment and biomass plots. SSB is shown from 1989, with uncertainty available from 2018. The 2027 advice reports a forecast median SSB and 90% interval. These outputs are not a full age-structured N/F/M time series.'),
  detailed_source_url = paste('https://www.hi.no/hi/nettrapporter/imr-vniro-en-2026-10;',
    'https://www.hi.no/hi/nettrapporter/imr-vniro-en-2026-9;',
    'https://doi.org/10.17895/ices.pub.23260388;',
    'https://github.com/IMRpelagic/bifrost/tree/4d4a30aa35db71e0bc3a9ad819ac3a89ad7b189f;',
    'https://imrpelagic.github.io/bifrostdocumentation/data.html;',
    'https://rdrr.io/github/IMRpelagic/bifrost/man/catch.html'),
  review_date = '2026-10-31',
  decision_reason = paste('The latest official assessment is the 2026 JRN-AFWG assessment for 2027 advice, not an ICES advice run: the bilateral working group has conducted Barents Sea capelin assessments outside ICES since 2022. The ICES SID code is retained as the discovery-source identifier only. Age-specific acoustic estimates and historical Bifrost age data are available, but the reviewed public Bifrost inputs end in 2019 for catch and acoustic biology, maturity parameters end in 2018, and the 2026 assessment reports only total bycatch. Eligibility remains unresolved until current-run catch, biological and survey inputs can be reconciled.'),
  notes = paste('Distinct candidate unit jrn_afwg_barents_capelin; no canonical stock or numerical records created. The current report identifies 2026 stock estimates from StoX and an October-to-April Bifrost forecast. ICES SID lists this historical code with assessment year 2021, which is not the latest assessment.'))

current <- lapply(names(review), function(column) as.character(candidates[[column]][row]))
names(current) <- names(review)
already_reviewed <- all(vapply(names(review), function(column)
  identical(current[[column]], as.character(review[[column]])), logical(1L)))
pristine <- candidates$match_status[row] == 'unreviewed' &&
  candidates$screening_status[row] == 'not_started' &&
  candidates$eligibility[row] == 'unresolved' &&
  (is.na(candidates$candidate_unit_id[row]) || !nzchar(candidates$candidate_unit_id[row]))
if (!pristine && !already_reviewed)
  stop('Barents capelin candidate already has a conflicting review.', call. = FALSE)

if (!identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1') && !already_reviewed) {
  for (column in names(review)) candidates[[column]][row] <- review[[column]]
  source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
  replace_candidate_register_row(register_path, row,
    candidates[row, , drop = FALSE], candidate_id)
  source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
  source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
}

cat('Screened Barents Sea capelin as eligibility-unresolved pending current-run input recovery.\n')

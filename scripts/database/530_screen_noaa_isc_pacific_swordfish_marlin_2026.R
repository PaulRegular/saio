root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

source_urls <- paste(
  'https://isc.fra.go.jp/pdf/ISC14/Annex9-NP_Swordfish_Stock_Assessment_2014.pdf',
  'https://isc.fra.go.jp/pdf/ISC23/ISC23_ANNEX11-Stock_Assessment_Report_for_North_Pacific_Ocean_Swordfish_FINAL.pdf',
  'https://meetings.wcpfc.int/system/files/2023-08/SC19-SA-WP-11%20ISC23%20ANNEX%2014%20-%20Stock%20Assessment%20Report%20for%20WCNPO%20Striped%20Marlin%20-%20FINAL.pdf',
  'https://www.isc.fra.go.jp/pdf/ISC26/ISC26_ANNEX_09_Stock_Assessment_Report_for_Blue_Marlin_in_the_Pacific_Ocean.pdf',
  'https://www.fisheries.noaa.gov/species/north-pacific-swordfish/seafood',
  'https://isc.fra.go.jp/recommendation/isc26/isc26_swordfish.html',
  'https://isc.fra.go.jp/recommendation/isc26/isc26_stripedmarlin.html',
  'https://isc.fra.go.jp/recommendation/isc26/isc26_bluemarlin.html',
  sep = '; ')

review <- data.frame(
  candidate_id = c('NOAA:11642', 'NOAA:11643', 'NOAA:11692', 'NOAA:11706'),
  candidate_unit_id = c('noaa_wcnpo_swordfish', 'noaa_eastern_pacific_swordfish',
    'isc_wcnpo_striped_marlin', 'isc_pacific_blue_marlin'),
  match_status = rep('new', 4L),
  screening_status = rep('screened', 4L),
  eligibility = rep('ineligible', 4L),
  import_status = rep('not_started', 4L),
  catch_age_evidence = c(
    'The 2023 Stock Synthesis assessment uses fleet catches, standardized CPUE, and quarterly length compositions in 5-cm bins. The model is age structured internally, but no catch-at-age or population age-composition likelihood is used.',
    'The latest NOAA-listed Eastern Pacific assessment is the 2014 Bayesian state-space surplus-production model. It uses catches and standardized CPUE, with no age-structured catch or composition observations.',
    'The 2023 Stock Synthesis assessment uses fleet catches, standardized CPUE, and length/size compositions. The age-structured population model does not use catch-at-age or age-composition observations.',
    'The 2026 pan-Pacific Stock Synthesis assessment uses fishery catches, standardized CPUE, and length or weight size compositions. It is age structured internally but does not use catch-at-age or age-composition observations.'),
  survey_age_evidence = c(
    'Standardized fishery CPUE is an aggregate abundance index; the reviewed assessment does not fit an age-specific survey abundance index.',
    'Standardized fishery CPUE is an aggregate abundance index in the production model; no age-specific survey index is fitted.',
    'Standardized fishery CPUE is aggregate. The report does not identify an age-specific survey abundance index among the fitted inputs.',
    'Standardized fishery CPUE is aggregate. The reviewed assessment does not identify an age-specific survey abundance index among the fitted inputs.'),
  weights_evidence = c(
    'Length and weight information supports the model size-composition and biological specifications; a run-matched weight-at-age observation series is not an input likelihood.',
    'The surplus-production assessment has no weight-at-age input.',
    'Length/weight information supports size compositions and biological specifications; a run-matched weight-at-age observation series is not an input likelihood.',
    'Length/weight size-composition and biological information is used, but no run-matched weight-at-age observation series is an input likelihood.'),
  maturity_evidence = c(
    'Maturity information informs the assessment biology and spawning-biomass output, but is not evidence of catch-at-age or age-composition inputs.',
    'The production model reports exploitable biomass and does not use maturity-at-age as an age-structured observation input.',
    'Maturity information informs spawning-biomass calculations, but the model inputs are not age-disaggregated catch or survey observations.',
    'Female maturity informs spawning-biomass calculations; the fitted observations are not age-disaggregated catch or survey observations.'),
  mortality_evidence = c(
    'The Stock Synthesis assessment includes age-specific population dynamics and mortality assumptions, but these do not supply the missing observed age-disaggregated inputs.',
    'The Bayesian surplus-production model has no age-specific natural-mortality surface.',
    'The Stock Synthesis assessment includes age-specific population dynamics and mortality assumptions, but these do not supply the missing observed age-disaggregated inputs.',
    'The Stock Synthesis assessment includes age-specific population dynamics and mortality assumptions, but these do not supply the missing observed age-disaggregated inputs.'),
  timing_evidence = rep(
    'The reviewed assessment sources do not specify a fractional within-year timing for an age-specific survey observation; the fitted CPUE series is fishery based and aggregate.',
    4L),
  output_evidence = c(
    'The 2023 report provides age-1+ biomass, spawning biomass, age-0 recruitment, and average F for ages 1–10. No annual N-at-age or F-at-age surface was identified.',
    'The 2014 assessment reports exploitable biomass and harvest rate with uncertainty, not age-specific abundance, fishing mortality, or recruitment.',
    'The 2023 report provides age-1+ biomass, spawning biomass, age-0 recruitment, and average F for ages 3–12. No annual N-at-age or F-at-age surface was identified.',
    'The 2026 report provides age-1+ biomass, female spawning biomass, age-0 recruitment, and fishing-mortality summaries. No annual N-at-age or F-at-age surface was identified.'),
  detailed_source_url = rep(source_urls, 4L),
  review_date = rep('2026-11-02', 4L),
  decision_reason = rep(
    'Ineligible for the age-disaggregated input screen: the latest official assessment relies on aggregate catches/CPUE and length or size compositions (or a production model), not catch-at-age plus age-specific abundance observations. Age-structured internal states and aggregate biomass outputs do not establish the required observed inputs.',
    4L),
  notes = c(
    'Keep the NOAA WCNPO management unit distinct. The 2023 ISC North Pacific swordfish assessment has broader spatial/model boundaries and includes an IATTC-area component north of 10 degrees N; this does not establish that NOAA WCNPO and Eastern Pacific management units are identical.',
    'Keep the NOAA Eastern Pacific swordfish unit distinct from WCNPO. NOAA identifies 2014 as the latest assessment for this unit. The 2014 assessment is a separate EPO surplus-production model; the later 2023 ISC model uses different spatial/model boundaries.',
    'The 2023 ISC WCNPO striped marlin assessment remains the basis of current ISC26 advice. Its assessment data period is 1977–2020.',
    'Stock SMART lists 2021, but ISC completed a pan-Pacific assessment in 2026 through 2024; use the newer official production assessment for screening.'),
  stringsAsFactors = FALSE)

if (anyDuplicated(register$candidate_id) || anyDuplicated(review$candidate_id))
  stop('NOAA candidate identifiers are duplicated.', call. = FALSE)
if (any(review$candidate_unit_id %in%
    register$candidate_unit_id[!register$candidate_id %in% review$candidate_id]))
  stop('A reviewed candidate unit is already assigned to another inventory row.',
    call. = FALSE)

blank <- function(x) is.na(x) || !nzchar(x)
for (i in seq_len(nrow(review))) {
  id <- review$candidate_id[i]
  row_index <- match(id, register$candidate_id)
  if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
  old <- register[row_index, , drop = FALSE]
  initial <- old$match_status == 'unreviewed' &&
    old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
    old$import_status == 'not_started' && blank(old$candidate_unit_id)
  unit <- if (blank(old$candidate_unit_id)) '' else as.character(old$candidate_unit_id)
  reviewed <- old$match_status == review$match_status[i] &&
    old$screening_status == 'screened' && old$eligibility == 'ineligible' &&
    old$import_status == 'not_started' &&
    identical(unit, as.character(review$candidate_unit_id[i]))
  if (!initial && !reviewed)
    stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
  for (name in setdiff(names(review), 'candidate_id'))
    register[[name]][row_index] <- review[[name]][i]
  same <- all(vapply(names(register), function(name) {
    x <- register[[name]][row_index]
    y <- old[[name]]
    if (is.na(x)) is.na(y) else !is.na(y) &&
      identical(as.character(x), as.character(y))
  }, logical(1L)))
  if (!same && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened four Pacific swordfish and marlin inventory records using current ISC assessment sources.\n')

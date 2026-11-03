root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

review <- data.frame(
  candidate_id = 'NOAA:14230',
  candidate_unit_id = 'noaa_gulf_smoothhound_complex',
  scientific_name = 'Mustelus spp.',
  assessment_area = 'Gulf of Mexico',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'SEDAR 39 states that no age-composition information was available.',
    'The accepted state-space production model fits catch and does not use a',
    'catch-at-age likelihood.'),
  survey_age_evidence = paste(
    'The model uses aggregate abundance indices. No age-specific abundance',
    'index or age-composition likelihood is reported.'),
  weights_evidence = paste(
    'Length-weight relationships support catch-weight calculations; the',
    'production model has no age-specific population-weight input.'),
  maturity_evidence = paste(
    'Life-history information informs the productivity prior. The production',
    'model does not use an age-specific maturity schedule or spawning-biomass',
    'surface.'),
  mortality_evidence = paste(
    'The model is a state-space surplus-production model estimating aggregate',
    'harvest rates and exploitable numbers, not an age-specific natural',
    'mortality process.'),
  timing_evidence = paste(
    'The assessment fits annual aggregate catch and abundance indices; it does',
    'not report a within-year survey timing fraction for age-specific data.'),
  output_evidence = paste(
    'The official report provides aggregate exploitable abundance, biomass,',
    'harvest rates and reference points. It does not report N-at-age, F-at-age',
    'or M-at-age.'),
  detailed_source_url = paste0(
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=14230; ',
    'https://sedarweb.org/assessments/sedar-39/; ',
    'https://sedarweb.org/documents/',
    'sedar-39-final-stock-assessment-report-hms-gulf-of-mexico-smoothhound-shark/'),
  review_date = '2026-11-02',
  decision_reason = paste(
    'Ineligible for age-disaggregated source curation: the latest fully',
    'accepted assessment is a state-space surplus-production model, and the',
    'SEDAR 39 report explicitly states that age-composition information was',
    'unavailable. Aggregate catch, indices and age-specific life-history',
    'information do not provide age-disaggregated observation inputs.'),
  notes = paste(
    'NOAA Stock SMART identifies the 2015 SEDAR 39 assessment (data through',
    '2012) as fully accepted. The assessment is for a Gulf of Mexico Mustelus',
    'spp. complex; species identification was limited. No matching canonical',
    'stock record was found. This is an inventory-only candidate screen; no',
    'canonical data was added.'),
  stringsAsFactors = FALSE)

if (anyDuplicated(register$candidate_id) || anyDuplicated(review$candidate_id))
  stop('NOAA candidate identifiers are duplicated.', call. = FALSE)
if (any(review$candidate_unit_id %in%
    register$candidate_unit_id[!register$candidate_id %in% review$candidate_id]))
  stop('The candidate unit is already assigned to another inventory row.',
    call. = FALSE)

blank <- function(x) is.na(x) || !nzchar(x)
id <- review$candidate_id
row_index <- match(id, register$candidate_id)
if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
old <- register[row_index, , drop = FALSE]
initial <- old$match_status == 'unreviewed' &&
  old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
  old$import_status == 'not_started' && blank(old$candidate_unit_id)
unit <- if (blank(old$candidate_unit_id)) '' else as.character(old$candidate_unit_id)
reviewed <- old$match_status == review$match_status &&
  old$screening_status == 'screened' && old$eligibility == 'ineligible' &&
  old$import_status == 'not_started' &&
  identical(unit, as.character(review$candidate_unit_id))
if (!initial && !reviewed)
  stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
for (name in setdiff(names(review), 'candidate_id'))
  register[[name]][row_index] <- review[[name]]

same <- all(vapply(names(register), function(name) {
  x <- register[[name]][row_index]
  y <- old[[name]]
  if (is.na(x)) is.na(y) else !is.na(y) &&
    identical(as.character(x), as.character(y))
}, logical(1L)))
if (!same && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
  replace_candidate_register_row(register_path, row_index,
    register[row_index, , drop = FALSE], id)

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened the NOAA Gulf smoothhound complex against SEDAR 39.\n')

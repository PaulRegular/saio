root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
id <- 'DFO:Pacific:Coho salmon - Interior Fraser'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected Interior Fraser Coho inventory row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(x$candidate_unit_id[i] == 'dfo_coho_interior_fraser',
    x$scientific_name[i] == 'Oncorhynchus kisutch',
    x$match_status[i] == 'new', x$eligibility[i] == 'ineligible',
    x$import_status[i] == 'not_started')
  quit(save = 'no')
}
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing Interior Fraser Coho review state.', call. = FALSE)
}

x$candidate_unit_id[i] <- 'dfo_coho_interior_fraser'
x$scientific_name[i] <- 'Oncorhynchus kisutch'
x$assessment_area[i] <- paste(
  'Fraser River watershed upstream of Hells Gate; one SMU, five Conservation',
  'Units, and eleven subpopulations'
)
x$inventory_assessment_year[i] <- 2022
x$match_status[i] <- 'new'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The assessment reports natural-origin catch and aggregate exploitation rates,',
  'but no catch numbers-at-age. Age proportions at recruitment ages 3 and 4',
  'enter the stock-recruit calculation; they are not a catch-at-age likelihood.'
)
x$survey_age_evidence[i] <- paste(
  'Spawner abundance is assessed by Conservation Unit and natural pre-fishery',
  'abundance is reported at aggregate scale. The report provides no age-specific',
  'survey index or annual age-composition likelihood.'
)
x$weights_evidence[i] <- paste(
  'No stock weight-at-age input is reported or used in the assessment.'
)
x$maturity_evidence[i] <- paste(
  'Scale ageing supports generation-time and age-at-maturity information, but',
  'the report does not provide a maturity-at-age surface used by the model.'
)
x$mortality_evidence[i] <- paste(
  'Aggregate exploitation rate is estimated from mixed methods, including FRAM;',
  'no age-specific fishing or natural mortality surface is reported.'
)
x$timing_evidence[i] <- paste(
  'The report uses return years and spawning abundance; no within-year survey',
  'timing fraction is specified for an age-specific abundance index.'
)
x$output_evidence[i] <- paste(
  'The report gives Conservation Unit spawner and recruit abundance, aggregate',
  'pre-fishery abundance, smolt-to-adult survival, exploitation rates, reference',
  'points, and forward simulations. It does not report N-at-age, F-at-age, or',
  'M-at-age population outputs.'
)
x$detailed_source_url[i] <- 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4130276x.pdf'
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'The current DFO assessment is for return year 2022 and was published as',
  'Science Response 2025/027. It combines Wild Salmon Policy rapid-status',
  'assessment, CU-level Ricker spawner-recruit analysis, and aggregate simulation.',
  'Age proportions at recruitment ages 3 and 4 and scale-age samples support',
  'life-history and stock-recruit calculations, but the assessment does not use',
  'age-specific catch/index likelihoods, a complete age-specific biological and',
  'mortality input set, or report population N/F/M-at-age. Ineligible for the',
  'age-disaggregated assessment set.'
)
x$notes[i] <- paste(
  'This is the Interior Fraser Coho SMU upstream of Hells Gate, distinct from',
  'Lower Fraser Coho. The 2022 assessment is the latest detailed source found;',
  'no canonical stock or assessment records were added. See discovery/source_reviews/',
  'dfo_interior_fraser_coho_2022.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, i, x[i, , drop = FALSE], id)

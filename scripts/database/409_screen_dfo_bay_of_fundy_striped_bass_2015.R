root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
id <- 'DFO:Maritimes:Striped Bass - Bay of Fundy'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected Bay of Fundy Striped Bass inventory row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(x$candidate_unit_id[i] == 'dfo_striped_bass_bay_of_fundy_du',
    x$scientific_name[i] == 'Morone saxatilis',
    x$match_status[i] == 'new', x$eligibility[i] == 'ineligible',
    x$import_status[i] == 'not_started')
  quit(save = 'no')
}
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing Bay of Fundy Striped Bass review state.', call. = FALSE)
}
if (any(x$candidate_unit_id[-i] == 'dfo_striped_bass_bay_of_fundy_du', na.rm = TRUE)) {
  stop('Bay of Fundy Striped Bass candidate-unit ID is already in use.', call. = FALSE)
}

x$candidate_unit_id[i] <- 'dfo_striped_bass_bay_of_fundy_du'
x$scientific_name[i] <- 'Morone saxatilis'
x$assessment_area[i] <- paste(
  'Bay of Fundy Designatable Unit; Shubenacadie, Annapolis, and Saint John',
  'River spawning populations'
)
x$inventory_assessment_year[i] <- NA_integer_
x$match_status[i] <- 'new'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2015 status review describes directed and bycatch fisheries but provides',
  'no unit-level catch numbers-at-age or catch-age likelihood. DFO notes that',
  'fishery catch and retention are not accurately monitored.'
)
x$survey_age_evidence[i] <- paste(
  'The 2014 recovery review and 2015 status synthesis describe local abundance',
  'observations, tagging, and juvenile surveys, but no annual age-specific',
  'abundance index or age-composition likelihood for the Designatable Unit.'
)
x$weights_evidence[i] <- paste(
  'No population weight-at-age surface used by a production assessment was',
  'identified in the DFO status or recovery documents.'
)
x$maturity_evidence[i] <- paste(
  'Age at first spawning is discussed as life-history context, but no model',
  'maturity-at-age input surface is reported.'
)
x$mortality_evidence[i] <- paste(
  'The recovery review discusses threats and mortality qualitatively; it does',
  'not estimate age-specific fishing or natural mortality for the unit.'
)
x$timing_evidence[i] <- paste(
  'Spawning is described as occurring mainly in May-June, but no annual survey',
  'index with a within-year timing fraction is used by a population model.'
)
x$output_evidence[i] <- paste(
  'The DFO documents provide status, recovery targets, local abundance',
  'observations, and threat summaries. They do not report population N-at-age,',
  'F-at-age, M-at-age, or fitted recruitment and spawning-biomass series.'
)
x$detailed_source_url[i] <- paste(
  'https://waves-vagues.dfo-mpo.gc.ca/Library/364418.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/Library/359709.pdf'
)
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'The DFO inventory lists the Bay of Fundy Striped Bass unit as Uncertain in',
  'the 2024 Sustainability Survey. The latest detailed DFO sources located are',
  'the 2014 recovery potential assessment and the 2015 review of 2013 biology',
  'and status; they are not a current production population assessment. The',
  'recovery review says projections cannot be calculated with available data',
  'and reports no current adult age-structure estimates for the extant',
  'Shubenacadie population. No age-structured catch/index likelihoods or',
  'population N/F/M-at-age outputs were identified. Screen ineligible for the',
  'age-disaggregated assessment set; do not treat the Gulf of St. Lawrence',
  'Striped Bass assessment as this distinct Bay of Fundy unit.'
)
x$notes[i] <- paste(
  'This candidate is the Bay of Fundy Designatable Unit, comprising three',
  'spawning populations, not the assessed southern Gulf of St. Lawrence stock.',
  'The 2024 DFO survey status is Uncertain. No canonical stock or assessment',
  'records were added. See discovery/source_reviews/',
  'dfo_striped_bass_bay_of_fundy.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, i, x[i, , drop = FALSE], id)

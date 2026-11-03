root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
id <- 'DFO:Pacific:Eulachon - Fraser River'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected Fraser River Eulachon inventory row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(x$candidate_unit_id[i] == 'dfo_eulachon_fraser_du',
    x$scientific_name[i] == 'Thaleichthys pacificus',
    x$match_status[i] == 'new', x$eligibility[i] == 'ineligible',
    x$import_status[i] == 'not_started')
  quit(save = 'no')
}
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing Fraser River Eulachon review state.', call. = FALSE)
}
if (any(x$candidate_unit_id[-i] == 'dfo_eulachon_fraser_du', na.rm = TRUE)) {
  stop('Fraser River Eulachon candidate-unit ID is already in use.', call. = FALSE)
}

x$candidate_unit_id[i] <- 'dfo_eulachon_fraser_du'
x$scientific_name[i] <- 'Thaleichthys pacificus'
x$assessment_area[i] <- 'Fraser River Designatable Unit, British Columbia'
x$inventory_assessment_year[i] <- NA_integer_
x$match_status[i] <- 'new'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2012 RPA model used annual commercial catch biomass for 1900-2009 and',
  'shrimp-trawl effort to represent bycatch. These are not catch numbers-at-age',
  'or an observed catch-age likelihood.'
)
x$survey_age_evidence[i] <- paste(
  'The current Fraser River Egg and Larval Survey provides an aggregate spawning',
  'biomass index. The historical 2012 model fitted aggregate relative-abundance',
  'indices; it did not use an age-specific survey index. Offshore survey ages are',
  'uncertain and stock origins can be mixed.'
)
x$weights_evidence[i] <- paste(
  'The 2012 RPA applied fixed mean mass values for model ages 1-3, but the current',
  'IFMP does not provide a current production weight-at-age input surface.'
)
x$maturity_evidence[i] <- paste(
  'The RPA assumed semelparity and a single maturity age of three years. DFO',
  'reports that there is no validated ageing technique and spawning age remains',
  'uncertain; no current model maturity-at-age surface is reported.'
)
x$mortality_evidence[i] <- paste(
  'The 2012 RPA fixed natural mortality at 0.51 per year and estimated historical',
  'fishery/bycatch mortality using aggregate catch and shrimping effort. These are',
  'historical assumptions, not a current production mortality surface.'
)
x$timing_evidence[i] <- paste(
  'The egg and larval survey is seasonal and the IFMP reports a seven-week core',
  'period, but no within-year timing fraction for an age-specific survey',
  'likelihood is defined.'
)
x$output_evidence[i] <- paste(
  'The 2026 IFMP reports annual aggregate Fraser River SSB-index values through',
  '2025. The 2012 RPA reports posterior biomass, recruitment-related and',
  'aggregate F quantities, but no annual fitted N-at-age or F/M-at-age output',
  'series was identified.'
)
x$detailed_source_url[i] <- paste(
  'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/eulachon-eulakane-ifmp-pgip-sm-eng.html;',
  'https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs143-3-23-2588-eng.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/364476.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/347894.pdf'
)
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'The DFO Sustainability Survey lists Fraser River Eulachon as Uncertain. The',
  'latest management source reviewed is the 2026 IFMP, which says the older 2003',
  'multi-indicator approach is no longer used and identifies the Egg and Larval',
  'Survey as the main source for current harvest decisions. The 2012 RPA includes',
  'a historical age-structured Bayesian model, but it fits aggregate catch biomass,',
  'abundance indices and shrimping effort with simplified fixed age assumptions;',
  'the 2015 Fraser-specific RPA refers back to that model. This does not establish',
  'a current production assessment or provide age-disaggregated observation inputs.',
  'DFO reports that eulachon ageing is not validated, and current survey outputs',
  'are aggregate SSB indices. No comparable annual N-at-age or F/M-at-age outputs',
  'were identified. Screen ineligible for the age-disaggregated candidate set.'
)
x$notes[i] <- paste(
  'This is the Fraser River Designatable Unit, not all Canadian Eulachon units.',
  'The historic 2012 RPA age-structured model is retained as context; current',
  'management uses aggregate indicators. No canonical stock or assessment data',
  'were added. See discovery/source_reviews/dfo_eulachon_fraser_2026.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, i, x[i, , drop = FALSE], id)

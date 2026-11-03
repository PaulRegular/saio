root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

urls <- paste(
  'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/smon-sc-cs-ifmp-pgip-sm-eng.html;',
  'https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs141-9-2026-eng.pdf;',
  'https://www-ops2.pac.dfo-mpo.gc.ca/fns-sap/index-eng.cfm?DOC_ID=371699&ID=all&pg=view_notice;',
  'https://www.pac.dfo-mpo.gc.ca/fm-gp/fraser/albion-eng.html'
)
review <- 'See discovery/source_reviews/dfo_fraser_chum_2026.md.'

fraser_id <- 'DFO:Pacific:Fraser Chum Salmon'
fraser_i <- match(fraser_id, x$candidate_id)
if (is.na(fraser_i)) stop('Expected Fraser Chum inventory row is missing.', call. = FALSE)

if (x$screening_status[fraser_i] == 'not_started') {
  x$candidate_unit_id[fraser_i] <- 'dfo_fraser_chum_smu'
  x$scientific_name[fraser_i] <- 'Oncorhynchus keta'
  x$assessment_area[fraser_i] <- 'Fraser River Stock Management Unit, British Columbia'
  x$inventory_assessment_year[fraser_i] <- 2026L
  x$match_status[fraser_i] <- 'new'
  x$screening_status[fraser_i] <- 'screened'
  x$eligibility[fraser_i] <- 'ineligible'
  x$import_status[fraser_i] <- 'not_started'
  x$catch_age_evidence[fraser_i] <- paste(
    'The 2026 in-season estimate combines Albion test-fishery catch information',
    'with historical run-size and timing information. The current notice describes',
    'aggregate catch counts, not catch numbers-at-age; no production catch-age',
    'likelihood was identified.'
  )
  x$survey_age_evidence[fraser_i] <- paste(
    'Albion test-fishery data inform aggregate terminal run-size estimates. DFO',
    'reports separate spawning escapement estimates that include age data, but',
    'does not describe an age-specific abundance-index likelihood.'
  )
  x$weights_evidence[fraser_i] <- paste(
    'No current production weight-at-age surface was identified for the',
    'aggregate run-size estimation.'
  )
  x$maturity_evidence[fraser_i] <- paste(
    'No maturity-at-age input is identified for the current in-season run-size',
    'estimation; spawning escapement is reported separately.'
  )
  x$mortality_evidence[fraser_i] <- paste(
    'The current Bayesian nonlinear regression estimates aggregate terminal',
    'abundance and migration timing, not annual fishing or natural mortality-at-age.'
  )
  x$timing_evidence[fraser_i] <- paste(
    'The Albion test fishery samples seasonally, normally every other day from',
    'September 1 through October 20 and daily later in the season. No annual',
    'within-year survey timing fraction for an age-specific index is defined.'
  )
  x$output_evidence[fraser_i] <- paste(
    'DFO reports a 2026 terminal Fraser River Chum return of 1,521,000 fish',
    '(median; 80% interval 748,000-3,051,000). This is an aggregate seasonal',
    'run-size estimate, not annual fitted N-at-age or F/M-at-age.'
  )
  x$detailed_source_url[fraser_i] <- urls
  x$review_date[fraser_i] <- '2026-10-30'
  x$decision_reason[fraser_i] <- paste(
    'The latest public current-season output is DFO\'s 2026 in-season terminal',
    'run-size estimate based on Albion test-fishery catch and historical run-size',
    'and migration-timing information. It estimates aggregate seasonal abundance,',
    'not an age-structured production assessment with age-specific inputs and',
    'population outputs. The Fraser Chum SMU is described as dominated by the',
    'Lower Fraser Chum CU; it remains distinct from the broader Inner South Coast',
    'Chum inventory label. Screen ineligible for the age-disaggregated set.'
  )
  x$notes[fraser_i] <- paste(
    'The 2026 run-size estimate is an aggregate in-season management output,',
    'not a fitted age-structured population model. The full 2026/2027 IFMP is',
    'available from DFO on request; the public summary and in-season notice are',
    'cached locally. ', review
  )
} else if (x$screening_status[fraser_i] == 'screened') {
  stopifnot(x$candidate_unit_id[fraser_i] == 'dfo_fraser_chum_smu',
    x$match_status[fraser_i] == 'new', x$eligibility[fraser_i] == 'ineligible')
} else {
  stop('Preserve the existing Fraser Chum review state.', call. = FALSE)
}

inner_id <- 'DFO:Pacific:Inner South Coast Chum'
inner_i <- match(inner_id, x$candidate_id)
if (is.na(inner_i)) stop('Expected Inner South Coast Chum inventory row is missing.', call. = FALSE)

if (x$screening_status[inner_i] == 'not_started') {
  x$scientific_name[inner_i] <- 'Oncorhynchus keta'
  x$assessment_area[inner_i] <- 'Multiple inner South Coast management components, British Columbia'
  x$inventory_assessment_year[inner_i] <- 2026L
  x$match_status[inner_i] <- 'ambiguous'
  x$screening_status[inner_i] <- 'screened'
  x$eligibility[inner_i] <- 'unresolved'
  x$import_status[inner_i] <- 'not_started'
  x$catch_age_evidence[inner_i] <- paste(
    'The 2026 IFMP and outlook distinguish Fraser and non-Fraser chum',
    'management components. The generic inventory label does not identify',
    'which current unit or catch series it represents.'
  )
  x$survey_age_evidence[inner_i] <- paste(
    'The 2026 Fraser Chum model uses aggregate Albion test-fishery information;',
    'this does not resolve the broader inner South Coast inventory row to one',
    'age-specific abundance series.'
  )
  x$weights_evidence[inner_i] <- paste(
    'No single current weight-at-age input can be assigned while the inventory',
    'row spans unresolved management components.'
  )
  x$maturity_evidence[inner_i] <- paste(
    'No single current maturity-at-age input can be assigned while the inventory',
    'row spans unresolved management components.'
  )
  x$mortality_evidence[inner_i] <- paste(
    'The available aggregate Fraser run-size output does not establish mortality',
    'assumptions for the broader inner South Coast inventory row.'
  )
  x$timing_evidence[inner_i] <- paste(
    'Timing differs among current fishery and management components; no single',
    'within-year timing fraction is established for this broad row.'
  )
  x$output_evidence[inner_i] <- paste(
    'The Fraser Chum component has an aggregate 2026 terminal run-size estimate.',
    'Comparable age-specific outputs for the broader inner South Coast row were',
    'not identified.'
  )
  x$detailed_source_url[inner_i] <- urls
  x$review_date[inner_i] <- '2026-10-30'
  x$decision_reason[inner_i] <- paste(
    'Current DFO material distinguishes Fraser and non-Fraser inner South Coast',
    'chum components, while the inventory label does not identify one of them.',
    'The Fraser row is screened separately. Keep this row identity-ambiguous',
    'and eligibility-unresolved; do not create an additional assessment unit or',
    'assign the Fraser run-size estimate to it.'
  )
  x$notes[inner_i] <- paste('No canonical records were added. ', review)
} else if (x$screening_status[inner_i] == 'screened') {
  stopifnot(x$match_status[inner_i] == 'ambiguous',
    x$eligibility[inner_i] == 'unresolved', is.na(x$candidate_unit_id[inner_i]))
} else {
  stop('Preserve the existing Inner South Coast Chum review state.', call. = FALSE)
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, fraser_i, x[fraser_i, , drop = FALSE], fraser_id)
replace_candidate_register_row(path, inner_i, x[inner_i, , drop = FALSE], inner_id)

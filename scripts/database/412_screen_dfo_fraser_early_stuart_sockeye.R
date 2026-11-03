root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

candidate_id <- 'DFO:Pacific:Sockeye Salmon - Fraser (Early Stuart)'
row <- match(candidate_id, x$candidate_id)
if (is.na(row)) stop('Expected Early Stuart sockeye inventory row is missing.', call. = FALSE)

if (x$screening_status[row] == 'not_started') {
  x$candidate_unit_id[row] <- 'dfo_fraser_sockeye_early_stuart'
  x$scientific_name[row] <- 'Oncorhynchus nerka'
  x$assessment_area[row] <- paste(
    'Fraser River Early Stuart management group',
    '(Takla/Trembleur Early Stuart Conservation Unit), British Columbia'
  )
  x$inventory_assessment_year[row] <- NA_integer_
  x$match_status[row] <- 'new'
  x$screening_status[row] <- 'screened'
  x$eligibility[row] <- 'ineligible'
  x$import_status[row] <- 'not_started'
  x$catch_age_evidence[row] <- paste(
    'The PSC production dataset has age-specific recruit/run-size outputs and',
    'spawner estimates, but not original fishery catch numbers-at-age or the',
    'source matrices needed to reproduce the run-size assessment.'
  )
  x$survey_age_evidence[row] <- paste(
    'No independent age-specific abundance-index likelihood was identified.',
    'PSC age-specific recruits are constructed run-size outputs, not survey',
    'observations.'
  )
  x$weights_evidence[row] <- paste(
    'No age-specific population or spawning weight input vector was recovered',
    'for an age-structured population assessment.'
  )
  x$maturity_evidence[row] <- paste(
    'DFO spawner data include sex and spawning-success information, but no',
    'current age-specific maturity vector for a population assessment was found.'
  )
  x$mortality_evidence[row] <- paste(
    'The sources describe stock-specific run-size adjustment and environmental',
    'effects, not annual F-at-age or M-at-age processes.'
  )
  x$timing_evidence[row] <- paste(
    'No within-year survey timing fraction is defined for an age-specific',
    'abundance-index likelihood.'
  )
  x$output_evidence[row] <- paste(
    'The PSC 2026.05.07 detailed file reports Early Stuart recruitment by',
    'Gilbert-Rich age code for return years 1950-2025. The 2025 entries are',
    'in-season-based and incomplete by age; the dataset has no uncertainty.'
  )
  x$detailed_source_url[row] <- paste(
    'https://www.psc.org/publications/data/fraser-sockeye-stock-recruit-dataset/;',
    'https://www.psc.org/download/130/frp-data/19739/stock-recruit-data-documentation.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41294622.pdf;',
    'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/smon-sc-cs-ifmp-pgip-sm-eng.html;',
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs141-9-2026-eng.pdf'
  )
  x$review_date[row] <- '2026-10-30'
  x$decision_reason[row] <- paste(
    'The latest public official product provides age-specific Fraser Early',
    'Stuart recruits and spawner estimates, but the reviewed sources do not',
    'provide the original catch-at-age and independent age-specific index',
    'inputs, age-specific population biology, or F/M process assumptions',
    'required for an age-structured population assessment. Keep the unit',
    'crosswalked, but screen it out of the age-input candidate set.'
  )
  x$notes[row] <- paste(
    'This is a current Fraser Sockeye management group and PSC production',
    'stock group, not a standalone age-structured population model. Return-year',
    '2025 is incomplete in-season data; no canonical records were added. See',
    'discovery/source_reviews/dfo_fraser_sockeye_early_stuart.md.'
  )
} else if (x$screening_status[row] == 'screened') {
  stopifnot(
    x$candidate_unit_id[row] == 'dfo_fraser_sockeye_early_stuart',
    x$match_status[row] == 'new',
    x$eligibility[row] == 'ineligible'
  )
} else {
  stop('Preserve the existing Early Stuart sockeye review state.', call. = FALSE)
}

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, row, x[row, , drop = FALSE], candidate_id)

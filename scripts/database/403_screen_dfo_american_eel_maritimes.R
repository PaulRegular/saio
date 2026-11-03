# Link and screen the two Maritimes American eel fishery entries as one unit.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c('DFO:Maritimes:Eel (Large)', 'DFO:Maritimes:Elvers')
i <- match(ids, x$candidate_id)
if (anyNA(i)) stop('Expected Maritimes eel inventory rows are missing.', call. = FALSE)

if (all(x$screening_status[i] == 'screened')) {
  stopifnot(all(x$candidate_unit_id[i] == 'dfo_american_eel_maritimes'),
    all(x$match_status[i] == 'new'), all(x$eligibility[i] == 'ineligible'))
  quit(save = 'no')
}
if (any(x$screening_status[i] != 'not_started') ||
    any(!is.na(x$candidate_unit_id[i]) & nzchar(x$candidate_unit_id[i]))) {
  stop('Preserve the existing Maritimes eel identity review.', call. = FALSE)
}

x$scientific_name[i] <- 'Anguilla rostrata'
x$assessment_area[i] <- 'DFO Maritimes Region; large-eel and elver fisheries'
x$candidate_unit_id[i] <- 'dfo_american_eel_maritimes'
x$match_status[i] <- 'new'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2026 update reports landings and effort by fishery/life stage. Neither',
  'the current indicator update nor the 2018 assessment provides annual',
  'population catch numbers-at-age for these entries.'
)
x$survey_age_evidence[i] <- paste(
  'The 2026 report updates the East River-Chester elver recruitment index and',
  'regional electrofishing, juvenile and silver-eel abundance indicators.',
  'These are not age-specific indices from a population model.'
)
x$weights_evidence[i] <- paste(
  'No annual stock or observation weights-at-age for an age-structured',
  'population assessment were identified in the 2018 assessment or 2026 update.'
)
x$maturity_evidence[i] <- paste(
  'No population maturity-at-age series was identified. The SPR analysis',
  'does not supply annual maturity-at-age inputs for a population model.'
)
x$mortality_evidence[i] <- paste(
  'The 2018 assessment uses spawner-per-recruit analyses to define mortality',
  'reference points, including for the elver fishery. It does not estimate',
  'annual fishing or natural mortality-at-age population surfaces.'
)
x$timing_evidence[i] <- paste(
  'No within-year observation timing for an age-structured assessment was',
  'identified; the available fishery and indicator analyses do not define one.'
)
x$output_evidence[i] <- paste(
  'The latest detailed 2026 update reports fishery and abundance indicators,',
  'not annual population N-at-age, F-at-age, M-at-age, recruitment or SSB',
  'outputs from a fitted age-structured assessment.'
)
x$detailed_source_url[i] <- paste(
  'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-021-eng.pdf;',
  'https://publications.gc.ca/collections/collection_2024/mpo-dfo/fs70-6/Fs70-6-2024-013-eng.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41040624.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40872415.pdf'
)
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'The large-eel and elver entries are fishery life stages of the Maritimes',
  'American eel population and are linked to one candidate unit. DFO identifies',
  'the 2018 process as the last assessment; the latest detailed 2026 report',
  'updates fishery and regional abundance indicators rather than fitting an',
  'age-structured population model. No annual age-specific population inputs',
  'or comparable population outputs are available, so this unit is ineligible',
  'for the age-disaggregated assessment set.'
)
x$notes[i] <- paste(
  'One population unit with two fishery-life-stage inventory rows; not two',
  'assessment stocks. See source_reviews/dfo_american_eel_maritimes_2026.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
for (j in i) {
  replace_candidate_register_row(path, j, x[j, , drop = FALSE], ids[match(j, i)])
}

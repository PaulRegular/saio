root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
id <- 'DFO:Maritimes:Gaspereau'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected Maritimes Gaspereau inventory row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'ambiguous', is.na(x$candidate_unit_id[i]),
    x$eligibility[i] == 'unresolved', x$import_status[i] == 'not_started')
  quit(save = 'no')
}
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing Maritimes Gaspereau review state.', call. = FALSE)
}

x$candidate_unit_id[i] <- NA_character_
x$scientific_name[i] <- NA_character_
x$assessment_area[i] <- 'DFO Maritimes Region; multiple river-specific populations and two species'
x$match_status[i] <- 'ambiguous'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2025-2026 review is specifically for Alewife in the Gaspereau River,',
  'but this inventory row covers the regional fishery across rivers and two',
  'species. No run-matched annual catch-at-age series for the row was verified;',
  'the current Research Document remains an expected publication.'
)
x$survey_age_evidence[i] <- paste(
  'DFO describes river-specific escapement counts, run-size estimates and',
  'catch-per-unit-effort indicators. No age-specific abundance-index series',
  'aligned to one population in this broad inventory row was verified.'
)
x$weights_evidence[i] <- paste(
  'No current age-specific weights for Alewife in the Gaspereau River or for',
  'the broad regional fishery were verified. The 2016 Tusket assessment is a',
  'separate river unit and cannot supply these inputs.'
)
x$maturity_evidence[i] <- paste(
  'No current maturity-at-age inputs for the Gaspereau River Alewife',
  'assessment were verified. The regional fishery entry combines multiple',
  'populations and species.'
)
x$mortality_evidence[i] <- paste(
  'DFO reports that an LRP for Gaspereau River Alewife was developed and',
  'accepted in 2025-2026; the current assessment assumptions and mortality',
  'inputs are not in a published detailed report found for this review.'
)
x$timing_evidence[i] <- paste(
  'The fishery and spawning runs occur in spring, but no single survey timing',
  'or within-year sampling fraction applies to this multi-river inventory row.'
)
x$output_evidence[i] <- paste(
  'The accepted 2025-2026 LRP is a reference-point result for Gaspereau River',
  'Alewife. The official schedule still lists a Research Document as expected;',
  'no comparable annual N-at-age, F-at-age, M-at-age, recruitment or SSB series',
  'for this generic regional row was verified.'
)
x$detailed_source_url[i] <- paste(
  'https://www.isdm-gdsi.gc.ca/csas-sccs/applications/events-evenements/result-eng.asp?curr=year;',
  'https://www.dfo-mpo.gc.ca/csas-sccs/Schedule-Horraire/2025/794-eng.html;',
  'https://www.dfo-mpo.gc.ca/about-notre-sujet/publications/work-plan-travail/2026-2027/work-plan-travail-2025-26-eng.html;',
  'https://www.dfo-mpo.gc.ca/about-notre-sujet/publications/work-plan-travail/2026-2027/wp-pt-eng.html;',
  'https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/gaspereau-gaspareau/index-eng.html;',
  'https://waves-vagues.dfo-mpo.gc.ca/Library/40604470.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/Library/40579591.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/Library/329174.pdf'
)
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'This regional inventory label is a fishery encompassing two species and',
  'river-specific populations, so it cannot be linked to one assessment unit.',
  'The latest located process is specifically for Alewife in the Gaspereau',
  'River; its LRP was accepted in 2025-2026, but DFO lists a Research Document',
  'as expected and its age-structured inputs and outputs remain unverified.',
  'Keep identity ambiguous and eligibility unresolved until the detailed',
  'assessment is available; register the specific river/species unit separately.'
)
x$notes[i] <- paste(
  'Do not treat this regional fishery row as one stock. The 2025-2026 Alewife',
  'assessment concerns the Gaspereau River specifically; see',
  'source_reviews/dfo_maritimes_gaspereau.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, i, x[i, , drop = FALSE], id)

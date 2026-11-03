root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
id <- 'DFO:Pacific:Chinook Salmon - North Coast'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected North Coast Chinook inventory row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(is.na(x$candidate_unit_id[i]), x$match_status[i] == 'ambiguous',
    x$eligibility[i] == 'unresolved', x$import_status[i] == 'not_started')
  quit(save = 'no')
}
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing North Coast Chinook review state.', call. = FALSE)
}

x$candidate_unit_id[i] <- NA_character_
x$scientific_name[i] <- 'Oncorhynchus tshawytscha'
x$assessment_area[i] <- paste(
  'DFO North Coast region; inventory label spans multiple Chinook management units,',
  'including Skeena-Nass and Central Coast ISBM units'
)
x$inventory_assessment_year[i] <- NA_integer_
x$match_status[i] <- 'ambiguous'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The broad regional inventory row cannot be matched to one official production',
  'assessment. The current Northern BC IFMP describes Skeena-Nass and Central',
  'Coast Chinook management units separately; unit-specific catch-at-age inputs',
  'were not established for this aggregate label.'
)
x$survey_age_evidence[i] <- paste(
  'The 2026-2027 IFMP describes stream escapement monitoring, Nass fish-wheel',
  'information and mark-recapture, and the Skeena Tyee test fishery as an',
  'uncalibrated relative-abundance tool for Chinook. No age-specific abundance',
  'index or age-composition likelihood for one matching aggregate was verified.'
)
x$weights_evidence[i] <- paste(
  'No unit-matched stock weight-at-age input was verified for the broad regional',
  'inventory label.'
)
x$maturity_evidence[i] <- paste(
  'No unit-matched maturity-at-age input was verified for the broad regional',
  'inventory label.'
)
x$mortality_evidence[i] <- paste(
  'The IFMP describes escapement and fishery indicators rather than one shared',
  'age-structured F/M assessment for all North Coast Chinook units.'
)
x$timing_evidence[i] <- paste(
  'The source describes in-river run timing and monitoring, not a single annual',
  'survey timing fraction for the broad North Coast label.'
)
x$output_evidence[i] <- paste(
  'The current IFMP reports unit-specific management status and monitoring',
  'information, but no single comparable N-at-age, F-at-age, or M-at-age output',
  'for the broad North Coast inventory row.'
)
x$detailed_source_url[i] <- paste(
  'https://publications.gc.ca/site/eng/9.963335/publication.html;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41248077.pdf;',
  'https://www.pac.dfo-mpo.gc.ca/pacific-smon-pacifique/science/research-recherche/smon-summ-somm-eng.html'
)
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'The 2026 DFO salmon summary counts 22 North Coast stock management units',
  'across salmon species. The Northern BC IFMP describes Skeena-Nass ISBM and',
  'Central Coast ISBM Chinook separately, while the 2026 outlook is an early',
  'regional scan rather than a formal assessment. The source-list label therefore',
  'does not identify one current assessment unit. Preserve it as an ambiguous',
  'regional inventory entry and leave age-structured eligibility unresolved',
  'until unit-specific production assessment sources are identified.'
)
x$notes[i] <- paste(
  'Do not use this row as a North Coast-wide stock or merge Skeena-Nass and',
  'Central Coast Chinook. No canonical stock or assessment records were added.',
  'See discovery/source_reviews/dfo_north_coast_chinook_inventory.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, i, x[i, , drop = FALSE], id)

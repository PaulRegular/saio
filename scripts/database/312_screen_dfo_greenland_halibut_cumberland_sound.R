path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  candidate_id = 'DFO:Arctic:Greenland Halibut - Cumberland Sound Turbot Management Area',
  candidate_unit_id = 'greenland_halibut_cumberland_sound_tma',
  official_stock_id = '',
  scientific_name = 'Reinhardtius hippoglossoides',
  stock_name = 'Greenland halibut - Cumberland Sound Turbot Management Area',
  assessment_area = 'Cumberland Sound Turbot Management Area, Nunavut',
  inventory_assessment_year = '2019',
  catch_age_evidence = paste(
    'The 2019 assessment reports landings, logbook data and catch length-frequency.',
    'Plant samples included otolith extraction, but no run-matched catch numbers-at-age',
    'or age-composition likelihood input was located.'
  ),
  survey_age_evidence = paste(
    'The fishery-independent bottom-longline survey ran annually from 2011 to 2018',
    'across five depth strata. It reports aggregate abundance and biomass indices',
    'derived from catch per set and stratum area, not an age-specific abundance index.'
  ),
  weights_evidence = paste(
    'Round and dressed weights were measured in plant samples; survey longline sets',
    'recorded total catch weight. No run-matched population weight-at-age input was located.'
  ),
  maturity_evidence = paste(
    'Plant and survey samples recorded sex and maturity condition, but no age-specific',
    'maturity vector was reported. Survey fish examined were immature or resting.'
  ),
  mortality_evidence = paste(
    'No accepted population model estimates fishing or natural mortality. The generic',
    'DLMTools model had poor convergence and was not used for science advice; the report',
    'recommends estimating mortality from tagging data.'
  ),
  timing_evidence = paste(
    'The survey uses overnight 12-hour bottom-longline sets; a fractional within-year',
    'timing for a population observation model is not reported.'
  ),
  output_evidence = paste(
    'The 2019 assessment reports aggregate fishery-independent abundance and biomass',
    'indices for 2011-2018 (biomass unavailable in 2011-2012), but no accepted model',
    'outputs for N-at-age, F-at-age, recruitment or SSB.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-007-eng.pdf;',
    'https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/groundfish-poisson-fond/2019/halibut-fletan-eng.htm;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41085607.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/335647.pdf;',
    'https://www.dfo-mpo.gc.ca/fisheries-peches/commercial-commerciale/atl-arc/2026/halibut-fletan-2026-2027-tac-eng.html'
  ),
  decision_reason = paste(
    'Ineligible for the age-disaggregated set: the latest assessment for this unit',
    'reports aggregate survey indices and length-based fishery demographics, while the',
    'generic population model had poor convergence and was not used for advice. No',
    'accepted age-structured inputs or outputs were verified.'
  ),
  notes = paste(
    'The DFO inventory treats the Cumberland Sound Turbot Management Area as a separate',
    'management unit from NAFO Subarea 0. The 2019 review reports seasonal movement and',
    'emigration between Cumberland Sound and offshore waters, so this is a management',
    'crosswalk, not a claim of a biologically isolated population. The latest assessment',
    'review was held in 2019 and published as Science Advisory Report 2026/007 in February',
    '2026. Its publication page states that additional meeting publications would be posted',
    'when available; no detailed research document or native model files were located.'
  )
)

i <- match(review$candidate_id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == review$candidate_id) != 1L) {
  stop('Expected single DFO Cumberland Sound Greenland Halibut inventory row was not found.', call. = FALSE)
}
if (!x$screening_status[i] %in% c('not_started', 'screened') ||
    !x$match_status[i] %in% c('unreviewed', 'new') ||
    !x$eligibility[i] %in% c('unresolved', 'ineligible') ||
    !is.na(x$candidate_unit_id[i]) && nzchar(x$candidate_unit_id[i])) {
  stop('DFO Cumberland Sound Greenland Halibut row has an unexpected prior review state.', call. = FALSE)
}
if (any(x$candidate_unit_id[-i] == review$candidate_unit_id, na.rm = TRUE)) {
  stop('Candidate unit ID is already assigned to another inventory row.', call. = FALSE)
}
stock_description <- paste(stocks$scientific_name, stocks$area, stocks$region, stocks$notes)
same_unit <- grepl('Cumberland Sound|CSTMA|Turbot Management Area',
  stock_description, ignore.case = TRUE)
if (any(stocks$scientific_name == review$scientific_name & same_unit, na.rm = TRUE)) {
  stop('A canonical Cumberland Sound Greenland Halibut record now exists; reconcile it before rerunning.',
    call. = FALSE)
}

review$match_status <- 'new'
review$screening_status <- 'screened'
review$eligibility <- 'ineligible'
review$import_status <- 'not_started'
review$review_date <- '2026-10-29'
for (column in names(review)) x[[column]][i] <- review[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
row <- x[i, , drop = FALSE]
row[] <- lapply(row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened the DFO Cumberland Sound Greenland Halibut inventory row as a new but age-structured-ineligible management unit.\n')

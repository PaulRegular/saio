# Reconcile and screen the DFO Strait of Georgia herring inventory entry.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('DFO:Pacific:Pacific Herring - Strait of Georgia', x$candidate_id)
if (is.na(i)) stop('Expected DFO Strait of Georgia herring row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(
    x$matched_stock_id[i] == 'dfo_herring_sog',
    x$eligibility[i] == 'ineligible',
    x$import_status[i] == 'imported'
  )
  quit(save = 'no')
}
if (x$match_status[i] != 'matched' || x$matched_stock_id[i] != 'dfo_herring_sog' ||
    x$screening_status[i] != 'not_started') {
  stop('Preserve the existing identity review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Clupea pallasii'
x$assessment_area[i] <- 'Strait of Georgia'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste(
  'The matched 2025 DDM ensemble inputs retain catches by three fleets in',
  'thousand tonnes plus native fishery age-composition sample counts at ages',
  '1-10+. Catch numbers-at-age are not a direct observation; they require',
  'composition and catch-weight processing.'
)
x$survey_age_evidence[i] <- paste(
  'The sole combined surface/dive survey input is total spawning biomass for',
  '1951-2023. All native survey age samples are missing (-1), and both survey',
  'age-composition likelihood weights are zero. No age-specific survey index',
  'or observed survey composition is available for reconstruction.'
)
x$weights_evidence[i] <- paste(
  'The canonical record contains empirical stock weight-at-age in kg/fish',
  'for ages 1-10+ and year-varying values through 2023.'
)
x$maturity_evidence[i] <- paste(
  'The fixed combined-sex maturity-at-age vector is 0 at age 1, 0.24974 at',
  'age 2, 0.9 at age 3, and 1 for ages 4-10+.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is estimated in the DDM ensemble, is density dependent',
  'and time varying, and has a distinct age-1 juvenile component. The database',
  'contains age-specific mortality outputs for each of the five models.'
)
x$timing_evidence[i] <- paste(
  'Native model-year sampling fractions are 0.54 for reduction catch, 0.766',
  'for seine roe catch, 0.774 for gillnet catch, and 0.79 for spawning/survey',
  'observations. The assessment year ends June 30.'
)
x$output_evidence[i] <- paste(
  'The canonical record contains SSB and age-1 recruitment series for',
  '1951-2023 and age-specific M plus model-specific MPD N-at-age. The',
  'published terminal SSB is 84.33375 thousand tonnes; posterior ensemble',
  'N-at-age and F-at-age draws were not recovered.'
)
x$detailed_source_url[i] <- 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41320013.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'This inventory entry matches the existing dfo_herring_sog stock and',
  'dfo_herring_sog_2025 assessment. Its production model has age-specific',
  'fishery compositions, but its only abundance observation is total',
  'spawning biomass; native survey age samples are missing and their age',
  'likelihood weights are zero.',
  'cannot fit this aggregate spawning-biomass observation, so the case is not',
  'eligible for the current age-indexed translation screen.'
)
x$notes[i] <- paste(
  'Already imported as dfo_herring_sog_2025; do not create a duplicate stock',
  'or assessment. The full source review is source_reviews/dfo_herring_sog.md.',
  'Its cached 2025 update and pinned native DDM sources are under',
  'source_cache/dfo_herring_sog/.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

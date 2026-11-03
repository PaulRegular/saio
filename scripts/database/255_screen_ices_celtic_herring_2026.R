path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:her.27.irls'
i <- match(id, x$candidate_id)
if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)
updates <- list(
  matched_stock_id = NA_character_,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = 'HAWG 2026 Table 6.6.1.1 reports catch numbers-at-age for winter-ring ages 1-9+ over 1958-2025.',
  survey_age_evidence = 'HAWG 2026 Table 6.6.1.2 reports the October acoustic index in numbers with age-specific numbers for ages 2-7, annual CV 0.5, and sample sizes; assessment tuning excludes 2004, 2017 and 2024.',
  weights_evidence = 'Table 6.6.1.1 reports catch and spawning-stock weights-at-age in kg for winter-ring ages 1-9+; TAF preparation reads the Lowestoft weight inputs.',
  maturity_evidence = 'The 2026 production assessment uses a time-invariant maturity ogive: 0.5 at age 1 and 1 at ages 2-9+.',
  mortality_evidence = 'The assessment fixes natural mortality at ages 1-9+ to 0.767, 0.385, 0.356, 0.339, 0.319, 0.314, 0.307, 0.307 and 0.307, retained from the HAWG 2015 procedure using the 2011 SMS run.',
  timing_evidence = 'The assessment year is 1 April-31 March. ASAP specifies the acoustic index month as October (month 10); the 2025 survey ran 9-29 October.',
  output_evidence = 'HAWG 2026 Table 6.6.1.4 gives annual catch, SSB, total biomass, Fbar ages 2-5 and age-1 recruitment through 2025. The pinned TAF output script writes N-at-age and F-at-age files, but generated numerical age-specific output files were not present in the public repository snapshot.',
  detailed_source_url = 'https://doi.org/10.17895/ices.pub.31424315; https://github.com/ices-advice/2026_her.27.irls/tree/cf29535caedd3b97d1912a1fd5b37be350e3d916/2026_her.27.irls_assessment',
  review_date = '2026-10-29',
  decision_reason = 'Eligible for source curation: the 2026 official ASAP assessment report provides tabulated catch-at-age, age-specific acoustic survey input, weights, fixed maturity and mortality, timing, and annual SSB, Fbar and recruitment outputs. Exact raw bootstrap inputs are absent from the public TAF snapshot, but the assessment report contains detailed numerical input tables. Age-specific fitted N/F output files are not present in that snapshot. The report documents unquantified mixing with Irish Sea herring; this is a biological limitation, not an identity match.',
  notes = 'No canonical stock matches ICES her.27.irls. The existing her.27.6aN, her.27.6aS7bc and historical her.27.6a7bc records have different stock codes and areas. Retain as a distinct provisional new unit; the HAWG 2026 report notes unquantified mixing with Irish Sea herring her.27.nirs. Assessment/input evidence and pinned TAF scripts are cached under source_cache/discovery_ices_celtic_sea_herring_2026/.'
)
for (column in names(updates)) x[[column]][i] <- updates[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)
cat('Screened ICES her.27.irls; eligible for source curation.\n')

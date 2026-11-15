path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10512', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Stock SMART 10512.', call. = FALSE)

review <- list(
  candidate_unit_id = 'noaa_pollock_bogoslof',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest accepted production method is Tier 5 and does not fit a',
    'catch-at-age likelihood. Directed fishing has been closed since 1992;',
    'recent removals are bycatch. Reported catch totals are not expanded to',
    'age. The age-specific survey table is supporting information for a',
    'separate Tier-3-type research model, not the Tier-5 production fit.'
  ),
  survey_age_evidence = paste(
    'The accepted Tier-5 assessment uses aggregate acoustic-trawl biomass',
    'in tonnes from the winter survey (February-March). The report also',
    'publishes estimated survey numbers at age 4-15+ for 1988-2020 from an',
    'age-structured research model; age data from the 2024 survey were not',
    'available. Those age estimates are not fitted by the production model.'
  ),
  weights_evidence = paste(
    'No weight-at-age input is required or reported for the accepted Tier-5',
    'biomass smoother. A run-matched weight-at-age series for the separate',
    'age-structured research model was not verified.'
  ),
  maturity_evidence = paste(
    'No maturity-at-age input is required or reported for the accepted',
    'Tier-5 biomass smoother. A run-matched maturity-at-age series for the',
    'separate age-structured research model was not verified.'
  ),
  mortality_evidence = paste(
    'The production calculation uses M = 0.313, carried forward from a',
    'Tier-3-type age-structured research model. M is a scalar input to the',
    'Tier-5 harvest calculation, not an estimated age-specific surface.'
  ),
  timing_evidence = paste(
    'The acoustic-trawl survey is conducted in February-March and is',
    'periodic; the 2024 assessment describes the 2024 survey as the latest',
    'available observation. The production smoother is annual on survey',
    'year, with no within-year observation timing.'
  ),
  output_evidence = paste(
    'The accepted 2024 SAFE reports a random-effects survey-biomass estimate',
    'of 247,137 t and 2025/2026 ABC and OFL of 58,015 t and 77,354 t.',
    'Population-at-age and fishing-mortality-at-age outputs are not reported',
    'for the Tier-5 production assessment.'
  ),
  detailed_source_url = paste0(
    'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BOGpollock.pdf; ',
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=Bogoslof+Pollock.pdf&p=a1d6b604-9624-4e8c-b35b-c93f571ea2e2.pdf; ',
    'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2024_FINAL.pdf&p=2587e1ac-2a37-4a80-b68b-7a8c7e7a02ca.pdf; ',
    'https://www.fisheries.noaa.gov/species/alaska-pollock/management; ',
    'https://www.fisheries.noaa.gov/alaska/ecosystems/alaska-fish-research-surveys'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10512 is the separate Central Bering Sea-Bogoslof',
    'management unit, absent from the canonical database. NOAA and NPFMC',
    'sources identify it separately from Eastern Bering Sea, Aleutian Islands',
    'and GOA pollock. The Council-approved 2024 production assessment for',
    '2025-2026 uses a Tier-5 random-effects biomass smoother; the age table',
    'is for supporting age-structured research and does not provide a',
    'current catch-at-age likelihood or fitted N/F-at-age outputs. A newer',
    'September 2026 SAFE chapter proposes 2027-2028 specifications but says',
    'it is pre-dissemination peer review. The unit is ineligible for the',
    'current age-disaggregated assessment pool; this does not mean age data',
    'are absent from all supporting research.'
  ),
  notes = paste(
    'Stock SMART lists assessment year 2022, which is stale relative to the',
    '2024 SAFE assessment using the 2024 acoustic survey for 2025-2026',
    'advice. The 2026 SAFE chapter is retained as later draft evidence, not',
    'as formally disseminated agency policy. Source PDFs and SHA-256 hashes',
    'are in the ignored source_cache/discovery_noaa_pollock_age_units/.'
  )
)

matches_review <- vapply(names(review), function(column) {
  value <- as.character(x[[column]][i])
  expected <- as.character(review[[column]])
  if (is.na(value)) value <- ''
  if (is.na(expected)) expected <- ''
  identical(value, expected)
}, logical(1L))
new_entry <- x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed'
prior_screen <- x$match_status[i] == 'new' &&
  x$screening_status[i] == 'screened' &&
  x$eligibility[i] == 'ineligible' &&
  x$candidate_unit_id[i] == review$candidate_unit_id
if (new_entry || prior_screen) {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!all(matches_review)) {
  stop('Bogoslof pollock has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
csv_row <- x[i, , drop = FALSE]
csv_row[] <- lapply(csv_row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(csv_row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA:10512 as a new ineligible age-structured assessment candidate.\n')

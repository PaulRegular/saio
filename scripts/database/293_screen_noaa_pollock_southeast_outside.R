path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10514', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Stock SMART 10514.', call. = FALSE)

review <- list(
  candidate_unit_id = 'noaa_pollock_southeast_outside',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 GOA assessment fits catch-at-age in its age-structured',
    'C/W/WYK model, which covers the area west of 140 degrees W. The',
    'separately managed Southeast Outside unit is outside that model and',
    'uses a Tier-5 biomass approach without catch-at-age.'
  ),
  survey_age_evidence = paste(
    'The latest full report uses aggregate NMFS bottom-trawl survey biomass',
    'estimates for the Southeast Outside assessment area east of 140 degrees',
    'W. A random-effects model smooths the 1990-2023 biomass series; no',
    'age-specific survey index is reported for this unit.'
  ),
  weights_evidence = paste(
    'No weight-at-age input is required or reported for the Tier-5',
    'Southeast Outside biomass assessment. The weight-at-age inputs in the',
    'report apply to the distinct C/W/WYK age-structured assessment.'
  ),
  maturity_evidence = paste(
    'No maturity-at-age input is required or reported for the Tier-5',
    'Southeast Outside biomass assessment. Biological age surfaces in the',
    'report apply to the distinct C/W/WYK age-structured assessment.'
  ),
  mortality_evidence = paste(
    'The Tier-5 calculation uses M = 0.30, with FABC = 0.75 M and FOFL = M.',
    'This scalar is not an estimated age-specific mortality surface.'
  ),
  timing_evidence = paste(
    'The assessment uses bottom-trawl survey biomass observations from',
    '1990-2023. No within-year timing is specified for the aggregate',
    'Southeast Outside index in Appendix 1B.'
  ),
  output_evidence = paste(
    'The accepted 2024 SAFE reports an estimated biomass of 43,328 t and',
    '2025/2026 ABC and OFL of 9,749 t and 12,998 t. No population-at-age or',
    'fishing-mortality-at-age outputs are reported for Southeast Outside.'
  ),
  detailed_source_url = paste0(
    'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOApollock.pdf; ',
    'https://www.npfmc.org/december-2024-newsletter/; ',
    'https://meetings.npfmc.org/Meeting/Details/3108; ',
    'https://www.fisheries.noaa.gov/species/alaska-pollock/management'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10514 is the separate Southeast Outside management',
    'unit east of 140 degrees W and is not represented by the canonical',
    'Gulf of Alaska stock, which covers the C/W/WYK area west of 140 degrees',
    'W. NOAA identifies the two as separate stocks. The Council-approved',
    '2024 GOA SAFE uses an age-structured model for C/W/WYK but Tier 5 and',
    'an aggregate random-effects survey-biomass model for Southeast Outside.',
    'No age-disaggregated production inputs or N/F-at-age outputs are',
    'reported for this unit, so it is ineligible for the current',
    'age-structured assessment pool.'
  ),
  notes = paste(
    'The 2024 detailed assessment run (with SEO survey observations through',
    '2023) remains the latest unit-specific production assessment located.',
    "NOAA's public management page still labels the latest SEO assessment as",
    '2023; the SAFE report is the detailed source used for 2025-2026',
    'specifications. Later harvest-specification material links back to the',
    '2024 SAFE. Source PDFs and SHA-256 hashes are in the ignored',
    'source_cache/discovery_noaa_pollock_age_units/.'
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
  stop('Southeast Outside pollock has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
csv_row <- x[i, , drop = FALSE]
csv_row[] <- lapply(csv_row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(csv_row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA:10514 as a new ineligible age-structured assessment candidate.\n')

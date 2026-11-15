path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10168', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Stock SMART 10168.', call. = FALSE)

review <- list(
  candidate_unit_id = 'iattc_eastern_pacific_yellowfin',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2025 IATTC benchmark fits fishery catches and standardized length',
    'compositions. It does not fit observed catch-at-age or fishery age',
    'compositions. External otolith and tagging age-length data inform',
    'growth but do not provide fishery-specific catch-age compositions.'
  ),
  survey_age_evidence = paste(
    'Abundance indices are aggregate, derived from spatiotemporal models',
    'for purse-seine fisheries associated with dolphins in EPO/NE models',
    'and longline fisheries in SW. No age-specific abundance index is fitted.'
  ),
  weights_evidence = paste(
    'The 2025 report updates growth and reproductive biology and uses',
    'length-based compositions. A run-matched annual observed weight-at-age',
    'input series was not recovered from the public report.'
  ),
  maturity_evidence = paste(
    'Reproductive biology is documented as an assessment assumption, but',
    'a numeric run-matched maturity-at-age series was not recovered in the',
    'public report tables reviewed.'
  ),
  mortality_evidence = paste(
    'Natural mortality is age- and sex-specific, estimated externally from',
    'tagging cohort analysis, then fixed in the assessment. Low/base/high',
    'mortality assumptions are included in the risk analysis.'
  ),
  timing_evidence = paste(
    'The assessment uses quarterly fisheries and reports the 2025 benchmark',
    'results at the start of 2024. A single annual survey timing is not',
    'applicable to its fishery-based abundance indices.'
  ),
  output_evidence = paste(
    'Official outputs include probabilistic spawning-biomass and fishing-',
    'mortality status relative to reference points and trajectories. Numeric',
    'run-matched annual N-at-age and F-at-age arrays were not recovered.'
  ),
  detailed_source_url = paste0(
    'https://www.iattc.org/GetAttachment/11b8757d-ad0f-435c-b2c6-40f5658c56c0/SAC-16-03_Yellowfin-benchmark-assessment---2025.pdf; ',
    'https://www.iattc.org/en-US/Event/DetailMeeting/Meeting-SAC-16; ',
    'https://www.iattc.org/StockAssessments/2025/YFTWebsite/SW_base-1/plots/_SS_output.html; ',
    'https://www.fisheries.noaa.gov/species/pacific-yellowfin-tuna/resources'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10168 identifies the Eastern Pacific yellowfin unit.',
    'The latest detailed assessment located is IATTC 2025, based on data',
    'through 2023. Although Stock Synthesis is age-structured internally,',
    'the fitted observations are catches, aggregate indices and length',
    'compositions, with no observed age-specific catch or abundance input.',
    'The unit is ineligible for the age-disaggregated input screen.'
  ),
  notes = paste(
    'The assessment evaluates EPO-wide, SW, NE and NE-short configurations,',
    'with risk analyses over biological, effort-creep and stock-recruitment',
    'hypotheses. IATTC output pages prohibit redistribution of native run',
    'files and derivative content without permission; only the public report',
    'was cached locally under',
    'source_cache/discovery_noaa_iattc_yellowfin_2025/.'
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
  stop('Eastern Pacific yellowfin has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
csv_row <- x[i, , drop = FALSE]
csv_row[] <- lapply(csv_row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(csv_row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA:10168 as a new but ineligible IATTC Eastern Pacific yellowfin unit.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10163', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Stock SMART 10163.', call. = FALSE)

review <- list(
  candidate_unit_id = 'noaa_pacific_mackerel_pacific_coast',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2025 catch-only assessment updates catch through model year 2023',
    'and retains the 2023 benchmark age-composition likelihoods for model',
    'years 2008-2021. Fishery age compositions are based on California',
    'commercial samples and can be combined with fleet catch and weights',
    'at age for a documented catch-at-age reconstruction. Age groups are',
    '0-8+; no age compositions are available after 2021.'
  ),
  survey_age_evidence = paste(
    'The model fits a summer Acoustic-Trawl (AT) aggregate biomass index',
    'and AT survey age compositions for 2008-2021. The inherited 2023',
    'Stock Synthesis data file records the index at model month 1.6.'
  ),
  weights_evidence = paste(
    'Empirical weight-at-age is used for fishery and AT survey data.',
    'Survey weight-at-age is derived from acoustic-trawl abundance-at-length,',
    'a length-weight relationship and age-length keys.'
  ),
  maturity_evidence = paste(
    'The model uses a fixed age-specific maturity vector estimated from',
    'summer AT samples of 494 female fish, multiplied by a fixed fecundity',
    'vector.'
  ),
  mortality_evidence = paste(
    'Natural mortality is age-specific with a Lorenzen pattern. The average',
    'M is estimated using a longevity-based prior.'
  ),
  timing_evidence = paste(
    'The assessment uses annual July-June model years; the summer AT index',
    'is at model month 1.6 in the 2023 model data file. The exact conversion',
    ''
  ),
  output_evidence = paste(
    'The adopted 2025 assessment reports age-1+ biomass of 61,737 mt',
    '(SD 41,422) for model year 2025 and 67,954 mt (SD 43,375) for model',
    'year 2026, plus recruitment and fishing-mortality/exploitation',
    'trajectories. Run-matched annual numeric N-at-age and F-at-age tables',
    'were not located.'
  ),
  detailed_source_url = paste0(
    'https://www.pcouncil.org/documents/2025/05/catch-only-stock-assessment-of-pacific-mackerel-scomber-japonicus-for-u-s-management-in-the-2025-26-and-2026-27-fishing-years.pdf; ',
    'https://repository.library.noaa.gov/view/noaa/67353; ',
    'https://www.govinfo.gov/content/pkg/FR-2025-08-25/pdf/2025-16233.pdf; ',
    'https://www.pcouncil.org/documents/2023/06/assessment-of-pacific-mackerel-scomber-japonicus-for-u-s-management-in-the-2023-24-and-2024-25-fishing-years.pdf; ',
    'https://www.pcouncil.org/documents/mackerel-2023-model-files-zip-file/; ',
    'https://www.fisheries.noaa.gov/species/pacific-mackerel'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10163 maps to the current U.S.-managed Pacific Coast',
    'unit, north of Punta Abreojos. The latest official assessment is the',
    'Council-adopted 2025 catch-only update. Its model retains age-composition',
    'and survey likelihoods from the 2023 benchmark while adding catch through',
    '2023. Catch, age compositions, weights, maturity, M, survey index and',
    'official biomass outputs are documented, so the unit is eligible for',
    'source curation.'
  ),
  notes = paste(
    'The 2025 assessment is a catch-only update built on the 2023 benchmark',
    'model; age-composition observations end in 2021. The model uses one',
    'combined U.S.-Mexico fishery, one AT survey, combined sexes, age groups',
    '0-8+, and annual July-June model years. Stock SMART reports a 2025 row',
    'with a 2022 biomass value, older model version, and a 2024 last-data-year;',
    'the detailed report and Council adoption record identify the latest run.',
    'Run inputs and model details are cached in',
    'source_cache/discovery_noaa_pacific_mackerel_2025/.'
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
  x$eligibility[i] == 'eligible' &&
  x$candidate_unit_id[i] == review$candidate_unit_id
if (new_entry || prior_screen) {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!all(matches_review)) {
  stop('Pacific mackerel has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
csv_row <- x[i, , drop = FALSE]
csv_row[] <- lapply(csv_row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(csv_row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA:10163 as a new eligible Pacific mackerel unit.\n')

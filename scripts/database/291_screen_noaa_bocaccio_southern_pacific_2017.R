path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10413', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Stock SMART 10413.', call. = FALSE)

review <- list(
  candidate_unit_id = 'noaa_bocaccio_southern_pacific_coast',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The fitted model uses catch and length compositions plus conditional',
    'age-at-length observations inherited from the 2015 assessment. More',
    'than 8,000 fish were aged, including nearly 3,000 from the NWFSC bottom-',
    'trawl survey. Ages 0-21 are represented. These are not direct marginal',
    'catch-at-age counts; native age-at-length and expansion records must be',
    'verified before reconstructing catch-at-age.'
  ),
  survey_age_evidence = paste(
    'The 2015 age data include nearly 3,000 samples from the NWFSC bottom-',
    'trawl survey, fitted as conditional age-at-length. The assessment also',
    'uses ten aggregate abundance indices; no age-specific abundance index',
    'is reported.'
  ),
  weights_evidence = paste(
    'The 2017 update retains the fixed length-weight relationship from the',
    '2015 assessment. An observed annual weight-at-age series was not',
    'reported; age-specific weights can be derived only from the documented',
    'growth and length-weight inputs.'
  ),
  maturity_evidence = paste(
    'Fixed maturity and fecundity relationships from the 2015 assessment',
    'are retained. The source describes them by length; an age-specific',
    'surface would be derived using the model growth relationship.'
  ),
  mortality_evidence = paste(
    'Natural mortality is estimated with a lognormal prior. The 2017 model',
    'has no age-, time- or sex-varying M.'
  ),
  timing_evidence = paste(
    'The population model is annual. Ten fishery-independent abundance',
    'indices are fitted; exact observation timing should be recovered from',
    'the native data and model documentation during source import.'
  ),
  output_evidence = paste(
    'The 2017 fit reports spawning output, recruitment and exploitation',
    'trajectories. The 2025 catch-only projection reports spawning output',
    'and stock status through 2036 but does not refit population states.',
    'Annual numeric N-at-age and F-at-age tables were not found.'
  ),
  detailed_source_url = paste0(
    'https://www.pcouncil.org/documents/2017/02/stock-assessment-update-status-of-bocaccio-sebastes-paucispinis-in-the-conception-monterey-and-eureka-inpfc-areas-for-2017.pdf; ',
    'https://www.pcouncil.org/documents/2017-bocaccio-model-files-zip-file-47-kb/; ',
    'https://www.pcouncil.org/documents/2025/08/g-3-attachment-18-catch-only-projection-for-bocaccio-in-2025.pdf/; ',
    'https://www.fisheries.noaa.gov/species/bocaccio; ',
    'https://www.fisheries.noaa.gov/action/amendment-37-pacific-coast-groundfish-fishery-management-plan-stock-definitions'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10413 identifies the Southern Pacific Coast unit.',
    'The latest fitted assessment is the 2017 update, using the 2015 model',
    'age-at-length data; the 2025 event is a catch-only projection that',
    'reuses the 2017 fit. Observed age-at-length data, aggregate indices,',
    'biology, M assumptions and population outputs are documented, so the',
    'unit is eligible for source curation.'
  ),
  notes = paste(
    'The 2017 assessed area is south of 43 degrees N to the U.S.-Mexico',
    'border. NOAA currently lists Southern Pacific Coast separately; the',
    '2026 Amendment 37 coastwide definition is proposed and remains under',
    'NMFS review. Do not merge this assessment with DFO British Columbia',
    'bocaccio or treat the proposed coastwide boundary as implemented. The',
    '2025 catch-only projection updates catch through 2024 and projections',
    'through 2036 but contains no new fitted age data. Sources are cached in',
    'source_cache/discovery_noaa_bocaccio_southern_pacific_2017/.'
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
  stop('Southern Pacific Coast bocaccio has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
csv_row <- x[i, , drop = FALSE]
csv_row[] <- lapply(csv_row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(csv_row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA:10413 as a new eligible Southern Pacific Coast bocaccio unit.\n')

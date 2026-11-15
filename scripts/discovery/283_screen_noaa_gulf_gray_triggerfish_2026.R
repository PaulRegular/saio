path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10062'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one NOAA Gulf gray triggerfish inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_gulf_gray_triggerfish',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'SEDAR 100 uses fleet-level landings and discards with commercial',
    'vertical-line and longline, and recreational, conditional age-at-length',
    'data. These are not direct catch-numbers-at-age observations. The DW-04',
    'and DW-07 source files provide fishery age and length data from 1999-2024;',
    'reconstructing catch at age would require an explicit composition and',
    'growth-based conversion. Years and fishery strata vary with sample-size',
    'cutoffs.'
  ),
  survey_age_evidence = paste(
    'The assessment fits aggregate annual abundance indices, including early',
    'SEAMAP summer-fall trawl (1987-2008), late SEAMAP summer-fall trawl',
    '(2009-2024), and G-FISHER video. SEAMAP trawl age and length samples',
    'were available for 2008-2024 (N=519), but the assessment fits survey',
    'length compositions rather than an age-composition likelihood. G-FISHER',
    'has length compositions but no empirical ages. An age-specific index',
    'would therefore be a documented reconstruction, not a native input.'
  ),
  weights_evidence = paste(
    'The assessment uses length-based biology and estimates growth internally',
    'from age-at-length data. Weight-at-age is not a native supplied likelihood',
    'input; deriving it would require the assessment length-weight relationship',
    'and estimated growth.'
  ),
  maturity_evidence = paste(
    'Maturity is modeled as a fixed function of length, not as a supplied',
    'maturity-at-age vector. Deriving maturity at age would require the',
    'assessment growth relationship and would be an explicit approximation.'
  ),
  mortality_evidence = paste(
    'The reviewed assessment fixes target natural mortality at 0.36 per year',
    'and scales it by age with a Lorenzen relationship through modeled age 15.',
    'The review-panel revised base model fixes M at 0.36 and estimates stock-',
    'recruitment steepness at about 0.422.'
  ),
  timing_evidence = paste(
    'The model covers 1945-2024, starts at age 0, and uses age-composition bins',
    '0-10+ while modeling population ages through 15. It assumes continuous',
    'fishing through the year and July 1 settlement. Exact within-year timing',
    'fractions for the abundance surveys were not established in the reviewed',
    'sources.'
  ),
  output_evidence = paste(
    'The review-panel revised-base tables report annual biomass, SSB in metric',
    'tons, exploited abundance ages 1+, age-0 recruitment, and SSB ratio for',
    '1945-2024. Annual F is reported as a harvest rate (biomass killed divided',
    'by age-1+ biomass), not instantaneous F-at-age. The published report does',
    'not provide numeric annual N-at-age or F-at-age arrays; the tabulated',
    'series are point estimates.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-100-gulf-triggerfish/;',
    'https://sedarweb.org/documents/sedar-100-gulf-gray-triggerfish-final-stock-assessment-report/;',
    'https://sedarweb.org/documents/sedar-100-dw-04-gulf-of-america-gray-triggerfish-balistes-capriscus-length-and-age-compositions-from-the-recreational-fishery/;',
    'https://sedarweb.org/documents/sedar-100-dw-05-commercial-landings-of-gulf-of-america-gray-triggerfish-balistes-capriscus-from-1949-2024/;',
    'https://sedarweb.org/documents/sedar-100-dw-07-gulf-of-america-gray-triggerfish-balistes-capriscus-preliminary-length-and-age-compositions-for-the-commercial-handline-and-longline-fisheries/;',
    'https://sedarweb.org/documents/sedar-100-dw-13-length-and-age-compositions-of-gulf-gray-triggerfish-balistes-capriscus-collected-in-association-with-fishery-dependent-projects/;',
    'https://sedarweb.org/documents/sedar-100-dw-14-a-review-of-gray-triggerfish-balistes-capriscus-age-length-data-in-the-gulf-of-america-1999-2024/;',
    'https://sedarweb.org/documents/sedar-100-dw-16-gray-triggerfish-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-america/;',
    'https://sedarweb.org/documents/sedar-100-cie-review-report-fisch/;',
    'https://www.noaa.gov/information-technology/sedar-100-gulf-gray-triggerfish;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10062'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'Eligible for source curation: the completed SEDAR 100 assessment report',
    'and supporting data papers provide removals, fishery conditional age-at-',
    'length observations, aggregate abundance indices, survey age samples,',
    'biological relationships, mortality assumptions, and comparable annual',
    'population outputs. Catch-at-age, age-specific survey indices, weight-at-',
    'age, and maturity-at-age are not direct inputs and would require explicit',
    'reconstruction, so this is not yet a translation-readiness decision. The',
    'SEDAR page says the assessment was completed in September 2026, but the',
    'NOAA peer-review listing has no actual dissemination date and formal',
    'management adoption was not confirmed in the reviewed sources.'
  ),
  notes = paste(
    'NOAA Stock SMART lists an older 2020 assessment year; the latest detailed',
    'source is SEDAR 100, with data through 2024. The assessment is one',
    'Gulf-wide unit (sexes combined), modeled from 1945 to 2024 in Stock',
    'Synthesis 3.30.21.00. The final report contains the assessment-process',
    'model and a review-panel revised base model. No numerical records were',
    'imported and no selected-batch decision has been made.'
  )
)

matches_review <- all(vapply(names(review), function(column) {
  value <- as.character(x[[column]][i])
  expected <- as.character(review[[column]])
  if (is.na(value)) value <- ''
  if (is.na(expected)) expected <- ''
  identical(value, expected)
}, logical(1L)))
if (x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed') {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!matches_review) {
  stop('Candidate row has a conflicting prior review.', call. = FALSE)
}
if (is.na(x$matched_stock_id[i])) x$matched_stock_id[i] <- ''

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
tmp <- tempfile(fileext = '.csv')
row <- x[i, , drop = FALSE]
row[] <- lapply(row, as.character)
write.csv(row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Gulf gray triggerfish as eligible for source curation; catch-at-age and age-specific survey data require documented reconstruction.\n')

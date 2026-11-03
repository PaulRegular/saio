path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10207'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one NOAA Gulf greater amberjack inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_gulf_greater_amberjack',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The SEDAR 70 Stock Synthesis model covers ages 0-10+ and four fleets.',
    'Total commercial catches are reported by weight and recreational catches',
    'by numbers; the model also includes discards. Fishery age compositions',
    'are available for commercial handline in 2001-2017, commercial longline',
    'in 2009, 2011, and 2013-2014, recreational charter/private in 2002-2018,',
    'and headboat in 1994-2016. WP-13 weights age samples to final length',
    'compositions and reports figures and methods, but not the numerical',
    'fleet-year-age matrices needed to recover exact catch-at-age.'
  ),
  survey_age_evidence = paste(
    'The production model uses one combined fishery-independent video index',
    'for 1995-1997, 2002, and 2004-2018, plus commercial longline, headboat,',
    'and charter/private indices. The Panama City video survey index is an',
    'aggregate MaxN-based index; its documented age-based indices target other',
    'species, and no greater-amberjack survey age-composition likelihood was',
    'verified. Survey age samples are not a substitute for annual survey ages.'
  ),
  weights_evidence = paste(
    'A fixed weight-length relationship is used to convert length to biomass;',
    'weight-at-age is generated within Stock Synthesis using growth. An',
    'observed annual weight-at-age series was not verified in the reviewed',
    'sources.'
  ),
  maturity_evidence = paste(
    'Mature-female biomass defines SSB. The model uses fixed age-specific',
    'maturity based on a logistic length relationship with 50% maturity at',
    '82.7 cm; age-0 fish are excluded from spawning biomass.'
  ),
  mortality_evidence = paste(
    'Natural mortality is fixed using an age-specific Lorenzen curve scaled',
    'to M=0.28 per year for ages 3+; the source report provides the age',
    'schedule. M is not estimated in the SEDAR 70 base model.'
  ),
  timing_evidence = paste(
    'The assessment assumes fishing and spawning are continuous through the',
    'year. The Panama City video survey is sampled May-November, mainly',
    'June-August; an exact annual timing fraction for the combined index was',
    'not established in this screen.'
  ),
  output_evidence = paste(
    'The operational assessment reports annual total abundance, total biomass,',
    'and mature-female SSB for 1950-2018 with 95% confidence intervals, plus',
    'recruitment and F summaries. Reported F is a harvest rate, not',
    'instantaneous F-at-age. Numeric annual population N-at-age and F-at-age',
    'arrays were not verified.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-70/;',
    'https://sedarweb.org/documents/sedar-70-gulf-of-mexico-greater-amberjack-final-stock-assessment-report/;',
    'https://sedarweb.org/documents/sedar-70-gulf-of-mexico-greater-amberjack-executive-summary-report/;',
    'https://sedarweb.org/documents/sedar-70-wp-07-indices-of-abundance-for-greater-amberjack-seriola-dumerili-using-combined-data-from-three-independent-video-surveys/;',
    'https://sedarweb.org/documents/sedar-70-wp-10-gulf-of-mexico-greater-amberjack-seriola-dumerili-growth-model-for-sedar-70-operational-assessment/;',
    'https://sedarweb.org/documents/sedar-70-wp-12-greater-amberjack-seriola-dumerili-findings-from-the-nmfs-panama-city-laboratory-camera-trap-fishery-independent-survey-2006-2018/;',
    'https://sedarweb.org/documents/sedar-70-wp-13-gulf-of-mexico-greater-amberjack-seriola-dumerili-commercial-and-recreational-length-and-age-compositions/;',
    'https://sedarweb.org/documents/sedar-70-wp-11-standardized-catch-rate-indices-for-greater-amberjack-seriola-dumerili-during-1990-2018-by-the-u-s-gulf-of-mexico-vertical-line-and-longline-fisheries/;',
    'https://www.fisheries.noaa.gov/s3/2024-01/GAJ-Framework-Action-508-FINAL.pdf;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10207'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'No matching Gulf greater amberjack record was found in the canonical',
    'database; the unit is provisionally new. SEDAR 70 is an operational',
    'assessment completed in 2020, accepted by the Gulf Council SSC as',
    'appropriate for management advice, and remains the assessment cited by',
    'the 2023 framework action. It supplies comparable annual population',
    'outputs. Eligibility remains unresolved because exact numeric fishery',
    'age-composition inputs and a greater-amberjack survey age composition',
    'were not recovered; the official assessment report publishes age',
    'composition figures, not the numerical matrices.'
  ),
  notes = paste(
    'NOAA Stock SMART row 10207 lists assessment year 2021; the detailed',
    'SEDAR 70 fit uses data through terminal year 2018. The 2023 framework',
    'action identifies SEDAR 70 (2020) as the assessment informing current',
    'management. No canonical assessment or numerical values were added.'
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
cat('Screened NOAA Gulf greater amberjack; age-composition source readiness remains unresolved.\n')
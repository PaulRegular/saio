path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10063'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one NOAA South Atlantic gray triggerfish inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_south_atlantic_gray_triggerfish',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 SEDAR 82 research-track BAM uses commercial and recreational',
    'landings and discards with age and length compositions. Fishery age bins',
    'were 1-5+ during 1982-2014 and 1-8+ from 2015; they are compositions,',
    'not observed catch numbers-at-age. The AW01/AW02 papers document the',
    'fishery age and length inputs.'
  ),
  survey_age_evidence = paste(
    'The assessment uses one combined fishery-independent index from the',
    'SERFS chevron-trap and related trap-video surveys. DW05 provides annual',
    'index and age/length compositions for 1990-2021, with no survey in 2020.',
    'The review found the fitted index and age-composition data adequate; the',
    'survey age compositions can support an age-specific reconstruction.'
  ),
  weights_evidence = paste(
    'Growth information is estimated outside the assessment model and used',
    'with age-specific reproductive parameters. The assessment reports egg',
    'production rather than conventional biomass-based SSB; source weight-at-',
    'age inputs were not established in this screen.'
  ),
  maturity_evidence = paste(
    'Maturity and fecundity are age-specific components of the egg-production',
    'measure. The report describes mature-female proportions, batch fecundity,',
    'and spawning events by age; these are not a conventional maturity-only',
    'SSB calculation.'
  ),
  mortality_evidence = paste(
    'Natural mortality is age-dependent and time-invariant, derived using a',
    'life-history meta-analysis and the selected maximum age of 16 years.',
    'The review documents sensitivity of biomass and F outputs to this choice.'
  ),
  timing_evidence = paste(
    'The research-track model covers 1982-2021. The chevron-trap survey is',
    'conducted mainly May-September, with limited sampling outside that',
    'window. The model timing fraction for the combined annual index was not',
    'established in this screen.'
  ),
  output_evidence = paste(
    'The 2024 research-track assessment and peer-review report provide annual',
    'F and egg-production trajectories, reference points, and stock-status',
    'diagnostics. Egg production is called SSB in the report but is not',
    'biomass in tonnes. Numeric annual N-at-age and F-at-age output tables were',
    'not verified in this screen.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-82/;',
    'https://sedarweb.org/documents/sedar-82-south-atlantic-gray-triggerfish-final-stock-assessment-report/;',
    'https://sedarweb.org/documents/sedar-82-dw05-gray-triggerfish-fishery-independent-index-of-abundance-and-lengthage-compositions-in-us-south-atlantic-waters-based-on-a-chevron-trap-survey-1990-2021/;',
    'https://sedarweb.org/documents/sedar-82-dw08-nominal-length-and-age-distributions-of-southeast-u-s-atlantic-gray-triggerfish-balistes-capriscus-from-recreational-and-commercial-fisheries-revised-9-21-2022/;',
    'https://sedarweb.org/documents/sedar82_aw01_south-atlantic-u-s-gray-triggerfish-balistes-capriscus-age-and-length-composition-from-the-recreational-fisheries-pdf/;',
    'https://sedarweb.org/documents/sedar82_aw02_south-atlantic-u-s-gray-triggerfish-balistes-capriscus-age-and-length-composition-from-the-commercial-fisheries-pdf/;',
    'https://sedarweb.org/documents/sedar-82-cie-reviewer-report-holmes/;',
    'https://www.noaa.gov/information-technology/sedar-82-south-atlantic-gray-triggerfish-id467;',
    'https://www.fisheries.noaa.gov/species/gray-triggerfish;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10063'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 2024 SEDAR 82 research-track assessment has detailed age-based',
    'inputs and outputs and is suitable for further source review. However,',
    'the peer-review panel described it as suitable to carry forward to an',
    'operational assessment; NOAA lists no actual dissemination date, and its',
    'species page still says no formal South Atlantic assessment has been',
    'conducted. Current production/adoption status is therefore unresolved.',
    'Do not import this research-track run as current official production',
    'values unless later agency documentation confirms its use.'
  ),
  notes = paste(
    'NOAA Stock SMART row 10063 lists 2016. The newer SEDAR 82 run is a',
    '2024 Research Track assessment with data through 2021, not confirmed as',
    'an operational assessment. Its egg-production definition of SSB differs',
    'from biomass SSB. No canonical record or numerical data were changed.'
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
cat('Screened NOAA South Atlantic gray triggerfish; production/adoption status remains unresolved.\n')

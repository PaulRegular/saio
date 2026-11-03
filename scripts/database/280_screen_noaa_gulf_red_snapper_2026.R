path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10230'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one NOAA Gulf red snapper inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_gulf_red_snapper',
  official_stock_id = '10230',
  inventory_assessment_year = 2021,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The final 2026 SEDAR 98 Stock Synthesis assessment uses fleet- and area-specific',
    'catch totals with year-specific conditional age-at-length compositions for',
    'commercial and recreational fleets. These are age-disaggregated composition',
    'inputs, not a standalone observed catch-numbers-at-age table. Commercial',
    'landings are reported in whole-weight pounds and converted to metric tons;',
    'recreational landings are modeled in thousands of fish.'
  ),
  survey_age_evidence = paste(
    'The assessment combines aggregate annual survey indices with age compositions',
    'for SEAMAP fall trawl, G-FISHER video, and SEFSC bottom-longline surveys.',
    'Some survey age compositions are converted from length data using age-length',
    'keys; these are composition inputs, not separate age-specific abundance indices.'
  ),
  weights_evidence = paste(
    'Fixed externally estimated growth curves and fixed length-weight relationships',
    'are used to calculate weight at age. Spatial growth curves come from the',
    'SEDAR 74 life-history work; length-weight relationships are common across areas.'
  ),
  maturity_evidence = paste(
    'Age-based maturity is modeled with fixed, time-invariant area-specific',
    'logistic curves. Central and East use the East-area maturity estimates.'
  ),
  mortality_evidence = paste(
    'Natural mortality is a fixed age-specific Lorenzen vector, scaled from',
    'M = 0.104 per year; age-0 and age-1 mortality are fixed at 2.0 and 1.2',
    'per year. The vector is constant across years and areas.'
  ),
  timing_evidence = paste(
    'The model is annual and distinguishes seasonal survey programs (including',
    'summer and fall trawl surveys). A single fractional survey timing for a',
    'tinyAM representation is not specified in the reviewed report.'
  ),
  output_evidence = paste(
    'The final report gives annual, area-specific total biomass, exploitable',
    'biomass, SSB, age-1+ abundance, age-0 recruitment, and exploitation rates',
    'for 1950-2023. It does not publish numeric N-at-age or F-at-age tables;',
    'exploitation rate is not interchangeable with instantaneous F-at-age.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/documents/sedar-98-gulf-red-snapper-final-stock-assessment-report/;',
    'https://sedarweb.org/documents/sedar-98-dw-06-gulf-of-mexico-red-snapper-lutjanus-campechanus-commercial-landings-preliminary-length-and-age-compositions/;',
    'https://sedarweb.org/documents/sedar-98-dw-07-gulf-of-mexico-red-snapper-lutjanus-campechanus-length-and-age-compositions-from-the-recreational-fishery/;',
    'https://sedarweb.org/documents/sedar-98-dw-09-description-of-red-snapper-lutjanus-campechanus-age-data-collected-from-the-northern-gulf-of-mexico-from-1980-2023/'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 2026 SEDAR 98 final assessment report is the latest detailed run located',
    'for the current Gulf management unit; its terminal data year is 2023 and it',
    'uses an age-structured three-area Stock Synthesis model. Public sources document',
    'catch totals, fishery age-at-length compositions, age-composition survey inputs,',
    'fixed age-based biology, and comparable population outputs. It is eligible for',
    'source curation, with the lack of published age-specific population surfaces',
    'recorded as an output limitation. Council SSC review remains pending in the',
    'report. Stock SMART metadata still list 2021 and are not current for this run.'
  ),
  notes = paste(
    'The model covers the Gulf unit in West, Central, and East assessment areas;',
    'these are model areas, not separate candidate stocks. This unit is distinct',
    'from NOAA:10231, Red snapper - Southern Atlantic Coast. The final SEDAR 98',
    'report and supporting age-data papers are cached under',
    'source_cache/discovery_noaa_gom_red_snapper_2026/ with retrieval dates and',
    'SHA-256 checksums. No canonical numerical records were imported.'
  )
)

matches_review <- all(vapply(names(review), function(column) {
  identical(as.character(x[[column]][i]), as.character(review[[column]]))
}, logical(1L)))
if (x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed') {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!matches_review) {
  stop('Candidate row has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE)
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Gulf red snapper; current SEDAR 98 age-structured run is eligible for source curation.\n')

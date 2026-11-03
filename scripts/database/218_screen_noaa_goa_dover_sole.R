# Screen the NOAA Gulf of Alaska Dover sole candidate against its 2023 full assessment.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10021', x$candidate_id)
if (is.na(i)) stop('Expected NOAA GOA Dover sole row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'ineligible')
} else if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Microstomus pacificus'
x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2023 model includes fishery catch biomass in tonnes for 1978-2023 and',
  'fishery length compositions for 1991-2023. It contains no fishery age',
  'composition; the assessment states that no otoliths were collected from',
  'catches. Catch-at-age cannot be reconstructed from source fishery inputs',
  'without transferring an age-length relationship from survey samples or',
  'using model-estimated growth.'
)
x$survey_age_evidence[i] <- paste(
  'The GOA survey provides aggregate biomass in tonnes (triennial 1984-1999,',
  'biennial 2001-2023), survey length compositions, and conditional',
  'age-at-length samples for 1993, 1996, 1999, and 2003-2021. Combining',
  'same-year survey length and conditional age-at-length observations can',
  'support a marginal survey age composition; the conditional samples are',
  'not themselves an independent age-specific abundance index.'
)
x$weights_evidence[i] <- paste(
  'The model derives weight-at-age from estimated growth and a weight-length',
  'relationship. No observed fixed weight-at-age vector is listed among the',
  'assessment inputs.'
)
x$maturity_evidence[i] <- paste(
  'The model uses an age-based logistic maturity relationship; it is not a',
  'fixed maturity-at-age input vector.'
)
x$mortality_evidence[i] <- paste(
  'The 2023 Model 19.3.1 estimates sex-specific natural mortality in',
  'historical and 2014-2023 time blocks. The 2023 report gives point',
  'estimates and uncertainty summaries.'
)
x$timing_evidence[i] <- paste(
  'The native data file records survey month 6 (June); the assessment uses',
  'spawning month 5. These are distinct timings. A tinyAM survey fraction',
  'would need to be documented as a translation approximation.'
)
x$output_evidence[i] <- paste(
  'The 2023 SAFE tables report age-3+ biomass, female spawning biomass,',
  'age-3 and age-0 recruitment, and M estimates. The report says a separate',
  'numbers-at-age time series is available, but that file was not recovered;',
  'the pinned repository contains the assessment inputs and 2025 projection',
  'files, not a 2023 Report.sso or age-specific output table.'
)
x$detailed_source_url[i] <- 'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOAdeepflat.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'NOAA Stock SMART ID 10021 is a new Gulf of Alaska unit, distinct from',
  'the existing US West Coast Dover sole unit. The official 2023 Model',
  '19.3.1 is',
  'age- and sex-structured, but it fits fishery length compositions and has',
  'no fishery ages. A catch-at-age series would require transferring survey',
  'age-at-length samples to fishery observations or using fitted growth;',
  'neither conversion is verified as a source-supported catch input. Mark',
  'ineligible for the current age-input screen; retain its verified source',
  'information for possible future use.'
)
x$notes[i] <- paste(
  'The latest full assessment is the 2023 Model 19.3.1 update using data',
  'through September 2023. The 2025 harvest projection used this fitted',
  'assessment with updated catches. The 2023 report identifies Stock',
  'Synthesis 3.30.21, while the pinned CIE accepted-run files identify',
  '3.30.13 in their headers; record this version discrepancy. See',
  'discovery/source_reviews/noaa_goa_dover_sole.md.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Gulf:American Plaice - NAFO 4T'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_dfo_platessoides_4t' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Gulf 4T American plaice identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The 2016 VPA uses commercial catch-at-age including estimated discards, ages 4-16+, ',
  'for 1976-2015; values are in thousands of fish.'
)
x$survey_age_evidence[i] <- paste0(
  'The DFO RV and mobile-gear sentinel survey inputs are age-specific abundance indices ',
  'in thousands of fish. The RV index omits 2003 because an uncalibrated vessel was used; ',
  'the sentinel index covers 2003-2015.'
)
x$weights_evidence[i] <- paste0(
  'January 1 population weights-at-age are reported in kg/fish for ages 4-16+; ',
  'the 2003 age-16+ value of zero is retained and flagged in the source review.'
)
x$maturity_evidence[i] <- paste0(
  'Annual maturity-at-age is reported for 1976-2015; median post-1996 maturity-curve ',
  'coefficients are applied to 1976-1996 and 2012 maturity is carried forward through 2015.'
)
x$mortality_evidence[i] <- paste0(
  'The VPA estimates separate log-M random walks for ages 4-9 and 10+, with fixed ',
  'annual log-increment SD 0.075 and initial-M means 0.6 and 0.3.'
)
x$timing_evidence[i] <- paste0(
  'Both surveys are September surveys; 0.75 is used as a within-year timing approximation ',
  'because annual sampling dates are not reported.'
)
x$output_evidence[i] <- paste0(
  'Official outputs include N-at-age for 1976-2015, age-4 recruitment derived from N, ',
  'SSB medians and intervals, and digitized age-group F/M series. Several M points and ',
  'part of F-at-age are unavailable; digitized values are approximate.'
)
x$detailed_source_url[i] <- paste0(
  'https://waves-vagues.dfo-mpo.gc.ca/Library/365839.pdf; ',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current Southern Gulf of St. Lawrence 4T American plaice unit. The ',
  'detailed 2016 VPA provides the age-based inputs and comparable population/mortality ',
  'outputs needed for screening. The 2025 indicator update is a separate biomass indicator, ',
  'not a replacement assessment. Canonical output coverage remains partial.'
)
x$notes[i] <- paste0(
  'See source_reviews/ck_dfo_platessoides_4t.md; the 2016 VPA ',
  'is the latest detailed population assessment located, while the 2025 update is indicator-only.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened the matched DFO Gulf 4T American plaice assessment.\n')

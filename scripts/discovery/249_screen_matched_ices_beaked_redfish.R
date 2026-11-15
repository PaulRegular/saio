path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:reb.27.1-2'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_afwg_mentella_deep_1_2' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Northeast Arctic beaked redfish identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The current 2026 JRN-AFWG SCAA report gives total catch-at-age for 1992-2025, ages 6-19+, ' ,
  'and a separately reported pelagic component; exact two-fleet input assembly remains unresolved.'
)
x$survey_age_evidence[i] <- paste0(
  'The report supplies an ecosystem index for ages 2-15, winter bottom-trawl indices for ages ' ,
  '2-15, and a Russian autumn series by year class and ages 0-11. Published observations use ' ,
  'different bases and their source likelihood selections are not fully resolved.'
)
x$weights_evidence[i] <- paste0(
  'Fixed model stock and catch weights are reported for ages 6-19+ in kg per fish.'
)
x$maturity_evidence[i] <- paste0(
  'Fixed model maturity proportions are reported for ages 6-19+.'
)
x$mortality_evidence[i] <- paste0(
  'The 2026 production assessment fixes M at 0.05 per year for ages 2-19+.'
)
x$timing_evidence[i] <- paste0(
  'The 2018 framework reports survey sampling fractions of 0.12 winter, 0.75 ecosystem, ' ,
  '0.90 Russian autumn and 0.67 deep pelagic; unit scaling and application to all 2026 inputs ' ,
  'are not verified.'
)
x$output_evidence[i] <- paste0(
  'The 2026 report gives N-at-age, derived F-at-age, SSB, total biomass, recruitment and F ' ,
  'summaries through 2025. Numerical uncertainty is not supplied; age-19+ N sums older cohorts.'
)
x$detailed_source_url[i] <- paste0(
  'https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5; ' ,
  'https://doi.org/10.17895/ices.pub.19291142.v1; ' ,
  'https://www.hi.no/en/hi/nettrapporter/imr-vniro-en-2026-3'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'The ICES SID entry maps to the same Northeast Arctic beaked redfish stock code, while the ' ,
  'current detailed production run is JRN-AFWG 2026 rather than an ICES-run assessment. Age-based ' ,
  'inputs, fixed M and age/aggregate outputs are recovered, but the two-fleet catch assembly, ' ,
  'some survey likelihood selections and ecosystem index scaling remain unresolved.'
)
x$notes[i] <- paste0(
  'See source_reviews/ck_ices_afwg_mentella_deep_1_2.md. Do not treat ' ,
  'the 2020 year in the ICES SID row as the latest detailed run, and do not convert the framework ' ,
  'ecosystem scaling coefficient until its source units are reconciled.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched Northeast Arctic beaked redfish; run-input assembly remains unresolved.\n')

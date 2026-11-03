path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:her.27.20-24'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ices_herring_western_baltic' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing western Baltic herring identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 SAM run contains commercial catch-at-age for 1991-2025, ages 0-8+, ' ,
  'with age 8 as the plus group.'
)
x$survey_age_evidence[i] <- paste0(
  'The native run contains 372 finite survey observations across HERAS, GERAS, IBTS/BITS Q1 ' ,
  'and N20, with source age ranges and missing observations retained. HERAS has five missing ' ,
  'observations in 1999.'
)
x$weights_evidence[i] <- paste0(
  'Annual stock and catch weights are supplied on the official age structure.'
)
x$maturity_evidence[i] <- paste0(
  'Maturity is fixed over time and age-specific.'
)
x$mortality_evidence[i] <- paste0(
  'Natural mortality is fixed, time-invariant and age-specific.'
)
x$timing_evidence[i] <- paste0(
  'The SAM fit supplies the survey sampling fractions; annual F and M spawning fractions ' ,
  'are 0.168 and 0.25, respectively.'
)
x$output_evidence[i] <- paste0(
  'The native fit and report provide N-at-age, F-at-age, recruitment, SSB, Fbar and total ' ,
  'stock biomass. Official outputs agree with the report tables after expanding shared F states.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.31538287; ' ,
  'https://sg.ices.dk/ViewSourceData.aspx?key=21294; ' ,
  'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/WBSS_HAWG_2026/run/model.RData'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current western Baltic spring-spawning herring unit and official 2026 HAWG SAM run. ' ,
  'Age-disaggregated commercial catch, four survey series, annual biology, fixed M, timing and ' ,
  'official population outputs are verified. The aggregates population and ' ,
  'observation ages to resolve the differing survey plus groups; this is recorded separately.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_herring_western_baltic_2026.md. The official ' ,
  'population model is ages 0-8+, whereas the documented uses ages 0-5+; ' ,
  'preserve that as a translation approximation, not a source-data change.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched western Baltic herring using the official 2026 SAM run.\n')

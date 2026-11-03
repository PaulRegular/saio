path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:sol.27.7d'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_wgnssk_solea_ns_7d' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing ICES 7.d sole identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 SAM assessment reports combined catch numbers-at-age for 1982-2025, ' ,
  'ages 1-11+, with age 11 as the plus group.'
)
x$survey_age_evidence[i] <- paste0(
  'The assessment includes age-specific UK BTS indices for ages 1-6, UK YFS age 1, and ' ,
  'French YFS age 1. Three commercial LPUE biomass indices are also documented, but are ' ,
  ''
)
x$weights_evidence[i] <- paste0(
  'Catch and stock weights-at-age cover 1982-2025; stock weights for 1982-2003 are ' ,
  'identified as reconstructed in the source report.'
)
x$maturity_evidence[i] <- paste0(
  'The report supplies an age-specific maturity ogive for ages 0-11+.'
)
x$mortality_evidence[i] <- paste0(
  'Natural mortality is fixed at 0.1 per year.'
)
x$timing_evidence[i] <- paste0(
  'The 2025 stock annex gives survey timing windows of 0.5-0.75.' ,
  'uses their midpoint, 0.625, as an explicit approximation.'
)
x$output_evidence[i] <- paste0(
  'The 2026 report gives N-at-age, F-at-age and SSB-at-age for 1982-2025, plus aggregate ' ,
  'recruitment, SSB, landings, discards and Fbar ages 3-7 with intervals. Independent ' ,
  'N/F/biology-derived SSB agrees with the annual SSB series within 0.02%; age-state ' ,
  'uncertainty is unavailable.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.32676345.v2; ' ,
  'https://doi.org/10.17895/ices.pub.29085995.v4; ' ,
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23777; ' ,
  'https://github.com/ices-advice/2026_sol.27.7d/tree/468baf44b275c47923b0485cd67d86beb59a4b39/2026_sol.27.7d_assessment'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current ICES 7.d sole unit and its detailed 2026 assessment. Age-disaggregated ' ,
  'catch and tuning indices, biology, fixed M, timing windows and official population outputs are ' ,
  'recovered. Commercial aggregate biomass indices and SAM-specific variance sharing are not ' ,
  'those are translation limits rather than missing age inputs.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_sole_eastern_channel_7d_2026.md. The source ' ,
  '' ,
  'is a reason to alter the official inputs or suppress the source-based eligibility classification.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES 7.d sole as eligible for a source-based translation.\n')

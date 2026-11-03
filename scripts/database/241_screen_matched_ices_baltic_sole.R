path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:sol.27.20-24'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_wgbfas_solea_ns_iiia_22_24' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Baltic sole identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 SAM assessment reports catch-at-age for 1984-2025, ages 2-9+, ' ,
  'in thousand fish; discards are excluded.'
)
x$survey_age_evidence[i] <- paste0(
  'Age-specific Q4 survey indices cover ages 1-9 in 2004-2024, gillnet CPUE ages 2-9 ' ,
  'in 1994-2007, and trawl CPUE ages 2-6 in 1987-2008. Source scales are retained; ' ,
  'exact timing and observation precision are not reported.'
)
x$weights_evidence[i] <- paste0(
  'Stock weights cover ages 2-9+ in 1984-2025; source conversion from the printed table ' ,
  'is documented in the assessment review.'
)
x$maturity_evidence[i] <- paste0(
  'The 2026 stock annex documents fixed, knife-edged maturity at age 3.'
)
x$mortality_evidence[i] <- paste0(
  'Natural mortality is fixed at 0.1 per year.'
)
x$timing_evidence[i] <- paste0(
  'Exact tuning-series sampling times are not labelled in recovered source tables; ' ,
  'a tinyAM timing approximation must be identified explicitly.'
)
x$output_evidence[i] <- paste0(
  'The 2026 report provides fitted N-at-age and F-at-age for 1984-2025 and aggregate ' ,
  'recruitment, SSB, Fbar and total stock biomass; age-specific uncertainty is unavailable.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.32455056.v3; ' ,
  'https://doi.org/10.17895/ices.pub.29210012.v2; ' ,
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21317'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current ICES sole 20-24 unit and 2026 SAM run. Catch-at-age, age-specific ' ,
  'survey indices, stock weights, fixed M and maturity, plus fitted age-specific outputs, are ' ,
  'recovered. The exact survey timing, precision settings and native run object remain unavailable ' ,
  'and must be treated as translation approximations.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_sole_20_24_2026.md. The 2026 run is ' ,
  'the latest detailed assessment; retain the 2025 run as a separate historical record.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES Baltic sole using its official 2026 assessment.\n')

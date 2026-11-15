path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:spr.27.22-32'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ices_sprat_baltic' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Baltic sprat identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 SAM assessment reports aggregate catch-at-age for 1974-2025, ' ,
  'ages 1-8 with age 8 as the plus group, in thousands of fish.'
)
x$survey_age_evidence[i] <- paste0(
  'Four age-specific tuning fleets are documented: October BIAS for different area/year ' ,
  'periods, May BASS, and an October age-0 acoustic series shifted to age 1 in the following ' ,
  'year. Low-coverage and overlapping observations are excluded as documented in the review.'
)
x$weights_evidence[i] <- paste0(
  'Year- and age-specific catch and stock weights cover 1974-2025; they are assumed equal.'
)
x$maturity_evidence[i] <- paste0(
  'Maturity is fixed over time at 0.17 at age 1, 0.93 at age 2 and 1.0 at ages 3-8.'
)
x$mortality_evidence[i] <- paste0(
  'Natural mortality is supplied by year and age and varies with cod predation; 2025 M is ' ,
  'assumed equal to 2024.'
)
x$timing_evidence[i] <- paste0(
  'The assessment places 40% of F and M before spawning; survey times are represented by ' ,
  'month-based approximations of 0.8 for October and 0.375 for May.'
)
x$output_evidence[i] <- paste0(
  'The report provides N-at-age, F-at-age, recruitment, SSB and Fbar. It does not report ' ,
  'fitted q, fitted observation predictions or age-specific N/F uncertainty; aggregate ' ,
  'low/high interval confidence levels are unspecified.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.32455056; ' ,
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22378'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current ICES Baltic sprat unit and detailed 2026 SAM assessment. ' ,
  'Age-disaggregated catch, four age-specific survey fleets, annual biology and M, plus ' ,
  'official population outputs, are represented in the canonical database. Published ' ,
  'sampling times are approximated; q and age-specific uncertainty are unavailable.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_sprat_baltic.md. The 2026 row is an ' ,
  'intermediate-year estimate using an F assumption, not a full catch-data year.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES Baltic sprat using its official 2026 SAM assessment.\n')

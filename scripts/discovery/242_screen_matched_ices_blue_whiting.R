path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:whb.27.1-91214'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ices_bluewhiting_northeast_atlantic' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Northeast Atlantic blue whiting identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 SAM fit contains commercial catch numbers-at-age for 1981-2026, ' ,
  'ages 1-10+, in thousands of fish.'
)
x$survey_age_evidence[i] <- paste0(
  'The IBWSS survey index contains numbers-at-age for 2004-2026, ages 1-8, in millions ' ,
  'of fish; no observations occur in 2010 or 2020. Survey timing is 0.245 of the year.'
)
x$weights_evidence[i] <- paste0(
  'Annual stock-weight and catch-weight surfaces are supplied for the model age range.'
)
x$maturity_evidence[i] <- paste0(
  'A time-invariant maturity ogive is supplied for the model age range.'
)
x$mortality_evidence[i] <- paste0(
  'Natural mortality is fixed at 0.2 per year for all modeled ages.'
)
x$timing_evidence[i] <- paste0(
  'The IBWSS timing is 0.245 of the year.'
)
x$output_evidence[i] <- paste0(
  'The native official fit reports age-specific N, F and fixed M, SSB, total biomass, ' ,
  'recruitment, Fbar, q and fitted-observation predictions. At-age standard errors are ' ,
  'conditional log-state errors; aggregate intervals are available.'
)
x$detailed_source_url[i] <- paste0(
  'https://www.hafogvatn.is/static/extras/images/34_whb_2026_1_advice_en.html; ' ,
  'https://www.hafogvatn.is/static/extras/images/34_whb_2026_1_techreport_en.html; ' ,
  'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/BW-2026/run/model.RData'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current ICES blue whiting unit and the official BW-2026 SAM fit. ' ,
  'The native fit supplies age-disaggregated catch and survey inputs, biological surfaces, ' ,
  'survey timing and official population/mortality outputs. The fitted model converged with ' ,
  'a positive-definite Hessian; age-specific reported errors remain conditional.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_bluewhiting_northeast_atlantic_2026.md. ' ,
  'Survey input is in millions while catch is in thousands; preserve these distinct source units. ' ,
  'The advice-year recruitment adjustment is not substituted for fitted recruitment.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES blue whiting using the official 2026 SAM fit.\n')

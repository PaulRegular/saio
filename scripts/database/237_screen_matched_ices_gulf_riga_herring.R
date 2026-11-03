path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:her.27.28'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_wgbfas_harengus_bs_28_1' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Gulf of Riga herring identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 SAM run uses residual catch-at-age for 1977-2025, ages 0-8+, in ',
  'thousand fish, including the report-described 28.2 stock catch.'
)
x$survey_age_evidence[i] <- paste0(
  'The GRAHS acoustic tuning index is age-specific for ages 1-8+ in 1999-2025 on its ',
  'native scale; the model object retains predictions and observation-level data.'
)
x$weights_evidence[i] <- paste0(
  'Annual stock, catch, discard and landings weights are recovered from the fitted SAM data; ',
  'stock weights equal catch weights because spawning-time weights were unavailable.'
)
x$maturity_evidence[i] <- paste0(
  'Maturity is fixed for 1977-1994 and GAM-smoothed annually from 1995 onward using January-April samples.'
)
x$mortality_evidence[i] <- paste0(
  'M is fixed at 0.20 per year except 1979-1983, when it is 0.25 because cod were present.'
)
x$timing_evidence[i] <- paste0(
  'The August acoustic survey uses native sampling time 0.675 within the report interval 0.65-0.70.'
)
x$output_evidence[i] <- paste0(
  'The official SAM fit provides N/F-at-age for 1977-2025, SSB, age-0 recruitment and Fbar ',
  'ages 2-6, plus fitted catch/acoustic predictions and conditional N/F state uncertainty.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.32455056; ',
  'https://doi.org/10.17895/ices.advice.30932084; ',
  'https://standardgraphs.ices.dk/ViewCharts.aspx?key=22423; ',
  'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/GoR_WGBFAS_2026/run/model.RData'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current Gulf of Riga herring unit and official 2026 WGBFAS SAM production ',
  'run. Native model data provide age-based catch and acoustic indices, annual biology and ',
  'fixed M; the fitted object and official report/graphs verify age-specific and aggregate outputs.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_herring_gulf_riga_2026.md. The ',
  'acoustic index physical multiplier is not stated; source index values remain unscaled.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES Gulf of Riga herring against the 2026 WGBFAS SAM assessment.\n')

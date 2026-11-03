path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:nop.27.3a4'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ices_norway_pout_north_sea' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Norway pout identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The 2026 SESAM benchmark uses quarterly commercial catch-at-age for 1984-2025 Q3, ',
  'ages 0-3+, in millions of fish.'
)
x$survey_age_evidence[i] <- paste0(
  'The fitted object contains 424 survey rows across five fleets, with age-specific and ',
  'one grouped ages-2-3+ series. Grouped rows are retained in the database and excluded ',
  ''
)
x$weights_evidence[i] <- paste0(
  'Stock weights vary by age and quarter and are constant across years; catch weights vary ',
  'by age, year and quarter. Discard weights follow the source catch-weight treatment.'
)
x$maturity_evidence[i] <- paste0(
  'Maturity is constant across years: 0 at age 0, 0.2 at age 1, and 1 at ages 2-3+.'
)
x$mortality_evidence[i] <- paste0(
  'M is supplied externally by age and quarter from the North Sea SMS model for 1984-2022; ',
  'the 2022 mortality pattern is carried through 2025. It is not estimated by SESAM.'
)
x$timing_evidence[i] <- paste0(
  'The fitted input uses quarterly survey times including 0.95 for RU-BTr-Q4 and quarter ',
  'midpoints 0.125 for Q1 and 0.625 for Q3 series.'
)
x$output_evidence[i] <- paste0(
  'The official fit provides quarterly N/F surfaces, SSB and Fbar, annual recruitment, ',
  'fitted predictions for 1,092 observations, and available conditional state uncertainty. ',
  'Fbar covers ages 1-2; M is an input, not an estimated output.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.32019630; ',
  'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NP_Sep2025_bench_final_Mfor/run/sum.RData; ',
  'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NP_Sep2025_bench_final_Mfor/data/'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current North Sea Norway pout unit and selected 2026 WKBWNG benchmark. ',
  'The official native fit verifies run identity, age-structured inputs, fixed external M, ',
  'and fitted population/mortality outputs. The benchmark was not applied for advice; ',
  'quarterly-to-annual translation and grouped-age survey limitations remain documented.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_norway_pout_north_sea.md. The current ',
  'detailed benchmark is distinct from the 2025 production-advice assessment; grouped ',
  ''
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES North Sea Norway pout against the 2026 WKBWNG benchmark.\n')

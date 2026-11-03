path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:sol.27.4'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_wgnssk_solea_ns_4' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing North Sea sole identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 SS3 run reports landings-at-age for 1957-2025 and discards-at-age ',
  'for 2002-2025, ages 0-10+, in thousand fish; age-0 landings are reported as zero.'
)
x$survey_age_evidence[i] <- paste0(
  'The current assessment uses aggregate BTS and combined COAST biomass indices for ',
  '1990-2025 on native relative scales. A run-matched age-composition series or age-specific ',
  'abundance index was not recovered; prior 2025 age-index inputs are not substituted.'
)
x$weights_evidence[i] <- paste0(
  'Landings, discard and stock weights cover ages 0-10+ through 2025 in kg per fish; Q2 ',
  'catch weights are used as stock weights.'
)
x$maturity_evidence[i] <- paste0(
  'Maturity is fixed, age-specific and knife-edged at age 3.'
)
x$mortality_evidence[i] <- paste0(
  'M is fixed by age using the reported Lorenzen formulation with exponent -0.288; it is not estimated.'
)
x$timing_evidence[i] <- paste0(
  'Both surveys are Q3; tinyAM preparation uses 0.625 as a quarter-midpoint approximation.'
)
x$output_evidence[i] <- paste0(
  'The report gives official N-at-age and F-at-age for 1957-2025; ICES SAG supplies recruitment, ',
  'SSB and Fbar ages 2-6 with bounds. Age-specific uncertainty and total-abundance uncertainty are unavailable.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.32676345; ',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=23777'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current North Sea sole unit and 2026 SS3 assessment. Catch-at-age, age-specific ',
  'biology, fixed M and official age-specific outputs are recovered, but the current run documents ',
  'aggregate survey indices and no run-matched age compositions or age-specific abundance index. ',
  'Eligibility for the stated age-structured input screen therefore remains unresolved.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_sole_north_sea.md. Keep the 2025 age-specific ',
  'index series in its historical assessment record; do not use it to fill the 2026 assessment gap.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES North Sea sole; current-run age-index evidence remains unresolved.\n')

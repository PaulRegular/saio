path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:her.27.1-24a514a'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ices_herring_norwegian_spring_spawning' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Norwegian spring-spawning herring identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The official 2026 WGWIDE SAM assessment reports catch numbers-at-age in thousand fish ',
  'for 1950-2025; the fit uses 1988-2025 and aggregates ages 0-14 and 15+ into ages 2-15.'
)
x$survey_age_evidence[i] <- paste0(
  'Numerical age-specific inputs include NASF acoustic ages 3-12+, IESNS Barents age 2, ',
  'IESNS Norwegian Sea ages 3-12+, and BESS ages 2-3. Numerical RFID index values are not recovered.'
)
x$weights_evidence[i] <- paste0(
  'Catch weights cover ages 2-15 through 2025 and annual stock weights through 2026; ',
  'ages above 12 are combined to 12+ downstream using the reported age-12 biological values.'
)
x$maturity_evidence[i] <- paste0(
  'Maturity is reported by birth cohort and age through cohort 2026; translation maps ',
  'cohort to calendar year as year minus age.'
)
x$mortality_evidence[i] <- paste0(
  'Standard M is 0.9 per year at age 2 and 0.15 at ages 3+; annual M deviations mentioned ',
  'in the stock annex were not recovered.'
)
x$timing_evidence[i] <- paste0(
  'Approximate survey timing is 0.13 for NASF, 0.42 for IESNS Barents, 0.38 for IESNS ',
  'Norwegian Sea and 0.75 for BESS; exact fitted fleet settings were not recovered.'
)
x$output_evidence[i] <- paste0(
  'The 2026 report provides official N-at-age and F-at-age through 2026, plus recruitment, ',
  'SSB, catch and Fbar summaries. Total abundance is derived from N-at-age without uncertainty.'
)
x$detailed_source_url[i] <- paste0(
  'https://doi.org/10.17895/ices.pub.33882730.v1; ',
  'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25912'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current Norwegian spring-spawning herring unit and official 2026 WGWIDE ',
  'assessment. Recoverable age-based catch/index inputs, biological series and official ',
  'age-specific and aggregate outputs support eligibility. Numerical RFID indices, annual ',
  'M deviations, exact fitted configuration and age-specific uncertainty remain unavailable.'
)
x$notes[i] <- paste0(
  'See source_reviews/ices_herring_norwegian_spring_spawning.md. ',
  'Keep the 2026 assessment distinct from the historical 2025 record; the source age groups ',
  'above age 12 require documented plus-group aggregation.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched Norwegian spring-spawning herring against the 2026 WGWIDE assessment.\n')

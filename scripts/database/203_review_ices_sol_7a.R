# Record numerical tables for the Irish Sea sole assessment.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- which(x$candidate_id == 'ICES:sol.27.7a')
if (length(i) != 1L || x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') stop('Preserve the existing review; candidate state has changed.', call. = FALSE)
x$match_status[i] <- 'new'
x$screening_status[i] <- 'in_progress'
x$catch_age_evidence[i] <- 'WGCSE 2026 Table 19.2 gives catch numbers-at-age in thousands, ages 1-10+, 1970-2025; catch age 1 is excluded from the likelihood before 2003.'
x$survey_age_evidence[i] <- 'WGCSE 2026 Table 19.9 gives tuning series; UK(E&W)-BTS-Q3 age 1-7 in 1988-2025, with 2020 missing; Belgian commercial biomass index also used.'
x$weights_evidence[i] <- 'WGCSE 2026 Tables 19.3 and 19.5 provide catch and stock weights by age in kg; check source values and coverage against production input.'
x$maturity_evidence[i] <- 'WGCSE 2026 describes revised time-varying survey-derived maturity ogives, but numerical matrix is not identified in report tables or pinned code archive; seek original mo.txt.'
x$mortality_evidence[i] <- 'WGCSE 2026 section 19 reports the age-specific M vector for ages 1-10+; verify against the production run.'
x$timing_evidence[i] <- 'WGCSE 2026 model settings specify UK(E&W)-BTS-Q3 observation interval 0.75-0.85 of year; preserve interval semantics.'
x$output_evidence[i] <- 'WGCSE 2026 Tables 19.13-19.16 provide F and N at age, SSB-at-age, and annual summary; confirm uncertainty and official run identity.'
x$detailed_source_url[i] <- 'https://doi.org/10.17895/ices.pub.32625759'
x$review_date[i] <- '2026-10-28'
x$decision_reason[i] <- 'Irish Sea unit is not represented by the existing sole stock areas. Report has substantial numeric inputs and results; time-varying maturity and exact run provenance remain unresolved.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

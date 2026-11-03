# Record the 2025 coastwide chilipepper assessment and the older inventory label.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- match(c('NOAA:17357', 'NOAA:10395'), x$candidate_id)
if (anyNA(i) || any(x$match_status[i] != 'unreviewed') || any(x$screening_status[i] != 'not_started')) stop('Preserve the existing reviews; candidate state has changed.', call. = FALSE)
a <- i[1L]; b <- i[2L]
x$match_status[a] <- 'new'
x$screening_status[a] <- 'in_progress'
x$catch_age_evidence[a] <- '2025 report describes landed and discarded total catches for multiple fleets and age observations, mainly conditional on length; defensible reconstruction of catch numbers-at-age remains to be verified.'
x$survey_age_evidence[a] <- '2025 report describes two trawl survey indices and survey age samples; conditional age-at-length observations must not be assumed to be age-specific abundance indices.'
x$weights_evidence[a] <- '2025 report estimates sex-specific growth within the model and supplies weight-length relationships; source age-specific weights and reconstruction require verification.'
x$maturity_evidence[a] <- '2025 report section 2.4.3 describes a female maturity-at-length relationship; determine recoverability of an appropriate age-scale curve.'
x$mortality_evidence[a] <- '2025 report describes female natural mortality estimated with a prior and male mortality as an offset; verify fitted values and uncertainty.'
x$timing_evidence[a] <- 'Survey timing needs verification from the production data and report.'
x$output_evidence[a] <- '2025 report gives historical spawning output and recruitment summaries; spawning output is billions of eggs, not biomass. Verify run-matched age-specific numerical results.'
x$detailed_source_url[a] <- 'https://repository.library.noaa.gov/view/noaa/72420'
x$decision_reason[a] <- '2025 coastwide stock covers California, Oregon and Washington; no matching Sebastes goodei stock was found in the canonical database. Age-scale reconstruction and exact outputs remain under review.'
x$notes[a] <- '2025 coastwide Stock SMART ID 17357; inspect related historical southern-coast inventory ID 10395 before counting distinct units.'
x$match_status[b] <- 'ambiguous'
x$screening_status[b] <- 'in_progress'
x$detailed_source_url[b] <- 'https://repository.library.noaa.gov/view/noaa/72420'
x$decision_reason[b] <- 'Historical southern-coast label has 2017 as its latest inventory assessment; 2025 coastwide assessment is NOAA:17357. Review geographic and historical relationship before counting independently.'
x$notes[b] <- 'Potential predecessor or overlapping label for the 2025 coastwide assessment; do not count as another current stock without evidence.'
x$review_date[i] <- '2026-10-28'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (j in i) {
  write.csv(x[j, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[j + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

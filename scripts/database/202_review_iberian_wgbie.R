# Record 2026 WGBIE screening for two distinct Iberian units.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = 'NA')
i <- match(c('ICES:meg.27.8c9a', 'ICES:sol.27.8c9a'), x$candidate_id)
if (anyNA(i) || any(x$match_status[i] != 'unreviewed') || any(x$screening_status[i] != 'not_started')) stop('Preserve the existing reviews; candidate state has changed.', call. = FALSE)
a <- i[1L]; b <- i[2L]
x$match_status[i] <- 'new'
x$screening_status[i] <- 'in_progress'
x$review_date[i] <- '2026-10-28'
x$catch_age_evidence[a] <- 'WGBIE 2026 section 6.3.2: catch and discards-at-age used for 1986-2025; numerical production matrices require recovery.'
x$survey_age_evidence[a] <- 'WGBIE 2026: Spanish survey G2784 abundance-at-age 1-6, 1983 onward, used by the assessment; recover numerical matrix and exact timing.'
x$weights_evidence[a] <- 'WGBIE 2026 section 6.3.2: catch weights-at-age 1986-2025 also used as stock weights; figure provided, numerical production surface requires recovery.'
x$maturity_evidence[a] <- 'WGBIE 2026 refers to the stock annex for the maturity ogive; obtain and verify production values.'
x$mortality_evidence[a] <- 'WGBIE 2026 refers to the stock annex for natural mortality; obtain and verify production values.'
x$timing_evidence[a] <- 'Spanish SpGFS-WIBTS-Q4 survey; exact assessment timing requires the original model input.'
x$output_evidence[a] <- 'WGBIE 2026 Table 6.3.5 and SAG 22577 provide 1986 onward aggregate recruitment, SSB and F with uncertainty; check 2026 run and interval conventions.'
x$detailed_source_url[a] <- 'https://doi.org/10.17895/ices.pub.32790321.v1'
x$decision_reason[a] <- 'Iberian megrim unit is absent from the canonical species list. Numerical age matrices and stock-annex biology are still being sought; do not infer data availability from plotted surfaces.'
x$catch_age_evidence[b] <- 'WGBIE 2026 section 8 describes landings length-frequency data for 2011-2025 and catch totals; no catch-at-age matrix identified in the reviewed report.'
x$survey_age_evidence[b] <- 'WGBIE 2026 section 8: Spanish biomass index and Portuguese LPUE; no age-specific survey input identified in the reviewed report.'
x$weights_evidence[b] <- 'WGBIE 2026 discusses a length-weight relationship; age-specific weights remain unverified.'
x$maturity_evidence[b] <- 'WGBIE 2026 discusses maturity by length; age-specific maturity remains unverified.'
x$mortality_evidence[b] <- 'WGBIE 2026 describes length-based mortality indicators rather than an age-structured assessment input.'
x$timing_evidence[b] <- 'WGBIE 2026 identifies a Q4 survey; precise assessment timing for an age-based model is unresolved.'
x$output_evidence[b] <- '2025 ICES advice key 19817 reports biomass indices and length indicators; no age-structured population output identified.'
x$detailed_source_url[b] <- 'https://doi.org/10.17895/ices.pub.32790321.v1'
x$decision_reason[b] <- 'Iberian sole is distinct from the existing northern Bay of Biscay candidate; official advice uses length indicators and biomass indices. Verify potential public age sources before eligibility decision.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (j in i) { write.csv(x[j, , drop = FALSE], tmp, row.names = FALSE, na = ''); lines[j + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]] }
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- which(x$candidate_id == 'ICES:cod.27.5a')
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_nwwg_morhua_ice5a' ||
    x$screening_status[i] != 'not_started') {
  stop('Preserve the existing Icelandic cod identity or review.', call. = FALSE)
}
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- 'MFRI 2026 production tables provide commercial catch-at-age for 1955-2025, ages 3-14, in thousand fish, aggregated across 20 métiers.'
x$survey_age_evidence[i] <- 'MFRI 2026 production tables provide March IS-SMB ages 1-14 for 1985-2026 and October IS-SMH ages 1-14 for 1996-2025; the assessment uses October ages 3-13 and has no 2011 survey. Index scale is not specified.'
x$weights_evidence[i] <- 'MFRI 2026 tables provide catch, stock and spawning-stock weights at ages 1-14; 2026 values are projections.'
x$maturity_evidence[i] <- 'MFRI 2026 table provides maturity proportions at ages 1-14; pre-1985 values conflict with report text and are preserved unresolved.'
x$mortality_evidence[i] <- 'MFRI 2026 report states fixed M=0.2 per year at ages 1-14.'
x$timing_evidence[i] <- 'Exact 2026 survey timing was not recovered. The 2021 MUPPET configuration uses March 0.2 and October 0.8; treat as historical framework values pending production-run confirmation.'
x$output_evidence[i] <- 'MFRI 2026 tables provide N-at-age for 1955-2026, F-at-age for 1955-2025, and annual SSB, B4+ and age-3 recruitment; point values and reported bounds are rounded.'
x$detailed_source_url[i] <- paste('https://www.hafogvatn.is/static/extras/images/1_cod_2026_1_techreport_en.html', 'https://www.hafogvatn.is/static/extras/images/1_cod_2026_1_tables_en.html', 'https://doi.org/10.17895/ices.pub.32414577', sep = '; ')
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- 'Matched to the existing Icelandic Division 5.a stock and 2026 production assessment. Official source tables establish age-based catches, two age-disaggregated survey indices, age-specific biology and population/mortality outputs. Canonical values are already imported; exact production timing/configuration and reported source discrepancies remain documented in source_reviews/ices_cod_iceland_2026.md.'
x$notes[i] <- 'The inventory row is now linked to the already curated 2026 assessment ices_cod_iceland_2026. See source_reviews/ices_cod_iceland_2026.md and source_cache/ices_cod_iceland_2026/manifest.csv.'
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened the matched ICES cod.27.5a inventory entry.\n')

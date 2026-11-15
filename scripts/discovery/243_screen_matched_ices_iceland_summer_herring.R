path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:her.27.5a'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_nwwg_harengus_ice_summer' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Icelandic summer-spawning herring identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'unresolved'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'MFRI machine-readable 2026 assessment tables contain catch-at-age for 1980-2023, ' ,
  'ages 2-15, in millions of fish. The report has later raw catches, but their mapping ' ,
  'to the production SAM run is not verified.'
)
x$survey_age_evidence[i] <- paste0(
  'The model tables contain age-specific acoustic indices for ages 2-15 through 2023, ' ,
  'in millions of fish. Later raw acoustic estimates are reported separately; their ' ,
  'mapping to the production run is unresolved.'
)
x$weights_evidence[i] <- paste0(
  'Annual catch and stock weights are supplied for ages 2-15; MFRI reports weights in ' ,
  'kg per fish.'
)
x$maturity_evidence[i] <- paste0(
  'Annual maturity proportions are supplied for ages 2-15.'
)
x$mortality_evidence[i] <- paste0(
  'The framework gives baseline M of 0.1 per year plus an estimated infection-related ' ,
  'component; the current production age-year mortality surface was not recovered.'
)
x$timing_evidence[i] <- paste0(
  'The 2024 benchmark places acoustic observations at the beginning of the assessment year; ' ,
  'the exact 2026 production-run timing and mapping remain unverified.'
)
x$output_evidence[i] <- paste0(
  'The 2026 sources provide N-at-age and F-at-age through 2024 without age-specific uncertainty, ' ,
  'and aggregate SSB and recruitment through 2026. Production-run correspondence and M outputs ' ,
  'are incomplete.'
)
x$detailed_source_url[i] <- paste0(
  'https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_techreport_en.html; ' ,
  'https://www.hafogvatn.is/static/extras/images/30_sp30_2026_1_tables_en.html; ' ,
  'https://sg.ices.dk/ViewCharts.aspx?key=22455; ' ,
  'https://doi.org/10.17895/ices.pub.25605135; ' ,
  'https://doi.org/10.17895/ices.pub.25639419'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current Icelandic summer-spawning herring unit. The 2026 database record ' ,
  'has age-disaggregated catch, acoustic indices, biology and N/F outputs, but uses the MFRI ' ,
  'machine-readable input matrices only through 2023 while the later raw report series cannot ' ,
  'be linked confidently to the production fit. Current infection-related M and exact run settings ' ,
  'are also unavailable; age-structured eligibility remains unresolved.'
)
x$notes[i] <- paste0(
  'See source_reviews/ck_ices_nwwg_harengus_ice_summer.md. Do not ' ,
  'splice later raw catch/acoustic series or benchmark M into the 2026 production inputs.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched Icelandic summer-spawning herring; production-run input mapping remains unresolved.\n')

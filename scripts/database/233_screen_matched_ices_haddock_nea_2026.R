path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'ICES:had.27.1-2'
i <- which(x$candidate_id == id)
if (length(i) != 1L || x$matched_stock_id[i] != 'ck_ices_afwg_aeglefinus_nea_1_2' ||
    x$match_status[i] != 'matched' ||
    !x$screening_status[i] %in% c('not_started', 'screened')) {
  stop('Preserve the existing Northeast Arctic haddock identity.', call. = FALSE)
}

x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste0(
  'The 2026 production SAM fit uses 836 residual catch-at-age observations for 1950-2025, ',
  'ages 3-13+, in thousand fish. Total catch used for M reconstruction is retained as a ',
  'separate source quantity.'
)
x$survey_age_evidence[i] <- paste0(
  'Four age-specific or plus-group survey indices are recovered on native scales: RU-BTr-Q4, ',
  'BS-NoRU-Q1 acoustic, BS-NoRu-Q1 bottom trawl, and FLT007:Eco-NoRu-Q3. The final fit ',
  'contains 790 non-missing observations, including 678 single-age and 112 grouped-age rows.'
)
x$weights_evidence[i] <- paste0(
  'Catch, discard, landings and beginning-of-year stock weights are recovered from the ',
  'final SAM data object for 1950-2026, ages 3-13+, in kg per fish.'
)
x$maturity_evidence[i] <- paste0(
  'Annual maturity-at-age for 1950-2026, ages 3-13+, is recovered from the final SAM data object.'
)
x$mortality_evidence[i] <- paste0(
  'M is fixed in the final fit. Ages 3-6 include a reconstructed cod-predation component ',
  'over a 0.2 baseline; ages 7-13+ are fixed at 0.2 per year.'
)
x$timing_evidence[i] <- paste0(
  'Native sample times are 0.95 for RU-BTr-Q4, 0.133 for both Q1 indices, and 0.7 for ',
  'the Q3 ecosystem survey.'
)
x$output_evidence[i] <- paste0(
  'Verified report/native outputs include N-at-age through 2026, F/M-at-age through 2025, ',
  'age-3 recruitment, SSB, Fbar ages 4-7 and total biomass. The native fit also provides ',
  'fitted observations and conditional state uncertainty.'
)
x$detailed_source_url[i] <- paste0(
  'https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5; ',
  'https://www.stockassessment.org/datadisk/stockassessment/userdirs/user3/NEAHaddock2026/'
)
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste0(
  'Matched to the current ICES Northeast Arctic haddock unit and 2026 production SAM run. ',
  'Run-matched age-based catch, survey and biological inputs, fixed M, official outputs, ',
  'and native fitted-object checks are recovered. Observation-weight interpretation and ',
  'physical survey scales remain unresolved but do not prevent screening eligibility.'
)
x$notes[i] <- paste0(
  'See source_reviews/jrn_afwg_haddock_northeast_arctic_2026.md; ',
  '2026 run outputs are verified against the cached native fit. Grouped plus-age survey ',
  'observations must retain their group definition downstream.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened matched ICES Northeast Arctic haddock against the 2026 SAM production fit.\n')

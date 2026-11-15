# Screen NOAA widow rockfish against the 2025 update and October model review.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10568', x$candidate_id)
if (is.na(i)) stop('Expected NOAA widow rockfish row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
  quit(save = 'no')
}
if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Sebastes entomelas'
x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2025 native model data contain catches from bottom trawl, midwater',
  'trawl and at-sea hake fisheries, plus marginal age compositions from',
  'three commercial fleets. Age compositions are observed samples, not',
  'annual catch numbers-at-age; a catch-age series requires reconstruction.'
)
x$survey_age_evidence[i] <- paste(
  'The assessment uses three survey and three fishery-dependent abundance',
  'indices. WCGBTS contributes conditional age-at-length observations;',
  'these are not a direct age-specific abundance index. Derived marginal',
  'age compositions must not be treated as independent observations.'
)
x$weights_evidence[i] <- paste(
  'The model uses externally estimated sex-specific length-weight',
  'relationships; age-specific weights are derivable from the model biology',
  'and included in fitted outputs, not a fixed observed WAA input.'
)
x$maturity_evidence[i] <- paste(
  'Age at 50 percent maturity is 5.47 years and was retained from the 2015',
  'benchmark; the model files retain the detailed maturity specification.'
)
x$mortality_evidence[i] <- paste(
  'Sex-specific natural mortality is estimated with a lognormal prior',
  '(median 0.10 per year, log-SD 0.31); base estimates are 0.135 female',
  'and 0.147 male.'
)
x$timing_evidence[i] <- paste(
  'Survey identities and timing settings are present in the native data and',
  'control files; preserve their original structure during source import.'
)
x$output_evidence[i] <- paste(
  'The official Report.sso includes numbers-at-age, catch-at-age, F-at-age',
  'and biomass-at-age. The assessment reports recruitment and spawning',
  'output in billions of eggs, not spawning biomass.'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2026/05/status-of-widow-rockfish-stock-off-u-s-west-coast-in-2025.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'No matching canonical US West Coast widow rockfish stock was found.',
  'The official 2025 assessment bundle contains catch and age-composition',
  'inputs, survey age information, biological settings, and age-specific',
  'fitted outputs. It is eligible for source import and a documented',
  'age-structured approximation, not a like-for-like SS replication.'
)
x$notes[i] <- paste(
  'NOAA Stock SMART ID 10568. Use the 2025 update with data through 2024;',
  'the supplemental review endorsed the October 2025 model. Inventory metadata',
  'lists 2026, which is not a new detailed fit. Published report, review and',
  'bundled ss_summary.sso give different SS version labels; see discovery/',
  'source_reviews/noaa_west_coast_widow_rockfish.md.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
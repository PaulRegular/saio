# Screen the current NOAA northern yellowtail rockfish assessment.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10393', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Yellowtail Rockfish row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
} else if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing NOAA Yellowtail Rockfish review; candidate row changed.', call. = FALSE)
}

x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2025 single-area, two-sex Stock Synthesis model uses annual catch',
  'biomass in metric tonnes for three fisheries: commercial, at-sea hake,',
  'and recreational. The input bundle includes fishery age and length',
  'compositions, including age-at-length data. Catch-at-age is not a direct',
  'annual observation series and would require reconstruction from catch',
  'totals and age compositions.'
)
x$survey_age_evidence[i] <- paste(
  'The model uses four survey indices: Oregon-Washington hook-and-line',
  '(numbers), Triennial and WCGBTS (biomass), and SMURF (recruitment index).',
  'Triennial age and length data and WCGBTS conditional age-at-length data',
  'are included. An age-specific abundance index is not a direct input and',
  'would require an explicit index-composition reconstruction.'
)
x$weights_evidence[i] <- paste(
  'Sex-specific weight-at-age is derived from the fitted sex-specific growth',
  'curves and estimated weight-at-length relationships; the report and',
  'native output describe the resulting age surfaces.'
)
x$maturity_evidence[i] <- paste(
  'Female age-based maturity is estimated from 232 histological samples of',
  'aged fish collected north of 40.167 degrees N during 2016-2023.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is estimated freely with a lognormal prior based on',
  'maximum age; the prior uses age 43, the 99.9th percentile of PacFIN age',
  'observations.'
)
x$timing_evidence[i] <- paste(
  'The native input records month 7 (July) for its survey index series and',
  'month 7 for the Triennial and WCGBTS age observations. The model spawning',
  'month is January. Preserve the observation month in any fractional-year',
  'conversion.'
)
x$output_evidence[i] <- paste(
  'The native Report.sso includes annual numbers-at-age, catch-at-age,',
  'biomass-at-age, F-at-age, recruitment, and spawning output. The report',
  'provides uncertainty for key population quantities.'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2026/01/status-of-the-yellowtail-rockfish-stock-off-the-u-s-west-coast-north-of-40-10-in-2025.pdf/'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'NOAA Stock SMART ID 10393 is the U.S. northern yellowtail stock north of',
  '40 degrees 10 minutes N. It is distinct from the Canadian coastwide DFO',
  'unit and has no matching canonical stock. The adopted 2025 benchmark',
  'assessment has matching native inputs and outputs with fishery and survey',
  'age data, age-specific biology, and fitted age surfaces. Mark eligible for',
  'source curation and documented age-structured approximation; direct',
  'catch-at-age and age-specific survey indices are not observed likelihood',
  'inputs.'
)
x$notes[i] <- paste(
  'The official unit is northern yellowtail rockfish north of 40 degrees',
  '10 minutes N. The 2025 single-area assessment is sex-specific, uses 40',
  'population ages and age-composition bins 1-30, and data through 2024.',
  'The report and model bundle identify Stock Synthesis 3.30.23.1. The',
  'report and native ZIP, retrieval details, and checksums are in',
  'source_cache/discovery_noaa_yellowtail_2025/sources.csv.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)

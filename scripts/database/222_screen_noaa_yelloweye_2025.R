# Screen the current NOAA Pacific Coast Yelloweye Rockfish assessment.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10426', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Yelloweye Rockfish row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
} else if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing NOAA Yelloweye Rockfish review; candidate row changed.', call. = FALSE)
}

x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2025 single-sex, two-area model uses seven fishery fleets: six use',
  'biomass catch totals (metric tonnes), and Washington recreational catch',
  'is in numbers.',
  'Fishery length compositions and conditional age-at-length samples are',
  'available, with marginal fishery age compositions in some years. These',
  'are composition observations, not annual observed catch-at-age; any',
  ''
)
x$survey_age_evidence[i] <- paste(
  'The native model has recreational and survey indices, length compositions,',
  'and survey conditional age-at-length observations, including WCGBTS and',
  'IPHC data. The source does not provide a direct age-specific abundance',
  '',
  'from aggregate indices and compositions.'
)
x$weights_evidence[i] <- paste(
  'The model derives weight-at-age from its fitted growth curve and the',
  'assessment length-weight relationship; the source bundle includes the',
  'weight-at-age output and input biology needed to document that derivation.'
)
x$maturity_evidence[i] <- paste(
  'Maturity is fixed from a length-based schedule, rather than estimated as',
  'a maturity-at-age vector. The official input and report document the',
  'schedule and fitted growth relationship needed for age-specific derivation.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is fixed at 0.044 per year, as in the 2017 benchmark.'
)
x$timing_evidence[i] <- paste(
  'The native input identifies January spawning and survey observations at',
  'their recorded months. Survey timing can be recovered from the model data',
  'file; a fractional-year conversion must preserve the specific observation',
  'month for each survey series.'
)
x$output_evidence[i] <- paste(
  'The native Report.sso contains annual numbers-at-age, catch-at-age,',
  'biomass-at-age and F-at-age. The report gives spawning output and',
  'recruitment summaries with uncertainty; 2025 spawning output is 477.63',
  'billion eggs (95% interval 384-571 billion).'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2026/01/status-of-yelloweye-rockfish-off-the-u-s-west-coast-in-2025.pdf/'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'NOAA Stock SMART ID 10426 is the U.S. West Coast unit, separate from',
  'the Gulf of Alaska Yelloweye unit (10425) and Canadian inside/outside',
  'units. The adopted 2025 update has a matching native Stock Synthesis',
  'bundle with catches, composition observations, biological inputs and',
  'age-specific fitted outputs. Mark eligible for source curation and a',
  'documented age-structured approximation; source likelihood compositions',
  'are not direct catch-at-age or age-specific index observations.'
)
x$notes[i] <- paste(
  'The 2025 update uses data through 2024, with a single-sex model and two',
  'areas (California; Oregon/Washington). The report and native bundle both',
  'identify Stock Synthesis 3.30.23.2. Report, native bundle, retrieval',
  'details and checksums are recorded in',
  'source_cache/discovery_noaa_yelloweye_2025/sources.csv.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)

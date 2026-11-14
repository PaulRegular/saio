# Screen the current NOAA California Quillback Rockfish assessment.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:15342', x$candidate_id)
if (is.na(i)) stop('Expected NOAA California Quillback row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
} else if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing NOAA California Quillback review; candidate row changed.', call. = FALSE)
}

x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The native file contains total removals in metric tonnes and 253 conditional',
  'age-composition rows, not direct catch-at-age. Of these, 128 positive-year',
  'rows from 2010-2024 are active; 125 negative-year rows are excluded from',
  'the likelihood. This preserves the report-described age data while',
  'identifying the inactive records.'
)
x$survey_age_evidence[i] <- paste(
  'The model uses California recreational, CCFRP, and ROV abundance series;',
  'native index observations are recorded in July. It does not provide a',
  'direct age-specific abundance index. The conditional age-at-length data',
  'contain 128 active positive-year rows and 125 inactive negative-year rows.'
)
x$weights_evidence[i] <- paste(
  'The native natage.csv contains fitted population numbers-at-age, not',
  'length-at-age. Weight-at-age is derived from modeled growth and the fixed',
  'length-weight relationship; Report.sso includes biomass-at-age output.'
)
x$maturity_evidence[i] <- paste(
  'The native model uses a length-based logistic maturity relationship; the',
  'report documents California-specific biological inputs. Any age-specific',
  'maturity conversion should use the assessment growth surface.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is fixed at 0.068 per year in the base model; the report',
  'identifies M and steepness as fixed at prior values and explores M in the',
  'decision uncertainty analysis.'
)
x$timing_evidence[i] <- paste(
  'The native data records July for survey index observations and January as',
  'the model spawning month. Preserve survey timing in any fractional-year',
  'conversion.'
)
x$output_evidence[i] <- paste(
  'The native Report.sso includes annual numbers-at-age, catch-at-age,',
  'biomass-at-age, and F-at-age. The assessment report provides spawning',
  'output and recruitment estimates with uncertainty.'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2026/01/status-of-quillback-rockfish-in-u-s-waters-off-california-in-2025.pdf/'
x$review_date[i] <- '2026-11-10'
x$decision_reason[i] <- paste(
  'NOAA Stock SMART ID 15342 is the California Quillback Rockfish assessment',
  'unit; it is geographically separate from Canadian Quillback. No matching',
  'canonical California stock was found. The adopted 2025 age-structured',
  'assessment has a matching native Stock Synthesis bundle with catch totals,',
  'fishery and survey age data, biological inputs, timing, and fitted',
  'age-specific outputs. Mark eligible for source curation and a documented',
  'approximation; catch-at-age and age-specific survey indices are not direct',
  'observation inputs.'
)
x$notes[i] <- paste(
  'The official California management unit is distinct from Canadian',
  'Quillback. The model uses data through 2024, one area, one sex, and 80',
  'population age classes; composition bins span ages 1-60. Report.sso',
  'identifies Stock Synthesis 3.30.23.1. natage.csv matches fitted',
  'beginning-year N-at-age, not length-at-age. Of 253 agecomp rows, 128 are',
  'active and 125 have negative-year exclusion flags. Source files and',
  'checksums are in source_cache/discovery_noaa_quillback_ca_2025/sources.csv.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)

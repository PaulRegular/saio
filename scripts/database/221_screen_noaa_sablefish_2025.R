# Screen the current NOAA Pacific Coast Sablefish assessment.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10466', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Sablefish row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
} else if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing NOAA Sablefish review; candidate row changed.', call. = FALSE)
}

x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2025 Stock Synthesis input has retained catch biomass (metric tonnes)',
  'for trawl, hook-and-line and pot fleets, plus discard fleets. It includes',
  'sex-specific age compositions for retained catch (trawl from 1983; fixed',
  'gear from 1986) and discard compositions derived from length samples using',
  'a length-age key. Catch-at-age is not an observed annual input; it can be',
  'reconstructed for sampled years from catch totals, age compositions and',
  'weight-at-age, while unsampled years remain a limitation.'
)
x$survey_age_evidence[i] <- paste(
  'The model uses biomass indices from early and late Triennial surveys, the',
  'NWFSC Slope Survey, and the annual WCGBTS. Marginal survey age compositions',
  'are included in the native input in bins 0-50; WCGBTS sampling covers',
  '2003-2024 except 2020. There is no directly observed age-specific abundance',
  'index; a tinyAM age-indexed series would need an explicit reconstruction',
  'from an aggregate index and survey age composition.'
)
x$weights_evidence[i] <- paste(
  'The assessment reads sex-specific empirical weight-at-age inputs from',
  'WCGBTS biological samples for ages 0-30 in 2003-2024 (age 30 is the plus',
  'group); pre-2003 weights are held constant.'
)
x$maturity_evidence[i] <- paste(
  'The model uses a fixed, spatially integrated maturity-at-age schedule.',
  'The assessment report describes spatial variation in maturity and the',
  'biomass-weighted coastwide schedule.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is estimated as one time-invariant value shared by',
  'sexes: 0.088 per year in the base model, with a lognormal prior having',
  'median 0.072 and standard error 0.31.'
)
x$timing_evidence[i] <- paste(
  'The native survey observations include month fields. The listed survey',
  'indices are timed in July for early Triennial and NWFSC Slope, August for',
  'late Triennial, and July for WCGBTS; the model spawns in January. Any',
  'tinyAM conversion to a fractional year must document its timing convention.'
)
x$output_evidence[i] <- paste(
  'The 2025 Report.sso includes annual numbers-at-age, catch-at-age, F-at-age',
  'and biomass-at-age. The report gives spawning output, recruitment, and',
  'exploitation estimates with uncertainty; 2025 spawning output is 74,409 mt',
  'with a 95% interval of 59,331-89,486 mt.'
)
x$detailed_source_url[i] <- 'https://www.pcouncil.org/documents/2026/02/status-of-the-sablefish-off-the-u-s-west-coast-in-2025.pdf/'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'NOAA Stock SMART ID 10466 identifies the U.S. West Coast Sablefish unit,',
  'distinct from Alaska and British Columbia management units. The official',
  '2025 assessment has a matching 2025 native model bundle with catch totals,',
  'fishery and survey age compositions, biological inputs, survey timing, and',
  'age-specific fitted outputs. Mark eligible for source curation and a',
  'documented age-structured approximation; this does not imply that its raw',
  'likelihood inputs map directly to tinyAM.'
)
x$notes[i] <- paste(
  'The 2025 assessment uses data through 2024 and is a two-sex age-structured',
  'Stock Synthesis model. The report states version 3.30.24, while the bundled',
  'Report.sso and echoed input identify 3.30.23.1; retain this run-version',
  'discrepancy for source review. Cached report and native model archive,',
  'retrieval details, and checksums are in',
  'source_cache/discovery_noaa_sablefish_2025/sources.csv.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10239'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one NOAA Gulf lane snapper inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_gulf_lane_snapper',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The current 2026 SEDAR 49 interim analysis uses the ITarget data-limited',
    'method to set catch advice from an abundance-index reference period. The',
    'reviewed 2026 sources do not report catch numbers at age, and the SSC',
    'review says ages and lengths do not directly inform interim analyses.'
  ),
  survey_age_evidence = paste(
    'The 2026 interim analysis uses an aggregate G-FISHER composite video index',
    'of relative abundance from natural reef sites. It is not an age-specific',
    'index, and the SSC report confirms ages and lengths are not used directly.'
  ),
  weights_evidence = paste(
    'The reviewed 2026 ITarget interim analysis does not describe or use a',
    'weight-at-age input. Historical SEDAR 49 life-history material is not',
    'substituted for inputs to this current interim analysis.'
  ),
  maturity_evidence = paste(
    'The reviewed 2026 ITarget interim analysis does not describe or use a',
    'maturity-at-age input.'
  ),
  mortality_evidence = paste(
    'The reviewed 2026 ITarget interim analysis does not estimate or report an',
    'age-specific natural-mortality vector.'
  ),
  timing_evidence = paste(
    'The current method is an index-based interim analysis rather than an',
    'annual age-structured population model; a fractional within-year model',
    'timing is not specified.'
  ),
  output_evidence = paste(
    'The 2026 SSC review recommends an OFL of 1,336,445 lb whole weight and an',
    'ABC of 1,304,917 lb whole weight for 2026-2028. It reports no N-at-age,',
    'F-at-age, biomass-at-age, recruitment, or spawning-biomass trajectory.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/documents/report-of-the-gulf-ssc-review-of-the-2026-interim-analysis-of-the-sedar-49-lane-snapper-assessment/;',
    'https://sedarweb.org/assessments/sedar-49/;',
    'https://www.fisheries.noaa.gov/action/modifications-size-limit-and-catch-limits-gulf-lane-snapper;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10239'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'Ineligible for the age-disaggregated assessment set. The latest current',
    'unit analysis is the 2026 SEDAR 49 interim analysis, which applies an',
    'index-based ITarget method using G-FISHER relative abundance for catch',
    'advice. The SSC accepted this analysis as consistent with best available',
    'scientific information, but explicitly confirmed that ages and lengths',
    'do not directly inform interim analyses. No age-specific population input',
    'or output is documented for this current method.'
  ),
  notes = paste(
    'NOAA Stock SMART lists 2023 for this stock, but the latest run located is',
    'the 2026 SEDAR 49 interim analysis, which informed 2026-2028 catch advice.',
    'The earlier 2016 SEDAR 49 data-limited assessment is not used as a',
    'substitute for current-run age inputs or outputs. This Gulf management',
    'unit has no existing canonical stock match. No numerical records were',
    'imported.'
  )
)

matches_review <- all(vapply(names(review), function(column) {
  identical(as.character(x[[column]][i]), as.character(review[[column]]))
}, logical(1L)))
if (x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed') {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!matches_review) {
  stop('Candidate row has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE)
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Gulf lane snapper; the 2026 interim analysis is ineligible for age-disaggregated source curation.\n')

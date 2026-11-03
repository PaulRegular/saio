path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:National Capital Region:Atlantic Mackerel'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO Atlantic mackerel inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_northern_contingent_atlantic_mackerel',
  official_stock_id = 'Northern contingent Atlantic mackerel (Northwest Atlantic)',
  scientific_name = 'Scomber scombrus',
  stock_name = 'Atlantic Mackerel - Northern contingent',
  assessment_area = 'Northwest Atlantic northern contingent; main spawning area NAFO Division 4T',
  inventory_assessment_year = 2025L,
  matched_stock_id = 'ck_dfo_qc_scombrus_4t',
  match_status = 'matched',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'imported',
  catch_age_evidence = paste(
    'The pinned 2025 production run includes annual commercial catch-at-age for',
    'ages 1-10+ in thousands of fish, used as age-composition data, plus annual',
    'catch bounds and their source components in tonnes.'
  ),
  survey_age_evidence = paste(
    'The run uses an aggregate total egg production index for 1979-2025 in',
    'trillion eggs (source timing 0.47); it is not an age-specific fish index.',
    '',
    'prediction without changing the likelihood.'
  ),
  weights_evidence = paste(
    'Annual stock, January 1 stock, and catch weight-at-age surfaces for 1969-2025',
    'are retained as distinct inputs.'
  ),
  maturity_evidence = 'Annual maturity-at-age is provided for 1969-2025.',
  mortality_evidence = 'Natural mortality is fixed at 0.28 per year; it is not an estimated output.',
  timing_evidence = 'The total egg production index uses within-year timing 0.47.',
  output_evidence = paste(
    'The pinned fit exports annual N-at-age and F-at-age for 1969-2025, plus SSB,',
    'recruitment, total biomass and predicted catch. Output uncertainty is partial; M is fixed.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/site/eng/9.964308/publication.html;',
    'https://www.dfo-mpo.gc.ca/csas-sccs/Publications/ResDocs-DocRech/2025/2025_054-eng.pdf;',
    'https://github.com/iml-assess/mackerel_assessment/tree/435d10bcb6ee64e0d94c77f6854e0d37f53e4b8b'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'Matched to the existing canonical DFO northern-contingent assessment record.',
    'The 2025 production repository supplies age-based inputs and fitted age-specific',
    'outputs, with partial output uncertainty. DFO assessment unit and run are verified;',
    'the aggregate egg-production likelihood remains an important translation limitation.'
  ),
  notes = paste(
    'See source_reviews/dfo_northern_mackerel_2025.md. The source fit and inputs are',
    'already imported under ck_dfo_qc_scombrus_4t; cached source manifest is under',
    'source_cache/dfo_northern_mackerel_2025/. NOAA:10164 is a different, broader',
    'assessment unit and remains linked to nefsc_atlantic_mackerel.'
  )
)

if (x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed') {
  for (column in names(review)) x[[column]][i] <- review[[column]]
  lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
  writeLines(lines, path, useBytes = TRUE)
} else if (!all(vapply(names(review), function(column) {
  identical(as.character(x[[column]][i]), as.character(review[[column]]))
}, logical(1L)))) {
  stop('The DFO Atlantic mackerel row is already reviewed differently.', call. = FALSE)
}

cat('Matched the DFO northern-contingent mackerel inventory row to its existing assessment record.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c(
  'NOAA:10165',
  'DFO:National Capital Region:Bluefin Tuna - Western Atlantic'
)
i <- match(ids, x$candidate_id)
if (anyNA(i) || anyDuplicated(x$candidate_id[i])) {
  stop('Expected one NOAA and one DFO western Atlantic bluefin inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'western_atlantic_bluefin_tuna',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2021 Stock Synthesis advice model uses fleet catches in metric tonnes',
    'for 1950-2020 and size compositions. Conditional age-at-length data from',
    'otolith age-length pairs cover 1973-2018; 6,552 pairs remain after the',
    'strict-update screening. Japan longline catch-at-age was supplied only',
    'for diagnostics, not fitted in the likelihood. The report does not',
    'publish run-matched numeric catch-at-age or composition arrays.'
  ),
  survey_age_evidence = paste(
    'The model uses 12 aggregate relative-abundance indices, including the',
    'Gulf of St. Lawrence acoustic index, with within-year timing adjustments.',
    'The report documents fishery and survey age-length samples but no',
    'age-specific survey-index likelihood. Exact index timing and numeric',
    'age-composition inputs require the run-matched electronic files.'
  ),
  weights_evidence = paste(
    'Growth is estimated with a Richards model; the model uses the overall',
    'length-weight relationship 1.52e-5 * length^3.05305 to derive weight.',
    'A run-matched numeric weight-at-age surface was not found in the public',
    'assessment tables.'
  ),
  maturity_evidence = paste(
    'The model uses alternative early- and late-spawning maturity-at-age',
    'vectors for its two advice scenarios. SSB is the mass of mature fish;',
    'the vectors are tabulated for ages 0-35+.'
  ),
  mortality_evidence = paste(
    'Natural mortality is age-specific and follows a Lorenzen function scaled',
    'to M=0.1 per year at age 20; the report tabulates the resulting ages',
    '0-35+ schedule.'
  ),
  timing_evidence = paste(
    'The model uses an annual time step and continuous removals. Each of the',
    '12 abundance indices is adjusted for within-year timing, but the exact',
    'fractions are not enumerated in the report and remain to be checked in',
    'the run-matched model files.'
  ),
  output_evidence = paste(
    'The advice model reports SSB, recruitment, biomass and fishing-mortality',
    'trajectories through 2020 in figures, plus terminal F-based status and',
    'uncertainty in tables. It shows estimated F-at-age in a figure, but',
    'numeric annual N-at-age and F-at-age arrays were not located. Numeric',
    'VPA age-specific tables are not advice outputs.'
  ),
  detailed_source_url = paste(
    'https://iccat.int/en/assess.html;',
    'https://www.iccat.int/Documents/Meetings/Docs/2021/REPORTS/2021_WBFT_SA_ENG.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV078_2021/n_3/CV078030734.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV078_2021/n_3/CV078030756.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV078_2021/n_3/CV078030706.pdf;',
    'https://www.iccat.int/Documents/Meetings/Docs/2024/Reports/2024_SCRS_ENG.pdf;',
    'https://www.dfo-mpo.gc.ca/reports-rapports/regs/sff-cpd/survey-sondage/index-en.html'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The NOAA and DFO inventory entries describe the same Western Atlantic',
    'bluefin stock assessed by ICCAT; no canonical stock record was found.',
    'ICCAT identifies the 2021 Stock Synthesis model (1950-2020) as the model',
    'used for advice, and the 2024 SCRS summary still reports status from that',
    'assessment. The VPA supplied age-specific tables but was rejected for',
    'quantitative status and projection advice. The advice model includes',
    'conditional age-at-length information, but exact numerical input arrays,',
    'age-specific survey observations, and numeric age-specific outputs were',
    'not recovered from the public documents. Eligibility remains unresolved',
    'pending run-matched electronic inputs or a source-supported reconstruction.'
  ),
  notes = paste(
    'NOAA Stock SMART ID 10165 and the DFO Western Atlantic bluefin survey',
    'entry are linked as one transboundary ICCAT unit. The ICCAT assessment',
    'calendar lists the West Atlantic assessment as 2021/2027 and Stock',
    'Synthesis 3.30.14. Public reports and their checksummed source manifest',
    'are cached locally under source_cache/discovery_iccat_western_bluefin_2021/.',
    'No canonical database values were changed.'
  )
)

matches_review <- vapply(i, function(row) all(vapply(names(review), function(column) {
  value <- as.character(x[[column]][row])
  expected <- as.character(review[[column]])
  if (is.na(value)) value <- ''
  if (is.na(expected)) expected <- ''
  identical(value, expected)
}, logical(1L))), logical(1L))
if (all(x$screening_status[i] == 'not_started') && all(x$match_status[i] == 'unreviewed')) {
  for (row in i) for (column in names(review)) x[[column]][row] <- review[[column]]
} else if (!all(matches_review)) {
  stop('Western Atlantic bluefin inventory rows have a conflicting prior review.', call. = FALSE)
}
for (column in c('matched_stock_id', 'candidate_unit_id')) {
  missing <- is.na(x[[column]][i])
  x[[column]][i[missing]] <- ''
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
tmp <- tempfile(fileext = '.csv')
for (row in i) {
  csv_row <- x[row, , drop = FALSE]
  csv_row[] <- lapply(csv_row, as.character)
  write.csv(csv_row, tmp, row.names = FALSE, na = '')
  lines[row + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened the NOAA and DFO western Atlantic bluefin entries as one unresolved ICCAT unit.\n')

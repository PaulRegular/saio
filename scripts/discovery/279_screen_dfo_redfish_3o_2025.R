path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Newfoundland and Labrador:Redfish - NAFO 3O'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO 3O redfish inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'nafo_redfish_3o',
  official_stock_id = 'NAFO Division 3O redfish',
  inventory_assessment_year = 2025,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest detailed 2025 official assessment describes aggregate fishery',
    'catches and commercial length samples. It does not report catch-at-age as',
    'a fitted input; the report states that assessment is based primarily on',
    'research-vessel survey data.'
  ),
  survey_age_evidence = paste(
    'The 2025 assessment uses Canadian spring and autumn and EU-Spain survey',
    'indices, with length-frequency information. The report does not document',
    'an age-specific survey likelihood or fitted age-specific abundance index.'
  ),
  weights_evidence = 'Age-specific stock weights are not documented for the current survey-index assessment.',
  maturity_evidence = 'Age-specific maturity is not documented for the current survey-index assessment.',
  mortality_evidence = paste(
    'The assessment reports a fishing-mortality proxy and aggregate reference',
    'points, not age-specific fishing or natural mortality surfaces.'
  ),
  timing_evidence = 'Canadian spring/autumn and EU-Spain spring surveys are identified, but no fractional timing for an age-structured model is used.',
  output_evidence = paste(
    'The 2025 assessment reports aggregate survey biomass-index trends and',
    'stock-status probabilities/reference points through 2024. It does not',
    'report N-at-age, F-at-age, M-at-age, or recruitment-at-age surfaces.'
  ),
  detailed_source_url = paste(
    'https://www.nafo.int/Portals/0/PDFs/sc/2025/scr25-045.pdf;',
    'https://www.nafo.int/Science/Stocks-Advice'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NAFO treats redfish in Division 3O as a separate management unit and the',
    '2025 SCR Doc. 25/045 is its latest detailed assessment. The assessment',
    'uses research-vessel survey indices and reports aggregate status outputs,',
    'not an age-structured population model. It is therefore excluded from the',
    'age-structured candidate pool; this does not establish that no raw age',
    'observations exist elsewhere.'
  ),
  notes = paste(
    'The 2025 NAFO assessment is cached under',
    'source_cache/discovery_dfo_redfish_3o_2025/ with retrieval date and',
    'SHA-256 checksum. No canonical numerical data were imported.'
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
cat('Screened DFO/NAFO redfish in 3O; latest detailed assessment is survey-index based, not age structured.\n')

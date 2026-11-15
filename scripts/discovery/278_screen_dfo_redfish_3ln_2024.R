path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Newfoundland and Labrador:Redfish - NAFO 3LN'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO 3LN redfish inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'nafo_redfish_3ln',
  official_stock_id = 'NAFO Divisions 3LN redfish',
  inventory_assessment_year = 2024,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest detailed official assessment (NAFO SCR Doc. 24/048) is index',
    'based and does not report catch-at-age as a fitted input. Commercial catch',
    'and some length-sampling information are described; the assessment report',
    'says the current report did not update catch-at-length.'
  ),
  survey_age_evidence = paste(
    'The 2024 assessment uses standardized Canadian spring/autumn and EU-Spain',
    'survey indices for stock-status evidence. It does not document an age-specific',
    'survey likelihood or fitted age-specific abundance index.'
  ),
  weights_evidence = 'No age-specific stock-weight input is documented for the current index-based assessment.',
  maturity_evidence = 'No age-specific maturity surface is documented for the current index-based assessment.',
  mortality_evidence = 'The current assessment is not an age-structured model and does not report age-specific M or F surfaces.',
  timing_evidence = 'Canadian spring/autumn and EU-Spain survey seasons are identified, but no fractional timing for an age-structured model is used.',
  output_evidence = paste(
    'The 2024 official assessment reports survey-index trajectories and stock',
    'status/reference-point evidence. It does not report population N-at-age,',
    'F-at-age, M-at-age, or recruitment-at-age surfaces.'
  ),
  detailed_source_url = paste(
    'https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-048.pdf;',
    'https://www.nafo.int/Portals/0/PDFs/sc/2025/scr25-002.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The official 3LN unit manages deepwater and Acadian redfish together.',
    'The latest detailed production assessment located is the 2024 NAFO/DFO',
    'index-based status assessment. The 2025 document updates operating models',
    'for MSE and is not a new fitted production assessment. The current official',
    'method does not provide the age-specific input and output surfaces required',
    'for an age-structured comparison; this is not a claim that no raw age data',
    'exist in any source.'
  ),
  notes = paste(
    'The 2024 assessment and 2025 MSE update are cached under',
    'source_cache/discovery_dfo_redfish_3ln_2024/ with retrieval dates and',
    'SHA-256 checksums. No canonical numerical data were imported.'
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
cat('Screened DFO/NAFO redfish in 3LN; latest detailed assessment is index based, not age structured.\n')

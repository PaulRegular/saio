path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'DFO:Pacific:Dogfish - Inside waters'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected DFO Inside Dogfish inventory row was not found.', call. = FALSE)
if (!is.na(x$matched_stock_id[i]) && nzchar(x$matched_stock_id[i])) {
  stop('Unexpected canonical match for DFO Inside Dogfish.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_dogfish_inside_bc',
  official_stock_id = '',
  scientific_name = 'Squalus suckleyi',
  stock_name = 'Pacific Spiny Dogfish - Inside waters',
  assessment_area = 'Strait of Georgia and Johnstone Strait; DFO GMA 4B and Statistical Area 12',
  inventory_assessment_year = '2010',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2010 assessment states that the paucity of catch-age data precluded an',
    'age-structured model. It fits surplus-production models to catches and CPUE;',
    'there is no annual catch-at-age observation series or supported reconstruction.'
  ),
  survey_age_evidence = paste(
    'The assessment uses aggregate catch-per-unit-effort indices, including the',
    'inside Strait of Georgia longline survey. It does not use age-specific survey',
    'abundance observations or age-composition likelihoods.'
  ),
  weights_evidence = paste(
    'The report discusses dogfish age, growth and length biology, but no weight-at-age',
    'series is an input to the surplus-production assessment.'
  ),
  maturity_evidence = paste(
    'Life-history maturity information is described in the report, but no',
    'maturity-at-age vector is used in this biomass-dynamics model.'
  ),
  mortality_evidence = paste(
    'The production models use stock growth and shape parameters (r and m), not an',
    'age-specific natural-mortality schedule. No age-based M input applies.'
  ),
  timing_evidence = paste(
    'The assessment is annual and fits annual catch and CPUE indices; no within-year',
    'fractional survey timing is specified or required by its production model.'
  ),
  output_evidence = paste(
    'The detailed report provides inside-stock biomass, depletion, MSY and FMSY',
    'results for alternative production-model runs (including Table 15, B2009).',
    'It does not report age-specific abundance or fishing-mortality surfaces.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/Library/344050.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/Library/342425.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/346574.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41297726.pdf;',
    'https://www.dfo-mpo.gc.ca/species-especes/sharks/research/dogfish-eng.html'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The latest detailed assessment of this distinct inside stock remains the 2010',
    'assessment (Research Document 2011/034); DFO identifies the 2024 assessment as',
    'outside-waters only and states the last dogfish assessment was completed in',
    '2010. The inside assessment is a surplus-production analysis, and its report',
    'explicitly says the paucity of catch-age data precludes an age-structured model.',
    'It is therefore ineligible for the age-disaggregated candidate set. No canonical',
    'assessment data were imported.'
  ),
  notes = paste(
    'Distinct from the outside BC stock. Historical assessment title uses Squalus',
    'acanthias; current DFO sources use Squalus suckleyi. Inside stock spans the',
    'Strait of Georgia and Johnstone Strait. The 2010 peer review did not reach',
    'consensus on a model-based yield recommendation.'
  )
)

for (column in names(review)) x[[column]][i] <- review[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
row <- x[i, , drop = FALSE]
row[] <- lapply(row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened the DFO Inside Pacific Spiny Dogfish assessment.\n')

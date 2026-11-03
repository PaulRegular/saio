path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'DFO:Pacific:Dogfish - Outside waters'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected DFO Outside Dogfish inventory row was not found.', call. = FALSE)
if (!is.na(x$matched_stock_id[i]) && nzchar(x$matched_stock_id[i])) {
  stop('Unexpected canonical match for DFO Outside Dogfish.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_dogfish_outside_bc',
  official_stock_id = '',
  scientific_name = 'Squalus suckleyi',
  stock_name = 'Pacific Spiny Dogfish - Outside waters',
  assessment_area = 'PMFC major areas 3CD5ABCDE; outside British Columbia waters',
  inventory_assessment_year = '2024',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 Stock Synthesis assessment fits catch and length compositions, not',
    'catch-at-age or age compositions. Historical research ages could not be linked',
    'to survey-year or fishing-event samples and were used only to estimate growth;',
    'no source-supported catch-at-age reconstruction is available.'
  ),
  survey_age_evidence = paste(
    'The model uses aggregate standardized survey abundance or biomass indices.',
    'Age samples were not linked to survey-year observations and were not used as',
    'survey age compositions; the aggregate indices cannot be split by age from',
    'the reported observations.'
  ),
  weights_evidence = paste(
    'Sex-specific growth and weight-at-length are estimated from biological data;',
    'the model derives weight-at-age through its growth relationship. No annual',
    'weight-at-age observation series is needed to establish the age-input screen.'
  ),
  maturity_evidence = paste(
    'The assessment uses age-based maturity ogives informed by literature and',
    'biological samples; alternative maturity assumptions are included in',
    'sensitivity models.'
  ),
  mortality_evidence = paste(
    'The base model fixes shared natural mortality at 0.065; alternative constant',
    'and time-varying mortality assumptions are explored in sensitivity models.'
  ),
  timing_evidence = paste(
    'The assessment is annual and survey timing varies by survey from spring to',
    'early fall. A common fractional-year timing for the aggregate index inputs',
    'was not verified.'
  ),
  output_evidence = paste(
    'Official outputs include spawning output in pups, depletion S/S0, F/F0.4S0,',
    'and age-structured trajectories illustrated for selected ages. The advisory',
    'report gives 2023 S/S0 of 0.09 (95% CI 0.08-0.09) and F/F0.4S0 of 1.5',
    '(1.3-1.6). Numeric annual N-at-age and instantaneous F-at-age matrices were',
    'not located; pup production is not directly comparable to teleost SSB.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41320104.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41297726.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The latest detailed assessment is the 2024 outside-water stock assessment,',
    'published as Research Document 2025/055 in February 2026. It is age-structured',
    'but the fitted observation data include length compositions rather than age',
    'compositions. Historical research ages cannot be linked to fishery or survey',
    'events for reconstruction. Therefore it is ineligible for the age-disaggregated',
    'candidate set; no canonical data were imported.'
  ),
  notes = paste(
    'Distinct from the DFO inside-water Dogfish unit. The stock covers PMFC major',
    'areas 3CD5ABCDE. DFO identifies Squalus suckleyi as Pacific Spiny Dogfish;',
    'the selected-stock inventory provides no separate numeric stock code.'
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
cat('Screened the DFO Outside Pacific Spiny Dogfish assessment.\n')
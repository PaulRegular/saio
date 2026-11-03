root <- "."
candidate_path <- file.path(root, 'discovery', 'candidates.csv')
stocks_path <- file.path(root, 'database', 'stocks.csv')
candidates <- read.csv(candidate_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(stocks_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

reviews <- list(
  'DFO:National Capital Region:Redfish (Sebastes mentella) Unit 1 + 2' = list(
    candidate_unit_id = 'dfo_redfish_s_mentella_units_1_2',
    scientific_name = 'Sebastes mentella'
  ),
  'DFO:National Capital Region:Redfish (Sebastes fasciatus) Unit 1 + 2' = list(
    candidate_unit_id = 'dfo_redfish_s_fasciatus_units_1_2',
    scientific_name = 'Sebastes fasciatus'
  )
)
common <- list(
  official_stock_id = NA_character_,
  assessment_area = paste(
    'DFO Units 1 and 2; Unit 1: NAFO Divisions 4RST and Subdivisions 3Pn4Vn (January-May);',
    'Unit 2: Subdivisions 3Ps4Vs, unit areas 4Wfgj and Subdivisions 3Pn4Vn (June-December)'
  ),
  inventory_assessment_year = 2025L,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The accepted assessment is index-based and reports commercial landings by management unit,',
    'not species. No fitted catch-at-age series was verified for either species.'
  ),
  survey_age_evidence = paste(
    'The assessment uses empirical survey indices and biomass/length information, including',
    'species attribution by anal-fin-ray counts; it does not fit an age-specific survey index.'
  ),
  weights_evidence = paste(
    'The detailed assessment documents survey biomass and length-based biology, but no',
    'run-specific weights-at-age input for an age-structured population model was verified.'
  ),
  maturity_evidence = paste(
    'SSB is reported from survey and biological information, but no run-specific',
    'maturity-at-age input for an age-structured population model was verified.'
  ),
  mortality_evidence = paste(
    'Potential removals consider alternative natural-mortality assumptions, but the',
    'index-based assessment does not estimate age-specific M or F population surfaces.'
  ),
  timing_evidence = paste(
    'Unit 1 is monitored by an annual summer survey and Unit 2 by intermittent surveys;',
    'the accepted index-based approach does not specify a fractional age-structured survey timing.'
  ),
  output_evidence = paste(
    'The assessment reports SSB and recruitment biomass with uncertainty and survey biomass',
    'by size; species-level landings and F are unavailable. It reports no N-at-age, F-at-age,',
    'or M-at-age population outputs.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4129077x.pdf;',
    'https://publications.gc.ca/site/eng/9.961935/publication.html;',
    'https://publications.gc.ca/site/eng/9.959927/publication.html;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41078445.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'DFO recognizes two species stocks, S. mentella and S. fasciatus, across management Units 1 and 2.',
    'No current DFO unit record was found in the canonical database. The latest detailed assessment',
    'uses index-based status indicators rather than age-structured population dynamics, and its',
    'age-specific inputs and population outputs required for the candidate set were not verified.'
  ),
  notes = paste(
    'The detailed current record is the 2024 stock-status assessment, published as Research Document',
    '2026/037; the 2025 indicator update is Science Response 2026/009. The 2025 update could not',
    'report Unit 2 status because there was no 2025 Unit 2 survey. Source review:',
    'discovery/source_reviews/dfo_redfish_units_1_2_2024.md. Cached advisory PDFs and SHA-256',
    'values are in the ignored local source cache; current detailed PDFs redirected to an archived page.'
  )
)

for (id in names(reviews)) {
  i <- which(candidates$candidate_id == id)
  if (length(i) != 1L) stop('Expected one inventory row: ', id, call. = FALSE)
  review <- c(reviews[[id]], common)
  review$official_stock_id <- NA_character_
  review$scientific_name <- reviews[[id]]$scientific_name
  already_applied <- all(vapply(names(review), function(column) {
    identical(as.character(candidates[[column]][i]), as.character(review[[column]]))
  }, logical(1L)))
  if (!already_applied) {
    if (candidates$screening_status[i] != 'not_started' ||
        candidates$match_status[i] != 'unreviewed') {
      stop('Inventory row has a conflicting prior review: ', id, call. = FALSE)
    }
    for (column in names(review)) candidates[[column]][i] <- review[[column]]
  }
}

for (id in names(reviews)) {
  if (sum(candidates$candidate_unit_id == reviews[[id]]$candidate_unit_id, na.rm = TRUE) != 1L) {
    stop('The candidate-unit identifier must be unique: ', reviews[[id]]$candidate_unit_id,
      call. = FALSE)
  }
}
for (species in vapply(reviews, function(x) x[['scientific_name']], character(1L))) {
  known_unit <- grepl('Unit 1|Unit 2|4RST|3Pn4Vn|4Wfgj',
    paste(stocks$area, stocks$region, stocks$notes), ignore.case = TRUE)
  if (any(stocks$scientific_name == species & known_unit, na.rm = TRUE)) {
    stop('A DFO Units 1+2 redfish stock now exists; reconcile before rerunning.', call. = FALSE)
  }
}

lines <- readLines(candidate_path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(candidates) + 1L) {
  stop('Candidate CSV contains multiline records; refusing unsafe update.', call. = FALSE)
}
for (id in names(reviews)) {
  i <- match(id, candidates$candidate_id)
  row <- candidates[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, candidate_path, useBytes = TRUE)
cat('Screened the two DFO Units 1+2 redfish entries as distinct species stocks using index-based assessment methods.\n')


path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Newfoundland and Labrador:Capelin - NAFO 2J3KL'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO 2J3KL Capelin inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_capelin_2j3kl',
  official_stock_id = '2J+3KL Capelin',
  scientific_name = 'Mallotus villosus',
  stock_name = 'Capelin - NAFO 2J3KL',
  assessment_area = paste(
    'NAFO Subarea 2 and Divisions 3K and 3L, assessed as one stock complex.',
    'DFO advice is also applied to separate 3Ps management area.'
  ),
  inventory_assessment_year = 2025L,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2025 detailed report describes catch-at-age reconstructed from commercial',
    'biological samples using year-, division-, sex-specific age-length keys, then',
    'scaled by landings for each gear-sector and division catch cell. These samples',
    'describe spawning-population structure; they are not a catch-at-age likelihood',
    'for a fitted age-structured population model. Landings span 1978-2025.'
  ),
  survey_age_evidence = paste(
    'The spring acoustic survey produces aggregate biomass and abundance indices.',
    'The 2025 detailed report plots age-disaggregated abundance and age composition',
    'for 1985-2024; the 2026 advice plots age-disaggregated biomass through 2025.',
    'These are survey indices, not fitted population N-at-age.'
  ),
  weights_evidence = paste(
    'The 2025 detailed report plots spring acoustic mean weights at ages 1-6 for',
    '1985-2024 and describes fishery length-to-weight conversions. Numeric annual',
    'weight-at-age arrays were not found.'
  ),
  maturity_evidence = paste(
    'The source reports the proportion of female age-2 fish maturing in the spring',
    'acoustic survey, including a 2025 value of 34%. This is not a full age-by-sex',
    'maturity matrix.'
  ),
  mortality_evidence = paste(
    'No age-specific natural-mortality assumption or fitted M surface is reported.',
    'The maximum-F index combines the mature fraction of the acoustic biomass index',
    'with landings; it is not a population-model estimate of F-at-age.'
  ),
  timing_evidence = paste(
    'The spring acoustic survey is typically conducted in May (May 6-24 in 2024);',
    'the inshore commercial fishery runs June-August. The index forecast is not an',
    'age-structured population model with observation timing parameters.'
  ),
  output_evidence = paste(
    'The latest 2026 advice reports 2025 aggregate acoustic biomass of 766 kt',
    '(90% CI 560-1,070 kt), a larval abundance recruitment indicator, a maximum-F',
    'index, and an age-disaggregated biomass figure. It reports no population',
    'N-at-age, F-at-age, M-at-age or SSB trajectory.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41306363.pdf;',
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-025-eng.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'This is a distinct current DFO stock complex with extensive age-specific',
    'survey and biological information. The latest advice classifies its approach',
    'as index-based and uses a forecast model for acoustic biomass. Catch-at-age',
    'is supporting fishery biology rather than a population-model likelihood, and',
    'the assessment does not provide population age surfaces or age-specific M.',
    ''
  ),
  notes = paste(
    'The 2026/025 advice presents the 2025 survey and states that additional',
    'publications from the review will follow. The cached Research Document',
    '2025/061 covers data through 2024 and is not a substitute for missing',
    'run-specific detail from the 2025 assessment. The 2025/061 PDF is cached',
    'under source_cache/discovery_dfo_capelin_2j3kl/. A local request for the',
    '2026 PDF returned the publications portal archived-notice page, not a PDF.'
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
  stop('The DFO 2J3KL Capelin row is already reviewed differently.', call. = FALSE)
}

cat('Screened DFO 2J3KL Capelin as outside the age-structured population-model set.\n')

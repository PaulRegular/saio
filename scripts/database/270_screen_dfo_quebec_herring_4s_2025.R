path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Quebec:Atlantic Herring - Herring Fishing Area 15'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO Quebec 4S herring inventory row.', call. = FALSE)
}

detailed_source_url <- paste(
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41291074.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41017535.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41194962.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4124364x.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41260776.pdf'
)
review <- list(
  candidate_unit_id = 'dfo_quebec_4s_herring',
  official_stock_id = 'Quebec North Shore (NAFO Division 4S) spring- and fall-spawning stocks',
  scientific_name = 'Clupea harengus',
  stock_name = 'Atlantic Herring - Quebec North Shore (NAFO 4S)',
  assessment_area = 'Quebec North Shore, NAFO Division 4S (Herring Fishing Area 15)',
  inventory_assessment_year = 2024L,
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2025 update reports commercial catch-at-age composition for spring and',
    'fall spawners through 2024, but the reviewed reports present the age series',
    'as proportions/figures rather than a complete numerical catch-at-age input.'
  ),
  survey_age_evidence = paste(
    'The 2025 update lists total biomass indices and age-specific abundances from',
    'summer acoustic surveys in 4Sw (2019-2024) and fall surveys (2009-2022).',
    'The available reports provide cohort composition and aggregate indices, but',
    'a numerical run-matched age-abundance series was not recovered.'
  ),
  weights_evidence = paste(
    'The 2020 assessment reports historical length- and weight-at-age indicators,',
    'but no complete current run-matched numerical weight-at-age input surface was found.'
  ),
  maturity_evidence = 'No assessment-specific maturity-at-age input was verified in the reviewed current sources.',
  mortality_evidence = paste(
    'The latest approach is index-based and the 2025 update lists mortality data',
    'as unavailable; no age-specific F or M model output is provided.'
  ),
  timing_evidence = paste(
    'The 2024 summer and fall survey-method reports describe survey design, but',
    'no fractional-year timing used by a population assessment is specified.'
  ),
  output_evidence = paste(
    'Official outputs are landings, acoustic biomass indices by spawning group,',
    'catch-age composition and a recruitment index. The reports do not provide',
    'estimated N-at-age, F-at-age, M-at-age or model-derived SSB.'
  ),
  detailed_source_url = detailed_source_url,
  review_date = '2026-10-29',
  decision_reason = paste(
    'The inventory label covers NAFO Division 4S, but official sources identify',
    'two genetically distinct spawning stocks that are assessed separately, so',
    'the one-row identity is ambiguous. The latest method is explicitly index-based,',
    'with no mortality data or fitted age-specific population-state outputs; it is',
    'ineligible for the current age-structured model candidate set.'
  ),
  notes = paste(
    'Do not merge with the separate NAFO 4TVn spring/fall canonical stocks. The',
    '2025 update notes movement and mixing between 4Sw and adjacent 4R and raises',
    'a possible future unit-boundary change, but no revised stock definition is',
    'yet adopted. Cached reports and checksums are under',
    'source_cache/discovery_dfo_quebec_herring_4s_2025/. See',
    'discovery/source_reviews/dfo_quebec_herring_4s_2025.md.'
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
  stop('The DFO Quebec 4S herring row is already reviewed differently.', call. = FALSE)
}

cat('Screened DFO Quebec North Shore herring; the composite is ambiguous and index-based.\n')

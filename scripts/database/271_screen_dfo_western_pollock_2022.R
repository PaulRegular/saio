path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO western-component Pollock inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_western_component_pollock_4xopqrs5',
  official_stock_id = 'Western Component Pollock (4Xopqrs + 5Yb + 5Zc)',
  scientific_name = 'Pollachius virens',
  stock_name = 'Pollock - Western Component',
  assessment_area = paste(
    'NAFO 4Xopqrs plus Canadian portions 5Yb and 5Zc; DFO science unit.',
    'This differs from the broader 4X5YbZc management areas.'
  ),
  inventory_assessment_year = 2024L,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The accepted 2022 ASAP model J_M4B uses commercial catch-at-age for ages',
    '2-13 in 1982-2020. The 2026 data-input report describes corrected fishery',
    'age assignments for 2017-2020. Numeric series are shown in figures; exact',
    'machine-readable arrays were not located.'
  ),
  survey_age_evidence = paste(
    'Model J_M4B uses summer RV trawl abundance-at-age (ages 2-13, 1984-2020',
    'with survey gaps) and acoustic biomass-at-age (ages 2-13, 2012 and 2016-2020).',
    'The acoustic age index is derived from total biomass using tow length',
    'frequencies; source-specific scales and year gaps must be preserved.'
  ),
  weights_evidence = paste(
    'The 2022 model specifies annual survey and beginning-of-year weight-at-age',
    'matrices for ages 2-13 through 2020; the data review plots survey and fishery',
    'weights by age and year. Numeric source arrays were not located.'
  ),
  maturity_evidence = paste(
    'The 2022 model specifies age-year maturity for ages 1-13. The 2026 input',
    'review documents winter-survey maturity samples and early/recent maturity',
    'patterns; exact model input arrays require recovery or documented digitization.'
  ),
  mortality_evidence = paste(
    'The accepted ASAP run uses the four-block natural-mortality matrix estimated',
    'by Model F: M is fixed at 0.2 for ages 2-4 since 1994, while M for ages 5+',
    'varies across 1994-2000, 2001-2010, and 2011-2020. The matrix is supplied to',
    'ASAP rather than estimated within it.'
  ),
  timing_evidence = paste(
    'The 2022 model treats catch and survey inputs at mid-year (0.5) and reports',
    'population outputs at start of year. Survey observations are summer RV and',
    'summer acoustic data; individual sampling dates are not reported as model timing.'
  ),
  output_evidence = paste(
    'The accepted J_M4B report shows N-at-age and F-at-age, SSB for ages 4+, and',
    'Age-2 recruitment for a population through 2020. Trajectories are figure-based;',
    'run-specific numeric output arrays and full trajectory uncertainty were not located.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-025-eng.pdf;',
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-029-eng.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41291050.pdf;',
    'https://www.dfo-mpo.gc.ca/species-especes/profiles-profils/pollock-goberge-eng.html'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'DFO identifies the western population component as 4Xopqrs plus Canadian',
    '5Yb and 5Zc. It is not the same unit as NOAA 5YZ: their assessment areas',
    'overlap but are not one-to-one. The 2022 accepted age-structured model and',
    'the 2026 detailed reports document the required input/output families, so',
    'the unit is eligible for source curation. Numeric arrays require figure',
    'digitization or further source recovery; no data have been imported.'
  ),
  notes = paste(
    'The 2024 HCR update identifies 2022 as the last full assessment and says',
    'no interim model update had occurred since the MSE. The 2026/025 and 2026/029',
    'research documents publish the 2022 MSE inputs and model review after the fact;',
    'they do not establish a later production fit. The assessment run terminates',
    'in 2020. The 2026 PDFs are accessible in the official publication viewer but',
    'the local download endpoint redirected to an archived-page notice; the 2024',
    'HCR update PDF is cached under source_cache/discovery_dfo_western_pollock_2022/.',
    'Do not merge with NOAA Stock SMART 10515 (5YZ); see',
    'discovery/source_reviews/dfo_western_component_pollock_2022.md.'
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
  stop('The DFO western-component Pollock row is already reviewed differently.', call. = FALSE)
}

cat('Screened DFO western-component Pollock; eligible for source curation, with figure-based source recovery limits.\n')

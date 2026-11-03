path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Newfoundland and Labrador:Capelin - NAFO 4RST'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one DFO 4RST Capelin inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_capelin_4rst',
  official_stock_id = 'Estuary and Gulf of St. Lawrence Capelin (4RST)',
  scientific_name = 'Mallotus villosus',
  stock_name = 'Capelin - NAFO 4RST',
  assessment_area = paste(
    'NAFO Divisions 4RST; DFO currently manages the Estuary and Gulf of',
    'St. Lawrence as one unit, although internal stock structure is unresolved.'
  ),
  inventory_assessment_year = 2025L,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The latest report lists annual landings for 1960-2025 and bottom-trawl survey',
    'catches in weight and number for 1990-2025. It explicitly reports age data',
    'as unavailable; no catch-at-age series is reported.'
  ),
  survey_age_evidence = paste(
    'The 2025 assessment uses mature-biomass indices from northern and southern',
    'Gulf bottom-trawl surveys. Age data are unavailable because true and false',
    'otolith annuli cannot be reliably distinguished; cohort analysis is precluded.'
  ),
  weights_evidence = paste(
    'The current assessment reports no weight-at-age data. Survey catch is',
    'reported in weight and number, but not by age.'
  ),
  maturity_evidence = paste(
    'The assessment estimates mature-biomass indices, but no maturity-at-age',
    'data or matrix is reported; age data are unavailable.'
  ),
  mortality_evidence = paste(
    'No age-specific natural mortality is estimated or supplied. A fishing-',
    'mortality index is calculated as landings divided by the previous year',
    'northern-Gulf mature-biomass index, assuming q = 0.01.'
  ),
  timing_evidence = paste(
    'Biomass indices represent August-September surveys, while the fishery begins',
    'at least six months later. No population-model observation timing is specified.'
  ),
  output_evidence = paste(
    'The 2026 advice reports northern- and southern-Gulf mature-biomass indices',
    'with 95% confidence intervals and a fishing-mortality index; the recruitment',
    'index is unavailable. No population N/F/M-at-age or SSB trajectory is reported.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-014-eng.pdf;',
    'https://open-science.canada.ca/server/api/core/bitstreams/b4b5421a-138d-4544-94b0-0c8032c76fc8/content;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41260831.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 4RST unit is distinct from 2J+3KL, but the latest 2025 assessment',
    'explicitly states that age data are unavailable and uses empirical mature-',
    'biomass and fishing-mortality indices rather than an age-structured population',
    'model. It is outside the age-structured tinyAM comparison set.'
  ),
  notes = paste(
    'The latest source is DFO Science Advisory Report 2026/014, based on the 2025',
    'assessment. It says additional meeting publications will follow; the report',
    'also lists the last full assessment as 2024, so retain that date-field',
    'inconsistency in mind. Research Document 2026/007 covers the 2022-2023',
    'assessment and is not a replacement for detailed 2025-run inputs. Its PDF is',
    'cached under source_cache/discovery_dfo_capelin_4rst/. A local request for',
    'the 2026/014 PDF returned HTML rather than a PDF.'
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
  stop('The DFO 4RST Capelin row is already reviewed differently.', call. = FALSE)
}

cat('Screened DFO 4RST Capelin as outside the age-structured population-model set.\n')

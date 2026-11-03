root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'ICES:ghl.27.561214', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'ices_greenland_halibut_561214_2026.md'), warn = FALSE), collapse = '\n')
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'ices_greenland_halibut_561214',
  row$organization == 'ICES',
  row$official_stock_id == 'ghl.27.561214',
  row$scientific_name == 'Reinhardtius hippoglossoides',
  row$inventory_assessment_year == '2026',
  row$match_status == 'new',
  is.na(row$matched_stock_id),
  row$screening_status == 'screened',
  row$eligibility == 'unresolved',
  row$import_status == 'not_started',
  grepl('length compositions by gear', row$catch_age_evidence, fixed = TRUE),
  grepl('from 2015 onward', row$survey_age_evidence, fixed = TRUE),
  grepl('fixed at M = 0.15', row$mortality_evidence, fixed = TRUE),
  grepl('age-5 recruitment', row$output_evidence, fixed = TRUE),
  grepl('catch-at-age or a supported reconstruction', row$decision_reason, fixed = TRUE),
  grepl('not a match to', row$notes, fixed = TRUE),
  grepl('maturity scale imprecise', review, fixed = TRUE),
  grepl('No canonical stock, assessment, input, or output records were added', review, fixed = TRUE),
  sum(units$candidate_ids == row$candidate_id, na.rm = TRUE) == 1L,
  !any(grepl('ghl.27.561214', read.csv(file.path(root, 'database', 'stocks.csv'),
    stringsAsFactors = FALSE)$authority_stock_id, fixed = TRUE), na.rm = TRUE)
)

cat('ICES Greenland halibut identity, 2026 input evidence, unresolved eligibility and no-import checks passed.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  candidate_id = 'DFO:Arctic:Greenland Halibut - NAFO 0A and 0B',
  candidate_unit_id = 'greenland_halibut_sa0_1_offshore',
  official_stock_id = '',
  scientific_name = 'Reinhardtius hippoglossoides',
  stock_name = 'Greenland halibut, NAFO Subarea 0+1 offshore',
  assessment_area = 'NAFO Subarea 0 (Divisions 0A and 0B); assessed jointly with Subarea 1 offshore',
  inventory_assessment_year = '2025',
  catch_age_evidence = paste(
    'The 2025 full assessment uses aggregate commercial catch, not catch-at-age.',
    'The 2026 NAFO data review reports catch totals in metric tonnes by area and',
    'country through 2025, with documented Canadian product-to-round-weight adjustments.'
  ),
  survey_age_evidence = paste(
    'The production assessment uses a combined exploitable-biomass index (>35 cm fork',
    'length) from the 1A-F and 0AB/1CD surveys. A separate age-1 abundance indicator',
    'from the 1A-F survey covers 1991-2025 except 2021; it is not an age-composition',
    'or age-structured likelihood input.'
  ),
  weights_evidence = paste(
    'Reports include supporting growth curves, but no run-matched weight-at-age input',
    'for the aggregate SPiCT production assessment.'
  ),
  maturity_evidence = paste(
    'Historical length-at-maturity information is reported for biological context;',
    'it is not a run-matched maturity-at-age input to the SPiCT assessment.'
  ),
  mortality_evidence = paste(
    'The current production model is surplus-production based and has no age-specific',
    'natural-mortality input.'
  ),
  timing_evidence = paste(
    'A within-year fractional survey timing is not specified for the aggregate',
    'production-model input.'
  ),
  output_evidence = paste(
    'The 2025 assessment reports aggregate biomass and fishing-mortality status relative',
    'to reference points with uncertainty, plus catch projections. The 2026 data review',
    'contains an observed age-1 survey index; no fitted N-at-age or F-at-age surfaces or',
    'model recruitment trajectory were found.'
  ),
  detailed_source_url = paste(
    'https://www.nafo.int/Portals/0/PDFs/sc/2026/scr26-029.pdf;',
    'https://www.nafo.int/Portals/0/PDFs/sc/2025/scs25-13.pdf;',
    'https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-022REV.pdf;',
    'https://www.nafo.int/Portals/0/PDFs/Advice/2025/ghl01off.pdf'
  ),
  decision_reason = paste(
    'The latest full production assessment is an aggregate SPiCT model using total catch',
    'and a biomass index. The separate age-1 index is a recruitment indicator, not a',
    'population age structure; age-based assessment is described as future work.'
  ),
  notes = paste(
    'The DFO Subarea 0 inventory row maps to the wider transboundary NAFO 0+1 offshore',
    'assessment unit. Inshore Cumberland Sound fisheries in 0B are separately managed',
    'and excluded. No matching Northwest Atlantic canonical stock was found; other',
    'Greenland halibut/turbot records cover distinct areas.'
  )
)

i <- match(review$candidate_id, x$candidate_id)
if (is.na(i)) stop('Expected DFO Greenland halibut inventory row was not found.', call. = FALSE)
if (!x$screening_status[i] %in% c('not_started', 'screened') ||
    !x$match_status[i] %in% c('unreviewed', 'new')) {
  stop('DFO Greenland halibut inventory row has an unexpected prior review state.', call. = FALSE)
}
if (any(x$candidate_unit_id[-i] == review$candidate_unit_id, na.rm = TRUE)) {
  stop('Candidate unit ID is already assigned to another inventory row.', call. = FALSE)
}
canonical_area <- paste(stocks$area, stocks$region, stocks$notes)
same_area <- grepl('NAFO Subarea 0|0A.*0B|0\\+1 offshore', canonical_area, ignore.case = TRUE)
if (any(stocks$scientific_name == review$scientific_name & same_area, na.rm = TRUE)) {
  stop('A canonical Northwest Atlantic Greenland halibut record now exists; reconcile it before rerunning.', call. = FALSE)
}

review$match_status <- 'new'
review$screening_status <- 'screened'
review$eligibility <- 'ineligible'
review$import_status <- 'not_started'
review$review_date <- '2026-10-29'
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
cat('Screened the DFO Greenland halibut Subarea 0 inventory entry against the current 0+1 offshore assessment.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:11682', 'DFO:Pacific:Albacore Tuna - North Pacific')
i <- match(ids, x$candidate_id)
if (anyNA(i) || anyDuplicated(x$candidate_id[i])) {
  stop('Expected one NOAA and one DFO North Pacific albacore inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'north_pacific_albacore',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2026 ISC assessment fits fleet catch by year and quarter, reported in metric',
    'tonnes or thousands of fish, plus size compositions. It does not fit observed',
    'catch-at-age; catch-at-age in model outputs is derived and cannot replace a',
    'source age composition.'
  ),
  survey_age_evidence = paste(
    'The base case fits one aggregate standardized CPUE index, Japanese longline Area 2',
    'Quarter 2 (F10, 1996-2024); it is a fishery index, not a survey. No age-specific',
    'index or age-composition likelihood is reported.'
  ),
  weights_evidence = paste(
    'The model uses non-sex-specific seasonal weight-at-length relationships (kg from',
    'fork length in cm). It does not report a fitted weight-at-age input; conversion',
    'would require the model sex-specific growth distribution.'
  ),
  maturity_evidence = paste(
    'Female maturity is assumed to be 50% at age 5 and 100% at ages 6+, based on',
    'length at 50% maturity of 86 cm fork length.'
  ),
  mortality_evidence = paste(
    'Base-case natural mortality is fixed by age and sex: a Lorenzen size-based schedule',
    'for ages 0-2, common to both sexes until age 3, then 0.38 per year for males and',
    '0.49 per year for females.'
  ),
  timing_evidence = paste(
    'The population model is quarterly; spawning and recruitment occur in Quarter 2',
    '(April-June). The fitted F10 index also represents Quarter 2. There is no survey',
    'timing because the base-case index is fishery-derived.'
  ),
  output_evidence = paste(
    'The 2026 report provides annual numeric estimates for age-1+ biomass, female SSB',
    'and recruitment through 2024, with uncertainty. Model-derived catch-at-age and',
    'sex-specific F-at-age are shown in figures; no historical numeric N-at-age table or',
    'machine-readable age-specific trajectories were found.'
  ),
  detailed_source_url = paste(
    'https://www.isc.fra.go.jp/pdf/ISC26/ISC26_ANNEX_08-Stock_Assessment_Report_for_Albacore_Tuna_in_the_North_Pacific_Ocean_v1.pdf;',
    'https://isc.fra.go.jp/reports/stock_assessments.html;',
    'https://www.iattc.org/GetAttachment/a10c525a-36ad-451b-b0fc-f52c532b0281/SAC-17-INF-I_ISC_ALBWG_2026_NPALB_StockAssessment_Executive_Summary_IATTC_SAC_DRAFT-EN.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 11682 and the DFO North Pacific albacore listing identify the',
    'same transboundary ISC stock (equator to 55 degrees N; 120 degrees E to 100',
    'degrees W), new to the canonical database. The latest production assessment is',
    'the 2026 ISC benchmark, based on data through 2024. Although its internal model',
    'is age- and sex-structured and reports age-specific fitted outputs, its accepted',
    'observations are total catch, aggregate fishery CPUE and length compositions.',
    '',
    'without inventing observations; screen this shared unit outside the current',
    'age-disaggregated translation set.'
  ),
  notes = paste(
    'ISC/26/ANNEX/08 supersedes the 2023 assessment; NOAA Stock SMART metadata still',
    'lists 2023, so the inventory year is retained as source metadata and not treated',
    'as the current production run. Canada is an ISC member and contributes fishery',
    'data to this shared assessment; DFO and NOAA entries are one biological unit,',
    'not two stocks. The official report is cached under',
    'source_cache/discovery_north_pacific_albacore/ with its retrieval date, pinned',
    'revision and SHA-256. ISC stock-assessment data files require an access request;'
    ,'the public report is the reviewed evidence.'
  )
)

for (j in seq_along(i)) {
  if (x$screening_status[i[j]] == 'not_started' &&
      x$match_status[i[j]] == 'unreviewed') {
    for (column in names(review)) x[[column]][i[j]] <- review[[column]]
  } else if (!all(vapply(names(review), function(column) {
    identical(as.character(x[[column]][i[j]]), as.character(review[[column]]))
  }, logical(1L)))) {
    stop(paste('Candidate row has a conflicting prior review:', ids[j]), call. = FALSE)
  }
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
for (j in seq_along(i)) {
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i[j], , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i[j] + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Crosswalked NOAA and DFO albacore entries to one screened North Pacific stock unit.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  candidate_id = 'DFO:Pacific:Longspine Thornyhead',
  candidate_unit_id = 'dfo_longspine_thornyhead_bc',
  scientific_name = 'Sebastolobus altivelis',
  assessment_area = 'British Columbia Pacific coast; no current assessment boundary verified',
  inventory_assessment_year = '',
  catch_age_evidence = paste(
    'The 2025 DFO review of commercial groundfish biological samples covers 1996-2022. It',
    'reports 34,488 Longspine Thornyhead age structures collected, none aged. No current',
    'numeric catch-at-age series was found.'
  ),
  survey_age_evidence = paste(
    'No age-specific survey index or survey age-composition input was verified. DFO reports',
    'that no acceptable ageing protocol was available for this species.'
  ),
  weights_evidence = paste(
    'The reviewed 2025 biological-sampling report describes length and specimen sampling,',
    'but no age-specific weight surface for a current assessment was found.'
  ),
  maturity_evidence = 'No run-matched age-specific maturity input for a current assessment was found.',
  mortality_evidence = 'No current age-structured assessment mortality specification was found.',
  timing_evidence = 'No current age-structured assessment observation timing was found.',
  output_evidence = paste(
    'No current official age-specific N, F, or M outputs, recruitment series, or assessment',
    'SSB trajectory were found for the British Columbia unit.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs97-6/Fs97-6-3722-eng.pdf;',
    'https://www.psmfc.org/tsc-drafts/2024/DFO_2024_TSC_Report.pdf;',
    'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/ground-fond-ifmp-pgip-sm-eng.html'
  ),
  decision_reason = paste(
    'Ineligible for the age-disaggregated assessment set: DFO reports that no current age',
    'assessment was scheduled and that age structures collected through 2022 had not been',
    'aged. The species has historical research documents, but current age observations and',
    'age-specific production outputs were not verified.'
  ),
  notes = paste(
    'Distinct provisional DFO Pacific unit; no canonical stock match found. The 2025 DFO',
    'technical-report PDF redirected to an archived-information notice and the 2024 DFO',
    'groundfish report URL returned 404 on 2026-10-29, so neither file was cached locally.'
  )
)

i <- match(review$candidate_id, x$candidate_id)
if (is.na(i)) stop('Expected DFO Longspine Thornyhead inventory row was not found.', call. = FALSE)
if (!x$screening_status[i] %in% c('not_started', 'screened') ||
    !x$match_status[i] %in% c('unreviewed', 'new')) {
  stop('DFO Longspine Thornyhead inventory row has an unexpected prior review state.', call. = FALSE)
}
if (any(stocks$scientific_name == review$scientific_name &
    grepl('longspine', tolower(stocks$common_name)), na.rm = TRUE)) {
  stop('A canonical Longspine Thornyhead record now exists; reconcile it before rerunning.', call. = FALSE)
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
cat('Screened the DFO British Columbia Longspine Thornyhead inventory entry as age-data-ineligible.\n')

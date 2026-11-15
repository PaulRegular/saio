root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)

unit_id <- 'pacific_sardine_northern_subpopulation'
source_review <- file.path(root, 'discovery', 'source_reviews',
  'pacific_sardine_northern_subpopulation_2025.md')
noaa_i <- match('NOAA:10573', x$candidate_id)
dfo_i <- which(x$organization == 'DFO' & grepl('^DFO:Pacific:Sardine', x$candidate_id))
if (is.na(noaa_i) || length(dfo_i) != 1L) {
  stop('Expected NOAA and DFO Pacific sardine inventory rows are missing.', call. = FALSE)
}
if (any(stocks$scientific_name == 'Sardinops sagax')) {
  stop('A canonical Pacific sardine record exists; reconcile it before screening.', call. = FALSE)
}

noaa_review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  scientific_name = 'Sardinops sagax',
  stock_name = 'Pacific sardine - Northern Subpopulation',
  assessment_area = 'Northern Baja California to British Columbia; California Current, offshore to 300 nm',
  catch_age_evidence = paste(
    'The 2025 Stock Synthesis update uses three commercial fleets and reports NSP landings',
    'by model year-semester in metric tonnes for 2005-2024. It confirms fishery age-composition',
    'data, but the full run-matched numerical age-composition arrays are not published in the',
    'report. Catch-at-age therefore cannot yet be reconstructed for this latest run.'
  ),
  survey_age_evidence = paste(
    'The model uses an acoustic-trawl survey with aggregate biomass and age compositions.',
    'The 2024 survey report gives regional biomass and sample summaries, including 80 core-area',
    'and 98 nearshore aged fish, but not the run-matched numerical age-composition arrays.'
  ),
  weights_evidence = paste(
    'Fishery conditional weights-at-age were updated for the 2025 run, and 2024 survey',
    'weights-at-age were computed. The report describes the conditional correlation models,',
    'but does not provide complete run-matched age-specific input surfaces.'
  ),
  maturity_evidence = paste(
    'The 2025 report refers to biological inputs from the 2024 benchmark; numeric run-matched',
    'maturity-at-age values were not recovered for the 2025 update.'
  ),
  mortality_evidence = paste(
    'Natural mortality is estimated with a prior; the 2025 report gives an estimate of',
    '0.53 per year. Run-matched age-specific estimates and uncertainty were not recovered.'
  ),
  timing_evidence = paste(
    'The model is seasonal with two semesters per calendar year; the mapping is shifted so',
    'calendar 2005-2 begins model year 2005-1. Exact within-year survey timing was not recovered.'
  ),
  output_evidence = paste(
    'The 2025 report tabulates official age-1+ biomass in metric tonnes and age-0 recruitment',
    'in thousands for semesters in 2005-2025, with aggregate uncertainty summaries. Numerical',
    'age-specific fitted N and F surfaces were not found in the public report.'
  ),
  detailed_source_url = paste(
    'https://doi.org/10.25923/z1xh-b932;',
    'https://www.pcouncil.org/documents/sardine-2024-model-files-zip-file/;',
    'https://doi.org/10.25923/jyw3-ys65'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The latest public production run is the detailed 2025 update assessment. It confirms',
    'age-composition likelihoods and reports run-specific catch and aggregate population',
    'outputs, but the exact 2025 age-composition arrays and complete age-specific biological',
    'and fitted population surfaces are unavailable. The public native files are for the 2024',
    'benchmark and cannot replace missing 2025-run data. Keep the latest run partial and',
    'eligibility unresolved pending its run-matched electronic files.'
  ),
  notes = paste(
    'Cross-inventory unit shared with the DFO Pacific Sardine management entry. DFO describes',
    'the northern subpopulation as the stock managed under its BC harvest plan; its 2022',
    'advice uses NOAA assessment biomass. This is one biological unit, not separate NOAA and',
    'DFO candidates. NOAA 2025 model files were not located; cached 2024 benchmark files are',
    'retained only as a source-availability cross-check. See the source review.'
  )
)

dfo_review <- list(
  candidate_unit_id = unit_id,
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  scientific_name = 'Sardinops sagax',
  stock_name = 'Pacific Sardine - Northern Subpopulation',
  assessment_area = 'Northern Subpopulation; British Columbia waters within the California Current range',
  catch_age_evidence = paste(
    'The reviewed DFO harvest advice does not provide a separate DFO catch-at-age series;',
    'it refers to the shared NOAA northern-subpopulation assessment.'
  ),
  survey_age_evidence = paste(
    'The reviewed DFO sources do not document a separate DFO age-specific survey input.',
    'The acoustic-trawl survey belongs to the shared NOAA assessment; see NOAA:10573.'
  ),
  weights_evidence = 'No separate DFO assessment weight-at-age input was identified in the reviewed advice or IFMP summary.',
  maturity_evidence = 'No separate DFO assessment maturity-at-age input was identified in the reviewed advice or IFMP summary.',
  mortality_evidence = 'The reviewed DFO sources do not identify a separate DFO mortality process; the linked NOAA model estimates M.',
  timing_evidence = 'No separate DFO model survey timing was identified; the linked NOAA assessment is semiannual.',
  output_evidence = paste(
    'DFO 2022 harvest advice reports the NOAA July 2022 age-1+ biomass forecast for the',
    'northern subpopulation; it is not a separate DFO model output.'
  ),
  detailed_source_url = paste(
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41074506.pdf;',
    'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/sardine-ifmp-pgip-sm-eng.html;',
    'https://doi.org/10.25923/z1xh-b932'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'DFO manages the same northern subpopulation under a BC harvest plan and its 2022 advice',
    'uses NOAA assessment biomass. No distinct DFO age-structured assessment was identified',
    'in the reviewed sources. Link this inventory row to the NOAA candidate unit and do not',
    'count or import it as a second assessment.'
  ),
  notes = paste(
    'The 2024-2029 IFMP summary says the fishery has not harvested Pacific sardine in BC since',
    '2012 and has been formally closed since 2015. The DFO row and NOAA:10573 are one',
    'transboundary northern-subpopulation unit. See ignored source_cache/',
    'discovery_pacific_sardine_2025/sources.csv.'
  )
)

update_row <- function(i, review, label) {
  if (x$screening_status[i] == 'screened') {
    for (column in names(review)) {
      if (!identical(as.character(x[[column]][i]), as.character(review[[column]]))) {
        stop(paste('Previously screened', label, 'field changed:', column), call. = FALSE)
      }
    }
    return(invisible(NULL))
  }
  if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
    stop(paste('Preserve the existing', label, 'review state before screening.'), call. = FALSE)
  }
  for (column in names(review)) x[[column]][i] <<- review[[column]]
}

update_row(noaa_i, noaa_review, 'NOAA Pacific sardine')
update_row(dfo_i, dfo_review, 'DFO Pacific sardine')
if (!file.exists(source_review)) stop('Pacific sardine source review is missing.', call. = FALSE)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
for (i in c(noaa_i, dfo_i)) {
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened the shared NOAA/DFO Pacific sardine northern-subpopulation unit; no canonical data imported.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'DFO:Pacific:Lingcod - Outside waters'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected DFO outside-lingcod inventory row was not found.', call. = FALSE)
if (any(x$stock_name == 'Lingcod - Outside waters' & x$organization != 'DFO', na.rm = TRUE)) {
  stop('Unexpected non-DFO stock-name collision for outside lingcod.', call. = FALSE)
}
if (!is.na(x$matched_stock_id[i]) && nzchar(x$matched_stock_id[i])) {
  stop('Unexpected canonical match for DFO outside lingcod.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_lingcod_outside_bc',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  scientific_name = 'Ophiodon elongatus',
  assessment_area = 'British Columbia outside waters, PMFC Areas 3CD + 5ABCDE, excluding Area 4B',
  inventory_assessment_year = '2025',
  catch_age_evidence = paste(
    'The 2025 Science Advisory Report gives fleet catch totals in tonnes for 1996-2024',
    'and identifies a reconstructed catch history from 1927. It confirms age-composition',
    'data for three fleets, but does not publish their numerical vectors or catch-at-age.',
    'The linked Research Document is cited as in preparation and was not located.'
  ),
  survey_age_evidence = paste(
    'The report describes four abundance indices and age compositions from SYN, HBLL,',
    'and IPHC surveys. No numerical age-composition arrays or age-specific index series',
    'were found in the public report.'
  ),
  weights_evidence = paste(
    'The report says growth and maturity parameters were estimated externally from BC',
    'research, survey, and commercial-fishery data. A run-matched weight-at-age surface',
    'is not tabulated in the public report.'
  ),
  maturity_evidence = paste(
    'Maturity is a fixed external biological input, but its age-specific values and',
    'run-matched source are not provided in the public report.'
  ),
  mortality_evidence = paste(
    'The report describes fishing-mortality and removal-reference quantities but does',
    'not provide the base-case natural-mortality input or an age-specific M schedule.'
  ),
  timing_evidence = paste(
    'The population trajectory is annual from 1927 to the beginning of 2025. Fractional',
    'timing for the four abundance indices is not given in the public report.'
  ),
  output_evidence = paste(
    'Table 1 provides 5th, 25th, 50th, 75th, and 95th posterior quantiles for B2025, B0,',
    'B2025/B0, F2024, and reference rates. SSB, F, and age-0 recruitment trajectories',
    'are shown graphically with 90% credibility envelopes; numeric N-at-age and F-at-age',
    'arrays were not found.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-6/Fs70-6-2025-054-eng.pdf;',
    'https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/ground-fond-ifmp-pgip-sm-eng.html'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 2025 full assessment concerns the distinct DFO outside-British-Columbia unit',
    '(PMFC 3CD + 5ABCDE, excluding 4B). The official report confirms age compositions',
    'in the fitted model and provides run-specific catch totals and population outputs,',
    'but the numeric age inputs, survey index series, biological surfaces, and model files',
    'were not located. Eligibility for the age-disaggregated source set remains unresolved;',
    'this is a source-availability gap, not evidence that the current model lacks age data.'
  ),
  notes = paste(
    'No canonical stock match was found. DFO identifies inside Area 4B and outside waters',
    'as separate lingcod units. NOAA Stock SMART has separate U.S. Northern and Southern',
    'Pacific Coast records; no unit equivalence to this Canadian outside unit was established.'
  )
)

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
cat('Screened DFO outside lingcod 2025 assessment.\n')
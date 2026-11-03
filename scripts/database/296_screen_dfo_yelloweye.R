path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  'DFO:Pacific:Yelloweye Rockfish - Inside Waters' = list(
    candidate_unit_id = 'dfo_yelloweye_inside_bc',
    official_stock_id = 'DFO Inside Yelloweye Rockfish (Area 4B)',
    scientific_name = 'Sebastes ruberrimus',
    stock_name = 'Yelloweye Rockfish - Inside Waters',
    assessment_area = paste(
      'Groundfish Management Area 4B: Queen Charlotte Strait, Strait of Georgia,',
      'and Strait of Juan de Fuca'
    ),
    inventory_assessment_year = '2020',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'unresolved',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The age-structured stock-reduction analyses used survey age compositions.',
      'Commercial age samples are reported from one 1989 fishing trip only;',
      'annual aggregate catches do not establish a representative catch-at-age',
      'series. The pinned source repository contains privacy-compliant sample',
      'objects and processing code.'
    ),
    survey_age_evidence = paste(
      'The 2021/008 report describes age data from area 4B surveys in 1984-2018,',
      'with most samples from the HBLL survey after it began in 2003. The SRA',
      'uses HBLL survey age compositions with an 80+ model group; sample sizes',
      'are small.'
    ),
    weights_evidence = paste(
      'Biological samples and growth relationships are documented, but a',
      'run-matched numeric weight-at-age input table was not verified in this',
      'screen.'
    ),
    maturity_evidence = paste(
      'The detailed rebuilding report derives age-based, sex-specific maturity',
      'ogives from survey biological samples.'
    ),
    mortality_evidence = paste(
      'Natural mortality is an assumed/distributional OM quantity informed by',
      'life history and prior work; the model does not estimate an age-specific',
      'M surface.'
    ),
    timing_evidence = paste(
      'The reports identify survey series and years, but a fractional within-year',
      'timing for the age-composition observations was not verified.'
    ),
    output_evidence = paste(
      'The latest detailed age-structured MSE report provides OM biomass',
      'trajectories and stock-status probabilities through 2019, not a standard',
      'annual N-at-age/F-at-age output table.'
    ),
    detailed_source_url = paste(
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/4127698x.pdf;',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41058136.pdf;',
      'https://github.com/pbs-assess/yelloweye-inside/tree/2f9a8a4'
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'DFO identifies June 2020 as the latest science advice for the current',
      'inside unit. The detailed 2021/008 rebuilding analysis and its pinned',
      'source repository document age-structured SRA operating models and',
      'survey age-composition data. Eligibility remains unresolved for the',
      '',
      'cover only one trip and do not establish annual catch-at-age; a numeric',
      'weight-at-age series, survey timing, and comparable age-specific outputs',
      'also remain unverified.'
    ),
    notes = paste(
      'Inside is a distinct current population in Area 4B, separate from Outside',
      'Yelloweye Rockfish. The 2021/008 analysis models data through 2019 and is',
      'a rebuilding/MSE analysis, not a new conventional assessment run. No',
      'canonical assessment or numeric series was imported.'
    )
  ),
  'DFO:Pacific:Yelloweye Rockfish - Outside Waters' = list(
    candidate_unit_id = 'dfo_yelloweye_outside_bc',
    official_stock_id = 'DFO Outside Yelloweye Rockfish (BC coastwide)',
    scientific_name = 'Sebastes ruberrimus',
    stock_name = 'Yelloweye Rockfish - Outside Waters',
    assessment_area = paste(
      'British Columbia outside waters; the 2026 advice reports a coastwide',
      'status update, with North and South operating-model components'
    ),
    inventory_assessment_year = '2024',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'unresolved',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The detailed 2020/069 rebuilding analysis uses aggregate commercial catch',
      'and available age-composition inputs from commercial and survey sources.',
      'The 2024 update inputs could not be verified because its report PDF is',
      'currently unavailable at the official download URL.'
    ),
    survey_age_evidence = paste(
      'The 2019 age-structured operating models use survey age-composition data',
      'from PHMA, IPHC, and trawl sources. The 2023 update corrects the age-',
      'composition likelihood but explicitly adds no new data.'
    ),
    weights_evidence = paste(
      'The 2020/069 report documents growth and biological sampling, but a',
      'run-matched numeric weight-at-age input table for the 2024 update was not',
      'verified.'
    ),
    maturity_evidence = paste(
      'The 2020/069 operating models use age-based maturity derived from',
      'biological samples; the 2024 update-specific input was not verified.'
    ),
    mortality_evidence = paste(
      'Natural mortality is an uncertain operating-model quantity and was',
      'revised with the 2023 likelihood correction; it is not an estimated',
      'age-specific M surface.'
    ),
    timing_evidence = paste(
      'The 2020/069 report identifies the survey series, but the 2024 update',
      'report and its fractional survey timing could not be verified.'
    ),
    output_evidence = paste(
      'DFO published a 2026/039 science advisory report titled as a 2024 stock-',
      'status update. Its official PDF URL returned an archived-information',
      'placeholder during this review, so the current numeric outputs could not',
      'be checked. The 2023 advice reports status through 2018.'
    ),
    detailed_source_url = paste(
      'https://publications.gc.ca/site/eng/9.964233/publication.html;',
      'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-039-eng.pdf;',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41218607.pdf;',
      'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40951704.pdf'
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'The current outside unit received a 2024 status update, published as DFO',
      'Science Advisory Report 2026/039 in August 2026. The official PDF link',
      'currently returns an archived-information page, so run-specific inputs',
      'and numerical outputs from the latest update remain unverified. Earlier',
      'same-unit documents confirm age-structured operating models and age-',
      'composition data, but cannot substitute for the current update. Keep',
      'eligibility unresolved pending access to the 2026 report and its detailed',
      'supporting data.'
    ),
    notes = paste(
      'The 2024 update is the primary current-unit record. The 2019 data through',
      '2018 in Research Document 2020/069 and its 2023 likelihood correction are',
      'historical same-unit context only; they are not used to fill current-run',
      'gaps. Inside Yelloweye Rockfish remains a separate population. No',
      'canonical assessment or numeric series was imported.'
    )
  )
)

for (id in names(review)) {
  i <- match(id, x$candidate_id)
  if (is.na(i)) stop('Expected candidate row: ', id, call. = FALSE)
  if (!is.na(x$matched_stock_id[i]) && nzchar(x$matched_stock_id[i])) {
    stop('Unexpected canonical match for ', id, call. = FALSE)
  }
  for (column in names(review[[id]])) x[[column]][i] <- review[[id]][[column]]
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) {
  stop('Candidate CSV contains multiline rows; refusing unsafe update.', call. = FALSE)
}
for (id in names(review)) {
  i <- match(id, x$candidate_id)
  row <- x[i, , drop = FALSE]
  row[] <- lapply(row, as.character)
  tmp <- tempfile(fileext = '.csv')
  write.csv(row, tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened the current DFO inside and outside Yelloweye inventory entries.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  'NOAA:10521' = list(
    candidate_unit_id = 'noaa_silver_hake_northern',
    matched_stock_id = '',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    scientific_name = 'Merluccius bilinearis',
    stock_name = 'Silver hake - Gulf of Maine / Northern Georges Bank',
    assessment_area = 'Gulf of Maine and northern Georges Bank',
    catch_age_evidence = paste(
      'The 2023 update reports commercial landings, discards, and total catch',
      'in metric tons, not catch-at-age. Older reports show NEFSC survey',
      'numbers-at-age, but those are not fishery catch-at-age. An age-based',
      'ASAP assessment attempted in the 2010 benchmark was not accepted.'
    ),
    survey_age_evidence = paste(
      'The current empirical update uses aggregate NEFSC fall bottom-trawl',
      'biomass indices in kg/tow. Fall survey numbers-at-age are shown in the',
      '2017 update for 1963-2015, but are supporting age information and are',
      'not used by the current assessment; a run-matched numeric age-index',
      'series for the current fit was not verified.'
    ),
    weights_evidence = paste(
      'The empirical catch-and-survey-index method does not require or report',
      'weight-at-age.'
    ),
    maturity_evidence = paste(
      'The empirical catch-and-survey-index method does not require or report',
      'maturity-at-age.'
    ),
    mortality_evidence = paste(
      'The current assessment is empirical rather than age-structured. It',
      'reports a three-year mean exploitation ratio (catch divided by survey',
      'biomass); it does not estimate age-specific F, recruitment, or M.'
    ),
    timing_evidence = paste(
      'The index comes from the NEFSC autumn bottom-trawl survey. The',
      'assessment reports annual survey years but no within-year observation',
      'fraction.'
    ),
    output_evidence = paste(
      'The 2023 Management Track report updates catch and survey biomass',
      'through 2022. For 2022 it reports the 2020-2022 mean fall biomass',
      'index of 28.64 kg/tow and mean exploitation ratio of 0.11. It does not',
      'report fitted population-at-age or F-at-age.'
    ),
    detailed_source_url = paste(
      'https://repository.library.noaa.gov/view/noaa/70900/noaa_70900_DS1.pdf;',
      'https://repository.library.noaa.gov/view/noaa/39404/noaa_39404_DS1.pdf;',
      'https://repository.library.noaa.gov/view/noaa/17249/noaa_17249_DS1.pdf;',
      'https://repository.library.noaa.gov/view/noaa/3778;',
      'https://www.fisheries.noaa.gov/species/silver-hake', sep = ' '
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'NOAA identifies a distinct northern silver hake stock in the Gulf of',
      'Maine and northern Georges Bank. The latest detailed update used for',
      'advice is the 2023 Management Track update (data through 2022); it was',
      'not peer reviewed in fall 2023 and continues the empirical index-based',
      'method. Fishery catch is aggregate, and no current age-specific',
      'population outputs or fishery catch-at-age were verified. The older',
      'age-structured ASAP attempt was not accepted. Ineligible for the',
      'age-disaggregated assessment set.'
    ),
    notes = paste(
      'The 2017 report presents survey numbers-at-age through 2015, but that',
      'does not make them likelihood inputs to the current empirical model.',
      'NOAA repository PDFs were readable in the official online viewer but',
      'direct local downloads returned HTTP 403; no incomplete files were',
      'retained in source_cache/discovery_silver_hake/.'
    )
  ),
  'NOAA:10522' = list(
    candidate_unit_id = 'noaa_silver_hake_southern',
    matched_stock_id = '',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    scientific_name = 'Merluccius bilinearis',
    stock_name = 'Silver hake - Southern Georges Bank / Mid-Atlantic',
    assessment_area = 'Southern Georges Bank and Mid-Atlantic Bight',
    catch_age_evidence = paste(
      'The 2023 update reports commercial landings, discards, and total catch',
      'in metric tons, not catch-at-age. Older reports show NEFSC survey',
      'numbers-at-age, but those are not fishery catch-at-age. An age-based',
      'ASAP assessment attempted in the 2010 benchmark was not accepted.'
    ),
    survey_age_evidence = paste(
      'The current empirical update uses aggregate NEFSC fall bottom-trawl',
      'biomass indices in kg/tow. Fall survey numbers-at-age are shown in the',
      '2017 update for 1963-2015, but are supporting age information and are',
      'not used by the current assessment; a run-matched numeric age-index',
      'series for the current fit was not verified.'
    ),
    weights_evidence = paste(
      'The empirical catch-and-survey-index method does not require or report',
      'weight-at-age.'
    ),
    maturity_evidence = paste(
      'The empirical catch-and-survey-index method does not require or report',
      'maturity-at-age.'
    ),
    mortality_evidence = paste(
      'The current assessment is empirical rather than age-structured. It',
      'reports a three-year mean exploitation ratio (catch divided by survey',
      'biomass); it does not estimate age-specific F, recruitment, or M.'
    ),
    timing_evidence = paste(
      'The index comes from the NEFSC autumn bottom-trawl survey. The',
      'assessment reports annual survey years but no within-year observation',
      'fraction.'
    ),
    output_evidence = paste(
      'The 2023 Management Track report updates catch and survey biomass',
      'through 2022. For 2022 it reports the 2020-2022 mean fall biomass',
      'index of 1.036 kg/tow and mean exploitation ratio of 3.878. It does',
      'not report fitted population-at-age or F-at-age.'
    ),
    detailed_source_url = paste(
      'https://repository.library.noaa.gov/view/noaa/70900/noaa_70900_DS1.pdf;',
      'https://repository.library.noaa.gov/view/noaa/39404/noaa_39404_DS1.pdf;',
      'https://repository.library.noaa.gov/view/noaa/17249/noaa_17249_DS1.pdf;',
      'https://repository.library.noaa.gov/view/noaa/3778;',
      'https://www.fisheries.noaa.gov/species/silver-hake', sep = ' '
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'NOAA identifies a distinct southern silver hake stock in southern',
      'Georges Bank and the Mid-Atlantic Bight. The latest detailed update',
      'used for advice is the 2023 Management Track update (data through',
      '2022); it was not peer reviewed in fall 2023 and continues the',
      'empirical index-based method. Fishery catch is aggregate, and no',
      'current age-specific population outputs or fishery catch-at-age were',
      'verified. The older age-structured ASAP attempt was not accepted.',
      'Ineligible for the age-disaggregated assessment set.'
    ),
    notes = paste(
      'NOAA defines this as separate from the northern stock; the southern',
      'management unit also includes offshore hake in catch advice. The 2017',
      'report presents survey numbers-at-age through 2015, but these are not',
      'likelihood inputs to the current empirical model. NOAA repository',
      'PDFs were readable in the official online viewer but direct local',
      'downloads returned HTTP 403; no incomplete files were retained in',
      'source_cache/discovery_silver_hake/.'
    )
  ),
  'DFO:Maritimes:Silver Hake - NAFO 4VWX' = list(
    candidate_unit_id = 'dfo_silver_hake_4vwx',
    matched_stock_id = '',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    official_stock_id = 'NAFO 4VWX',
    scientific_name = 'Merluccius bilinearis',
    stock_name = 'Silver Hake - NAFO 4VWX',
    assessment_area = 'NAFO Divisions 4VWX (Scotian Shelf)',
    inventory_assessment_year = '2025',
    catch_age_evidence = paste(
      'The latest 2025 stock status update uses commercial landings, not',
      'catch-at-age. The 2012 framework describes exploratory VPA work, but',
      'the current production update uses a biomass-dynamics model.'
    ),
    survey_age_evidence = paste(
      'The current assessment uses the DFO Maritimes Summer RV Survey as an',
      'aggregate biomass index. No current age-specific index or age',
      'composition used by the 2025 update was verified.'
    ),
    weights_evidence = paste(
      'The biomass-dynamics assessment does not use or report',
      'weight-at-age.'
    ),
    maturity_evidence = paste(
      'The biomass-dynamics assessment does not use or report',
      'maturity-at-age.'
    ),
    mortality_evidence = paste(
      'The current method is a logistic biomass-dynamics model. The 2025',
      'update reports aggregate fishing mortality relative to FMSY, not',
      'age-specific F or natural mortality.'
    ),
    timing_evidence = paste(
      'The abundance index is from the DFO Maritimes Summer RV Survey.',
      'The report identifies a summer survey but does not specify an exact',
      'within-year fraction.'
    ),
    output_evidence = paste(
      'The 2025 update reports biomass above the upper stock reference in',
      '2025, recruitment trends, aggregate fishing mortality below FMSY, and',
      '2026/27 catch advice. No age-specific N or F outputs are reported.'
    ),
    detailed_source_url = paste(
      'https://publications.gc.ca/site/eng/9.960341/publication.html;',
      'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-7/Fs70-7-2026-011-eng.pdf;',
      'https://waves-vagues.dfo-mpo.gc.ca/Library/350223.pdf;',
      'https://waves-vagues.dfo-mpo.gc.ca/Library/348812.pdf', sep = ' '
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'The latest DFO assessment is the 2025 4VWX stock status update,',
      'reviewed in December 2025 and published in March 2026. It documents',
      'an aggregate logistic biomass-dynamics model based on commercial',
      'landings and the summer RV biomass survey. Age-structured VPA work in',
      'the 2012 framework is historical and is not the current method. The',
      'latest unit has run-specific catch, biomass, recruitment and aggregate',
      'mortality information, but no age-disaggregated input set or outputs;',
      'ineligible for the age-disaggregated assessment set.'
    ),
    notes = paste(
      'The 4VWX Scotian Shelf unit is retained separately from the NOAA',
      'northern and southern U.S. management units; shared species identity',
      'does not establish a shared assessment unit. The 2012 framework and',
      'assessment PDFs are cached locally with checksums. The 2026/011 PDF',
      'link currently returns a Government of Canada archive landing page to',
      'direct download, so only its online text and catalogue record were',
      'reviewed; the incomplete response was not retained.'
    )
  )
)

for (id in names(review)) {
  i <- match(id, x$candidate_id)
  if (is.na(i)) stop('Expected candidate row: ', id, call. = FALSE)
  fields <- review[[id]]
  for (column in names(fields)) x[[column]][i] <- fields[[column]]
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
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
cat('Screened two NOAA and one DFO silver hake inventory entries.\n')

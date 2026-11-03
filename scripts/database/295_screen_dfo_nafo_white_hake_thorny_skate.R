path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

review <- list(
  'DFO:Newfoundland and Labrador:Thorny Skate - NAFO 3LNO' = list(
    candidate_unit_id = 'nafo_thorny_skate_3lnops',
    official_stock_id = 'NAFO 3LNOPs',
    scientific_name = 'Amblyraja radiata',
    stock_name = 'Thorny skate - NAFO 3LNOPs',
    assessment_area = 'NAFO Divisions 3LNO and Subdivision 3Ps',
    inventory_assessment_year = '2026',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2024 NAFO assessment reviews landings and commercial size distributions,',
      'not catch-at-age. The 2024 NAFO sampling inventory lists Canadian commercial',
      'sampling as catch only; no Canadian age samples are listed.'
    ),
    survey_age_evidence = paste(
      'The current advice method is a qualitative review of aggregate survey biomass',
      'and abundance indices. The recruitment indicator counts fish <=21 cm total',
      'length; it is not an age-specific abundance series.'
    ),
    weights_evidence = 'Weight-at-age is not required or reported by the current qualitative survey-index assessment.',
    maturity_evidence = 'Maturity-at-age is not required or reported by the current qualitative survey-index assessment.',
    mortality_evidence = paste(
      'The assessment reports a relative F index calculated as commercial landings',
      'divided by Canadian spring survey biomass. It does not estimate age-specific',
      'instantaneous F or M.'
    ),
    timing_evidence = paste(
      'The reports identify Canadian spring and autumn surveys and EU surveys by',
      'season. No within-year fraction is specified for an age-specific observation.'
    ),
    output_evidence = paste(
      'The 2024 assessment reports aggregate survey indices, length-based recruitment',
      'and relative F, not fitted N-at-age, F-at-age, or M-at-age. NAFO could not',
      'provide updated 2026 assessment or monitoring advice.'
    ),
    detailed_source_url = paste(
      'https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf;',
      'https://www.nafo.int/Portals/0/PDFs/Advice/2026/skate3lno3ps.pdf;',
      'https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-038.pdf;',
      'https://www.nafo.int/Portals/0/PDFs/sc/2024/scs24-24.pdf;',
      'https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/groundfish-poisson-fond/2025/groundfish-poisson-fond-div3ps-nafo-opano-eng.html'
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'DFO and NAFO describe 3LNO and 3Ps as one biological stock, although 3Ps',
      'is separately managed by Canada and France. The latest 2026 advice reports',
      'that no full assessment or interim monitoring report was completed. The',
      'latest detailed assessment, NAFO SCR Doc. 24/038, is a qualitative analysis',
      'of catch and survey indices without age-disaggregated observations or',
      'population outputs. Ineligible for the age-disaggregated assessment set.'
    ),
    notes = paste(
      'The 2025 state-space paper for this stock is research and is not the',
      'production assessment underlying NAFO advice. The DFO inventory name',
      '3LNO is retained in candidate_id; candidate_unit_id represents the',
      'whole NAFO 3LNOPs biological stock. The detailed 2024 SCR is marked DRAFT.'
    )
  ),
  'DFO:Newfoundland and Labrador:White Hake - NAFO 3NOPs' = list(
    candidate_unit_id = 'nafo_white_hake_3nops',
    official_stock_id = 'NAFO 3NOPs',
    scientific_name = 'Urophycis tenuis',
    stock_name = 'White hake - NAFO 3NOPs',
    assessment_area = 'NAFO Divisions 3NO and Subdivision 3Ps',
    inventory_assessment_year = '2026',
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The 2023 assessment reports landings and fishery length frequencies, not',
      'catch-at-age. Age determination of collected otoliths is recommended for',
      'future age-based analyses.'
    ),
    survey_age_evidence = paste(
      'The assessment uses aggregate survey biomass and abundance indices and a',
      'recruitment index based on fish <27 cm. It does not use age-specific survey',
      'observations.'
    ),
    weights_evidence = 'Weight-at-age is not required or reported by the current qualitative survey-index assessment.',
    maturity_evidence = 'Maturity-at-age is not required or reported by the current qualitative survey-index assessment.',
    mortality_evidence = paste(
      'Relative F is calculated as commercial landings divided by Canadian spring',
      'survey biomass. The assessment does not estimate age-specific instantaneous',
      'F or natural mortality.'
    ),
    timing_evidence = paste(
      'The report identifies Canadian spring and autumn surveys and EU surveys by',
      'season; it does not specify an age-specific survey timing fraction.'
    ),
    output_evidence = paste(
      'The 2023 full assessment reports aggregate survey indices, length-based',
      'recruitment and relative F, not fitted N-at-age, F-at-age, or M-at-age.',
      'The 2026 Council report says no full assessment or monitoring report was',
      'completed for 2027 and beyond.'
    ),
    detailed_source_url = paste(
      'https://www.nafo.int/Portals/0/PDFs/sc/2026/scs26-12.pdf;',
      'https://www.nafo.int/Portals/0/PDFs/sc/2025/scs25-13.pdf;',
      'https://www.nafo.int/Portals/0/PDFs/sc/2023/scr23-036.pdf;',
      'https://www.nafo.int/Portals/0/PDFs/sc/2024/scs24-24.pdf;',
      'https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/groundfish-poisson-fond/2025/groundfish-poisson-fond-div3ps-nafo-opano-eng.html'
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'The latest NAFO advice is for the 3NO management portion of the biological',
      'stock distributed across 3NO and 3Ps. No full assessment or interim',
      'monitoring report was completed in 2026 because the designated-expert',
      'position was vacant. The latest detailed full assessment located is NAFO',
      'SCR Doc. 23/036, a qualitative catch-and-survey review using lengths and',
      'aggregate indices rather than age-disaggregated observations or population',
      'outputs. Ineligible for the age-disaggregated assessment set.'
    ),
    notes = paste(
      'The canonical white-hake record for the Gulf of Maine and Georges Bank is',
      'a separate unit. The NAFO biological stock includes 3Ps, which Canada also',
      'manages separately. The detailed 2023 SCR says not to cite it without prior', 'reference to the authors. No canonical records or numerical series were imported.'
    )
  )
)

for (id in names(review)) {
  i <- match(id, x$candidate_id)
  if (is.na(i)) stop('Expected candidate row: ', id, call. = FALSE)
  for (column in names(review[[id]])) x[[column]][i] <- review[[id]][[column]]
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
cat('Screened the current DFO thorny-skate and white-hake inventory entries.\n')

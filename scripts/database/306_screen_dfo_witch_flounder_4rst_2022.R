path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'DFO:Gulf:Witch Flounder - NAFO 4RST'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected DFO 4RST witch-flounder inventory row was not found.', call. = FALSE)
if (!is.na(x$matched_stock_id[i]) && nzchar(x$matched_stock_id[i])) {
  stop('Unexpected canonical match for DFO 4RST witch flounder.', call. = FALSE)
}
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
if (any(stocks$stock_id == 'dfo_witch_flounder_4rst')) {
  stop('Candidate stock ID already exists in the canonical database.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'dfo_witch_flounder_4rst',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  scientific_name = 'Glyptocephalus cynoglossus',
  assessment_area = 'Gulf of St. Lawrence, NAFO Divisions 4RST',
  inventory_assessment_year = '2022',
  catch_age_evidence = paste(
    'The 2022 Research Document reports total landings by gear in tonnes for fishing years',
    '1960-2021 and states the model uses the September-to-August series from 1961 onward.',
    'Commercial catch-at-length is described, but the fitted model is surplus production and',
    'does not use age-specific catch or length compositions.'
  ),
  survey_age_evidence = paste(
    'The model fits three aggregate trawlable-biomass indices for fish >=30 cm: the 4T',
    'September RV index (1971-1992), combined 4RST August/September RV index (1987-2021),',
    'and combined July/August sentinel index (2003-2019). An under-30-cm recruitment',
    'indicator is length-based. These are not age-specific abundance indices.'
  ),
  weights_evidence = paste(
    'No weight-at-age surface is used in the fitted model. The modeled state is biomass of',
    'fish >=30 cm; the report describes historical age samples for growth analysis, not an',
    'age-structured population or weight-at-age input.'
  ),
  maturity_evidence = paste(
    'The report estimates historical sex-specific maturity-at-age and maturity-at-length',
    'from survey biology, but these quantities are not inputs to the fitted surplus-production',
    'model. No annual age-specific maturity surface is used.'
  ),
  mortality_evidence = paste(
    'The fitted Schaefer model does not estimate or use age-specific natural mortality or',
    'fishing mortality. It estimates population growth, process variation, biomass and',
    'exploitation rate.'
  ),
  timing_evidence = paste(
    'The annual catch series is aligned from September of year t-1 to August of year t;',
    'model biomass is described as late-summer/early-fall biomass. The three indices combine',
    'August/September RV surveys or July/August sentinel surveys; no within-year age model'
  ),
  output_evidence = paste(
    'The official DFO dataset provides 30+ cm biomass posterior medians and 2.5th, 25th,',
    '75th and 97.5th percentiles for 1961-2021 in tonnes, matching the 2022 report (2021',
    'median about 17,768 t). The 2024 interim update extends a survey indicator through 2024,',
    'not the full model. No SSB, N-at-age or F-at-age trajectory is reported.'
  ),
  detailed_source_url = paste(
    'https://open-science.canada.ca/server/api/core/bitstreams/8608cfcd-0cdb-4beb-9b93-cc6b9a3b2b76/content;',
    'https://publications.gc.ca/collections/collection_2022/mpo-dfo/fs70-6/Fs70-6-2022-028-eng.pdf;',
    'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282851.pdf;',
    'https://open.canada.ca/data/en/dataset/ade72f36-17fe-11ed-b70d-1860247f53e3;',
    'https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/ade72f36-17fe-11ed-b70d-1860247f53e3/attachments/NAFO-4RST-Witch-Flounder-biomass-estimates-1961-2021.csv'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The latest full assessment is the 2022 Bayesian Schaefer surplus-production model to',
    '2021. The 2024 update reports interim survey indicators and identifies a full assessment',
    'for 2027. Because the production model does not use age-disaggregated population or',
    'observation data, this unit is ineligible for the age-structured expansion batch.'
  ),
  notes = paste(
    'Confirmed as a distinct DFO Gulf unit (NAFO 4RST); not the separate US Gulf of Maine',
    'Witch Flounder record. No canonical database values were added. Full assessment:',
    'Ricard (2022), CSAS Research Document 2022/054; latest interim update covers 2024.'
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
cat('Screened DFO Gulf witch flounder against its 2022 full assessment and 2024 update.\n')
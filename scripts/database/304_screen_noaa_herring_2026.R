path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'NOAA:10572'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected NOAA Atlantic herring inventory row was not found.', call. = FALSE)
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
if (any(stocks$authority == 'NOAA' & stocks$authority_stock_id == '10572', na.rm = TRUE)) {
  stop('Unexpected canonical match for NOAA Atlantic herring.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_atlantic_herring_gom_georges_bank',
  official_stock_id = '10572',
  stock_name = 'Atlantic herring - Northwestern Atlantic Coast',
  assessment_area = 'U.S. Gulf of Maine and Georges Bank stock complex',
  inventory_assessment_year = '2026',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2026 NOAA support archive contains numeric fixed- and mobile-fleet catch-age',
    'proportions for ages 1-8 in 1987-2025. It does not contain the corresponding',
    'run-matched fleet catch totals needed to reconstruct numbers-at-age; the report',
    'only tabulates combined U.S., Canadian, and total catches for 2018-2025.'
  ),
  survey_age_evidence = paste(
    'The run archive plots age compositions for the spring/fall bottom-trawl and summer',
    'shrimp surveys, plus aggregate abundance indices. Numeric survey age-composition',
    'vectors and annual index values were not found. The acoustic index has no age',
    'composition in the assessment.'
  ),
  weights_evidence = paste(
    'Annual spawning-stock and fleet weight-at-age surfaces are plotted in All_inputdata.pdf,',
    'but run-matched numeric arrays and their units are not tabulated in the archive.'
  ),
  maturity_evidence = paste(
    'The run archive plots maturity-at-age for selected years; a complete numeric',
    'maturity surface for the 2026 assessment was not found.'
  ),
  mortality_evidence = paste(
    'The 2026 report states natural mortality is constant over ages and years but does',
    'not give its numeric value. The 2025 research-track value cannot be assumed to be',
    'the exact 2026 input without the run files.'
  ),
  timing_evidence = paste(
    'The model uses annual survey series for spring, fall, summer shrimp, and acoustic',
    'observations. Exact within-year timing values for the 2026 fit were not located.'
  ),
  output_evidence = paste(
    'The 2026 report gives annual catch, SSB, mobile-fleet Fbar at ages 7-8, and age-1',
    'recruitment for 2018-2025, and trend figures for 1987-2025 with approximate 90%',
    'intervals. Numeric N-at-age and F-at-age output arrays were not found.'
  ),
  detailed_source_url = paste(
    'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=21&stock_id=6&review_type_id=6&filename=2026_HER_UNIT.zip;',
    'https://www.fisheries.noaa.gov/s3/2026-07/june-2026-management-track-peer-review-panel-report_508_20260710.pdf;',
    'https://repository.library.noaa.gov/view/noaa/71350/noaa_71350_DS1.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The 2026 WHAM Management Track is the latest assessment used for advice and its',
    'peer review found it technically sufficient and Best Scientific Information Available.',
    'Run-specific outputs and some age-composition inputs are available, but the complete',
    'numeric survey indices/compositions, fleet catch totals, age-specific biology, exact M,',
    'and survey timing were not recovered. Source-curation eligibility remains unresolved.'
  ),
  notes = paste(
    'The 2026 assessment defines the U.S. Gulf of Maine/Georges Bank stock complex.',
    'It includes Canadian catch and the peer review identifies uncertain mixing with',
    'Canadian herring stocks; this does not establish one-to-one identity with DFO 4VWX',
    'components. No canonical database values were added. See',
    'discovery/source_reviews/noaa_atlantic_herring_2026.md.'
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
cat('Screened NOAA Atlantic herring stock 10572 using the 2026 assessment archive.\n')

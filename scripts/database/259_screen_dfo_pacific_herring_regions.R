path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

areas <- list(
  'DFO:Pacific:Pacific Herring - Central Coast' = list(
    code = 'CC',
    area = 'Central Coast',
    output = 'The 2025 production SCA report shows posterior SSB, age-2 recruitment, and annual M estimates through 2025. It reports no numerical fitted N-at-age or F-at-age series.'
  ),
  'DFO:Pacific:Pacific Herring - Haida Gwaii' = list(
    code = 'HG',
    area = 'Haida Gwaii',
    output = 'The 2025 production SCA report shows posterior SSB, age-2 recruitment, and annual M estimates through 2025. It reports no numerical fitted N-at-age or F-at-age series.'
  ),
  'DFO:Pacific:Pacific Herring - Prince Rupert District' = list(
    code = 'PRD',
    area = 'Prince Rupert District',
    output = 'The 2026 PRD report plots SSB, recruitment, M and harvest-rate estimates through 2024. Numerical age-specific fitted N/F and a machine-readable historical output series were not recovered.'
  ),
  'DFO:Pacific:Pacific Herring - West Coast of Vancouver Island' = list(
    code = 'WCVI',
    area = 'West Coast of Vancouver Island',
    output = 'The 2025 production SCA report shows posterior SSB, age-2 recruitment, and annual M estimates through 2025. It reports no numerical fitted N-at-age or F-at-age series.'
  )
)

if (any(stocks$scientific_name == 'Clupea pallasii' &
    stocks$stock_id != 'dfo_herring_sog', na.rm = TRUE)) {
  stop('A non-SoG Pacific herring stock is already in the canonical database.', call. = FALSE)
}
if (any(x$scientific_name == 'Clupea pallasii' & x$organization != 'DFO',
    na.rm = TRUE)) {
  stop('Review possible cross-organization Pacific herring matches first.', call. = FALSE)
}

reviews <- lapply(names(areas), function(id) {
  area <- areas[[id]]
  list(
    candidate_id = id,
    stock_code = area$code,
    assessment_area = area$area,
    match_status = 'new',
    screening_status = 'screened',
    eligibility = 'ineligible',
    import_status = 'not_started',
    catch_age_evidence = paste(
      'The current assessment uses commercial catches by gear and fishery/test-fishery',
      'number-at-age compositions. The official catch and individual biological-sample',
      'datasets are public. The source report describes ages 2-10+, with age 10 a plus',
      'group; exact run-specific sampling and catch-at-age expansion still require review.'
    ),
    survey_age_evidence = paste(
      'The assessment uses an aggregate spawning-biomass index in tonnes, with a surface',
      'series (1951-1987) and dive series (1988-2025 for SCA; the PRD SISCAH report',
      'uses observations through 2024). The survey is not age-specific and survey-age',
      'compositions were not found. Fishery/test-fishery compositions cannot be treated',
      'as survey compositions without an additional selectivity assumption.'
    ),
    weights_evidence = paste(
      'Official biological-sample files include individual fish weight and age. The',
      '2026 SCA report presents stock weight-at-age in kg/fish for ages 2-10+ and',
      'describes five-year running means in the figure. The exact production input',
      'filter and smoothing recipe remains to be checked against the model sources.'
    ),
    maturity_evidence = paste(
      'The current SCA assessment specifies maturity-at-age as fixed. The numeric',
      'production vector is not tabulated in the current 2026 status report and remains',
      'to be verified from the detailed framework or model source.'
    ),
    mortality_evidence = if (area$code == 'PRD') paste(
      'The 2025 PRD model uses the SISCAH framework with density-dependent mortality;',
      'the 2026 report gives Mb = 0.35 for its operating model. The framework also',
      'estimates a time-varying mortality series. Full age-specific model settings are',
      'not recovered from the short response.'
    ) else paste(
      'The current SCA assessment estimates annual instantaneous natural mortality;',
      'the 2026 report presents posterior M summaries. The exact age structure and',
      'production parameter settings remain to be checked in the detailed framework.'
    ),
    timing_evidence = paste(
      'The assessment year runs July 1 to June 30. Catch and biological sources retain',
      'calendar sample dates and gear. Exact within-year model observation fractions',
      'for catch and spawn-index data were not recovered.'
    ),
    output_evidence = area$output,
    detailed_source_url = paste(
      'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-7/Fs70-7-2026-014-eng.pdf;',
      'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-7/Fs70-7-2026-006-eng.pdf;',
      'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2024-066-eng.pdf;',
      'https://open.canada.ca/data/en/dataset/1b289790-d0fe-49dc-af20-4ae7d91e17af;',
      'https://open.canada.ca/data/en/dataset/71c25df1-0577-43f7-b9f8-95cc321e7cbc;',
      'https://open.canada.ca/data/en/dataset/d892511c-d851-4f85-a0ec-708bc05d2810'
    ),
    review_date = '2026-10-29',
    decision_reason = paste(
      'DFO identifies this as a separate current major herring assessment region, and',
      'the canonical database has no matching Pacific herring unit; the other inventory',
      'organizations list Atlantic Clupea harengus, not Clupea pallasii. This is a',
      'provisional new source-curation candidate. It is ineligible for the current tinyAM',
      'age-indexed translation because the official abundance observation is aggregate',
      'spawn biomass and no survey age composition was recovered. Preserve the verified',
      'source data for database curation; do not allocate the aggregate index to ages.'
    ),
    notes = paste(
      'Provisional new DFO Pacific herring assessment unit; not an imported canonical',
      'record. Current unit/run: 2025 SCA for CC, HG and WCVI, and 2025 SISCAH for PRD.',
      'Detailed 2025 SCA inputs/outputs and the 2024/066 framework were reviewed online.',
      'The local source cache has the 2025/005 report and current official source datasets;',
      'the 2026/014, 2026/006 and 2024/066 PDF URLs currently redirect shell downloads to',
      'the Government Publications archive notice. See source_reviews/dfo_pacific_herring_areas_discovery.md.'
    )
  )
})
names(reviews) <- names(areas)

for (id in names(reviews)) {
  i <- match(id, x$candidate_id)
  if (is.na(i)) stop(paste('Expected DFO inventory row is missing:', id), call. = FALSE)
  review <- reviews[[id]]
  if (x$screening_status[i] == 'screened') {
    if (x$official_stock_id[i] != review$stock_code ||
        x$match_status[i] != review$match_status ||
        x$eligibility[i] != review$eligibility) {
      stop(paste('Previously screened DFO herring row changed:', id), call. = FALSE)
    }
    next
  }
  if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
    stop(paste('Preserve the existing review state for:', id), call. = FALSE)
  }
  for (column in setdiff(names(review), c('candidate_id', 'stock_code'))) {
    x[[column]][i] <- review[[column]]
  }
  x$scientific_name[i] <- 'Clupea pallasii'
  x$official_stock_id[i] <- review$stock_code
  x$assessment_area[i] <- review$assessment_area
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
for (id in names(reviews)) {
  i <- match(id, x$candidate_id)
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened four current DFO Pacific herring regions; no canonical data imported.\n')

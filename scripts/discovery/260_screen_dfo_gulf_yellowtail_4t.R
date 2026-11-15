root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'DFO:Gulf:Yellowtail Flounder - NAFO 4T'
source_review <- file.path(root, 'source_reviews',
  'dfo_yellowtail_flounder_4t_2025.md')

if (any(stocks$scientific_name %in% c('Myzopsetta ferruginea', 'Limanda ferruginea') &
    grepl('4T', stocks$area, fixed = TRUE), na.rm = TRUE)) {
  stop('A possible DFO 4T yellowtail canonical stock already exists; reconcile before screening.',
    call. = FALSE)
}

i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected DFO Gulf yellowtail inventory row is missing.', call. = FALSE)

review <- list(
  scientific_name = 'Myzopsetta ferruginea',
  inventory_assessment_year = 2025,
  assessment_area = 'NAFO Division 4T, southern Gulf of St. Lawrence',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The official 2025 age-structured assessment uses annual total fishery catch',
    'and numbers-at-age proportions by seine and trawl fleet for 1985-2022.',
    'The catch-at-age counts are not the native observation as reported; the',
    'source catch totals, age compositions and model weight-at-age support a',
    'documented downstream reconstruction, with fleet-specific expansion details',
    'to verify from the detailed report before import.'
  ),
  survey_age_evidence = paste(
    'The DFO RV survey contributes annual numbers-at-age proportions and an',
    'age-aggregated biomass index for 1985-2025. The index is not directly',
    'age-specific; an age-specific abundance series can be reconstructed from',
    'the aggregate index, matching age proportions and weights-at-age after',
    'confirming the index age coverage in the detailed report.'
  ),
  weights_evidence = paste(
    'The assessment uses RV survey weight-at-age for 1985-2025. The official',
    'summary identifies a refinement to historical age-length keys; the exact',
    'age grid and numeric series remain to be extracted from the detailed report.'
  ),
  maturity_evidence = paste(
    'The assessment uses RV survey maturity-at-age for 1985-2025. The exact',
    'age grid, sex treatment and numeric series remain to be extracted.'
  ),
  mortality_evidence = paste(
    'The official state-space model estimates strongly time-varying, age-dependent',
    'natural mortality. Reported M groups include ages 4-7, 8-9 and 10+; the',
    'detailed report is needed to verify lower-age treatment and process settings.'
  ),
  timing_evidence = paste(
    'The fishery and RV inputs are annual. The DFO RV survey is conducted in',
    'September. The model-year definition and within-year observation timing',
    'were not verified from the available report text.'
  ),
  output_evidence = paste(
    'The official 2025 assessment reports age-5+ biomass of 8,269 t in 2025,',
    'age-1 recruitment, mean F for ages 4-10+, and annual age-group M summaries.',
    'Historical trajectories are reported graphically; numerical output series',
    'and uncertainty details need extraction from the detailed report.'
  ),
  detailed_source_url = paste(
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-5/Fs70-5-2026-054-eng.pdf;',
    'https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-022-eng.pdf;',
    'https://publications.gc.ca/collections/collection_2025/mpo-dfo/fs70-7/Fs70-7-2025-010-eng.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'DFO identifies NAFO 4T as a single current biological management unit.',
    'It is distinct from the existing U.S. Georges Bank and Southern New England/',
    'Mid-Atlantic yellowtail records; no canonical DFO 4T unit exists. The 2025',
    'official assessment provides age compositions, biological age inputs and',
    'comparable official population/mortality outputs. Native observations and',
    'the reconstruction details remain to be extracted before any canonical import.'
  ),
  notes = paste(
    'Screened from the official 2025 production assessment (Science Response',
    '2026/022) and its detailed Research Document 2026/054. This is a distinct',
    'current DFO stock unit, not a match to the DFO-NEFSC Georges Bank or NOAA',
    'Southern New England/Mid-Atlantic units. Model inputs include aggregate',
    '',
    'require explicit source-based reconstruction. The detailed Research Document',
    'and Science Response PDFs redirected to the Government Publications archive',
    'notice when downloaded on 2026-10-29; their official catalogue records are',
    'cached locally. See the linked source review.'
  )
)

if (x$screening_status[i] == 'screened') {
  for (column in names(review)) {
    if (!identical(as.character(x[[column]][i]), as.character(review[[column]]))) {
      stop(paste('Previously screened DFO yellowtail field changed:', column), call. = FALSE)
    }
  }
  if (!file.exists(source_review)) stop('DFO yellowtail source review is missing.', call. = FALSE)
  cat('DFO 4T yellowtail already screened; no canonical data imported.\n')
  quit(save = 'no', status = 0L)
}

if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review state before screening DFO 4T yellowtail.', call. = FALSE)
}

for (column in names(review)) x[[column]][i] <- review[[column]]
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened DFO NAFO 4T yellowtail; no canonical data imported.\n')

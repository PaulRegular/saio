path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10160', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Stock SMART 10160.', call. = FALSE)

review <- list(
  candidate_unit_id = 'iattc_eastern_pacific_skipjack',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 quarterly Stock Synthesis assessment fits fleet catch and',
    'length compositions, not observed catch-at-age or age compositions.',
    'A modeled age grid is derived through assumed growth; the report says',
    'reliable aging is unavailable, so converting the length compositions',
    'to catch-at-age would impose an unsupported reconstruction.'
  ),
  survey_age_evidence = paste(
    'Five aggregate abundance/biomass indices were considered. The reference',
    'model uses an echosounder-buoy relative-abundance index and one',
    'tag-recapture biomass estimate (2020 Q2, CV 0.3); neither is age-specific.'
  ),
  weights_evidence = paste(
    'Weight-at-age is derived from modeled mean length-at-age and the',
    'length-weight relationship 5.53e-6 * L^3.336; no observed annual',
    'weights-at-age series is reported.'
  ),
  maturity_evidence = paste(
    'Maturity and batch fecundity are specified by length, with maturity',
    'from the central EPO area; no observed maturity-at-age input series',
    'is reported.'
  ),
  mortality_evidence = paste(
    'Natural mortality is specified by length using Hampton (2000), with',
    'linear interpolation between length-class midpoints and a constant',
    'value above 65 cm.'
  ),
  timing_evidence = paste(
    'The model is quarterly over 2006-2023. Index and composition data are',
    'quarterly or assigned to quarters.',
    'be copied directly from this model.'
  ),
  output_evidence = paste(
    'The report presents quarterly recruitment with 95% confidence intervals,',
    'spawning biomass/ratios and exploitation-rate trajectories. NOAA Stock',
    'SMART reports 2023 SSB of 17,809 metric tonnes. IATTC generated run',
    'outputs are linked online, but its page prohibits public redistribution',
    'of the files and derivative content without IATTC permission.'
  ),
  detailed_source_url = paste(
    'https://www.iattc.org/GetAttachment/f57dece1-81ba-4771-8fa8-3362320a368a/',
    'SAC-15-04_Skipjack-tuna-benchmark-assessment-2024.pdf;',
    'https://www.iattc.org/StockAssessments/2024/SKJWebsite/plots/_SS_output.html;',
    'https://www.iattc.org/en-US/Event/DetailMeeting/Meeting-SAC-15;',
    'https://www.fisheries.noaa.gov/species/pacific-skipjack-tuna/seafood;',
    'https://apps-st.fisheries.noaa.gov/stocksmart'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10160 maps to the IATTC Eastern Pacific skipjack',
    '2024 benchmark, with terminal data year 2023 and full acceptance in',
    'the inventory metadata. The 2024 quarterly Stock Synthesis benchmark',
    'has age states but fits catch,',
    'aggregate abundance/biomass indices and length compositions; no observed',
    'age-specific inputs were found. It is ineligible for the current',
    'age-disaggregated candidate screen.'
  ),
  notes = paste(
    'The assessment is quarterly, combines sexes, and models ages 0-20+',
    'quarters on a 1-cm population-length grid from 2-110 cm. The report',
    'states reliable aging is unavailable and derives age from assumed growth.',
    'Purse-seine compositions use 1-cm size bins (20-100+ cm); longline uses',
    '5-cm bins (40-100+ cm). Detailed native run files are linked by IATTC',
    'but were not cached because of the redistribution notice. The report PDF',
    'is cached in discovery_iattc_eastern_skipjack_2024/.'
  )
)

matches_review <- vapply(names(review), function(column) {
  value <- as.character(x[[column]][i])
  expected <- as.character(review[[column]])
  if (is.na(value)) value <- ''
  if (is.na(expected)) expected <- ''
  identical(value, expected)
}, logical(1L))
new_entry <- x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed'
prior_screen <- x$match_status[i] == 'new' &&
  x$screening_status[i] == 'screened' &&
  x$eligibility[i] == 'ineligible' &&
  x$candidate_unit_id[i] == review$candidate_unit_id
if (new_entry || prior_screen) {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!all(matches_review)) {
  stop('Eastern Pacific skipjack has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
csv_row <- x[i, , drop = FALSE]
csv_row[] <- lapply(csv_row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(csv_row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA:10160 as a new but ineligible IATTC Eastern Pacific skipjack unit.\n')

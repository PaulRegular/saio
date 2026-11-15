path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:10158', x$candidate_id)
if (is.na(i)) stop('Expected NOAA Stock SMART 10158.', call. = FALSE)

review <- list(
  candidate_unit_id = 'iccat_west_atlantic_skipjack',
  matched_stock_id = '',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2022 Stock Synthesis advice model uses annual fleet catch in mass',
    'and catch-at-size/size compositions for 1952-2020. The data-preparatory',
    'meeting explicitly states that catch-at-age was not planned or calculated.',
    'No age compositions are fitted, so the public catch and size data do not',
    'support the required source-based catch-at-age reconstruction.'
  ),
  survey_age_evidence = paste(
    'The advice model uses five aggregate relative-abundance indices with',
    'lognormal errors. No age-specific index or survey age composition is',
    'reported for the fitted model.'
  ),
  weights_evidence = paste(
    'The model uses a combined-sex von Bertalanffy growth model and the',
    'length-weight relationship 7.48e-06 * fork length(cm)^3.253. These',
    'support size-to-weight conversion but do not supply age compositions.'
  ),
  maturity_evidence = paste(
    'The model is combined-sex; 50% maturity is at 42 cm fork length and',
    'full maturity at 55 cm. SSB is the summed biomass of mature fish.'
  ),
  mortality_evidence = paste(
    'The advice uncertainty grid uses Lorenzen-scaled M-at-age hypotheses',
    'anchored to the M-at-age-6 value for each growth scenario.'
  ),
  timing_evidence = paste(
    'The model has an annual time step, with fishing throughout the year.',
    'Individual relative-abundance indices are adjusted for within-year',
    'timing; exact fractions require the electronic model inputs.'
  ),
  output_evidence = paste(
    'Official outputs include SSB and F trajectories and uncertainty-grid',
    'status estimates through 2020. The latest summary reports 2020 relative biomass ratio',
    'of 1.60 (95% interval 0.90-2.87) and relative F of 0.41 (0.19-0.89).',
    'The assessment paper plots estimated numbers-at-age, but no run-matched',
    'numeric annual N-at-age/F-at-age tables were located.'
  ),
  detailed_source_url = paste(
    'https://iccat.int/en/assess.html;',
    'https://www.iccat.int/Documents/SCRS/DetRep/SKJ_DP_ENG.pdf;',
    'https://www.iccat.int/Documents/SCRS/DetRep/SKJ_SA_ENG.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010001.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010907.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010611.pdf;',
    'https://www.iccat.int/Documents/CVSP/CV079_2022/n_1/CV079010701.pdf;',
    'https://www.iccat.int/Documents/SCRS/ExecSum/SKJ_ENG.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'NOAA Stock SMART 10158 represents the Western Atlantic skipjack unit',
    'assessed by ICCAT in 2022.',
    'The model is age-structured internally but fits catch-at-size, size',
    'compositions, and aggregate CPUE. The official data-preparatory report',
    'states no catch-at-age was planned, and no age-specific survey input is',
    'reported. Length compositions alone do not meet the age-disaggregated',
    'source screen, so this unit is ineligible for the current candidate set.'
  ),
  notes = paste(
    'The 2022 Stock Synthesis model covers 1952-2020, has one area, combined',
    'sexes, ages 0-6+, five fleets/indices, and 2-cm size bins over 20-156 cm.',
    'The advice combines nine runs spanning growth and steepness uncertainty.',
    'The latest ICCAT executive summary located says the last assessment was in',
    '2022 and reports 2020 status; later MSE operating-model updates are not a',
    'new assessment fit. Checked source PDFs are cached under',
    'source_cache/discovery_iccat_western_skipjack_2022/ with checksums.'
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
  stop('Western Atlantic skipjack has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
csv_row <- x[i, , drop = FALSE]
csv_row[] <- lapply(csv_row, as.character)
tmp <- tempfile(fileext = '.csv')
write.csv(csv_row, tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA:10158 as a new but ineligible Western Atlantic ICCAT skipjack unit.\n')

path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'NOAA:10173'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected NOAA Gulf Spanish mackerel inventory row was not found.', call. = FALSE)
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
if (any(stocks$authority == 'NOAA' & stocks$authority_stock_id == '10173', na.rm = TRUE)) {
  stop('Unexpected canonical match for NOAA Gulf Spanish mackerel.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_gulf_spanish_mackerel',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'unresolved',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'SEDAR 81 reports commercial landings by gear in pounds whole weight and recreational',
    'landings by mode in numbers for 1986-2021, plus discards. The assessment uses commercial',
    'and recreational conditional age-at-length observations for ages 0-11, not direct',
    'catch numbers-at-age. Supporting papers show sample counts and figures, but the full',
    'run-matched year-by-length-by-age and length-composition arrays were not located.'
  ),
  survey_age_evidence = paste(
    'The fitted model uses numeric aggregate Florida vertical-line CPUE (1986-2021) and two',
    'aggregate SEAMAP trawl indices (1987-2008; 2009-2020; 2021 zero catch excluded), with',
    'log-scale SEs. Age samples were collected by fishery-independent programs, but the',
    'assessment states those age data were not fitted. The indices are not age-specific.'
  ),
  weights_evidence = paste(
    'The report gives a fixed fork-length-to-whole-weight equation: WW = 1.5e-05 * FL^2.8617,',
    'with FL in cm and WW in kg. Growth is estimated from age data; complete numerical',
    'weight-at-age inputs are not supplied as fixed surfaces.'
  ),
  maturity_evidence = paste(
    'Maturity is fixed as a length-based logistic function (slope -0.44, L50 31.41 cm FL);',
    'maturity-at-age is derived using estimated growth rather than supplied as a complete',
    'numerical age-specific surface.'
  ),
  mortality_evidence = paste(
    'The assessment uses a Lorenzen age-specific natural-mortality schedule for ages 0-11,',
    'scaled to a Hoenig maximum-age estimate of 0.38 per year. Table 2 reports the SEDAR 81',
    'base schedule directly.'
  ),
  timing_evidence = paste(
    'Settlement is set to May 1. Fishing is continuous over the annual model year; no seasonal',
    'population model or survey timing fraction is used.'
  ),
  output_evidence = paste(
    'Table 15 reports annual total/exploitable biomass, SSB, age-1+ abundance, age-0 recruits,',
    'and SSB/SSB0 for 1986-2021. Numerical N-at-age and F-at-age arrays were not located.',
    'The report defines F as a biomass harvest rate, not instantaneous F-at-age.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/assessments/sedar-81/;',
    'https://gulf-council-media.s3.amazonaws.com/uploads/2025/05/07d.-sedar-81-gulf-of-mexico-spanish-mackerel-final-stock-assessment.pdf;',
    'https://sedarweb.org/documents/sedar-81-gulf-of-mexico-spanish-mackerel-executive-summary-report/;',
    'https://sedarweb.org/documents/sedar81-wp-03-a-review-of-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-age-data-1987-2021-from-various-age-data-sources/;',
    'https://sedarweb.org/documents/sedar81-wp-04-commercial-landings-of-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-1887-2021/;',
    'https://sedarweb.org/documents/sedar-81-wp-06-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-recreational-landings-length-and-age-compositions/;',
    'https://sedarweb.org/documents/sedar-81-wp-07-gulf-of-mexico-spanish-mackerel-scomberomorus-maculatus-commercial-landings-length-and-age-compositions/;',
    'https://sedarweb.org/documents/sedar-81_wp_08-annual-indices-of-abundance-of-gulf-of-mexico-spanish-mackerel-from-florida-commercial-trip-tickets-1986-2021/;',
    'https://sedarweb.org/documents/sedar-81-wp-09-spanish-mackerel-abundance-indices-from-seamap-groundfish-surveys-in-the-northern-gulf-of-mexico/;',
    'https://www.fisheries.noaa.gov/s3/2026-03/FW-14_Spanish_catch_limits_2026.03.02.pdf'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'SEDAR 81 is the current Gulf assessment used for catch-limit decisions. It provides',
    'detailed catch, abundance-index, mortality, biology, and aggregate output tables.',
    'Source-curation eligibility remains unresolved because full numeric conditional',
    'age-at-length and length-composition inputs were not found; survey-age observations',
    'were not part of the fitted model.'
  ),
  notes = paste(
    'The Gulf stock is bounded eastward by the Dade-Monroe County line and is distinct from',
    'NOAA:10174 South Atlantic Spanish mackerel. No canonical database values were added.',
    'See discovery/source_reviews/noaa_gulf_spanish_mackerel_2023.md.'
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
cat('Screened NOAA Gulf Spanish mackerel against SEDAR 81.\n')
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

id <- 'NOAA:10056'
i <- match(id, x$candidate_id)
if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)

updates <- list(
  match_status = 'ambiguous',
  screening_status = 'screened',
  eligibility = 'ineligible',
  import_status = 'not_started',
  catch_age_evidence = 'The 2024 FSD assessment uses aggregate annual catch in metric tonnes by disposition; it does not use catch-at-age. The report identifies additional age and length data as needed for a more sophisticated future assessment.',
  survey_age_evidence = 'The assessment uses the NEFSC fall bottom-trawl biomass index and two discard-ratio indices. These are aggregate indices, not age-specific abundance observations.',
  weights_evidence = 'The FSD assessment does not use weights-at-age.',
  maturity_evidence = 'The FSD assessment does not use maturity-at-age.',
  mortality_evidence = 'The method does not estimate a natural-mortality process. Discard mortality is assumed to be 0.76 for trawl gear and 0.30 for gillnet gear.',
  timing_evidence = 'The assessment identifies an annual fall bottom-trawl index and annual discard-ratio indices; no within-year model timing is used.',
  output_evidence = 'The 2024 report provides catch multipliers and catch advice, catches in metric tonnes, and aggregate index trends with 90% lognormal intervals. It does not estimate N-, F-, M-, recruitment-, or SSB-at-age surfaces.',
  detailed_source_url = paste('https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=9875', 'https://d23h0vhsm26o6d.cloudfront.net/SSC-report-groundfish-10_21_24.pdf', sep = '; '),
  review_date = '2026-10-29',
  decision_reason = 'The latest listed NOAA assessment is the 2024 FSD update through 2023. It is aggregate and empirical rather than age-structured, so it is ineligible for the current age-disaggregated candidate set. NOAA documents uncertainty about how its U.S. assessment unit relates to the larger halibut stock centered in Canadian waters; available sources do not support a one-to-one match to either DFO halibut unit.',
  notes = 'NOAA Stock SMART ID 10056; 2024 run used for 2025 catch advice. Identity remains ambiguous relative to DFO Atlantic halibut units 3NOPs4VWX5Zc and 4RST. Detailed assessment and SSC report are cached under source_cache/discovery_noaa_atlantic_halibut_2024/.'
)

for (column in names(updates)) x[[column]][i] <- updates[[column]]

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
lines[i + 1L] <- updated
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Atlantic halibut 2024; retained the unresolved cross-border identity.\n')

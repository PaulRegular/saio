path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
id <- 'NOAA:10231'
i <- match(id, x$candidate_id)
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one NOAA Southern Atlantic red snapper inventory row.', call. = FALSE)
}

review <- list(
  candidate_unit_id = 'noaa_south_atlantic_red_snapper',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  catch_age_evidence = paste(
    'The 2024 update fits the BAM statistical catch-age model through 2023. It',
    'updates commercial handline, headboat, and general recreational landings',
    'and discards. Recreational landings are in thousands of fish, commercial',
    'landings in thousand pounds whole weight, and discards in numbers. Fishery age',
    'compositions are fitted with catch totals; they are not a direct annual',
    'catch-numbers-at-age observation table. Composition bins pool older ages',
    'at age 10 for headboat, general recreational, and SERFS trap samples, and',
    'at age 13 for commercial samples.'
  ),
  survey_age_evidence = paste(
    'The fitted assessment uses five aggregate abundance indices: commercial',
    'handline, headboat, headboat discards, SERFS chevron trap, and SERFS video.',
    'SERFS chevron-trap age compositions are fitted, but no age-specific',
    'abundance index is reported. The 2024 update extends the SERFS indices and',
    'chevron-trap age compositions through 2023; no SERFS observations are',
    'available in 2020. Chevron-trap and video index likelihoods each receive',
    'half weight to account for shared sampling.'
  ),
  weights_evidence = paste(
    'The SEDAR 73 life-history table provides input growth curves and',
    'length-to-whole-weight relationships used to derive weight at age. The',
    '2024 update retains the SEDAR 73 model configuration.'
  ),
  maturity_evidence = paste(
    'Female maturity is a fixed input logistic curve with a supplied',
    'age-specific vector. The SEDAR 73 model calculates spawning output as',
    'eggs using maturity, female proportion, batches at age, and size-based',
    'fecundity; this is not conventional SSB in biomass units.'
  ),
  mortality_evidence = paste(
    'Natural mortality is fixed over time and decreases with age using a',
    'Lorenzen curve. It is scaled to match cumulative survival over ages 4',
    'through the oldest observed age (51) under constant M = 0.11 per year.'
  ),
  timing_evidence = paste(
    'The assessment is annual. A fractional within-year timing for the fitted',
    'survey indices is not specified in the reviewed production report.'
  ),
  output_evidence = paste(
    'The 2024 report publishes annual numbers at age (1000 fish), biomass at',
    'age (1000 lb), and instantaneous F at age (per year) for 1950-2023; the',
    'model age range is 1-20+, with age 20 as the plus group. Age-1 abundance',
    'is recruitment (1000 fish). Spawning output is reported in 1e8 eggs, not',
    'biomass. MCBE uncertainty is summarized, but age-specific uncertainty is',
    'not tabulated in these output tables.'
  ),
  detailed_source_url = paste(
    'https://sedarweb.org/documents/sefsc-2024-update-to-sedar-73-south-atlantic-red-snapper-assessment/;',
    'https://sedarweb.org/documents/sedar-73-stock-assessment-report-south-atlantic-red-snapper/;',
    'https://sedarweb.org/assessments/sedar-90-south-atlantic-red-snapper/;',
    'https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=10231'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'Eligible for source curation. NOAA Stock SMART lists a 2024 operational',
    'assessment with terminal data year 2023 and full acceptance. The final',
    '2024 SEFSC update is the latest detailed run located; it updates the 2021',
    'SEDAR 73 BAM assessment and reports catch-age inputs, fixed age-based',
    'biology, aggregate indices and comparable population and mortality',
    'outputs. SEDAR 90 is in progress and is not substituted for the completed',
    '2024 run.'
  ),
  notes = paste(
    'NOAA:10231 is the South Atlantic management unit and is distinct from',
    'NOAA:10230, Gulf of Mexico red snapper. The 2024 update was prepared by',
    'SEFSC at the request of the Southeast Regional Office under a Secretarial',
    'Amendment; Stock SMART labels it Full acceptance / Operational, while its',
    'citation field still points to SEDAR 41. Do not treat that stale citation',
    'as the model run. SEDAR 73 (2021) supplies the retained model structure and',
    'life-history documentation; the 2024 update supplies revised observations',
    'and outputs through 2023. Neither source supports assuming survey timing',
    'or converting egg-based spawning output to biomass SSB. No canonical',
    'numerical records were imported.'
  )
)

matches_review <- all(vapply(names(review), function(column) {
  identical(as.character(x[[column]][i]), as.character(review[[column]]))
}, logical(1L)))
if (x$screening_status[i] == 'not_started' && x$match_status[i] == 'unreviewed') {
  for (column in names(review)) x[[column]][i] <- review[[column]]
} else if (!matches_review) {
  stop('Candidate row has a conflicting prior review.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE)
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened NOAA Southern Atlantic red snapper; the 2024 SEDAR 73 update is eligible for source curation.\n')

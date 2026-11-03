path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
updates <- list(
  list(
    id = 'ICES:her.27.3a47d', stock = 'ices_herring_north_sea', review = 'ices_herring_north_sea.md',
    catch = 'The 2026 HAWG report provides direct commercial catch-at-age for the official FLSAM assessment, model ages 0-8 winter-ring classes; the fitted period ends in 2025.',
    survey = 'Eight fleets are represented: HERAS, IBTS-Q1, IBTS0 and IBTS-Q3 age indices plus four larval indices for partial spawning-component likelihoods; sampling fractions for the age indices are approximate.',
    weights = 'Annual stock and catch weights are reported through 2025; source-specific outer-year averaging inconsistency is documented.',
    maturity = 'Annual maturity-at-age is reported through 2025.',
    mortality = 'The assessment imports SMS-2023 natural mortality with a +0.02 offset in the official model script.',
    timing = 'LAI fractions are 0.67; timing for other surveys uses approximate seasonal midpoints because the official fleet.txt was unavailable.',
    output = 'The report tables provide fitted N- and F-at-age, summaries and uncertainty through 2025; 2026 is an advice-year forecast.',
    sources = 'https://doi.org/10.17895/ices.pub.31424315; https://github.com/ices-advice/2026_her.27.3a47d',
    reason = 'Matched to the existing her.27.3a47d unit and curated 2026 assessment. Direct catch-at-age, age-specific survey series, biological inputs and fitted outputs support source eligibility. Larval indices use a partial spawning-component likelihood, and non-LAI timing, some inputs and current fitted object remain incomplete.'
  ),
  list(
    id = 'ICES:had.27.46a20', stock = 'ices_haddock_north_sea', review = 'ices_haddock_north_sea.md',
    catch = 'The official 2026 SAM run uses commercial catch numbers-at-age, ages 0-8+, 1972-2025.',
    survey = 'The Q1 index covers ages 1-8+ in 1983-2026; Q3+Q4 covers ages 0-8+ in 1991-2025. Both are standardized on native, uncalibrated scales.',
    weights = 'Age-specific stock and catch weights are represented in the 2026 assessment inputs.',
    maturity = 'The official assessment includes maturity-at-age inputs; source review records the selected surface and temporal treatment.',
    mortality = 'Age-specific natural mortality and its source construction are represented in the official assessment inputs.',
    timing = 'Survey sampling times are 0.125 for Q1 and 0.75 for Q3+Q4.',
    output = 'The official fit and report verify annual recruitment, SSB, Fbar and total biomass with intervals for 1972-2025, and N/F-at-age estimates; N/F uncertainty is conditional.',
    sources = 'https://doi.org/10.17895/ices.pub.32676345; https://ndownloader.figshare.com/files/66104291; https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NShaddock_WGNSSK2026_Run1/run/model.RData',
    reason = 'Matched to the existing had.27.46a20 unit and curated official 2026 SAM assessment. Catch-at-age, two age-indexed surveys, biology and fitted outputs are recovered. Survey index physical units are unknown and age-state uncertainty is conditional; canonical completeness remains partial.'
  ),
  list(
    id = 'ICES:ple.27.420', stock = 'ices_plaice_north_sea', review = 'ices_plaice_north_sea.md',
    catch = 'The official 2026 assessment reports direct catch-at-age, ages 1-10+, 1957-2025, in thousands of fish.',
    survey = 'Five age-specific indices are reported: BTS, IBTS Q3, SNS1, SNS2 and IBTS Q1, with documented year-age coverage; 2003 SNS2 observations are missing.',
    weights = 'Annual stock weight-at-age is reported in kg for 1957-2025.',
    maturity = 'The selected time-invariant maturity ogive is 0, 0.5, 0.5, then 1.0 at ages 4-10+.',
    mortality = 'M is fixed by age at 0.495, 0.394, 0.343, 0.311, 0.292, 0.278, 0.268, 0.260, 0.252, 0.246 per year for ages 1-10+.',
    timing = 'Report quarter labels support midpoint approximations 0.125 and 0.75; exact SAM sampling fractions were not recovered.',
    output = 'Official N/F-at-age and recruitment, SSB, and Fbar outputs cover 1957-2025; aggregate outputs include reported 95% intervals.',
    sources = 'https://doi.org/10.17895/ices.pub.32676345; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22489; https://doi.org/10.17895/ices.pub.21558681',
    reason = 'Matched to the existing ple.27.420 unit and curated 2026 assessment. Direct catch-at-age, five age-indexed surveys, biology and fitted outputs are available. Survey physical units and exact sampling fractions remain unresolved; the 2026 advice forecast is stored separately from the fitted series.'
  ),
  list(
    id = 'ICES:pok.27.3a46', stock = 'ices_saithe_north_sea', review = 'ices_saithe_north_sea.md',
    catch = 'The official SAM assessment reports total catch numbers-at-age, ages 3-10+, for 1967-2025.',
    survey = 'An age-specific research-vessel index combines Q3 and Q4 surveys for ages 3-8, 1992-2025; relative commercial trawl CPUE is available for 2000-2025.',
    weights = 'Total catch weights and stock weights at ages 3-10+ are reported for 1967-2025.',
    maturity = 'Annual maturity-at-age is reported for ages 3-10+.',
    mortality = 'Fixed Lorenzen M-at-age is reported for ages 3-10+ (0.384 to 0.177 per year).',
    timing = 'Exact 2026 survey fractions are absent; the cached older data object has 0.730 for the Q3-Q4 index, which is historical evidence only.',
    output = 'The report provides official N-at-age, F-at-age, recruitment, SSB, TSB and Fbar through 2025; summary intervals are reported.',
    sources = 'https://doi.org/10.17895/ices.pub.32676345; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22504; https://doi.org/10.17895/ices.pub.25002470',
    reason = 'Matched to the existing pok.27.3a46 unit and curated 2026 assessment. Direct catch-at-age, age-indexed survey information, age-specific biology and population/mortality outputs are available. Exact 2026 sampling fractions and final native fit were not recovered; report configuration is timestamped 2024.'
  ),
  list(
    id = 'ICES:whg.27.47d', stock = 'ices_whiting_north_sea', review = 'ices_whiting_north_sea_2026.md',
    catch = 'The official April NSwhiting_2026n SAM run uses total catch numbers-at-age, ages 0-8+, 1978-2025.',
    survey = 'IBTS Q1 provides ages 1-6+ for 1983-2026 (time 0.125); IBTS Q3 provides ages 0-6+ for 1991-2025 (time 0.625).',
    weights = 'Catch and stock weights-at-age are included; ages 6+ are grouped and expanded over model ages 6-8.',
    maturity = 'Smoothed maturity-at-age is included; age 6+ is grouped and expanded over ages 6-8.',
    mortality = 'The SAM model estimates time-varying M using a GMRF from WGSAM natural-mortality observations.',
    timing = 'Native sampling fractions are 0.125 for Q1 and 0.625 for Q3; before-spawning mortality fractions are separately zero.',
    output = 'The official fitted object and report provide N/F/M-at-age, q, fitted catch/index predictions and annual summaries; source review verifies published series and records conditional state uncertainty.',
    sources = 'https://doi.org/10.17895/ices.pub.32676345; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22488; https://doi.org/10.17895/ices.pub.32019630',
    reason = 'Matched to the existing whg.27.47d unit and canonical April 2026 official SAM run. Native inputs, fit and outputs are recovered, and the fit reproduces published historical summaries. Age-6+ survey and biological grouping is expanded in the canonical surfaces; a later June variant is not used because it does not match published series.'
  )
)
for (u in updates) {
  i <- which(x$candidate_id == u$id)
  if (length(i) != 1L || x$matched_stock_id[i] != u$stock ||
      x$match_status[i] != 'matched' || !(x$screening_status[i] %in% c('not_started', 'screened'))) {
    stop('Preserve the current identity or screen for ', u$id, '.', call. = FALSE)
  }
  x$screening_status[i] <- 'screened'
  x$eligibility[i] <- 'eligible'
  x$import_status[i] <- 'imported'
  for (field in c('catch_age_evidence','survey_age_evidence','weights_evidence',
                  'maturity_evidence','mortality_evidence','timing_evidence','output_evidence')) {
    key <- switch(field, catch_age_evidence = 'catch', survey_age_evidence = 'survey',
      weights_evidence = 'weights', maturity_evidence = 'maturity',
      mortality_evidence = 'mortality', timing_evidence = 'timing',
      output_evidence = 'output')
    x[[field]][i] <- u[[key]]
  }
  x$detailed_source_url[i] <- u$sources
  x$review_date[i] <- '2026-10-29'
  x$decision_reason[i] <- u$reason
  x$notes[i] <- paste0('Already curated as ', u$stock, '_2026; see ',
    'source_reviews/', u$review, '.')
}
lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (u in updates) {
  i <- match(u$id, x$candidate_id)
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened five matched ICES North Sea assessment entries.\n')

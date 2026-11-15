# Screen the NOAA Gulf of Alaska Pacific ocean perch candidate against its
# current assessment report and pinned model files.
path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
i <- match('NOAA:11056', x$candidate_id)
if (is.na(i)) stop('Expected NOAA GOA Pacific ocean perch row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(x$match_status[i] == 'new', x$eligibility[i] == 'eligible')
  quit(save = 'no')
}
if (x$match_status[i] != 'unreviewed' || x$screening_status[i] != 'not_started') {
  stop('Preserve the existing review; the candidate row has changed.', call. = FALSE)
}

x$match_status[i] <- 'new'
x$matched_stock_id[i] <- NA_character_
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The run-matched 2023 model has fishery catch biomass in tonnes for 1961-2023',
  'and number proportions at ages 2-24 plus 25+ in 17 sampled years (1990,',
  '1998-2002, 2004-2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022).',
  'The pinned repository also supplies fishery weight-at-age for ages 2-29 in',
  'grams per fish. A source-based catch-number reconstruction is possible only',
  'for composition years; unsampled years remain missing.'
)
x$survey_age_evidence[i] <- paste(
  'The assessment has aggregate bottom-trawl biomass in tonnes for 16 years',
  'from 1990-2023, with standard errors, and age proportions plus sampling',
  'counts for 14 years (1990, 1993, 1996, 1999, 2003-2021 biennially).',
  'Survey weight-at-age is supplied in grams per fish, supporting an',
  'age-specific abundance reconstruction for shared survey years. The final',
  'model .dat and SAFE list 1990 ages; an auxiliary repository CSV omits that',
  'row and must not replace the run-matched input.'
)
x$weights_evidence[i] <- paste(
  'Pinned 2023 repository exports separate model, fishery and survey',
  'weight-at-age vectors for ages 2-29 in grams per fish. The official model',
  'uses one weight vector in its biomass equations.',
  'can use the source-specific fishery and survey vectors and must document',
  'that distinction.'
)
x$maturity_evidence[i] <- paste(
  'The official model estimates a logistic maturity-at-age curve from two',
  'female maturity datasets (Lunsford 1999 and Conrath and Knoth 2013);',
  'maturity is not a fixed supplied ogive.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is estimated as one constant parameter with a prior',
  'mean of 0.0614 and prior CV 0.1; the fitted value is about 0.074.'
)
x$timing_evidence[i] <- paste(
  'The official annual survey prediction uses abundance at the survey year',
  'without a separate within-year sampling fraction. The input value spawn',
  'month 5 is spawning timing, not survey timing. Exact survey timing is not',
  ''
)
x$output_evidence[i] <- paste(
  'The pinned run repository contains point estimates of numbers-at-age',
  '(1961-2023, ages 2-29), recruitment, F, total biomass and spawning',
  'biomass. The SAFE report and model repository include MCMC uncertainty for',
  'selected aggregate quantities and parameters; age-specific N intervals',
  'are not in the exported N-at-age table.'
)
x$detailed_source_url[i] <- 'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOApop.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'Provisionally eligible for source curation and a later:',
  'run-matched catch totals, age proportions and fishery weights support',
  'catch-number reconstruction in sampled years; survey biomass, age',
  'proportions and survey weights support age-specific index reconstruction;',
  'the assessment has biological inputs, estimated M and age-specific outputs.',
  'The translation must retain missing composition years, account for the',
  '25+ observation group and disclose likelihood and timing approximations.'
)
x$notes[i] <- paste(
  'NOAA Stock SMART ID 11056 is a separate GOA unit from BSAI POP (NOAA:11055)',
  'and British Columbia POP (DFO). Stock SMART lists 2024, but the latest',
  'completed detailed fit located is the 2023 operational update, Model 20.1,',
  'with data through 2023. The 2025 full assessment was cancelled; a new GOA',
  'assessment was scheduled for December 2026 and had not been released by',
  'the 2026-10-29 review date. See source_reviews/noaa_goa_pacific_ocean_perch.md.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

# Screen the DFO Southern Gulf spring- and fall-spawning herring entries.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c(
  'DFO:Gulf:Atlantic Herring - NAFO 4T (Spring Spawner)',
  'DFO:Gulf:Atlantic Herring - NAFO 4T (Fall Spawner)'
)
stock_ids <- c('dfo_herring_4tvn_spring', 'ck_dfo_gsl_harengus_4t_fall')
i <- match(ids, x$candidate_id)
if (anyNA(i)) stop('Expected DFO Southern Gulf herring rows are missing.', call. = FALSE)

if (all(x$screening_status[i] == 'screened')) {
  stopifnot(all(x$matched_stock_id[i] == stock_ids),
    all(x$eligibility[i] == 'eligible'), all(x$import_status[i] == 'imported'))
  quit(save = 'no')
}
if (any(x$match_status[i] != 'matched') || any(x$matched_stock_id[i] != stock_ids) ||
    any(x$screening_status[i] != 'not_started')) {
  stop('Preserve the existing identity review; one or more candidate rows changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Clupea harengus'
x$assessment_area[i] <- c('Southern Gulf spring component (4Tmno)', 'Southern Gulf fall component (4T)')
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i[1L]] <- paste(
  'The detailed 2024 assessment reports fixed- and mobile-gear catch-at-age',
  'and weight-at-age for 1978-2023, ages 2-11+. The 2023 mobile catch is a',
  'documented zero reconstruction from reported landings; the source reports',
  'age-specific catch observations rather than requiring a new allocation.'
)
x$survey_age_evidence[i[1L]] <- paste(
  'The 2024 source includes fixed-gear CPUE-at-age for 1990-2021 and spring',
  'acoustic age-index values for ages 2-10 during 1994-2023, in thousands',
  'of fish. The acoustic series is an abundance index, not raw trawl sample',
  'counts. Separate public biomass observations are recorded under the 2026 event.'
)
x$weights_evidence[i[1L]] <- paste(
  'Fixed- and mobile-gear weight-at-age are reported in kg/fish. Stock-weight',
  'combination for the comparison is reconstructed and explicitly documented; it',
  'is not presented as the official model input.'
)
x$maturity_evidence[i[1L]] <- paste(
  'The source assessment uses a knife-edge maturity schedule: ages 2-3 are',
  'immature and ages 4-11+ mature.'
)
x$mortality_evidence[i[1L]] <- paste(
  'The documented SCA estimates time-varying log-M in age blocks 2-6 and',
  '7-11+; 2022 methods provide process details. Numerical fitted M surfaces',
  'are unavailable for the detailed 2024 run. The 2026 advisory reports grouped M.'
)
x$timing_evidence[i[1L]] <- paste(
  'The spring acoustic series represents the 4Tmno spring-spawner survey and',
  'the comparison recipe records acoustic timing 0.75 and CPUE timing 0.25 as',
  'explicit approximations; exact 2024 fitted timing is not fully documented.'
)
x$output_evidence[i[1L]] <- paste(
  'The detailed 2024 source reports January 1 N-at-age, SSB/biomass-at-age and',
  'F-at-age, with derived total abundance and mature biomass. The separate 2026',
  'assessment reports 2024-2025 April 1 SSB, age-2 recruitment and grouped M;',
  'full 2026 age surfaces remain unavailable.'
)

x$catch_age_evidence[i[2L]] <- paste(
  'The detailed 2024 source reports fixed- and mobile-gear catch-at-age and',
  'weight-at-age for 1978-2023, ages 2-11+. The published mobile catch-at-age',
  'duplicates the fixed-gear table and is explicitly flagged as unverified;',
  'the translation uses the fixed-gear series only.'
)
x$survey_age_evidence[i[2L]] <- paste(
  'The 2024 source reports fall fixed-gear CPUE-at-age for ages 4-11 during',
  '1986-2023, acoustic age-index observations for ages 2-10 during 1994-2023,',
  'and bottom-trawl numbers per tow at ages 1-11+ during 1994-2023. The separate',
  'public acoustic biomass series is retained under the 2026 event.'
)
x$weights_evidence[i[2L]] <- paste(
  'Fixed- and mobile-gear weight-at-age are reported by region in kg/fish;',
  'the 2023 mobile-gear weight row is missing. The assessment-specific tables',
  'and gaps are retained in the canonical data.'
)
x$maturity_evidence[i[2L]] <- paste(
  'The documented SCA uses knife-edge maturity with ages 4+ mature; the exact',
  '2024 run settings are not fully restated in the supporting document.'
)
x$mortality_evidence[i[2L]] <- paste(
  'The documented SCA estimates time-varying log-M in age blocks 2-6 and',
  '7-11+; the detailed 2024 numerical fitted M surface is unavailable. The',
  '2026 advisory reports a single aggregate 2025 SSB, not age-specific M.'
)
x$timing_evidence[i[2L]] <- paste(
  'The supporting source identifies fixed-gear, acoustic and bottom-trawl',
  'series, but an exact fitted fractional-year timing for the latest run is',
  'unresolved. Do not infer a numeric timing from season names alone.'
)
x$output_evidence[i[2L]] <- paste(
  'Tables 22-29 report January 1 abundance and biomass at age by region and',
  'combined population; Tables 30-33 report January 1 F-at-age and Fbar.',
  'The 2026 advisory reports 2025 total SSB (321 kt, 95% interval 259-433 kt),',
  'but not full age-specific surfaces or numerical M.'
)

x$detailed_source_url[i] <- 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41256384.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i[1L]] <- paste(
  'This is the existing Southern Gulf spring-spawning herring unit. Detailed',
  '2024 age-specific catches, indices and biological inputs plus official',
  'population/F outputs are available; current 2026 advice and selected',
  'grouped M/recruitment outputs are recorded separately. Age-based translation',
  'is source-supported with the documented likelihood and timing approximations.'
)
x$decision_reason[i[2L]] <- paste(
  'This is the existing Southern Gulf fall-spawning herring unit. The detailed',
  '2024 assessment provides age-specific catch/index inputs and January 1 N/F',
  'outputs, while its mobile catch table is duplicated and excluded from the',
  'translation. The 2026 advisory update remains a separate, summary-only event.'
)
x$notes[i[1L]] <- paste(
  'Already curated as dfo_herring_4tvn_spring_2024 and a separate 2026 summary',
  'event; do not merge their data. See source_reviews/dfo_herring_4tvn_spring.md.'
)
x$notes[i[2L]] <- paste(
  'Already curated as dfo_herring_4tvn_fall_2024 and a separate 2026 summary',
  'event; do not merge their data. See source_reviews/dfo_herring_4tvn_fall.md.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (j in i) {
  write.csv(x[j, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[j + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

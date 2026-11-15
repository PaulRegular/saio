# Reconcile the DFO Canary Rockfish inventory row to its curated assessment.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
i <- match('DFO:Pacific:Canary Rockfish', x$candidate_id)
if (is.na(i)) stop('Expected DFO Canary Rockfish row is missing.', call. = FALSE)
if (x$screening_status[i] == 'screened') {
  stopifnot(
    x$matched_stock_id[i] == 'dfo_canary_bc',
    x$eligibility[i] == 'eligible',
    x$import_status[i] == 'imported'
  )
  quit(save = 'no')
}
if (x$match_status[i] != 'matched' || x$matched_stock_id[i] != 'dfo_canary_bc' ||
    x$screening_status[i] != 'not_started') {
  stop('Preserve the existing identity review; the candidate row has changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Sebastes pinniger'
x$assessment_area[i] <- 'British Columbia coastwide (3CD and 5ABCDE; excludes 4B)'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste(
  'Run24/24.01 includes annual catch biomass for 1935-2022 and joint-sex',
  'trawl age compositions in 36 years (1977-2017). Catch-at-age requires',
  'the documented composition and weight reconstruction; no composition is',
  'invented for unsampled fleets or years.'
)
x$survey_age_evidence[i] <- paste(
  'Six biomass surveys and commercial CPUE are retained. QCS, WCVI and NMFS',
  'have source age compositions; the annual aggregate biomass indices and',
  'those compositions support a documented approximate age-specific index.',
  'Other surveys and CPUE have no age compositions.'
)
x$weights_evidence[i] <- paste(
  'Source growth, length variability and weight-length parameters are fixed.',
  'The matching SS3 3.30.18 executable was used to reconstruct beginning-year,',
  'midyear, catch and survey weights by sex; the source review documents the',
  'evaluation and its checksum.'
)
x$maturity_evidence[i] <- paste(
  'The original female maturity-at-age and effective reproductive weights',
  'are retained separately. The official executable applies a first-mature',
  'age cutoff at 10 to January spawning biomass.'
)
x$mortality_evidence[i] <- paste(
  'Natural mortality is estimated as one constant per sex, with a natural-scale',
  'Normal prior (mean 0.06, SD 0.018; bounds 0.02-0.2). Published sex-specific',
  'M estimates and their native 90% limits are in the official report.'
)
x$timing_evidence[i] <- paste(
  'All source catch, survey and CPUE observations use native month 6,',
  'equivalent to annual timing 5/12. January spawning uses no pre-spawning',
  'mortality adjustment.'
)
x$output_evidence[i] <- paste(
  'The curated record includes 500 official posterior-subset female SSB',
  'trajectories for 1935-2023, sex-specific M and published reference output.',
  'The subset is not the full 2,000-draw posterior; numerical N-at-age,',
  'F-at-age and annual recruitment outputs were not recovered.'
)
x$detailed_source_url[i] <- 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41218875.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'The DFO survey entry matches the existing coastwide dfo_canary_bc_2022',
  'Run24/24.01 record. Its source includes catch totals, fishery and survey',
  'age compositions, aggregate indices, biology, timing and comparable official',
  'SSB/M outputs; reconstructed age-specific observations are documented.',
  'Limitations include a female-only translation, missing age samples in some',
  'years/streams, and a 500-draw subset rather than the full posterior.'
)
x$notes[i] <- paste(
  'Already curated as dfo_canary_bc_2022; do not create a duplicate stock or',
  'assessment. See source_reviews/dfo_canary_bc.md and the cached source',
  'manifest.'
)

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)

root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
id <- 'DFO:Pacific:Chinook salmon - Okanagan'
i <- match(id, x$candidate_id)
if (is.na(i)) stop('Expected Okanagan Chinook inventory row is missing.', call. = FALSE)

if (x$screening_status[i] == 'screened') {
  stopifnot(x$candidate_unit_id[i] == 'dfo_okanagan_chinook',
    x$match_status[i] == 'new', x$eligibility[i] == 'ineligible',
    x$import_status[i] == 'not_started')
  quit(save = 'no')
}
if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
  stop('Preserve the existing Okanagan Chinook review state.', call. = FALSE)
}

x$candidate_unit_id[i] <- 'dfo_okanagan_chinook'
x$scientific_name[i] <- 'Oncorhynchus tshawytscha'
x$assessment_area[i] <- 'Canadian Okanagan watershed; DFO summer-run SMU with one CU; spring-run information limited'
x$inventory_assessment_year[i] <- 2023
x$match_status[i] <- 'new'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'ineligible'
x$import_status[i] <- 'not_started'
x$catch_age_evidence[i] <- paste(
  'The 2023 assessment does not estimate absolute catch because recruitment',
  'is unavailable. No fishery catch-at-age input is reported. The exploitation',
  'series is a proxy from the U.S. Similkameen indicator stock.'
)
x$survey_age_evidence[i] <- paste(
  'The assessment uses an aggregate natural-origin spawner index from stream',
  'float/walk and area-under-the-curve surveys, plus whole-population',
  'mark-recapture estimates in 2020 and 2023. DFO says age estimates have not',
  'been collected sufficiently to assign escapement to cohorts; no age-specific',
  'index or model age-composition input is reported.'
)
x$weights_evidence[i] <- paste(
  'The current assessment does not report or use a conventional',
  'weight-at-age surface.'
)
x$maturity_evidence[i] <- paste(
  'The current assessment does not report or use a conventional',
  'maturity-at-age surface. Life-history age ranges in supporting material',
  'are not a fitted biological input.'
)
x$mortality_evidence[i] <- paste(
  'No age-specific F or M is estimated. Summer/fall harvest is represented',
  'by an exploitation proxy from the U.S. Similkameen indicator stock; DFO',
  'notes exploitation is not measured directly for this SMU.'
)
x$timing_evidence[i] <- paste(
  'The abundance observations are spawning escapement counts rather than an',
  'annual fishery-independent index with a within-year timing fraction.'
)
x$output_evidence[i] <- paste(
  'The 2023 assessment reports an aggregate spawner index from 2006 onward,',
  'whole-population abundance estimates for 2020 and 2023, and status metrics.',
  'It states recruitment estimates are unavailable and does not report',
  'N-at-age or F-at-age.'
)
x$detailed_source_url[i] <- paste(
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41276371.pdf;',
  'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40959429.pdf;',
  'https://www.dfo-mpo.gc.ca/fisheries-peches/ifmp-gmp/salmon-saumon/2024/okanagan-2024-eng.html'
)
x$review_date[i] <- '2026-10-30'
x$decision_reason[i] <- paste(
  'The latest official assessment is the 2023 stock assessment published as',
  'DFO Science Response 2025/003. It assesses aggregate escapement and status,',
  'not an age-structured production model. DFO states that ages are not',
  'available in sufficient detail to estimate escapement by cohort and that',
  'recruitment is unavailable. Fishery catch-at-age, age-specific abundance',
  'and population outputs, conventional weight/maturity inputs, and age-specific',
  'mortality are not available in the current assessment; ineligible for the',
  'age-disaggregated assessment set.'
)
x$notes[i] <- paste(
  'The DFO SMU is one CU and focuses on summer-run fish; spring-run information',
  'is limited. It is transboundary but is not identical to NOAA Stock SMART',
  '17337, Aggregate Chinook Salmon Complex. No canonical stock record was',
  'added. The 2019 RPA is historical context for this same unit, not a fallback',
  'for the 2023 assessment. See discovery/source_reviews/',
  'dfo_okanagan_chinook_2023.md.'
)

source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))
replace_candidate_register_row(path, i, x[i, , drop = FALSE], id)

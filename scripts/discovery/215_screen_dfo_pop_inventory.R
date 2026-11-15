# Screen the three DFO inventory entries against the coastwide POP assessment.
root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c(
  'DFO:Pacific:Pacific Ocean Perch - PMFC 3CD-WCVI',
  'DFO:Pacific:Pacific Ocean Perch - PMFC 5ABC-QCS',
  'DFO:Pacific:Pacific Ocean Perch - PMFC 5DE-HS/DE/WHG'
)
i <- match(ids, x$candidate_id)
if (anyNA(i)) stop('Expected DFO Pacific ocean perch rows are missing.', call. = FALSE)

if (all(x$screening_status[i] == 'screened')) {
  stopifnot(
    all(x$matched_stock_id[i] == 'dfo_pop_bc'),
    all(x$eligibility[i] == 'eligible'),
    all(x$import_status[i] == 'imported')
  )
  quit(save = 'no')
}
if (any(x$match_status[i] != 'matched') || any(x$matched_stock_id[i] != 'dfo_pop_bc') ||
    any(x$screening_status[i] != 'not_started')) {
  stop('Preserve the existing identity review; one or more candidate rows changed.', call. = FALSE)
}

x$scientific_name[i] <- 'Sebastes alutus'
x$assessment_area[i] <- 'British Columbia coastwide (5ABC, 3CD, 5DE)'
x$screening_status[i] <- 'screened'
x$eligibility[i] <- 'eligible'
x$import_status[i] <- 'imported'
x$catch_age_evidence[i] <- paste(
  'The 2023 production assessment includes annual commercial catch in tonnes',
  'for 1935-2023 and fishery age-composition inputs for three subarea fisheries.',
  'Catch-at-age is a documented downstream reconstruction from catch totals',
  'and composition data, not the original model observation.'
)
x$survey_age_evidence[i] <- paste(
  'The model uses six trawl survey biomass series and age-composition inputs',
  'from five surveys (29 survey-years). With source survey weights, these',
  'support a documented approximate age-specific index; ages are not direct',
  'abundance-at-age observations. Survey biomass data span 1967-2022.'
)
x$weights_evidence[i] <- paste(
  'The source run fixes growth and length-weight parameters rather than',
  'supplying an empirical weight-at-age matrix. Beginning- and midyear',
  'population weights were reconstructed by evaluating those fixed inputs',
  'with the matching SS3 3.30.20 release; source review records the method.'
)
x$maturity_evidence[i] <- paste(
  'The official input supplies a fixed female maturity-at-age schedule;',
  'mature biomass is based on females. Native age range is 0-60+, with',
  'observed composition bins 1-60+.'
)
x$mortality_evidence[i] <- paste(
  'The coastwide two-sex Bayesian assessment estimates constant natural',
  'mortality by sex. Table F.4 reports female M median 0.05229 (90% limits',
  '0.04365-0.06146) and male M median 0.05939 (0.05050-0.06902).'
)
x$timing_evidence[i] <- paste(
  'The native model records survey month 6; the corresponding annual timing',
  'is 5/12. The assessment retains three subareas, two sexes, three trawl',
  'catch series and six survey series.'
)
x$output_evidence[i] <- paste(
  'The official report gives January 2024 spawning biomass of 61,965 t with',
  '90% limits 44,390-90,825 t, plus sex-specific M estimates. Regional',
  'posterior biomass trajectories are available for 3CD and 5DE, but matching',
  '2023-run 5ABC trajectories and historical N-at-age, F-at-age and recruitment',
  'outputs were not recovered. The biomass definition also needs confirmation.'
)
x$detailed_source_url[i] <- 'https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41282565.pdf'
x$review_date[i] <- '2026-10-29'
x$decision_reason[i] <- paste(
  'These three 2024 DFO inventory entries are subareas in one current',
  'coastwide 2023 assessment, not three additional stock units. The source',
  'provides catch totals, fishery and survey age compositions, aggregate survey',
  'indices, weights, maturity, timing, and official sex-specific M and terminal',
  'biomass outputs; source-supported age-index reconstruction is possible.',
  'Historical comparison remains limited because matching full coastwide',
  'population-output series and the biomass definition are unresolved.'
)
x$notes[i] <- paste(
  'All three entries map to the existing dfo_pop_bc / dfo_pop_bc_2023 record;',
  'do not create duplicate stock or assessment records. See',
  'source_reviews/dfo_pop_bc.md and its local source-cache manifest.'
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

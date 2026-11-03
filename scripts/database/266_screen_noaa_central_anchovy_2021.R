root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)

id <- 'NOAA:10574'
i <- match(id, x$candidate_id)
source_review <- file.path(root, 'discovery', 'source_reviews',
  'noaa_northern_anchovy_central_subpopulation_2021.md')
if (is.na(i) || sum(x$candidate_id == id) != 1L) {
  stop('Expected one NOAA northern anchovy inventory row.', call. = FALSE)
}
if (any(stocks$scientific_name == 'Engraulis mordax')) {
  stop('An Engraulis mordax stock record exists; reconcile identity before screening.', call. = FALSE)
}
if (!file.exists(source_review)) stop('The source review is missing.', call. = FALSE)

review <- list(
  candidate_unit_id = 'noaa_northern_anchovy_central_subpopulation',
  match_status = 'new',
  screening_status = 'screened',
  eligibility = 'eligible',
  import_status = 'not_started',
  assessment_area = paste(
    'Central subpopulation, California to northern Baja California;',
    'Stock SMART label: Southern Pacific Coast'
  ),
  catch_age_evidence = paste(
    'The native SS input contains 2000-2021 semester catches in metric tonnes for two pooled',
    'MexCal fleets and their age-composition proportions. These are not direct catch numbers-at-age;',
    'the report documents reconstructing them from monthly landings, age proportions and final',
    'weight-at-age, then aggregating to semesters.'
  ),
  survey_age_evidence = paste(
    'The base model fits acoustic-trawl summer and spring biomass indices with lognormal errors;',
    'the run archive includes survey age compositions and weights-at-age. Age-specific survey',
    'abundance is reconstructable from index biomass, age composition and weight-at-age, but',
    'is not a direct age-specific index likelihood.'
  ),
  weights_evidence = paste(
    'The native weight-at-age file contains empirical fleet-, year- and semester-specific weights',
    'for ages 0, 1, 2 and 3+. The report documents averaging and interpolation used for missing',
    'fishery values; survey values were derived from acoustic-trawl age and length data.'
  ),
  maturity_evidence = paste(
    'Fixed maturity proportions are approximately 0.726, 0.931, 0.985 and 0.997 for ages 0, 1,',
    '2 and 3+; fecundity is fixed at one gram of eggs per gram body weight.'
  ),
  mortality_evidence = paste(
    'The base model estimates uniform natural mortality; the report gives 0.414 per year.',
    'Steepness is fixed at 0.6.'
  ),
  timing_evidence = paste(
    'The model runs 2015-2021 in biological semesters: June-December (7 months) and January-May',
    '(5 months), with a June 1 birth date. The run file records a survey timing field and assigns',
    'observations to semesters; an unambiguous within-semester calendar fraction was not recovered.'
  ),
  output_evidence = paste(
    'Tables 11-14 report numbers-at-age (thousands of fish), biomass-at-age and annual biomass',
    '(metric tonnes), SSB and recruitment with asymptotic standard errors; the report also gives',
    'the 0.414 per-year M estimate. Apical F by fishery is plotted, not tabulated by age.'
  ),
  detailed_source_url = paste(
    'https://www.pcouncil.org/documents/2022/07/assessment-of-the-northern-anchovy-engraulis-mordax-central-subpopulation-in-2021-for-u-s-management-june-2022.pdf/;',
    'https://www.pcouncil.org/documents/anchovy-2021-model-files/;',
    'https://www.fisheries.noaa.gov/species/northern-anchovy'
  ),
  review_date = '2026-10-29',
  decision_reason = paste(
    'The latest detailed production assessment located is the 2021 CSNA benchmark adopted in 2022.',
    'Its native run archive supplies fishery and survey age compositions, catches, weights and',
    'fixed maturity; the report supplies age-structured population outputs. Catch-at-age and an',
    'age-specific survey index can be reconstructed using the report-documented transformations,',
    'so the unit is eligible for source curation. No numerical data have been imported.'
  ),
  notes = paste(
    'Stock SMART 10574 uses “Southern Pacific Coast”; the PFMC run calls this the central',
    'subpopulation. The current NOAA page identifies the southern stock as assessed in 2022.',
    'The historical Charbonneau-Keith E. mordax label is actually Iberian E. encrasicolus and is',
    'not a match. See source_reviews/noaa_northern_anchovy_central_subpopulation_2021.md.'
  )
)

if (x$screening_status[i] == 'screened') {
  for (column in names(review)) {
    if (!identical(as.character(x[[column]][i]), as.character(review[[column]]))) {
      stop(paste('Previously screened NOAA anchovy field changed:', column), call. = FALSE)
    }
  }
  cat('NOAA:10574 is already screened consistently.\n')
} else {
  if (x$screening_status[i] != 'not_started' || x$match_status[i] != 'unreviewed') {
    stop('Preserve the existing NOAA anchovy review state before screening.', call. = FALSE)
  }
  for (column in names(review)) x[[column]][i] <- review[[column]]
  lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
  if (length(lines) != nrow(x) + 1L) stop('Unexpected multiline rows in candidate register.', call. = FALSE)
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
  writeLines(lines, path, useBytes = TRUE)
  cat('Screened NOAA Stock SMART 10574 as the central-subpopulation northern anchovy unit.\n')
}
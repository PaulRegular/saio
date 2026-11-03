root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
rows <- register[match(c('NOAA:10500', 'NOAA:10501'), register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(rows) == 2L,
  identical(rows$candidate_unit_id,
    c('noaa_monkfish_north_10500', 'noaa_monkfish_south_10501')),
  all(rows$match_status == 'new'),
  all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'),
  all(rows$import_status == 'not_started'),
  all(rows$review_date == '2026-10-30'),
  all(grepl('reliable aging method was lacking', rows$catch_age_evidence, fixed = TRUE)),
  all(grepl('age-specific abundance index', rows$survey_age_evidence, fixed = TRUE)),
  all(grepl('0.829 in the North|0.646 in the South', rows$output_evidence)),
  all(grepl('does not claim that biological age samples do not exist',
    rows$decision_reason, fixed = TRUE)),
  all(grepl('Full acceptance', rows$notes, fixed = TRUE)),
  all(grepl('Plan B', rows$notes, fixed = TRUE)),
  !any(stocks$scientific_name == 'Lophius americanus'),
  !any(c('NOAA:10500','NOAA:10501',
    'noaa_monkfish_north_10500','noaa_monkfish_south_10501') %in%
    c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id)),
  file.exists(file.path(root, 'discovery', 'source_reviews', 'noaa_monkfish_2022.md'))
)
cat('NOAA monkfish identity, source evidence, eligibility, and no-import checks passed.\n')

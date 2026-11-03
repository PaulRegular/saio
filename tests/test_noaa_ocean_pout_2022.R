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
row <- register[register$candidate_id == 'NOAA:10525', , drop = FALSE]
stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_ocean_pout_10525',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  row$review_date == '2026-10-30',
  grepl('Full acceptance', row$notes, fixed = TRUE),
  grepl('not peer-reviewed in the Fall 2022 panel', row$notes, fixed = TRUE),
  grepl('index-based method', row$decision_reason, fixed = TRUE),
  grepl('does not claim that biological age samples do not exist', row$decision_reason, fixed = TRUE),
  grepl('Zoarces americanus', row$notes, fixed = TRUE),
  !any(stocks$scientific_name == 'Zoarces americanus'),
  !any(c('NOAA:10525', 'noaa_ocean_pout_10525') %in% c(assessments$assessment_id,
    inputs$assessment_id, outputs$assessment_id)),
  file.exists(file.path(root, 'discovery', 'source_reviews', 'noaa_ocean_pout_2022.md'))
)
cat('NOAA ocean-pout identity, index-method exclusion, provenance, and no-import checks passed.\n')

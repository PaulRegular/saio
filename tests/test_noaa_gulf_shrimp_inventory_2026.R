root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/363_reconcile_noaa_gulf_shrimp_inventory.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:10079', 'NOAA:10081', 'NOAA:10083')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(rows) == 3L,
  !anyNA(rows$candidate_unit_id),
  !anyDuplicated(rows$candidate_unit_id),
  identical(rows$match_status, rep('new', 3L)),
  identical(rows$screening_status, rep('screened', 3L)),
  identical(rows$eligibility, rep('ineligible', 3L)),
  all(grepl('outside the initial marine-finfish scope', rows$decision_reason, fixed = TRUE)),
  !any(rows$official_stock_id %in% stocks$authority_stock_id),
  !any(rows$scientific_name %in% stocks$scientific_name),
  !any(rows$candidate_unit_id %in% assessments$assessment_id),
  !any(rows$candidate_unit_id %in% inputs$assessment_id),
  !any(rows$candidate_unit_id %in% outputs$assessment_id),
  file.exists(file.path(root, 'discovery/source_reviews/noaa_gulf_shrimp_inventory_2026.md'))
)

cat('NOAA Gulf shrimp identity and scope checks passed.\n')

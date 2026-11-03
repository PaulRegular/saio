root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/364_reconcile_noaa_invertebrate_inventory.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- paste0('NOAA:', c(10080, 10082, 10084, 10087, 10088, 10786, 10787,
  10792, 10798, 10802, 10803, 10809, 10810, 10811, 10813, 10814, 10816,
  10817, 10820, 10821, 10933, 10958, 11031, 11201, 11843, 12532, 12533,
  12534, 14841, 14842))
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
  nrow(rows) == length(ids),
  !anyNA(rows$candidate_unit_id),
  !anyDuplicated(rows$candidate_unit_id),
  identical(rows$match_status, rep('new', length(ids))),
  identical(rows$screening_status, rep('screened', length(ids))),
  identical(rows$eligibility, rep('ineligible', length(ids))),
  identical(rows$import_status, rep('not_started', length(ids))),
  all(grepl('outside the initial marine-finfish scope', rows$decision_reason, fixed = TRUE)),
  !any(rows$official_stock_id %in% stocks$authority_stock_id),
  !any(rows$candidate_unit_id %in% assessments$assessment_id),
  !any(rows$candidate_unit_id %in% inputs$assessment_id),
  !any(rows$candidate_unit_id %in% outputs$assessment_id),
  file.exists(file.path(root, 'discovery/source_reviews/noaa_invertebrate_inventory_2026.md'))
)

cat('NOAA invertebrate identity and scope checks passed.\n')

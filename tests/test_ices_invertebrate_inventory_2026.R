root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/365_reconcile_ices_invertebrate_inventory.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

rows <- register[register$organization == 'ICES' & register$scientific_name %in%
  c('Nephrops norvegicus', 'Pandalus borealis'), , drop = FALSE]
expected_units <- paste0('ices_', gsub('(^_+|_+$)', '', gsub('[^a-z0-9]+', '_',
  tolower(rows$official_stock_id))))
stopifnot(
  nrow(rows) == 32L,
  !anyDuplicated(rows$candidate_id),
  !anyDuplicated(rows$candidate_unit_id),
  identical(rows$match_status, rep('new', nrow(rows))),
  identical(rows$candidate_unit_id, expected_units),
  all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'),
  all(rows$import_status == 'not_started'),
  all(grepl('crosswalked against the pinned 2026 ICES SID', rows$notes,
    fixed = TRUE)),
  all(grepl('remain unaudited', rows$notes, fixed = TRUE)),
  !any(rows$official_stock_id %in% stocks$authority_stock_id),
  !any(rows$candidate_unit_id %in% assessments$assessment_id),
  !any(rows$candidate_unit_id %in% inputs$assessment_id),
  !any(rows$candidate_unit_id %in% outputs$assessment_id),
  file.exists(file.path(root, 'discovery/source_reviews/ices_invertebrate_inventory_2026.md'))
)

cat('ICES invertebrate inventory identity and scope checks passed.\n')

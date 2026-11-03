root <- '.'
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/365_screen_ices_wgnssk_n_age_methods.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')

register <- read.csv(file.path(root, 'discovery/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('ICES:gug.27.3a47d', 'ICES:bll.27.3a47de', 'ICES:fle.27.420')
unit_ids <- c('ices_grey_gurnard_3a47d', 'ices_brill_3a47de', 'ices_flounder_420')
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
  identical(rows$candidate_unit_id, unit_ids),
  identical(rows$match_status, rep('new', 3L)),
  identical(rows$screening_status, rep('screened', 3L)),
  identical(rows$eligibility, rep('ineligible', 3L)),
  identical(rows$import_status, rep('not_started', 3L)),
  grepl('category-3', rows$catch_age_evidence[1L], fixed = TRUE),
  grepl('SPiCT', rows$catch_age_evidence[2L], fixed = TRUE),
  grepl('Kattegat', rows$decision_reason[3L], fixed = TRUE),
  all(rows$detailed_source_url == 'https://doi.org/10.17895/ices.pub.32676345.v2'),
  !any(rows$official_stock_id %in% stocks$authority_stock_id),
  !any(rows$scientific_name %in% stocks$scientific_name),
  !any(rows$candidate_unit_id %in% assessments$assessment_id),
  !any(rows$candidate_unit_id %in% inputs$assessment_id),
  !any(rows$candidate_unit_id %in% outputs$assessment_id),
  file.exists(file.path(root, 'discovery/source_reviews/ices_wgnssk_n_age_methods_2026.md'))
)

cat('ICES WGNSSK non-age method screening checks passed.\n')

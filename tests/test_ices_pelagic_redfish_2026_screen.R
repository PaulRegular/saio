source("scripts/shared/candidate_reports.R", local = TRUE)

source('scripts/ices_pelagic_redfish_2026/468_screen_ices_pelagic_redfish_2026.R')
root <- "."
register <- read.csv(file.path(root, 'database/candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- c('ICES:reb.2127.dp', 'ICES:reb.2127.sp')
rows <- register[match(ids, register$candidate_id), ]
stopifnot(nrow(rows) == 2L, !anyNA(rows$candidate_unit_id),
  !anyDuplicated(rows$candidate_unit_id),
  identical(rows$match_status, c('new', 'new')),
  identical(rows$screening_status, c('screened', 'screened')),
  identical(rows$eligibility, c('unresolved', 'ineligible')),
  grepl('weight and maturity inputs', rows$decision_reason[1L], fixed = TRUE),
  grepl('survey-trends assessment', rows$decision_reason[2L], fixed = TRUE))
inventory_units <- candidate_units()
stopifnot(all(rows$candidate_unit_id %in% inventory_units$candidate_unit_id))
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
stopifnot(!any(tolower(sub('^ICES:', '', ids)) %in%
  tolower(trimws(stocks$authority_stock_id)), na.rm = TRUE))
cat('ICES deep/shallow beaked-redfish identity and source-screen checks passed.\n')

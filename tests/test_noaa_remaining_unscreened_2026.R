root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- paste0('NOAA:', c(10689, 10989, 11402, 11444, 11712, 11714,
  11724, 11763, 14821, 14822, 15052, 15310, 15335, 15351, 15439,
  15512, 15577))
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(rows) == 17L,
  !anyNA(rows$candidate_id),
  all(rows$screening_status == 'screened'),
  all(rows$import_status == 'not_started'),
  sum(rows$eligibility == 'eligible') == 5L,
  sum(rows$eligibility == 'ineligible') == 10L,
  sum(rows$eligibility == 'unresolved') == 2L,
  rows$match_status[rows$candidate_id == 'NOAA:11402'] == 'ambiguous',
  rows$eligibility[rows$candidate_id == 'NOAA:11714'] == 'unresolved',
  rows$eligibility[rows$candidate_id == 'NOAA:11763'] == 'unresolved',
  all(rows$review_date == '2026-11-02'),
  !anyDuplicated(rows$candidate_unit_id)
)

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(
  sum(noaa$inventory_rows) == 432L,
  sum(noaa$matched) == 28L,
  sum(noaa$new) == 388L,
  sum(noaa$ambiguous) == 14L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$eligible) == 89L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L
)

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE)
stopifnot(!any(stocks$authority == 'NOAA' &
  stocks$authority_stock_id %in% rows$official_stock_id))
stopifnot(file.exists(file.path(root, 'discovery', 'source_reviews',
  'noaa_remaining_unscreened_2026.md')))

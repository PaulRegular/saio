root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- 17337:17341
rows <- register[match(paste0('NOAA:', ids), register$candidate_id), , drop = FALSE]

stopifnot(nrow(rows) == length(ids), !anyNA(rows$candidate_id),
  identical(rows$candidate_unit_id, paste0('noaa_uci_salmon_', ids)),
  identical(rows$match_status, rep('new', 5L)),
  identical(rows$screening_status, rep('screened', 5L)),
  identical(rows$eligibility,
    c('unresolved', 'unresolved', 'unresolved', 'ineligible', 'ineligible')),
  identical(rows$import_status, rep('not_started', 5L)),
  all(grepl('Cook Inlet EEZ', rows$assessment_area, fixed = TRUE)),
  all(grepl('CookInletSalmon.pdf', rows$detailed_source_url, fixed = TRUE)),
  all(nzchar(rows$decision_reason)))

review <- readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_cook_inlet_salmon_2026.md'), warn = FALSE)
stopifnot(any(grepl('one-year metadata difference', review, fixed = TRUE)),
  any(grepl('2023 (ages 3–6', review, fixed = TRUE)),
  any(grepl('Stock SMART labels its 2026', review, fixed = TRUE)),
  any(grepl('No numerical assessment inputs or outputs were added', review,
    fixed = TRUE)))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(as.character(ids) %in% stocks$authority_stock_id),
  !any(grepl('noaa_uci_salmon_', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_uci_salmon_', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_uci_salmon_', outputs$assessment_id, fixed = TRUE)))

progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(sum(noaa$inventory_rows) == 432L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L)

cat('NOAA Cook Inlet salmon inventory screen passed.\n')

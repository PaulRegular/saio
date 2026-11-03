root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c('NOAA:14407', 'NOAA:14409', 'NOAA:17194', 'NOAA:17195',
  'NOAA:10402', 'NOAA:11302', 'NOAA:14408')
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
current_units <- c('noaa_black_rockfish_oregon_2023',
  'noaa_black_rockfish_washington_2023',
  'noaa_black_rockfish_california_2023',
  'noaa_black_rockfish_california_2023')
unit_ids <- unique(current_units)
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', ''))
units <- units[units$candidate_unit_id %in% unit_ids, , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_black_rockfish_pacific_coast_2023.md'), warn = FALSE), collapse = '\n')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))

stopifnot(
  nrow(rows) == 7L,
  identical(as.character(rows$candidate_unit_id[1:4]), current_units),
  identical(as.character(rows$official_stock_id[1:4]), c('14407', '14409', '17194', '17195')),
  identical(as.character(rows$match_status[1:4]), rep('new', 4L)),
  identical(as.character(rows$screening_status[1:4]), rep('screened', 4L)),
  identical(as.character(rows$eligibility[1:4]), rep('eligible', 4L)),
  identical(as.character(rows$import_status[1:4]),
    c('partial', 'not_started', 'not_started', 'not_started')),
  all(rows$scientific_name[1:4] == 'Sebastes melanops'),
  identical(as.character(rows$match_status[5:7]), rep('ambiguous', 3L)),
  identical(as.character(rows$screening_status[5:7]), rep('screened', 3L)),
  identical(as.character(rows$eligibility[5:7]), rep('ineligible', 3L)),
  all(is.na(rows$candidate_unit_id[5:7]) | !nzchar(rows$candidate_unit_id[5:7])),
  nrow(units) == 3L,
  setequal(units$candidate_unit_id, unit_ids),
  identical(sort(units$inventory_entries), c(1L, 1L, 2L)),
  !any(register$candidate_id == 'NOAA:166727'),
  grepl('not a unique Stock SMART stock ID', review, fixed = TRUE),
  grepl('not additional stock cases', review, fixed = TRUE),
  grepl('do not map one-to-one', review, fixed = TRUE),
  !any(stocks$authority_stock_id == '166727', na.rm = TRUE),
  any(stocks$stock_id == 'noaa_black_rockfish_oregon'),
  any(assessments$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  any(inputs$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  any(outputs$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  !any(stocks$stock_id %in% unit_ids[-1L], na.rm = TRUE),
  !any(assessments$assessment_id %in% unit_ids[-1L], na.rm = TRUE),
  !any(inputs$assessment_id %in% unit_ids[-1L], na.rm = TRUE),
  !any(outputs$assessment_id %in% unit_ids[-1L], na.rm = TRUE)
)

cat('NOAA Pacific Coast black rockfish source-ID and case crosswalk checks passed.\n')

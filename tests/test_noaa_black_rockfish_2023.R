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
read_assessment_rows <- function(path, ids, measures = NULL) {
  con <- file(path, open = 'rt')
  on.exit(close(con))
  header <- readLines(con, n = 1L, warn = FALSE)
  rows <- character()
  repeat {
    block <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(block)) break
    selected <- Reduce(`|`, lapply(ids, function(id) startsWith(block, paste0('"', id, '",'))))
    if (!is.null(measures)) {
      selected <- selected & Reduce(function(a, b) a | b,
        lapply(measures, function(measure) {
        grepl(paste0(',"', measure, '",'), block, fixed = TRUE)
      }))
    }
    if (any(selected)) rows <- c(rows, block[selected])
  }
  if (!length(rows)) return(read.csv(text = header, stringsAsFactors = FALSE))
  read.csv(text = paste(c(header, rows), collapse = '\n'),
    stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
}
observed_ids <- c('noaa_black_rockfish_oregon_2023',
  'noaa_black_rockfish_washington_2023')
input_ids <- c(observed_ids, 'noaa_black_rockfish_california_2023')
inputs <- read_assessment_rows(file.path(root, 'database', 'inputs.csv'), input_ids)
outputs <- read_assessment_rows(file.path(root, 'database', 'outputs.csv'), observed_ids)
california_outputs <- read_assessment_rows(
  file.path(root, 'database', 'outputs.csv'),
  'noaa_black_rockfish_california_2023',
  measures = c('spawning_output', 'natural_mortality_at_age')
)
source_review <- paste(readLines(file.path(root, 'source_reviews',
  'noaa_black_rockfish_california_2023.md'), warn = FALSE), collapse = '\n')
source_manifest <- read.csv(file.path(root, 'provenance',
  'noaa_black_rockfish_california_2023_sources.csv'),
  stringsAsFactors = FALSE)
california_inputs <- inputs[
  inputs$assessment_id == 'noaa_black_rockfish_california_2023', , drop = FALSE
]
california_cpue <- california_inputs[
  california_inputs$type == 'index' &
    california_inputs$measure %in% c('total_biomass', 'total_numbers'),
  , drop = FALSE
]
published_spawn <- california_outputs[
  california_outputs$scenario == 'published post-STAR summary', , drop = FALSE
]
archive_spawn <- california_outputs[
  california_outputs$scenario == 'native model archive' &
    california_outputs$measure == 'spawning_output' &
    california_outputs$year == 2023, , drop = FALSE
]
california_m <- california_outputs[
  california_outputs$measure == 'natural_mortality_at_age', , drop = FALSE
]

stopifnot(
  nrow(rows) == 7L,
  identical(as.character(rows$candidate_unit_id[1:4]), current_units),
  identical(as.character(rows$official_stock_id[1:4]), c('14407', '14409', '17194', '17195')),
  identical(as.character(rows$match_status[1:4]),
    c('new', 'matched', 'matched', 'matched')),
  identical(as.character(rows$screening_status[1:4]), rep('screened', 4L)),
  identical(as.character(rows$eligibility[1:4]), rep('eligible', 4L)),
  identical(as.character(rows$import_status[1:4]),
    rep('partial', 4L)),
  all(rows$scientific_name[1:4] == 'Sebastes melanops'),
  identical(as.character(rows$match_status[5:7]), rep('ambiguous', 3L)),
  identical(as.character(rows$screening_status[5:7]), rep('screened', 3L)),
  identical(as.character(rows$eligibility[5:7]), rep('ineligible', 3L)),
  all(is.na(rows$candidate_unit_id[5:7]) | !nzchar(rows$candidate_unit_id[5:7])),
  nrow(units) == 2L,
  setequal(units$candidate_unit_id, c('noaa_black_rockfish_california_2023',
    'noaa_black_rockfish_washington_2023')),
  identical(sort(units$inventory_entries), c(1L, 2L)),
  !any(register$candidate_id == 'NOAA:166727'),
  grepl('not a unique Stock SMART stock ID', review, fixed = TRUE),
  grepl('not additional stock cases', review, fixed = TRUE),
  grepl('do not map one-to-one', review, fixed = TRUE),
  !any(stocks$authority_stock_id == '166727', na.rm = TRUE),
  any(stocks$stock_id == 'noaa_black_rockfish_oregon'),
  any(stocks$stock_id == 'noaa_black_rockfish_washington'),
  any(assessments$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  any(assessments$assessment_id == 'noaa_black_rockfish_washington_2023'),
  any(inputs$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  any(inputs$assessment_id == 'noaa_black_rockfish_washington_2023'),
  any(outputs$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  any(outputs$assessment_id == 'noaa_black_rockfish_washington_2023'),
  any(stocks$stock_id == 'noaa_black_rockfish_california'),
  any(assessments$assessment_id == 'noaa_black_rockfish_california_2023'),
  any(inputs$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  any(inputs$assessment_id == 'noaa_black_rockfish_washington_2023'),
  any(outputs$assessment_id == 'noaa_black_rockfish_oregon_2023'),
  any(outputs$assessment_id == 'noaa_black_rockfish_washington_2023'),
  nrow(california_inputs) == 63335L,
  setequal(unique(california_inputs$region),
    c('North sub-area', 'Central sub-area')),
  sum(california_inputs$type == 'catch' &
    california_inputs$measure == 'total_biomass') == 1341L,
  nrow(california_cpue) == 226L,
  setequal(unique(california_cpue$measure),
    c('total_biomass', 'total_numbers')),
  all(california_cpue$sampling_time == 0.5),
  !any(california_inputs$measure == 'catch_numbers_at_age'),
  !any(california_inputs$type == 'index' &
    california_inputs$measure %in% c('numbers_at_age',
      'abundance_at_age', 'index_at_age')),
  nrow(published_spawn) == 3L,
  published_spawn$value[published_spawn$region == 'North sub-area'] == 410,
  published_spawn$value[published_spawn$region == 'Central sub-area'] == 145,
  published_spawn$value[published_spawn$region == 'California statewide'] == 555,
  published_spawn$lwr[published_spawn$region == 'Central sub-area'] == 36,
  published_spawn$upr[published_spawn$region == 'Central sub-area'] == 253,
  archive_spawn$value[archive_spawn$region == 'Central sub-area'] == 136.324,
  nrow(california_m) > 0L,
  max(california_m$age) == 49,
  grepl('provisional front matter', source_review, fixed = TRUE),
  nrow(source_manifest) == 12L,
  all(grepl('^[0-9a-f]{64}$', source_manifest$sha256))
)

cat('NOAA Pacific Coast black rockfish source-ID and case crosswalk checks passed.\n')

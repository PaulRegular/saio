root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ids <- c(
  'DFO:Pacific:Sockeye Salmon - Fraser (Early Summer)',
  'DFO:Pacific:Sockeye Salmon - Fraser (Summer)',
  'DFO:Pacific:Sockeye Salmon - Fraser (Late)'
)
rows <- register[register$candidate_id %in% ids, , drop = FALSE]
unit_ids <- c('dfo_fraser_sockeye_early_summer', 'dfo_fraser_sockeye_summer',
  'dfo_fraser_sockeye_late')
stocks <- read.csv(file.path(root, 'database', 'stocks.csv'), stringsAsFactors = FALSE)
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'), stringsAsFactors = FALSE)
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'), stringsAsFactors = FALSE)
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'), stringsAsFactors = FALSE)
review_path <- file.path(root, 'discovery', 'source_reviews',
  'dfo_fraser_sockeye_other_groups.md')
cache <- file.path(root, 'source_cache', 'discovery_dfo_fraser_sockeye')
production <- read.csv(file.path(cache, 'stock-recruit-data_detailed-format.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
files <- file.path(cache, manifest$file)

stopifnot(
  nrow(rows) == 3L,
  setequal(rows$candidate_id, ids),
  all(is.na(rows$candidate_unit_id)),
  all(rows$scientific_name == 'Oncorhynchus nerka'),
  all(rows$match_status == 'ambiguous'),
  all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'unresolved'),
  all(rows$import_status == 'not_started'),
  all(vapply(unit_ids, function(id) !id %in% stocks$stock_id, logical(1))),
  all(vapply(unit_ids, function(id) !id %in% assessments$assessment_id, logical(1))),
  all(vapply(unit_ids, function(id) !id %in% inputs$assessment_id, logical(1))),
  all(vapply(unit_ids, function(id) !id %in% outputs$assessment_id, logical(1))),
  file.exists(review_path),
  all(file.exists(files)),
  !any(c('Early Summer', 'Summer', 'Late') %in% unique(production$production_stock_name))
)
review <- paste(readLines(review_path, warn = FALSE), collapse = ' ')
stopifnot(
  grepl('multiple production groups and conservation units', review, ignore.case = TRUE),
  grepl('identity-ambiguous with age-input eligibility unresolved', review, ignore.case = TRUE),
  grepl('Do not create canonical stock or assessment records', review, fixed = TRUE)
)

cat('DFO Fraser sockeye management-group boundary checks passed.\n')

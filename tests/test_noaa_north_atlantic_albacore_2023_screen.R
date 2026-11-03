source('scripts/database/513_screen_noaa_north_atlantic_albacore_2023.R')

root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
row <- register[register$candidate_id == 'NOAA:10950', , drop = FALSE]
review <- paste(readLines(file.path(root, 'discovery', 'source_reviews',
  'noaa_north_atlantic_albacore_2023.md'), warn = FALSE), collapse = ' ')
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'noaa_north_atlantic_albacore',
  row$match_status == 'new', row$screening_status == 'screened',
  row$eligibility == 'unresolved', row$import_status == 'not_started',
  row$inventory_assessment_year == 2023L,
  grepl('record 13464', row$decision_reason, fixed = TRUE),
  grepl('through 2022', row$decision_reason, fixed = TRUE),
  grepl('through 2021', row$decision_reason, fixed = TRUE),
  grepl('age-specific observations remain unresolved', row$decision_reason, fixed = TRUE),
  grepl('Keep this distinct from the North Pacific albacore unit', row$decision_reason, fixed = TRUE),
  grepl('not a new North Atlantic assessment', row$notes, fixed = TRUE),
  grepl('age information came from fish sampled in 1990 and 2008-2012', review, fixed = TRUE),
  grepl('Keep the candidate screened with eligibility unresolved', review, fixed = TRUE),
  grepl('Do not add canonical numerical records', review, fixed = TRUE))

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
assessment <- stocksmart_env$stock_assessment_summary[
  as.character(stocksmart_env$stock_assessment_summary$assessment_id) == '13464', , drop = FALSE]
stopifnot(nrow(assessment) == 1L,
  as.character(assessment$stock_id) == '10950',
  as.integer(assessment$assessment_year) == 2023L,
  as.integer(assessment$last_data_year) == 2022L,
  as.character(assessment$review_result) == 'Full acceptance',
  as.character(assessment$assessment_model) == 'SS')

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_north_atlantic_albacore', , drop = FALSE]
stopifnot(nrow(unit) == 1L, unit$inventory_entries == 1L,
  unit$screening_status == 'screened', unit$eligibility == 'unresolved')

cache <- file.path(root, 'source_cache', 'noaa_north_atlantic_albacore_2023')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
files <- c('ICCAT_2023_NAtlantic_Albacore_Data_Preparatory_Meeting.pdf',
  'ICCAT_2023_Atlantic_Albacore_Stock_Assessment_Meeting.pdf',
  'ICCAT_2023_NAtlantic_Albacore_SS3_SCRS_2023_107.pdf',
  'ICCAT_2023_NAtlantic_Albacore_SS3_Diagnostics_SCRS_2023_145.pdf',
  'ICCAT_2025_SCRS_Report.pdf',
  'ICCAT_2026_Albacore_Assessment_Meeting_Agenda.pdf')
stopifnot(nrow(manifest) == length(files), all(files %in% manifest$file),
  all(file.exists(file.path(cache, files))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])),
  all(nzchar(manifest$source_url[match(files, manifest$file)])),
  all(!is.na(manifest$revision[match(files, manifest$file)])),
  all(vapply(file.path(cache, files), function(path) {
    con <- file(path, 'rb')
    on.exit(close(con))
    identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
  }, logical(1L))))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$authority_stock_id == '10950', na.rm = TRUE),
  !any(grepl('noaa_north_atlantic_albacore', assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_north_atlantic_albacore', inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_north_atlantic_albacore', outputs$assessment_id, fixed = TRUE)))

cat('NOAA North Atlantic albacore source screen passed.\n')

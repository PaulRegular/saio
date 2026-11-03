root <- '.'
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)
ids <- paste0('NOAA:', c(10973, 10974, 11405, 11448, 11803, 11804))
rows <- register[match(ids, register$candidate_id), , drop = FALSE]
expected_units <- c('noaa_bsai_other_flatfish_complex',
  'noaa_bsai_other_rockfish_complex', 'noaa_alaska_sculpin_complex',
  'noaa_alaska_sculpin_complex',
  'noaa_goa_other_shallow_water_flatfish_complex',
  'noaa_goa_other_rockfish_complex')
stopifnot(nrow(rows) == 6L, !anyNA(rows$candidate_id),
  identical(rows$candidate_unit_id, expected_units),
  identical(as.integer(rows$inventory_assessment_year), c(2020L, 2024L, 2023L, 2023L, 2024L, 2023L)),
  identical(rows$assessment_area, c('Bering Sea and Aleutian Islands', 'Bering Sea and Aleutian Islands',
    'Bering Sea and Aleutian Islands', 'Gulf of Alaska', 'Gulf of Alaska', 'Gulf of Alaska')),
  all(rows$match_status == 'new'), all(rows$screening_status == 'screened'),
  all(rows$eligibility == 'ineligible'), all(rows$import_status == 'not_started'),
  all(!is.na(rows$review_date)),
  grepl('share one ecosystem-report candidate unit', rows$notes[rows$candidate_id == 'NOAA:11405'], fixed = TRUE),
  grepl('share one ecosystem-report candidate unit', rows$notes[rows$candidate_id == 'NOAA:11448'], fixed = TRUE),
  grepl('no new Tier 4/5 model', rows$decision_reason[rows$candidate_id == 'NOAA:11804'], fixed = TRUE),
  grepl('2024 operational update', rows$decision_reason[rows$candidate_id == 'NOAA:10973'], fixed = TRUE),
  grepl('latest listed full-acceptance record is assessment 11254', rows$decision_reason[rows$candidate_id == 'NOAA:10973'], fixed = TRUE),
  file.exists(file.path(root, 'discovery', 'source_reviews', 'noaa_alaska_index_aggregates_2024.md')),
  all(is.na(rows$matched_stock_id)))

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
sculpins <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == 'noaa_alaska_sculpin_complex', , drop = FALSE]
stopifnot(nrow(sculpins) == 1L, sculpins$inventory_entries == 2L,
  sculpins$eligibility == 'ineligible', sculpins$screening_status == 'screened',
  identical(sculpins$candidate_ids, 'NOAA:11405 | NOAA:11448'))

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
assessment_ids <- c('11254', '13871', '13123', '13122', '13893', '13100')
assessments <- stocksmart[match(assessment_ids, as.character(stocksmart$assessment_id)), , drop = FALSE]
stopifnot(nrow(assessments) == 6L,
  identical(as.character(assessments$stock_id), c('10973', '10974', '11405', '11448', '11803', '11804')),
  all(as.character(assessments$review_result) == 'Full acceptance'),
  all(as.integer(assessments$model_category) == 2L))

cache <- file.path(root, 'source_cache', 'discovery_noaa_alaska_aggregates_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
files <- c('BSAI_Other_Flatfish_SAFE_2024.pdf',
  'BSAI_Other_Rockfish_SAFE_2024.pdf', 'GOA_Other_Rockfish_SAFE_2024.pdf',
  'GOA_Shallow_Water_Flatfish_SAFE_2024.pdf',
  'NOAA_Alaska_Sculpin_Ecosystem_Report_2023.pdf',
  'BSAI_SAFE_Introduction_2024.pdf', 'GOA_SAFE_Introduction_2024.pdf',
  'SSC_Final_Report_December_2023.pdf', 'SSC_Final_Report_December_2024.pdf', 'StockSMART_DataDictionary.pdf')
stopifnot(nrow(manifest) == length(files), all(files %in% manifest$file),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(files, manifest$file)])),
  all(nzchar(manifest$url[match(files, manifest$file)])),
  all(!is.na(manifest$revision[match(files, manifest$file)])),
  all(file.exists(file.path(cache, files))),
  all(vapply(file.path(cache, files), function(path) {
    con <- file(path, 'rb')
    on.exit(close(con))
    identical(readBin(con, 'raw', 5L), charToRaw('%PDF-'))
  }, logical(1L))))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments_db <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$authority_stock_id %in% as.character(c(10973, 10974, 11405, 11448, 11803, 11804)), na.rm = TRUE),
  !any(grepl('noaa_bsai_other_flatfish_complex|noaa_bsai_other_rockfish_complex|noaa_alaska_sculpin_complex|noaa_goa_other_shallow_water_flatfish_complex|noaa_goa_other_rockfish_complex', assessments_db$assessment_id)),
  !any(grepl('noaa_bsai_other_flatfish_complex|noaa_bsai_other_rockfish_complex|noaa_alaska_sculpin_complex|noaa_goa_other_shallow_water_flatfish_complex|noaa_goa_other_rockfish_complex', inputs$assessment_id)),
  !any(grepl('noaa_bsai_other_flatfish_complex|noaa_bsai_other_rockfish_complex|noaa_alaska_sculpin_complex|noaa_goa_other_shallow_water_flatfish_complex|noaa_goa_other_rockfish_complex', outputs$assessment_id)))

cat('NOAA Alaska aggregate assessment screen passed.\n')

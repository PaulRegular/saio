root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:11715', , drop = FALSE]
atlantic_mako <- register[register$candidate_id == 'NOAA:10657', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_north_pacific_shortfin_mako', , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
swfsc_pifsc <- noaa[noaa$source_region == 'SWFSC / PIFSC', , drop = FALSE]

cache <- file.path(root, 'source_cache', 'discovery_noaa_isc_shortfin_mako_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('ISC24_ANNEX14_shortfin_mako_2024.pdf', 'ISC25_Plenary_Report_FINAL.pdf')
source_rows <- manifest[match(required, manifest$file), , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'noaa_north_pacific_shortfin_mako',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'ineligible',
  candidate$import_status == 'not_started',
  candidate$inventory_assessment_year == 2024L,
  candidate$review_date == '2026-11-02',
  grepl('did not fit catch-at-age', candidate$catch_age_evidence, fixed = TRUE),
  grepl('four standardized annual longline CPUE indices',
    candidate$survey_age_evidence, fixed = TRUE),
  grepl('diagnostic analyses', candidate$output_evidence, fixed = TRUE),
  grepl('carried forward by ISC25', candidate$decision_reason, fixed = TRUE),
  nrow(atlantic_mako) == 1L,
  atlantic_mako$candidate_unit_id == 'noaa_north_atlantic_shortfin_mako',
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  unit$import_status == 'not_started',
  sum(noaa$new) == 388L,
  sum(noaa$identity_unreviewed) == 2L,
  sum(noaa$eligible) == 89L,
  sum(noaa$excluded) == 252L,
  sum(noaa$eligibility_unresolved) == 91L,
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  nrow(swfsc_pifsc) == 1L,
  swfsc_pifsc$inventory_rows == 7L,
  swfsc_pifsc$screening_complete == 7L,
  swfsc_pifsc$screening_not_started == 0L,
  nrow(source_rows) == length(required),
  all(file.exists(file.path(cache, required))),
  all(file.info(file.path(cache, required))$size == source_rows$bytes),
  all(grepl('^[[:xdigit:]]{64}$', source_rows$sha256)),
  all(source_rows$retrieved_on == '2026-11-02'),
  all(nzchar(source_rows$url)),
  all(nzchar(source_rows$revision))
)

stocksmart_env <- new.env(parent = emptyenv())
load(file.path(root, 'source_cache', 'discovery_noaa_stocksmart',
  'stock_assessment_summary.rda'), envir = stocksmart_env)
stocksmart <- stocksmart_env$stock_assessment_summary
stocksmart <- stocksmart[as.character(stocksmart$stock_id) == '11715', , drop = FALSE]
latest <- stocksmart[which.max(as.integer(stocksmart$assessment_year)), , drop = FALSE]
stopifnot(
  nrow(latest) == 1L,
  latest$assessment_id == 13565L,
  latest$assessment_year == 2024L,
  latest$last_data_year == 2022L,
  latest$science_center == 'SWFSC / PIFSC',
  latest$assessment_model == 'BSP',
  latest$review_result == 'Full acceptance'
)

database <- lapply(c('stocks', 'assessments', 'inputs', 'outputs'), function(table) {
  read.csv(file.path(root, 'database', paste0(table, '.csv')),
    stringsAsFactors = FALSE, na.strings = c('', 'NA'))
})
names(database) <- c('stocks', 'assessments', 'inputs', 'outputs')
stopifnot(
  !any(database$stocks$scientific_name == 'Isurus oxyrinchus', na.rm = TRUE),
  !any(grepl('noaa_north_pacific_shortfin_mako',
    database$assessments$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_north_pacific_shortfin_mako',
    database$inputs$assessment_id, fixed = TRUE)),
  !any(grepl('noaa_north_pacific_shortfin_mako',
    database$outputs$assessment_id, fixed = TRUE)),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'noaa_isc_shortfin_mako_2024.md'))
)
cat('NOAA 11715 North Pacific shortfin mako screening checks passed.\n')

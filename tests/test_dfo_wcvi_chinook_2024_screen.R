root <- '.'
register_path <- file.path(root, 'discovery/candidates.csv')
register_before <- readLines(register_path, warn = FALSE, encoding = 'UTF-8')
Sys.setenv(TAM_SOURCE_DRY_RUN = '1')
source(file.path(root, 'scripts/database/375_screen_dfo_wcvi_chinook_2024.R'))
Sys.unsetenv('TAM_SOURCE_DRY_RUN')
stopifnot(identical(register_before, readLines(register_path, warn = FALSE, encoding = 'UTF-8')))

register <- read.csv(register_path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
progress <- read.csv(file.path(root, 'discovery/inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
units <- read.csv(file.path(root, 'discovery/inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv(file.path(root, 'database/stocks.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database/assessments.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database/inputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database/outputs.csv'), stringsAsFactors = FALSE,
  na.strings = c('', 'NA'))
cache <- file.path(root, 'source_cache/discovery_dfo_wcvi_chinook_2024')
row <- register[register$candidate_id ==
  'DFO:Pacific:Chinook Salmon - West Coast of Vancouver Island', , drop = FALSE]
dfo <- progress[progress$organization == 'DFO', , drop = FALSE]

stopifnot(
  nrow(row) == 1L,
  row$candidate_unit_id == 'dfo_chinook_wcvi_natural_origin',
  row$scientific_name == 'Oncorhynchus tshawytscha',
  row$inventory_assessment_year == '2024',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'unresolved',
  row$import_status == 'not_started',
  grepl('catch and escapement totals', row$catch_age_evidence, fixed = TRUE),
  grepl('CU-specific', row$decision_reason, fixed = TRUE),
  grepl('Robertson Creek hatchery', row$decision_reason, fixed = TRUE),
  row$candidate_unit_id %in% units$candidate_unit_id,
  !any(stocks$scientific_name == 'Oncorhynchus tshawytscha', na.rm = TRUE),
  !any(grepl('wcvi_chinook|west_coast_vancouver_island_chinook',
    c(assessments$assessment_id, inputs$assessment_id, outputs$assessment_id),
    ignore.case = TRUE), na.rm = TRUE),
  any(grepl('Research Document 2026/020', row$notes, fixed = TRUE))
)

if (file.exists(file.path(cache, 'sources.csv'))) {
  sources <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
  stopifnot(
    nrow(sources) == 4L,
    all(file.exists(file.path(cache, sources$file))),
    all(nzchar(sources$sha256))
  )
}

cat('DFO WCVI Chinook identity, evidence, unresolved eligibility and source-cache checks passed.\n')

root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:11684', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'wcpfc_wcpo_bigeye', , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]

cache <- file.path(root, 'source_cache', 'discovery_noaa_wcpfc_bigeye_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('SC19-SA-WP-05_BET_2023_Rev02.pdf', 'SC19_Outcomes_2023.pdf',
  'SPC__README.md', 'SPC__TAF__data.R', 'SPC_MFCL__bet.age_length',
  'SPC_MFCL__bet.frq', 'TAF__data__otoliths.csv',
  'TAF__data__length_comps.csv', 'TAF__data__weight_comps.csv',
  'TAF__data__cpue.csv', 'TAF__output__natage.csv',
  'TAF__output__f_annual.csv', 'TAF__output__biology.csv',
  'TAF__output__summary.csv')
source_rows <- manifest[match(required, manifest$file), , drop = FALSE]
stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'wcpfc_wcpo_bigeye',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  candidate$review_date == '2026-11-02',
  grepl('1,010 conditional age-at-length', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not age-specific', candidate$survey_age_evidence, fixed = TRUE),
  grepl('2026 assessment report was reviewed at SC22', candidate$decision_reason, fixed = TRUE),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$eligibility == 'eligible',
  unit$screening_status == 'screened',
  unit$import_status == 'not_started',
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(source_rows) == length(required),
  all(file.exists(file.path(cache, required))),
  all(file.info(file.path(cache, required))$size == source_rows$bytes),
  all(grepl('^[[:xdigit:]]{64}$', source_rows$sha256)),
  any(grepl('81fc412ad1f36416f78f84ef6bd2d5dff68d14c8', source_rows$url, fixed = TRUE))
)

database <- lapply(c('stocks', 'assessments', 'inputs', 'outputs'), function(table) {
  read.csv(file.path(root, 'database', paste0(table, '.csv')),
    stringsAsFactors = FALSE, na.strings = c('', 'NA'))
})
names(database) <- c('stocks', 'assessments', 'inputs', 'outputs')
stopifnot(
  !any(database$stocks$scientific_name == 'Thunnus obesus', na.rm = TRUE),
  !any(grepl('wcpfc_wcpo_bigeye', database$assessments$assessment_id, fixed = TRUE)),
  !any(grepl('wcpfc_wcpo_bigeye', database$inputs$assessment_id, fixed = TRUE)),
  !any(grepl('wcpfc_wcpo_bigeye', database$outputs$assessment_id, fixed = TRUE))
)
cat('NOAA 11684 WCPO bigeye source-screen checks passed.\n')

root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
candidate <- register[register$candidate_id == 'NOAA:11694', , drop = FALSE]
units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'wcpfc_wcpo_yellowfin', , drop = FALSE]
progress <- read.csv(file.path(root, 'discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE)
noaa <- progress[progress$organization == 'NOAA', , drop = FALSE]
pifsc <- noaa[noaa$source_region == 'PIFSC', , drop = FALSE]

cache <- file.path(root, 'source_cache', 'discovery_noaa_wcpo_yellowfin_2026')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('WCPFC-SC22-2026-SA-WP05_Rev01_YFT_2026.pdf',
  'WCPFC-SC22-2026-SA-IP03_Rev01_BET_YFT_inputs.pdf', 'SPC_README.md',
  'TAF_data.R', 'MFCL_yft.age_length', 'MFCL_yft.frq', 'TAF_data_otoliths.csv',
  'TAF_data_length_comps.csv', 'TAF_data_cpue.csv', 'TAF_output_natage.csv',
  'TAF_output_f_annual.csv', 'TAF_output_biology.csv', 'TAF_output_summary.csv')
source_rows <- manifest[match(required, manifest$file), , drop = FALSE]

stopifnot(
  nrow(candidate) == 1L,
  candidate$candidate_unit_id == 'wcpfc_wcpo_yellowfin',
  candidate$match_status == 'new',
  candidate$screening_status == 'screened',
  candidate$eligibility == 'eligible',
  candidate$import_status == 'not_started',
  candidate$review_date == '2026-11-02',
  grepl('1,873 conditional age-at-length', candidate$catch_age_evidence, fixed = TRUE),
  grepl('not age-specific', candidate$survey_age_evidence, fixed = TRUE),
  grepl('did not review this assessment for management advice',
    candidate$decision_reason, fixed = TRUE),
  grepl('assessment 13365 (2023, data through 2021)',
    candidate$decision_reason, fixed = TRUE),
  nrow(unit) == 1L,
  unit$inventory_entries == 1L,
  unit$eligibility == 'eligible',
  unit$screening_status == 'screened',
  unit$import_status == 'not_started',
  sum(noaa$screening_complete) == 432L,
  sum(noaa$screening_not_started) == 0L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(pifsc) == 1L,
  pifsc$eligible == 2L,
  pifsc$eligible_new == 2L,
  pifsc$screening_complete == 45L,
  pifsc$screening_not_started == 0L,
  nrow(source_rows) == length(required),
  all(file.exists(file.path(cache, required))),
  all(file.info(file.path(cache, required))$size == source_rows$bytes),
  all(grepl('^[[:xdigit:]]{64}$', source_rows$sha256)),
  all(grepl('b00a02f3537ef54520b219488f899188ea6eff3f',
    manifest$url[grepl('ofp-sam-yft-2026-diagnostic', manifest$url, fixed = TRUE)],
    fixed = TRUE))
)

otoliths <- read.csv(file.path(cache, 'TAF_data_otoliths.csv'))
length_comps <- read.csv(file.path(cache, 'TAF_data_length_comps.csv'))
cpue <- read.csv(file.path(cache, 'TAF_data_cpue.csv'))
natage <- read.csv(file.path(cache, 'TAF_output_natage.csv'))
summary <- read.csv(file.path(cache, 'TAF_output_summary.csv'))
stopifnot(
  nrow(otoliths) == 1873L,
  length(unique(otoliths$year)) == 17L,
  identical(range(otoliths$year), c(2006L, 2024L)),
  identical(range(otoliths$age), c(1L, 40L)),
  length(unique(otoliths$area)) == 5L,
  nrow(length_comps) == 297920L,
  length(unique(length_comps$fishery)) == 36L,
  identical(range(length_comps$year), c(1956L, 2024L)),
  nrow(cpue) == 1452L,
  length(unique(cpue$fishery)) == 5L,
  identical(range(cpue$year), c(1952L, 2024L)),
  nrow(natage) == 58400L,
  identical(range(natage$age), c(1L, 40L)),
  nrow(summary) == 73L,
  identical(range(summary$year), c(1952L, 2024L))
)

database <- lapply(c('stocks', 'assessments', 'inputs', 'outputs'), function(table) {
  read.csv(file.path(root, 'database', paste0(table, '.csv')),
    stringsAsFactors = FALSE, na.strings = c('', 'NA'))
})
names(database) <- c('stocks', 'assessments', 'inputs', 'outputs')
stopifnot(
  !any(database$stocks$scientific_name == 'Thunnus albacares', na.rm = TRUE),
  !any(grepl('wcpfc_wcpo_yellowfin', database$assessments$assessment_id, fixed = TRUE)),
  !any(grepl('wcpfc_wcpo_yellowfin', database$inputs$assessment_id, fixed = TRUE)),
  !any(grepl('wcpfc_wcpo_yellowfin', database$outputs$assessment_id, fixed = TRUE)),
  file.exists(file.path(root, 'discovery', 'source_reviews',
    'noaa_wcpfc_yellowfin_2026.md'))
)
cat('NOAA 11694 WCPO yellowfin source-screen checks passed.\n')

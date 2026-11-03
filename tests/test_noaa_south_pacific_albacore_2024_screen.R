root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:11688', , drop = FALSE]
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'wcpfc_south_pacific_albacore',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'eligible',
  row$import_status == 'not_started',
  grepl('approximate catch-numbers-at-age reconstruction',
    row$catch_age_evidence, fixed = TRUE),
  grepl('not an age-specific survey index', row$survey_age_evidence, fixed = TRUE),
  grepl('100-model ensemble', row$output_evidence, fixed = TRUE),
  row$review_date == '2026-11-02')

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) & units$candidate_unit_id == 'wcpfc_south_pacific_albacore', , drop = FALSE]
stopifnot(nrow(unit) == 1L,
  unit$match_status == 'new',
  unit$eligibility == 'eligible',
  unit$screening_status == 'screened',
  unit$import_status == 'not_started',
  unit$candidate_ids == 'NOAA:11688')

cache <- file.path(root, 'source_cache', 'discovery_noaa_south_pacific_albacore_2024')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('alb.frq', 'alb.age_length', 'taf_input_length_comps.csv',
  'taf_input_otoliths.csv', 'taf_input_cpue.csv', 'taf_output_biology.csv',
  'taf_output_natage.csv', 'taf_output_f_annual.csv')
stopifnot(all(required %in% manifest$file),
  all(file.exists(file.path(cache, required))),
  all(grepl('^[[:xdigit:]]{64}$',
    manifest$sha256[match(required, manifest$file)])))

length_comps <- read.csv(file.path(cache, 'taf_input_length_comps.csv'))
otoliths <- read.csv(file.path(cache, 'taf_input_otoliths.csv'))
cpue <- read.csv(file.path(cache, 'taf_input_cpue.csv'))
natage <- read.csv(file.path(cache, 'taf_output_natage.csv'))
f_annual <- read.csv(file.path(cache, 'taf_output_f_annual.csv'))
stopifnot(nrow(otoliths) == 654L,
  identical(range(otoliths$age), c(1L, 10L)),
  identical(range(length_comps$year), c(1965L, 2022L)),
  length(unique(length_comps$fishery)) == 17L,
  length(unique(cpue$fishery)) == 3L,
  identical(range(natage$year), c(1954L, 2022L)),
  identical(range(natage$age), c(1L, 12L)),
  length(unique(natage$area)) == 2L,
  identical(range(f_annual$year), c(1954L, 2022L)))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$stock_id == 'wcpfc_south_pacific_albacore'),
  !any(assessments$assessment_id == 'wcpfc_south_pacific_albacore'),
  !any(inputs$assessment_id == 'wcpfc_south_pacific_albacore'),
  !any(outputs$assessment_id == 'wcpfc_south_pacific_albacore'))

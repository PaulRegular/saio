root <- "."
register <- read.csv(file.path(root, 'discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
row <- register[register$candidate_id == 'NOAA:11691', , drop = FALSE]
stopifnot(nrow(row) == 1L,
  row$candidate_unit_id == 'wcpfc_wcpo_skipjack',
  row$match_status == 'new',
  row$screening_status == 'screened',
  row$eligibility == 'ineligible',
  row$import_status == 'not_started',
  grepl('not observed catch-at-age', row$catch_age_evidence, fixed = TRUE),
  grepl('10 fishery CPUE index series', row$survey_age_evidence, fixed = TRUE),
  grepl('one anomalous row', row$survey_age_evidence, fixed = TRUE),
  grepl('ages 1-16 across eight regions', row$output_evidence, fixed = TRUE),
  row$review_date == '2026-11-02')

units <- read.csv(file.path(root, 'discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'wcpfc_wcpo_skipjack', , drop = FALSE]
stopifnot(nrow(unit) == 1L,
  unit$match_status == 'new',
  unit$eligibility == 'ineligible',
  unit$screening_status == 'screened',
  unit$import_status == 'not_started',
  unit$candidate_ids == 'NOAA:11691')

cache <- file.path(root, 'source_cache', 'discovery_noaa_wcpfc_skipjack_2025')
manifest <- read.csv(file.path(cache, 'sources.csv'), stringsAsFactors = FALSE)
required <- c('wcpfc_sc21_skipjack_assessment_2025_rev3.pdf',
  'wcpfc_sc21_skipjack_background_inputs_2025_rev1.pdf',
  'wcpfc_sc21_summary_report_2025.pdf', 'TAF__data__cpue.csv',
  'TAF__data__length_comps.csv', 'TAF__data__tag_releases.csv',
  'TAF__data__tag_recaptures.csv', 'TAF__output__biology.csv',
  'TAF__output__biomass.csv', 'TAF__output__f_annual.csv',
  'TAF__output__natage.csv', 'TAF__output__summary.csv')
stopifnot(all(required %in% manifest$file),
  all(file.exists(file.path(cache, required))),
  all(grepl('^[[:xdigit:]]{64}$', manifest$sha256[match(required, manifest$file)])),
  all(grepl('f33de3a9d6f3acb02a0717340c1cc325f89f2eb6',
    manifest$url[grepl('raw.githubusercontent.com', manifest$url, fixed = TRUE)],
    fixed = TRUE)))

length_comps <- read.csv(file.path(cache, 'TAF__data__length_comps.csv'))
cpue <- read.csv(file.path(cache, 'TAF__data__cpue.csv'))
natage <- read.csv(file.path(cache, 'TAF__output__natage.csv'))
f_annual <- read.csv(file.path(cache, 'TAF__output__f_annual.csv'))
biology <- read.csv(file.path(cache, 'TAF__output__biology.csv'))
summary <- read.csv(file.path(cache, 'TAF__output__summary.csv'))
stopifnot(nrow(length_comps) == 132894L,
  identical(range(length_comps$year), c(1972L, 2024L)),
  length(unique(length_comps$fishery)) == 42L,
  nrow(cpue) == 1337L, length(unique(cpue$fishery)) == 10L,
  sum(cpue$year == 36 & abs(cpue$season - 14.3333333333333) < 1e-10) == 1L,
  identical(range(natage$year), c(1972L, 2024L)),
  identical(range(natage$age), c(1L, 16L)),
  length(unique(natage$area)) == 8L, length(unique(natage$season)) == 4L,
  identical(range(f_annual$year), c(1972L, 2024L)),
  identical(range(f_annual$age), c(1L, 16L)),
  setequal(unique(f_annual$area), c(as.character(1:8), 'all')),
  identical(range(biology$age), c(1L, 16L)),
  identical(range(summary$year), c(1972L, 2024L)))

stocks <- read.csv(file.path(root, 'database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
assessments <- read.csv(file.path(root, 'database', 'assessments.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inputs <- read.csv(file.path(root, 'database', 'inputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outputs <- read.csv(file.path(root, 'database', 'outputs.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(!any(stocks$stock_id == 'wcpfc_wcpo_skipjack'),
  !any(assessments$assessment_id == 'wcpfc_wcpo_skipjack'),
  !any(inputs$assessment_id == 'wcpfc_wcpo_skipjack'),
  !any(outputs$assessment_id == 'wcpfc_wcpo_skipjack'))
cat('NOAA 11691 WCPO skipjack screen and no-import checks passed.\n')

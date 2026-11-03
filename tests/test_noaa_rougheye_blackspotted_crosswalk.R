source('scripts/database/485_reconcile_noaa_rougheye_blackspotted_units.R')

register <- read.csv('discovery/candidates.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
lookup <- function(id) register[register$candidate_id == id, , drop = FALSE]

goa_old <- lookup('NOAA:10538')
goa <- lookup('NOAA:11443')
west_coast_old <- lookup('NOAA:10539')
west_coast <- lookup('NOAA:14516')
bsai <- lookup('NOAA:11382')
ebs <- lookup('NOAA:15394')
historical_ai <- lookup('NOAA:15395')
units <- read.csv('discovery/inventory_units.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
bsai_unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'noaa_bsai_rougheye_blackspotted', , drop = FALSE]

stopifnot(
  nrow(goa_old) == 1L, nrow(goa) == 1L,
  goa_old$candidate_unit_id == goa$candidate_unit_id,
  goa_old$candidate_unit_id == 'noaa_goa_rougheye_blackspotted',
  goa$screening_status == 'screened', goa$eligibility == 'eligible',
  goa$inventory_assessment_year == 2024L,
  grepl('2023 full age-structured assessment', goa$decision_reason, fixed = TRUE),
  goa_old$eligibility == 'ineligible',
  grepl('not counted separately', goa_old$decision_reason, fixed = TRUE),
  west_coast_old$candidate_unit_id == west_coast$candidate_unit_id,
  west_coast$candidate_unit_id == 'noaa_uswc_rougheye_blackspotted',
  west_coast$eligibility == 'eligible', west_coast_old$eligibility == 'ineligible',
  bsai$candidate_unit_id == ebs$candidate_unit_id,
  bsai$candidate_unit_id == historical_ai$candidate_unit_id,
  bsai$candidate_unit_id == 'noaa_bsai_rougheye_blackspotted',
  bsai$eligibility == 'eligible', ebs$eligibility == 'ineligible',
  historical_ai$screening_status == 'screened',
  historical_ai$eligibility == 'ineligible',
  historical_ai$inventory_assessment_year == 2008L,
  historical_ai$assessment_area == 'Aleutian Islands',
  grepl('historical component record', historical_ai$decision_reason, fixed = TRUE),
  grepl('AI-only age coverage', bsai$decision_reason, fixed = TRUE),
  grepl('non-age-structured Tier 5', ebs$decision_reason, fixed = TRUE),
  all(vapply(c('noaa_goa_rougheye_blackspotted',
    'noaa_uswc_rougheye_blackspotted', 'noaa_bsai_rougheye_blackspotted'),
    function(id) sum(units$candidate_unit_id == id, na.rm = TRUE) == 1L,
    logical(1))),
  nrow(bsai_unit) == 1L, bsai_unit$inventory_entries == 3L,
  grepl('NOAA:15395', bsai_unit$candidate_ids, fixed = TRUE),
  file.exists('discovery/source_reviews/noaa_rougheye_blackspotted_crosswalk.md')
)

cat('NOAA rougheye/blackspotted regional unit crosswalk checks passed.\n')

source('scripts/database/518_reconcile_noaa_goa_skate_components_2023.R')
source('scripts/database/519_screen_noaa_south_pacific_albacore_2024.R')
source('scripts/database/520_screen_noaa_wcpfc_skipjack_2025.R')
source('scripts/database/521_screen_noaa_wcpfc_bigeye_2023.R')
source('scripts/database/522_screen_noaa_wcpfc_yellowfin_2026.R')
source('scripts/database/523_screen_noaa_isc_shortfin_mako_2024.R')
source('scripts/database/529_screen_noaa_alaska_sharks_2022.R')
source('scripts/database/530_screen_noaa_isc_pacific_swordfish_marlin_2026.R')
source('scripts/database/531_screen_noaa_seak_coho_indicators_2024.R')
source('scripts/database/532_screen_noaa_blacktip_assessments_2018_2020.R')
source('scripts/database/533_screen_noaa_gulf_smoothhound_sedar39_2015.R')
source('scripts/database/534_screen_noaa_hogfish_sedar94_2026.R')
source('scripts/database/195_summarize_discovery.R')
source('scripts/database/196_summarize_inventory_units.R')
source('tests/test_noaa_alaska_sharks_2022_screen.R')
source('tests/test_noaa_isc_pacific_swordfish_marlin_2026_screen.R')
source('tests/test_noaa_seak_coho_indicators_2024_screen.R')
source('tests/test_noaa_blacktip_assessments_2018_2020_screen.R')
source('tests/test_noaa_gulf_smoothhound_sedar39_2015_screen.R')
source('tests/test_noaa_hogfish_sedar94_2026_screen.R')
source('tests/test_noaa_isc_shortfin_mako_2024_screen.R')
source('tests/test_noaa_south_pacific_albacore_2024_screen.R')
source('tests/test_noaa_wcpfc_skipjack_2025_screen.R')
source('tests/test_noaa_wcpfc_bigeye_2023_screen.R')
source('tests/test_noaa_wcpfc_yellowfin_2026_screen.R')
source('tests/test_noaa_goa_skate_components_2023_screen.R')

source('tests/test_candidate_register_io.R')
source('tests/test_noaa_klamath_spring_chinook_2013_screen.R')
source('tests/test_noaa_north_atlantic_shortfin_mako_2026_screen.R')
source('tests/test_noaa_northwest_atlantic_porbeagle_2020_screen.R')
source('tests/test_noaa_north_atlantic_albacore_2023_screen.R')
source('tests/test_noaa_alaska_index_aggregates_2024_screen.R')
source('tests/test_noaa_auke_creek_coho_2024_screen.R')
source('tests/test_noaa_ocean_quahog_2020_screen.R')
source('tests/test_noaa_atlantic_menhaden_2025_screen.R')
source('tests/test_noaa_cowcod_southern_california_2019_screen.R')
source('tests/test_noaa_south_atlantic_red_grouper_2017_screen.R')
source('tests/test_noaa_caribbean_snappers_sedar26_2011_screen.R')
source('tests/test_noaa_caribbean_red_hind_sedar35_screen.R')
source('tests/test_ices_barents_capelin_jrn_afwg_2026.R')
source('tests/test_noaa_squarespot_rockfish_pacific_2021_screen.R')
source('tests/test_noaa_bsai_alaska_skate_2026_screen.R')
source('tests/test_noaa_iattc_bigeye_2026_screen.R')
source('tests/test_noaa_iccat_white_marlin_2025_screen.R')
source('tests/test_noaa_iccat_blue_marlin_2024_screen.R')
source('tests/test_noaa_iccat_west_sailfish_2023_screen.R')
source('tests/test_noaa_iattc_striped_marlin_2010_screen.R')
source('tests/test_noaa_guam_reef_fish_2019.R')
source('tests/test_dfo_wcvi_barkley_sockeye_2024_screen.R')
source('tests/test_noaa_greenspotted_rockfish_2011.R')
source('tests/test_noaa_yellowtail_snapper_sedar96_2025_screen.R')
source('tests/test_ices_greater_silver_smelt_123a4_2026.R')
source('tests/test_ices_sprat_3a4_2026.R')
source('tests/test_ices_bay_biscay_anchovy_2025.R')
source('tests/test_ices_tusk_5a14_2026.R')
source('tests/test_ices_pollack_3a4_2024.R')
source('tests/test_ices_blackspot_seabream_9_2026.R')
source('tests/test_ices_cod_faroe_bank_2025_screen.R')
source('tests/test_ices_dogfish_8c9a_2025.R')
source('tests/test_ices_dogfish_67a_ce_j_2025.R')
source('tests/test_ices_plaice_89a_2025.R')
source('tests/test_ices_white_skate_nea_2025.R')
source('tests/test_ices_angel_shark_nea_2025.R')
source('tests/test_ices_smooth_hounds_nea_2025.R')
source('tests/test_ices_spotted_ray_3a47d_2025.R')
source('tests/test_ices_dogfish_3a47d_2025.R')
source('tests/test_ices_roundnose_grenadier_oceanic_2023_screen.R')
source('tests/test_ices_roundnose_grenadier_3a_2026_screen.R')
source('tests/test_ices_seabass_8c9a_2025_screen.R')
source('tests/test_noaa_rougheye_blackspotted_crosswalk.R')
source('tests/test_noaa_oregon_vermilion_2021_screen.R')
source('tests/test_noaa_vermilion_washington_2021_screen.R')
register <- read.csv('discovery/candidates.csv', stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stocks <- read.csv('database/stocks.csv', stringsAsFactors = FALSE)
stopifnot(nrow(register) > 0L, !anyNA(register$candidate_id), !anyDuplicated(register$candidate_id),
  !any(register$candidate_id == 'candidate_id'),
  all(register$organization %in% c('NOAA', 'ICES', 'DFO')),
  all(register$match_status %in% c('unreviewed', 'matched', 'new', 'ambiguous')),
  all(register$screening_status %in% c('not_started', 'in_progress', 'screened')),
  all(register$eligibility %in% c('unresolved', 'eligible', 'ineligible')),
  all(register$import_status %in% c('not_started', 'in_progress', 'imported', 'blocked')),
  all(is.na(register$matched_stock_id) | register$matched_stock_id %in% stocks$stock_id))
ices_matches <- register[register$organization == 'ICES' & register$match_status == 'matched', ]
if (nrow(ices_matches)) {
  stock_index <- match(ices_matches$matched_stock_id, stocks$stock_id)
  stopifnot(all(tolower(ices_matches$official_stock_id) == tolower(stocks$authority_stock_id[stock_index])))
}
eligible <- register$eligibility == 'eligible'
for (column in c('catch_age_evidence', 'survey_age_evidence', 'weights_evidence',
                 'maturity_evidence', 'mortality_evidence', 'timing_evidence',
                 'output_evidence', 'detailed_source_url', 'review_date')) {
  stopifnot(!any(is.na(register[[column]][eligible]) | !nzchar(register[[column]][eligible])))
}

lookup <- function(id) register[register$candidate_id == id, , drop = FALSE]
stopifnot(
  lookup('NOAA:10523')$matched_stock_id == 'joint_hake_coastal',
  lookup('NOAA:10425')$candidate_unit_id == 'noaa_goa_yelloweye_seo',
  lookup('NOAA:10425')$screening_status == 'screened',
  lookup('NOAA:10425')$eligibility == 'ineligible',
  lookup('NOAA:10435')$candidate_unit_id == 'noaa_pacific_sharpchin_rockfish',
  lookup('NOAA:10435')$screening_status == 'screened',
  lookup('NOAA:10435')$eligibility == 'ineligible',
  lookup('NOAA:10435')$import_status == 'not_started',
  lookup('DFO:Pacific:Yellowtail Rockfish - British Columbia coastwide')$eligibility == 'unresolved',
  lookup('DFO:Pacific:Yellowtail Rockfish - British Columbia coastwide')$screening_status == 'screened',
  lookup('DFO:Pacific:Yellowtail Rockfish - British Columbia coastwide')$import_status == 'not_started',
  lookup('DFO:Newfoundland and Labrador:Atlantic Cod - NAFO 2J3KL')$screening_status == 'screened',
  lookup('DFO:Newfoundland and Labrador:Atlantic Cod - NAFO 2J3KL')$eligibility == 'eligible',
  lookup('DFO:Newfoundland and Labrador:Atlantic Cod - NAFO 2J3KL')$import_status == 'imported',
  lookup('DFO:Quebec:Atlantic Cod - NAFO 3Pn4RS')$screening_status == 'screened',
  lookup('DFO:Quebec:Atlantic Cod - NAFO 3Pn4RS')$eligibility == 'eligible',
  lookup('DFO:Quebec:Atlantic Cod - NAFO 3Pn4RS')$import_status == 'imported',
  lookup('DFO:Pacific:Pacific Hake - Offshore')$matched_stock_id == 'joint_hake_coastal',
  lookup('DFO:Maritimes:Atlantic Cod - NAFO 5Zjm')$matched_stock_id == 'ck_nefsc_trac_cert_morhua_gb',
  lookup('DFO:Maritimes:Atlantic Cod - NAFO 5Zjm')$screening_status == 'screened',
  lookup('DFO:Maritimes:Atlantic Cod - NAFO 5Zjm')$eligibility == 'unresolved',
  lookup('DFO:Maritimes:Atlantic Cod - NAFO 5Zjm')$import_status == 'imported',
  lookup('DFO:Maritimes:Atlantic Cod - NAFO 4X5Y')$screening_status == 'screened',
  lookup('DFO:Maritimes:Atlantic Cod - NAFO 4X5Y')$eligibility == 'unresolved',
  grepl('run-matched matrices', lookup('DFO:Maritimes:Atlantic Cod - NAFO 4X5Y')$decision_reason, fixed = TRUE),
  lookup('DFO:Pacific:Canary Rockfish')$matched_stock_id == 'dfo_canary_bc',
  lookup('DFO:Pacific:Pacific Ocean Perch - PMFC 3CD-WCVI')$matched_stock_id == 'dfo_pop_bc',
  lookup('DFO:Pacific:Pacific Ocean Perch - PMFC 5ABC-QCS')$matched_stock_id == 'dfo_pop_bc',
  lookup('DFO:Pacific:Pacific Ocean Perch - PMFC 5DE-HS/DE/WHG')$matched_stock_id == 'dfo_pop_bc',
  lookup('NOAA:10014')$matched_stock_id == 'nefsc_witch_flounder_unit',
  lookup('NOAA:10026')$screening_status == 'screened',
  lookup('NOAA:10026')$eligibility == 'ineligible',
  lookup('NOAA:10026')$import_status == 'imported',
  lookup('NOAA:10026')$matched_stock_id == 'afsc_alaska_plaice_bsai',
  lookup('NOAA:10031')$matched_stock_id == 'afsc_yellowfin_sole_ebs',
  lookup('NOAA:10191')$matched_stock_id == 'nefsc_summer_flounder',
  lookup('NOAA:11050')$matched_stock_id == 'afsc_northern_rock_sole_ebs',
  lookup('NOAA:12746')$matched_stock_id == 'afsc_cod_ebs',
  lookup('NOAA:10510')$matched_stock_id == 'afsc_pollock_ebs',
  lookup('DFO:Gulf:Atlantic Herring - NAFO 4T (Spring Spawner)')$matched_stock_id == 'dfo_herring_4tvn_spring',
  lookup('DFO:Gulf:Atlantic Herring - NAFO 4T (Fall Spawner)')$matched_stock_id == 'ck_dfo_gsl_harengus_4t_fall',
  lookup('DFO:Gulf:American Plaice - NAFO 4T')$eligibility == 'eligible',
  lookup('DFO:Pacific:Dungeness Crab')$eligibility == 'ineligible',
  lookup('DFO:Maritimes:Grey Seal')$eligibility == 'ineligible'
)
faroe_bank_cod <- lookup('ICES:cod.27.5b2')
stopifnot(
  nrow(faroe_bank_cod) == 1L,
  faroe_bank_cod$candidate_unit_id == 'ices_cod_faroe_bank',
  faroe_bank_cod$match_status == 'new',
  faroe_bank_cod$screening_status == 'screened',
  faroe_bank_cod$eligibility == 'ineligible',
  faroe_bank_cod$import_status == 'not_started',
  grepl('aggregate summer survey index', faroe_bank_cod$decision_reason, fixed = TRUE),
  file.exists('discovery/source_reviews/ices_cod_faroe_bank_2025.md')
)
outside_dogfish <- lookup('DFO:Pacific:Dogfish - Outside waters')
outside_dogfish_units <- read.csv('discovery/inventory_units.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
outside_dogfish_unit <- outside_dogfish_units[
  outside_dogfish_units$unit_key == 'candidate:dfo_dogfish_outside_bc', , drop = FALSE]
stopifnot(
  nrow(outside_dogfish) == 1L,
  outside_dogfish$candidate_unit_id == 'dfo_dogfish_outside_bc',
  outside_dogfish$match_status == 'new',
  outside_dogfish$screening_status == 'screened',
  outside_dogfish$eligibility == 'ineligible',
  outside_dogfish$import_status == 'not_started',
  outside_dogfish$inventory_assessment_year == 2024,
  grepl('could not be linked', outside_dogfish$catch_age_evidence, fixed = TRUE),
  grepl('length compositions', outside_dogfish$decision_reason, fixed = TRUE),
  nrow(outside_dogfish_unit) == 1L,
  outside_dogfish_unit$screening_status == 'screened',
  outside_dogfish_unit$eligibility == 'ineligible',
  file.exists('discovery/source_reviews/dfo_dogfish_outside_2024.md')
)
stopifnot(
  lookup('DFO:Maritimes:Atlantic Canada Spiny Dogfish - NAFO 4VWX5')$candidate_unit_id == 'spiny_dogfish_northwest_atlantic',
  lookup('DFO:Maritimes:Atlantic Canada Spiny Dogfish - NAFO 4VWX5')$match_status == 'ambiguous',
  lookup('DFO:Maritimes:Atlantic Canada Spiny Dogfish - NAFO 4VWX5')$eligibility == 'ineligible',
  lookup('NOAA:10701')$candidate_unit_id == 'spiny_dogfish_northwest_atlantic',
  lookup('NOAA:10701')$match_status == 'new',
  lookup('NOAA:10701')$screening_status == 'screened',
  lookup('NOAA:10701')$eligibility == 'ineligible',
  grepl('age and growth data', lookup('NOAA:10701')$decision_reason, ignore.case = TRUE),
  file.exists('discovery/source_reviews/noaa_dfo_spiny_dogfish_northwest_atlantic.md'),
  lookup('ICES:nop.27.6a')$candidate_unit_id == 'ices_norway_pout_6a',
  lookup('ICES:nop.27.6a')$match_status == 'new',
  lookup('ICES:nop.27.6a')$screening_status == 'screened',
  lookup('ICES:nop.27.6a')$eligibility == 'ineligible',
  lookup('ICES:nop.27.6a')$import_status == 'not_started',
  grepl('status only', lookup('ICES:nop.27.6a')$output_evidence, ignore.case = TRUE),
  lookup('ICES:nep.fu.14')$eligibility == 'ineligible',
  lookup('ICES:wit.27.3a47d')$match_status == 'new',
  lookup('ICES:wit.27.3a47d')$screening_status == 'screened',
  lookup('ICES:wit.27.3a47d')$eligibility == 'unresolved',
  lookup('ICES:sol.27.7fg')$match_status == 'matched',
  lookup('ICES:sol.27.7fg')$screening_status == 'screened',
  lookup('ICES:sol.27.7fg')$eligibility == 'eligible',
  lookup('ICES:sol.27.7fg')$import_status == 'imported',
  lookup('ICES:sol.27.7e')$match_status == 'matched',
  lookup('ICES:sol.27.7e')$screening_status == 'screened',
  lookup('ICES:sol.27.7e')$eligibility == 'eligible',
  lookup('ICES:sol.27.7e')$import_status == 'imported',
  lookup('ICES:cod.27.7a')$match_status == 'matched',
  lookup('ICES:cod.27.7a')$screening_status == 'screened',
  lookup('ICES:cod.27.7a')$eligibility == 'eligible',
  lookup('ICES:cod.27.7a')$import_status == 'imported',
  lookup('ICES:had.27.6b')$match_status == 'matched',
  lookup('ICES:had.27.6b')$screening_status == 'screened',
  lookup('ICES:had.27.6b')$eligibility == 'eligible',
  lookup('ICES:had.27.6b')$import_status == 'imported',
  lookup('ICES:whg.27.6a')$match_status == 'matched',
  lookup('ICES:whg.27.6a')$screening_status == 'screened',
  lookup('ICES:whg.27.6a')$eligibility == 'eligible',
  lookup('ICES:whg.27.6a')$import_status == 'imported',
  lookup('ICES:cod.27.7e-k')$match_status == 'matched',
  lookup('ICES:cod.27.7e-k')$screening_status == 'screened',
  lookup('ICES:cod.27.7e-k')$eligibility == 'eligible',
  lookup('ICES:cod.27.7e-k')$import_status == 'imported',
  lookup('ICES:had.27.7b-k')$match_status == 'matched',
  lookup('ICES:had.27.7b-k')$screening_status == 'screened',
  lookup('ICES:had.27.7b-k')$eligibility == 'eligible',
  lookup('ICES:had.27.7b-k')$import_status == 'imported',
  lookup('ICES:ple.27.7a')$match_status == 'matched',
  lookup('ICES:ple.27.7a')$screening_status == 'screened',
  lookup('ICES:ple.27.7a')$eligibility == 'eligible',
  lookup('ICES:ple.27.7a')$import_status == 'imported',
  grepl('1981-2025', lookup('ICES:ple.27.7a')$catch_age_evidence, fixed = TRUE),
  grepl('UK(E&W) BTS-Q3', lookup('ICES:ple.27.7a')$survey_age_evidence, fixed = TRUE),
  lookup('ICES:sol.27.7a')$match_status == 'new',
  lookup('ICES:sol.27.7a')$screening_status == 'screened',
  lookup('ICES:sol.27.7a')$eligibility == 'unresolved',
  lookup('ICES:sol.27.8ab')$screening_status == 'screened',
  lookup('ICES:sol.27.8ab')$eligibility == 'unresolved',
  grepl('catch scale', lookup('ICES:sol.27.8ab')$decision_reason, fixed = TRUE),
  grepl('production-run M', lookup('ICES:sol.27.8ab')$decision_reason, fixed = TRUE),
  lookup('ICES:meg.27.8c9a')$screening_status == 'screened',
  lookup('ICES:meg.27.8c9a')$eligibility == 'unresolved',
  all(vapply(c('lez.27.4a6a', 'lez.27.6b', 'ple.27.7e', 'ple.27.7fg',
    'ple.27.7h-k', 'had.27.7a', 'sol.27.7h-k', 'bss.27.6a7bj',
    'cod.27.6b', 'ple.27.7bc', 'sol.27.7bc'), function(code) {
      row <- lookup(paste0('ICES:', code))
      nrow(row) == 1L && row$screening_status == 'screened' && row$eligibility == 'ineligible'
    }, logical(1L))),
  lookup('ICES:sol.27.8c9a')$screening_status == 'screened',
  lookup('ICES:sol.27.8c9a')$eligibility == 'ineligible',
  grepl('latest WGBIE update is length-based', lookup('ICES:sol.27.8c9a')$decision_reason, fixed = TRUE),
  lookup('ICES:meg.27.8c9a')$import_status == 'not_started',
  lookup('ICES:mac.27.nea')$match_status == 'new',
  lookup('ICES:mac.27.nea')$screening_status == 'screened',
  lookup('ICES:mac.27.nea')$eligibility == 'unresolved',
  grepl('age-specific fitted outputs', lookup('ICES:mac.27.nea')$decision_reason, fixed = TRUE),
  lookup('ICES:pra.27.1-2')$eligibility == 'ineligible',
  lookup('DFO:Arctic:Lake Trout - Great Slave Lake')$eligibility == 'ineligible',
  lookup('NOAA:10523')$screening_status == 'screened'
)
stopifnot(
  lookup('NOAA:10809')$eligibility == 'ineligible',
  lookup('NOAA:10011')$screening_status == 'screened',
  lookup('NOAA:10011')$eligibility == 'eligible',
  lookup('NOAA:10011')$import_status == 'not_started',
  grepl('Catch-at-age can be reconstructed', lookup('NOAA:10011')$catch_age_evidence, fixed = TRUE),
  grepl('Triennial survey has no age samples', lookup('NOAA:10011')$survey_age_evidence, fixed = TRUE),
  grepl('2023 spawning output', lookup('NOAA:10011')$output_evidence, fixed = TRUE),
  lookup('NOAA:17357')$match_status == 'new',
  lookup('NOAA:17357')$screening_status == 'screened',
  lookup('NOAA:17357')$eligibility == 'eligible',
  lookup('NOAA:17357')$import_status == 'not_started',
  grepl('Catch-at-age is not direct', lookup('NOAA:17357')$catch_age_evidence, fixed = TRUE),
  grepl('age-specific index requires', lookup('NOAA:17357')$survey_age_evidence, fixed = TRUE),
  grepl('N-at-age', lookup('NOAA:17357')$output_evidence, fixed = TRUE),
  lookup('NOAA:10395')$match_status == 'ambiguous',
  lookup('NOAA:10395')$screening_status == 'screened',
  lookup('NOAA:10395')$eligibility == 'ineligible',
  grepl('NOAA:17357', lookup('NOAA:10395')$notes, fixed = TRUE),
  lookup('NOAA:10977')$eligibility == 'ineligible',
  lookup('NOAA:11763')$eligibility == 'unresolved',
  lookup('NOAA:11763')$screening_status == 'screened'
)
matched_noaa_review <- c(
  'NOAA:10014','NOAA:10019','NOAA:10029','NOAA:10031','NOAA:10033','NOAA:10034',
  'NOAA:10191','NOAA:10286','NOAA:10506','NOAA:10510','NOAA:10511','NOAA:10513',
  'NOAA:10515','NOAA:10518','NOAA:10520','NOAA:10523','NOAA:11050','NOAA:11055',
  'NOAA:11662','NOAA:12745','NOAA:12746'
)
ne_noaa_review <- c('NOAA:10164','NOAA:10508','NOAA:10509','NOAA:10519')
reviewed_ne_noaa <- register[match(ne_noaa_review, register$candidate_id), , drop = FALSE]
stopifnot(
  !anyNA(reviewed_ne_noaa$candidate_id),
  identical(reviewed_ne_noaa$matched_stock_id, c('nefsc_atlantic_mackerel',
    'ck_nefsc_saw_morhua_gom','nefsc_cod_georges_bank','ck_nefsc_garmiii_aeglefinus_5y')),
  all(reviewed_ne_noaa$match_status == 'matched'),
  all(reviewed_ne_noaa$screening_status == 'screened'),
  all(reviewed_ne_noaa$import_status == 'imported'),
  identical(reviewed_ne_noaa$eligibility, c('eligible','ineligible','unresolved','unresolved')),
  grepl('combined U.S.-Canadian', lookup('NOAA:10164')$catch_age_evidence, fixed = TRUE),
  grepl('successor stock units', lookup('NOAA:10508')$decision_reason, fixed = TRUE),
  grepl('10509 / assessment 13596', lookup('NOAA:10509')$decision_reason, fixed = TRUE),
  grepl('2026 assessment', lookup('NOAA:10519')$decision_reason, fixed = TRUE)
)
reviewed_noaa_cod_units <- register[match(c('NOAA:17280', 'NOAA:17281', 'NOAA:17282'), register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(reviewed_noaa_cod_units) == 3L,
  all(reviewed_noaa_cod_units$match_status == 'new'),
  all(is.na(reviewed_noaa_cod_units$matched_stock_id)),
  all(reviewed_noaa_cod_units$screening_status == 'screened'),
  all(reviewed_noaa_cod_units$eligibility == 'unresolved'),
  all(reviewed_noaa_cod_units$import_status == 'not_started'),
  all(grepl('2024', reviewed_noaa_cod_units$detailed_source_url, fixed = TRUE)),
  grepl('commercial and recreational catch-age composition', lookup('NOAA:17280')$catch_age_evidence, fixed = TRUE),
  grepl('since 2013', lookup('NOAA:17281')$catch_age_evidence, fixed = TRUE),
  grepl('no ages from the recreational fishery', lookup('NOAA:17282')$catch_age_evidence, fixed = TRUE),
  all(grepl('not', reviewed_noaa_cod_units$output_evidence, fixed = TRUE)),
  lookup('NOAA:12805')$matched_stock_id == 'ck_nefsc_trac_cert_morhua_gb',
  lookup('NOAA:12805')$match_status == 'matched',
  lookup('NOAA:12805')$screening_status == 'screened',
  lookup('NOAA:12805')$eligibility == 'unresolved',
  grepl('no assessment model', lookup('NOAA:12805')$catch_age_evidence, fixed = TRUE),
  grepl('2023 TRAC document is an indicator-based status report', lookup('NOAA:12805')$decision_reason, fixed = TRUE)
)
reviewed_noaa <- register[match(matched_noaa_review, register$candidate_id), , drop = FALSE]
stopifnot(
  !anyNA(reviewed_noaa$candidate_id),
  all(reviewed_noaa$match_status == 'matched'),
  all(reviewed_noaa$screening_status == 'screened'),
  all(reviewed_noaa$import_status == 'imported'),
  identical(reviewed_noaa$eligibility, c(
    'ineligible','unresolved','eligible','eligible','unresolved','unresolved',
    'eligible','eligible','ineligible','eligible','eligible','eligible','eligible',
    'eligible','unresolved','eligible','eligible','eligible','eligible','ineligible','ineligible')),
  grepl('length compositions', lookup('NOAA:10506')$catch_age_evidence, fixed = TRUE),
  grepl('current official', lookup('NOAA:10014')$decision_reason, fixed = TRUE),
  grepl('age-based-M production run', lookup('NOAA:10033')$decision_reason, fixed = TRUE),
  grepl('2018 official ASAP record', lookup('NOAA:10191')$decision_reason, fixed = TRUE),
  grepl('no unconditional age-specific index', lookup('NOAA:12745')$survey_age_evidence, fixed = TRUE),
  all(vapply(c('catch_age_evidence','survey_age_evidence','weights_evidence',
    'maturity_evidence','mortality_evidence','timing_evidence','output_evidence',
    'detailed_source_url'), function(column) {
      values <- reviewed_noaa[[column]][reviewed_noaa$eligibility == 'eligible']
      all(!is.na(values) & nzchar(values))
    }, logical(1L)))
)
progress <- read.csv('discovery/inventory_progress.csv', stringsAsFactors = FALSE)
stopifnot(sum(progress$inventory_rows) == nrow(register),
  all(progress$inventory_rows == progress$matched + progress$new + progress$ambiguous + progress$identity_unreviewed),
  all(progress$inventory_rows == progress$eligible + progress$excluded + progress$eligibility_unresolved),
  all(progress$inventory_rows == progress$screening_not_started + progress$screening_in_progress + progress$screening_complete))
stopifnot(all(progress$eligible_new <= progress$new),
  all(progress$eligible_new <= progress$eligible))
dfo_progress <- progress[progress$organization == 'DFO', , drop = FALSE]
stopifnot(sum(dfo_progress$inventory_rows) == 199L,
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$ambiguous) == 18L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$eligibility_unresolved) == 31L)
unit3_redfish <- lookup('DFO:Maritimes:Acadian Redfish - Unit 3')
stopifnot(
  nrow(unit3_redfish) == 1L,
  unit3_redfish$scientific_name == 'Sebastes spp.',
  unit3_redfish$match_status == 'new',
  is.na(unit3_redfish$matched_stock_id),
  unit3_redfish$screening_status == 'screened',
  unit3_redfish$eligibility == 'ineligible',
  unit3_redfish$import_status == 'not_started',
  grepl('not catch-at-age', unit3_redfish$catch_age_evidence, fixed = TRUE),
  grepl('abundance-at-length', unit3_redfish$survey_age_evidence, fixed = TRUE),
  grepl('above 22 cm', unit3_redfish$maturity_evidence, fixed = TRUE),
  grepl('not separated in commercial or survey catches', unit3_redfish$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_unit3_redfish_2022.md'))
)
noaa_progress <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(sum(noaa_progress$new) == 388L, sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$ambiguous) == 14L, sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligible) == 89L, sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L)
pifsc_progress <- noaa_progress[noaa_progress$source_region == 'PIFSC', , drop = FALSE]
stopifnot(nrow(pifsc_progress) == 1L,
  pifsc_progress$inventory_rows == 45L,
  pifsc_progress$new == 44L,
  pifsc_progress$ambiguous == 1L,
  pifsc_progress$identity_unreviewed == 0L,
  pifsc_progress$eligible == 2L,
  pifsc_progress$excluded == 43L,
  pifsc_progress$eligibility_unresolved == 0L,
  pifsc_progress$screening_complete == 45L,
  pifsc_progress$screening_not_started == 0L)
nwfsc_progress <- noaa_progress[noaa_progress$source_region == 'NWFSC / SWFSC', , drop = FALSE]
stopifnot(nrow(nwfsc_progress) == 1L,
  nwfsc_progress$inventory_rows == 138L,
  nwfsc_progress$new == 130L,
  nwfsc_progress$ambiguous == 7L,
  nwfsc_progress$identity_unreviewed == 0L,
  nwfsc_progress$eligible == 37L,
  nwfsc_progress$excluded == 53L,
  nwfsc_progress$eligibility_unresolved == 48L,
  nwfsc_progress$screening_complete == 138L,
  nwfsc_progress$screening_not_started == 0L)
halibut <- lookup('NOAA:10056')
stopifnot(
  nrow(halibut) == 1L,
  halibut$match_status == 'ambiguous',
  is.na(halibut$matched_stock_id),
  halibut$screening_status == 'screened',
  halibut$eligibility == 'ineligible',
  halibut$import_status == 'not_started',
  grepl('aggregate annual catch', halibut$catch_age_evidence, fixed = TRUE),
  grepl('not age-specific', halibut$survey_age_evidence, fixed = TRUE),
  grepl('does not use maturity-at-age', halibut$maturity_evidence, fixed = TRUE),
  grepl('does not estimate a natural-mortality process', halibut$mortality_evidence, fixed = TRUE),
  grepl('does not estimate N-', halibut$output_evidence, fixed = TRUE),
  grepl('DFO halibut unit', halibut$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_atlantic_halibut_2024.md'))
)
greenland_turbot <- lookup('NOAA:10054')
stopifnot(
  nrow(greenland_turbot) == 1L,
  greenland_turbot$match_status == 'new',
  is.na(greenland_turbot$matched_stock_id),
  greenland_turbot$screening_status == 'screened',
  greenland_turbot$eligibility == 'unresolved',
  greenland_turbot$import_status == 'not_started',
  grepl('aggregate catch', greenland_turbot$catch_age_evidence, fixed = TRUE),
  grepl('excluded from the likelihood', greenland_turbot$survey_age_evidence, fixed = TRUE),
  grepl('0.112 per year', greenland_turbot$mortality_evidence, fixed = TRUE),
  grepl('60 cm', greenland_turbot$maturity_evidence, fixed = TRUE),
  grepl('numbers-at-age', greenland_turbot$output_evidence, fixed = TRUE),
  grepl('preliminary and not treated', greenland_turbot$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_greenland_turbot_bsai_2024.md'))
)
for (org in unique(register$organization)) {
  stopifnot(sum(progress$inventory_rows[progress$organization == org]) == sum(register$organization == org),
    sum(progress$excluded[progress$organization == org]) == sum(register$organization == org & register$eligibility == 'ineligible'),
    sum(progress$matched[progress$organization == org]) == sum(register$organization == org & register$match_status == 'matched'))
}
cat('Discovery register structure, identity and eligibility checks passed.\n')

wgcse <- function(code) lookup(paste0('ICES:', code))
stopifnot(
  wgcse('anf.27.3a46')$match_status == 'new',
  wgcse('anf.27.3a46')$screening_status == 'screened',
  wgcse('anf.27.3a46')$eligibility == 'ineligible',
  grepl('length-based', wgcse('anf.27.3a46')$decision_reason, fixed = TRUE),
  wgcse('bss.27.4bc7ad-h')$match_status == 'new',
  wgcse('bss.27.4bc7ad-h')$screening_status == 'screened',
  wgcse('bss.27.4bc7ad-h')$eligibility == 'unresolved',
  grepl('conditional age-at-length', wgcse('bss.27.4bc7ad-h')$decision_reason, fixed = TRUE),
  wgcse('pol.27.67')$match_status == 'new',
  wgcse('pol.27.67')$screening_status == 'screened',
  wgcse('pol.27.67')$eligibility == 'eligible',
  wgcse('pol.27.67')$import_status == 'not_started',
  grepl('since 2010', wgcse('pol.27.67')$catch_age_evidence, fixed = TRUE),
  grepl('0.920', wgcse('pol.27.67')$mortality_evidence, fixed = TRUE),
  wgcse('whg.27.7a')$match_status == 'matched',
  wgcse('whg.27.7a')$matched_stock_id == 'ck_ices_wgcse_merlangus_cs7a',
  wgcse('whg.27.7a')$eligibility == 'eligible',
  wgcse('whg.27.7a')$import_status == 'imported',
  wgcse('whg.27.7b-ce-k')$match_status == 'new',
  wgcse('whg.27.7b-ce-k')$screening_status == 'screened',
  wgcse('whg.27.7b-ce-k')$eligibility == 'eligible',
  wgcse('whg.27.7b-ce-k')$import_status == 'not_started',
  grepl('0-7+', wgcse('whg.27.7b-ce-k')$catch_age_evidence, fixed = TRUE),
  grepl('ages 0-2', wgcse('whg.27.7b-ce-k')$survey_age_evidence, fixed = TRUE),
  is.na(wgcse('whg.27.7b-ce-k')$matched_stock_id)
)
cat('WGCSE age-based screening decisions passed.\n')

alaska_flatfish <- register[match(paste0('NOAA:', c('10002','10003','10004','10015','10016')), register$candidate_id), , drop = FALSE]
stopifnot(
  !anyNA(alaska_flatfish$candidate_id),
  identical(alaska_flatfish$match_status, c('new','matched','new','new','new')),
  identical(alaska_flatfish$matched_stock_id, c(NA, 'afsc_arrowtooth_flounder_bsai', NA, NA, NA)),
  identical(alaska_flatfish$screening_status, rep('screened', 5L)),
  identical(alaska_flatfish$eligibility, c('ineligible','ineligible','ineligible','eligible','ineligible')),
  identical(alaska_flatfish$import_status, c('not_started','imported','not_started','not_started','not_started')),
  grepl('does not report a fishery catch-age', lookup('NOAA:10002')$catch_age_evidence, fixed = TRUE),
  grepl('no accepted fishery age-composition', lookup('NOAA:10003')$catch_age_evidence, fixed = TRUE),
  grepl('Stock SMART lists Reinhardtius stomias', lookup('NOAA:10003')$notes, fixed = TRUE),
  grepl('Stock SMART snapshot says 2024 and lists Reinhardtius stomias', lookup('NOAA:10004')$notes, fixed = TRUE),
  grepl('fishery length compositions', lookup('NOAA:10004')$catch_age_evidence, fixed = TRUE),
  grepl('October 2026 SSC report selects Model 25.0', lookup('NOAA:10004')$output_evidence, fixed = TRUE),
  grepl('age compositions', lookup('NOAA:10015')$catch_age_evidence, fixed = TRUE),
  grepl('flathead sole only', lookup('NOAA:10015')$catch_age_evidence, fixed = TRUE),
  grepl('ghosted', lookup('NOAA:10016')$survey_age_evidence, fixed = TRUE),
  all(file.exists(file.path('discovery','source_reviews',
    c('noaa_kamchatka_bsai.md','noaa_arrowtooth_bsai_identity.md','noaa_arrowtooth_goa.md',
      'noaa_flathead_bsai.md','noaa_flathead_goa.md'))))
)
cat('Alaska flatfish identity and age-input screening checks passed.\n')

goa_pop <- lookup('NOAA:11056')
stopifnot(
  goa_pop$match_status == 'new', is.na(goa_pop$matched_stock_id),
  goa_pop$screening_status == 'screened', goa_pop$eligibility == 'eligible',
  goa_pop$import_status == 'not_started',
  grepl('1961-2023', goa_pop$catch_age_evidence, fixed = TRUE),
  grepl('17 sampled years', goa_pop$catch_age_evidence, fixed = TRUE),
  grepl('14 years', goa_pop$survey_age_evidence, fixed = TRUE),
  grepl('fishery and survey', goa_pop$weights_evidence, fixed = TRUE),
  grepl('one constant parameter', goa_pop$mortality_evidence, fixed = TRUE),
  grepl('not survey timing', goa_pop$timing_evidence, fixed = TRUE),
  grepl('numbers-at-age', goa_pop$output_evidence, fixed = TRUE),
  grepl('2023 operational update', goa_pop$notes, fixed = TRUE),
  file.exists(file.path('discovery','source_reviews',
    'noaa_goa_pacific_ocean_perch.md'))
)
cat('GOA Pacific ocean perch identity and source-screen checks passed.\n')

northern_rockfish <- register[match(paste0('NOAA:', c('10416', '10417')), register$candidate_id), , drop = FALSE]
stopifnot(
  !anyNA(northern_rockfish$candidate_id),
  identical(northern_rockfish$match_status, c('new', 'new')),
  all(is.na(northern_rockfish$matched_stock_id)),
  identical(northern_rockfish$screening_status, c('screened', 'screened')),
  identical(northern_rockfish$eligibility, c('eligible', 'eligible')),
  identical(northern_rockfish$import_status, c('not_started', 'not_started')),
  grepl('2023 full assessment', lookup('NOAA:10416')$catch_age_evidence, fixed = TRUE),
  grepl('2024 full assessment', lookup('NOAA:10417')$catch_age_evidence, fixed = TRUE),
  grepl('2026 chapter is a harvest projection', lookup('NOAA:10416')$notes, fixed = TRUE),
  grepl('December 2026', lookup('NOAA:10417')$notes, fixed = TRUE),
  grepl('documented reconstruction', lookup('NOAA:10416')$decision_reason, fixed = TRUE),
  grepl('documented reconstruction', lookup('NOAA:10417')$decision_reason, fixed = TRUE),
  all(file.exists(file.path('discovery', 'source_reviews',
    c('noaa_northern_rockfish_bsai.md', 'noaa_northern_rockfish_goa.md'))))
)
cat('Northern rockfish identity and source-screening checks passed.\n')

arrowtooth <- lookup('NOAA:10005')
stopifnot(
  arrowtooth$match_status == 'new',
  arrowtooth$screening_status == 'screened',
  arrowtooth$eligibility == 'unresolved',
  arrowtooth$scientific_name == 'Atheresthes stomias',
  grepl('could not be recovered', arrowtooth$decision_reason, fixed = TRUE),
  grepl('Stock SMART ID 10005', arrowtooth$notes, fixed = TRUE),
  !identical(arrowtooth$matched_stock_id, 'afsc_arrowtooth_flounder_bsai')
)

dover <- lookup('NOAA:10022')
stopifnot(
  dover$match_status == 'new',
  dover$screening_status == 'screened',
  dover$eligibility == 'eligible',
  dover$import_status == 'not_started',
  grepl('year/sex/fleet age-composition', dover$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', dover$survey_age_evidence, fixed = TRUE),
  grepl('numbers-at-age, catch-at-age, F-at-age', dover$output_evidence, fixed = TRUE),
  grepl('dover sole', dover$decision_reason, ignore.case = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_pacific_coast_dover_sole.md'))
)
cat('Dover sole identity and source-screening checks passed.\n')

widow <- lookup('NOAA:10568')
stopifnot(
  widow$match_status == 'new',
  widow$screening_status == 'screened',
  widow$eligibility == 'eligible',
  widow$import_status == 'not_started',
  grepl('three commercial fleets', widow$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', widow$survey_age_evidence, fixed = TRUE),
  grepl('billions of eggs', widow$output_evidence, fixed = TRUE),
  grepl('version labels', widow$notes, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_west_coast_widow_rockfish.md'))
)
cat('Widow rockfish identity and source-screening checks passed.\n')

dfo_sablefish <- lookup('DFO:Pacific:Sablefish')
stopifnot(
  dfo_sablefish$scientific_name == 'Anoplopoma fimbria',
  dfo_sablefish$assessment_area == 'British Columbia coastwide',
  dfo_sablefish$match_status == 'new',
  is.na(dfo_sablefish$matched_stock_id),
  dfo_sablefish$screening_status == 'screened',
  dfo_sablefish$eligibility == 'unresolved',
  dfo_sablefish$import_status == 'not_started',
  grepl('no public numeric commercial age-composition arrays', dfo_sablefish$catch_age_evidence, fixed = TRUE),
  grepl('2003-2021', dfo_sablefish$survey_age_evidence, fixed = TRUE),
  grepl('prior (mean 0.1 and standard deviation 0.1', dfo_sablefish$mortality_evidence, fixed = TRUE),
  grepl('0.75', dfo_sablefish$timing_evidence, fixed = TRUE),
  grepl('N-at-age and F-at-age output matrices', dfo_sablefish$output_evidence, fixed = TRUE),
  grepl('2025-26 advice', dfo_sablefish$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_bc_sablefish.md'))
)
cat('B.C. Sablefish identity and source-screening checks passed.\n')

dfo_bocaccio <- lookup('DFO:Pacific:Bocaccio Rockfish')
stopifnot(
  dfo_bocaccio$scientific_name == 'Sebastes paucispinis',
  dfo_bocaccio$assessment_area == 'British Columbia coastwide (PMFC 3CD+5ABCDE)',
  dfo_bocaccio$match_status == 'new',
  is.na(dfo_bocaccio$matched_stock_id),
  dfo_bocaccio$screening_status == 'screened',
  dfo_bocaccio$eligibility == 'unresolved',
  dfo_bocaccio$import_status == 'not_started',
  grepl('only the combined trawl fishery has age-frequency observations', dfo_bocaccio$catch_age_evidence, fixed = TRUE),
  grepl('2021 QCS', dfo_bocaccio$survey_age_evidence, fixed = TRUE),
  grepl('0.07, 0.08, and 0.09', dfo_bocaccio$mortality_evidence, fixed = TRUE),
  grepl('fraction 0.5', dfo_bocaccio$timing_evidence, fixed = TRUE),
  grepl('B2024 = 23,789 tonnes', dfo_bocaccio$output_evidence, fixed = TRUE),
  grepl('no age composition for the non-trawl catch stream', dfo_bocaccio$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_bc_bocaccio.md'))
)
cat('B.C. Bocaccio identity and source-screening checks passed.\n')

dfo_sog_herring <- lookup('DFO:Pacific:Pacific Herring - Strait of Georgia')
stopifnot(
  dfo_sog_herring$scientific_name == 'Clupea pallasii',
  dfo_sog_herring$matched_stock_id == 'dfo_herring_sog',
  dfo_sog_herring$match_status == 'matched',
  dfo_sog_herring$screening_status == 'screened',
  dfo_sog_herring$eligibility == 'ineligible',
  dfo_sog_herring$import_status == 'imported',
  grepl('ages 1-10+', dfo_sog_herring$catch_age_evidence, fixed = TRUE),
  grepl('All native survey age samples are missing (-1)', dfo_sog_herring$survey_age_evidence, fixed = TRUE),
  grepl('density dependent', dfo_sog_herring$mortality_evidence, fixed = TRUE),
  grepl('0.766', dfo_sog_herring$timing_evidence, fixed = TRUE),
  grepl('84.33375 thousand tonnes', dfo_sog_herring$output_evidence, fixed = TRUE),
  grepl('cannot fit this aggregate spawning-biomass observation', dfo_sog_herring$decision_reason, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'dfo_herring_sog.md'))
)
cat('Strait of Georgia herring identity and source-screening checks passed.\n')

dfo_pop <- register[register$candidate_id %in% c(
  'DFO:Pacific:Pacific Ocean Perch - PMFC 3CD-WCVI',
  'DFO:Pacific:Pacific Ocean Perch - PMFC 5ABC-QCS',
  'DFO:Pacific:Pacific Ocean Perch - PMFC 5DE-HS/DE/WHG'), , drop = FALSE]
stopifnot(
  nrow(dfo_pop) == 3L,
  all(dfo_pop$scientific_name == 'Sebastes alutus'),
  all(dfo_pop$matched_stock_id == 'dfo_pop_bc'),
  all(dfo_pop$match_status == 'matched'),
  all(dfo_pop$screening_status == 'screened'),
  all(dfo_pop$eligibility == 'eligible'),
  all(dfo_pop$import_status == 'imported'),
  all(grepl('three subarea fisheries', dfo_pop$catch_age_evidence, fixed = TRUE)),
  all(grepl('five surveys', dfo_pop$survey_age_evidence, fixed = TRUE)),
  all(grepl('5/12', dfo_pop$timing_evidence, fixed = TRUE)),
  all(grepl('2024 spawning biomass', dfo_pop$output_evidence, fixed = TRUE)),
  all(grepl('do not create duplicate', dfo_pop$notes, fixed = TRUE)),
  file.exists(file.path('source_reviews', 'dfo_pop_bc.md'))
)
cat('British Columbia Pacific ocean perch identity and source-screening checks passed.\n')

dfo_canary <- lookup('DFO:Pacific:Canary Rockfish')
stopifnot(
  dfo_canary$scientific_name == 'Sebastes pinniger',
  dfo_canary$matched_stock_id == 'dfo_canary_bc',
  dfo_canary$match_status == 'matched',
  dfo_canary$screening_status == 'screened',
  dfo_canary$eligibility == 'eligible',
  dfo_canary$import_status == 'imported',
  grepl('36 years (1977-2017)', dfo_canary$catch_age_evidence, fixed = TRUE),
  grepl('QCS, WCVI and NMFS have source age compositions', dfo_canary$survey_age_evidence, fixed = TRUE),
  grepl('5/12', dfo_canary$timing_evidence, fixed = TRUE),
  grepl('500 official posterior-subset', dfo_canary$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews', 'dfo_canary_bc.md'))
)
cat('B.C. Canary Rockfish identity and source-screening checks passed.\n')

dfo_herring <- register[match(c(
  'DFO:Gulf:Atlantic Herring - NAFO 4T (Spring Spawner)',
  'DFO:Gulf:Atlantic Herring - NAFO 4T (Fall Spawner)'), register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(dfo_herring) == 2L,
  all(dfo_herring$scientific_name == 'Clupea harengus'),
  identical(dfo_herring$matched_stock_id, c(
    'dfo_herring_4tvn_spring', 'ck_dfo_gsl_harengus_4t_fall')),
  all(dfo_herring$match_status == 'matched'),
  all(dfo_herring$screening_status == 'screened'),
  all(dfo_herring$eligibility == 'eligible'),
  all(dfo_herring$import_status == 'imported'),
  grepl('thousands of fish', dfo_herring$survey_age_evidence[1L], fixed = TRUE),
  grepl('duplicat', dfo_herring$catch_age_evidence[2L]),
  grepl('2026', dfo_herring$decision_reason[1L], fixed = TRUE),
  grepl('2026 advisory', dfo_herring$decision_reason[2L], fixed = TRUE),
  file.exists(file.path('source_reviews',
    'dfo_herring_4tvn_spring.md')),
  file.exists(file.path('source_reviews',
    'dfo_herring_4tvn_fall.md'))
)
cat('Southern Gulf herring identity and source-screening checks passed.\n')

goa_dover <- lookup('NOAA:10021')
stopifnot(
  goa_dover$scientific_name == 'Microstomus pacificus',
  goa_dover$match_status == 'new', is.na(goa_dover$matched_stock_id),
  goa_dover$screening_status == 'screened',
  goa_dover$eligibility == 'ineligible',
  goa_dover$import_status == 'not_started',
  grepl('no fishery age composition', goa_dover$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', goa_dover$survey_age_evidence, fixed = TRUE),
  grepl('survey month 6', goa_dover$timing_evidence, fixed = TRUE),
  grepl('numbers-at-age time series', goa_dover$output_evidence, fixed = TRUE),
  grepl('Model 19.3.1', goa_dover$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_goa_dover_sole.md'))
)
cat('NOAA GOA Dover sole source-screening checks passed.\n')

starry <- register[match(c('NOAA:10025', 'NOAA:14804', 'NOAA:14805'), register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(starry) == 3L,
  starry$match_status[1L] == 'ambiguous',
  starry$eligibility[1L] == 'ineligible',
  all(starry$screening_status == 'screened'),
  all(starry$eligibility == 'ineligible'),
  all(starry$match_status[-1L] == 'new'),
  all(starry$inventory_assessment_year[-1L] == 2017L),
  all(grepl('DB-SRA', starry$decision_reason[-1L], fixed = TRUE)),
  all(grepl('2017 DB-SRA', starry$notes[-1L], fixed = TRUE)),
  all(grepl('catch numbers-at-age', starry$catch_age_evidence[-1L], fixed = TRUE)),
  all(grepl('age compositions', starry$survey_age_evidence[-1L], fixed = TRUE)),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_starry_flounder.md'))
)
cat('NOAA starry flounder identity and age-data screening checks passed.\n')

winter <- register[match(c('NOAA:10028', 'NOAA:10030'), register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(winter) == 2L,
  all(winter$scientific_name == 'Pseudopleuronectes americanus'),
  all(winter$match_status == 'new'),
  all(winter$screening_status == 'screened'),
  all(winter$inventory_assessment_year == 2025L),
  winter$eligibility[winter$official_stock_id == '10028'] == 'ineligible',
  grepl('30+ cm', winter$survey_age_evidence[winter$official_stock_id == '10028'], fixed = TRUE),
  winter$eligibility[winter$official_stock_id == '10030'] == 'unresolved',
  grepl('ASAP', winter$decision_reason[winter$official_stock_id == '10030'], fixed = TRUE),
  grepl('catch-age', winter$decision_reason[winter$official_stock_id == '10030'], fixed = TRUE),
  grepl('6,211 thousand fish', winter$output_evidence[winter$official_stock_id == '10030'], fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_winter_flounder_gom_sne.md'))
)
cat('NOAA winter flounder identity and source-screening checks passed.\n')

sablefish <- lookup('NOAA:10466')
stopifnot(
  sablefish$scientific_name == 'Anoplopoma fimbria',
  sablefish$assessment_area == 'Pacific Coast',
  sablefish$inventory_assessment_year == 2025L,
  sablefish$match_status == 'new', is.na(sablefish$matched_stock_id),
  sablefish$screening_status == 'screened',
  sablefish$eligibility == 'eligible',
  sablefish$import_status == 'not_started',
  grepl('1983', sablefish$catch_age_evidence, fixed = TRUE),
  grepl('length-age key', sablefish$catch_age_evidence, fixed = TRUE),
  grepl('no directly observed age-specific abundance', sablefish$survey_age_evidence, fixed = TRUE),
  grepl('0-30', sablefish$weights_evidence, fixed = TRUE),
  grepl('0.088 per year', sablefish$mortality_evidence, fixed = TRUE),
  grepl('July', sablefish$timing_evidence, fixed = TRUE),
  grepl('59,331-89,486 mt', sablefish$output_evidence, fixed = TRUE),
  grepl('3.30.23.1', sablefish$notes, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_west_coast_sablefish_2025.md'))
)
cat('NOAA West Coast Sablefish identity and source-screening checks passed.\n')

yelloweye <- lookup('NOAA:10426')
stopifnot(
  yelloweye$scientific_name == 'Sebastes ruberrimus',
  yelloweye$assessment_area == 'Pacific Coast',
  yelloweye$inventory_assessment_year == 2025L,
  yelloweye$match_status == 'new', is.na(yelloweye$matched_stock_id),
  yelloweye$screening_status == 'screened',
  yelloweye$eligibility == 'eligible',
  yelloweye$import_status == 'not_started',
  grepl('seven fishery fleets', yelloweye$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', yelloweye$catch_age_evidence, fixed = TRUE),
  grepl('direct age-specific', yelloweye$survey_age_evidence, fixed = TRUE),
  grepl('growth curve', yelloweye$weights_evidence, fixed = TRUE),
  grepl('0.044 per year', yelloweye$mortality_evidence, fixed = TRUE),
  grepl('January', yelloweye$timing_evidence, fixed = TRUE),
  grepl('477.63 billion eggs', yelloweye$output_evidence, fixed = TRUE),
  grepl('two areas', yelloweye$notes, fixed = TRUE),
  grepl('3.30.23.2', yelloweye$notes, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_west_coast_yelloweye_2025.md'))
)
cat('NOAA West Coast Yelloweye identity and source-screening checks passed.\n')

yellowtail <- lookup('NOAA:10393')
stopifnot(
  yellowtail$scientific_name == 'Sebastes flavidus',
  yellowtail$stock_name == 'Yellowtail rockfish - Northern Pacific Coast',
  yellowtail$inventory_assessment_year == 2025L,
  yellowtail$match_status == 'new', is.na(yellowtail$matched_stock_id),
  yellowtail$screening_status == 'screened',
  yellowtail$eligibility == 'eligible',
  yellowtail$import_status == 'not_started',
  grepl('three fisheries', yellowtail$catch_age_evidence, fixed = TRUE),
  grepl('age and length compositions', yellowtail$catch_age_evidence, fixed = TRUE),
  grepl('four survey indices', yellowtail$survey_age_evidence, fixed = TRUE),
  grepl('232 histological samples', yellowtail$maturity_evidence, fixed = TRUE),
  grepl('age 43', yellowtail$mortality_evidence, fixed = TRUE),
  grepl('July', yellowtail$timing_evidence, fixed = TRUE),
  grepl('3.30.23.1', yellowtail$notes, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_yellowtail_north_2025.md'))
)
cat('NOAA northern Yellowtail Rockfish identity and source-screening checks passed.\n')

rougheye <- lookup('NOAA:14516')
stopifnot(
  identical(rougheye$scientific_name, 'Sebastes aleutianus; Sebastes melanostictus'),
  rougheye$assessment_area == 'U.S. West Coast',
  rougheye$inventory_assessment_year == 2025L,
  rougheye$match_status == 'new', is.na(rougheye$matched_stock_id),
  rougheye$screening_status == 'screened',
  rougheye$eligibility == 'eligible',
  rougheye$import_status == 'not_started',
  grepl('six fisheries', rougheye$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', rougheye$catch_age_evidence, fixed = TRUE),
  grepl('Triennial, Alaska slope', rougheye$survey_age_evidence, fixed = TRUE),
  grepl('Male natural mortality is fixed at 0.036', rougheye$mortality_evidence, fixed = TRUE),
  grepl('3.30.23.2', rougheye$notes, fixed = TRUE),
  grepl('not be counted as two cases', rougheye$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_rougheye_blackspotted_2025.md'))
)
cat('NOAA Rougheye/Blackspotted identity and source-screening checks passed.\n')

quillback <- lookup('NOAA:15342')
stopifnot(
  quillback$scientific_name == 'Sebastes maliger',
  quillback$stock_name == 'Quillback rockfish - California',
  quillback$assessment_area == 'California',
  quillback$inventory_assessment_year == 2025L,
  quillback$match_status == 'new', is.na(quillback$matched_stock_id),
  quillback$screening_status == 'screened',
  quillback$eligibility == 'eligible',
  quillback$import_status == 'not_started',
  grepl('total removals in metric', quillback$catch_age_evidence, fixed = TRUE),
  grepl('2007-2024', quillback$catch_age_evidence, fixed = TRUE),
  grepl('CCFRP', quillback$survey_age_evidence, fixed = TRUE),
  grepl('0.068 per year', quillback$mortality_evidence, fixed = TRUE),
  grepl('July', quillback$timing_evidence, fixed = TRUE),
  grepl('3.30.23.1', quillback$notes, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_quillback_california_2025.md'))
)
cat('NOAA California Quillback identity and source-screening checks passed.\n')

ccgom_yellowtail <- lookup('NOAA:10035')
noaa_progress <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(
  nrow(ccgom_yellowtail) == 1L,
  ccgom_yellowtail$match_status == 'new',
  is.na(ccgom_yellowtail$matched_stock_id),
  ccgom_yellowtail$screening_status == 'screened',
  ccgom_yellowtail$eligibility == 'unresolved',
  ccgom_yellowtail$import_status == 'not_started',
  grepl('catch-at-age diagnostics', ccgom_yellowtail$catch_age_evidence, fixed = TRUE),
  grepl('aggregate survey indices', ccgom_yellowtail$survey_age_evidence, fixed = TRUE),
  grepl('January 1 numbers-at-age', ccgom_yellowtail$output_evidence, fixed = TRUE),
  grepl('best available science', ccgom_yellowtail$decision_reason, fixed = TRUE),
  grepl('numeric age inputs', ccgom_yellowtail$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_yellowtail_ccgom_2025.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$ambiguous) == 14L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L)
cat('NOAA Cape Cod/Gulf of Maine yellowtail identity and source-screening checks passed.\n')
icelandic_cod <- lookup('ICES:cod.27.5a')
stopifnot(
  nrow(icelandic_cod) == 1L,
  icelandic_cod$match_status == 'matched',
  icelandic_cod$matched_stock_id == 'ck_ices_nwwg_morhua_ice5a',
  icelandic_cod$screening_status == 'screened',
  icelandic_cod$eligibility == 'eligible',
  icelandic_cod$import_status == 'imported',
  grepl('1955-2025', icelandic_cod$catch_age_evidence, fixed = TRUE),
  grepl('IS-SMB', icelandic_cod$survey_age_evidence, fixed = TRUE),
  grepl('1955-2026', icelandic_cod$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_cod_iceland_2026.md'))
)
cat('ICES cod 5.a identity and current-run screen passed.\n')
northsea_ices_ids <- c('ICES:her.27.3a47d', 'ICES:had.27.46a20',
  'ICES:ple.27.420', 'ICES:pok.27.3a46', 'ICES:whg.27.47d')
northsea_ices <- register[match(northsea_ices_ids, register$candidate_id), , drop = FALSE]
stopifnot(
  !anyNA(northsea_ices$candidate_id),
  identical(northsea_ices$matched_stock_id, c('ices_herring_north_sea',
    'ices_haddock_north_sea', 'ices_plaice_north_sea', 'ices_saithe_north_sea',
    'ices_whiting_north_sea')),
  all(northsea_ices$match_status == 'matched'),
  all(northsea_ices$screening_status == 'screened'),
  all(northsea_ices$eligibility == 'eligible'),
  all(northsea_ices$import_status == 'imported'),
  grepl('winter-ring', northsea_ices$catch_age_evidence[1], fixed = TRUE),
  grepl('partial spawning-component', northsea_ices$survey_age_evidence[1], fixed = TRUE),
  grepl('Q1', northsea_ices$survey_age_evidence[2], fixed = TRUE),
  grepl('Five age-specific', northsea_ices$survey_age_evidence[3], fixed = TRUE),
  grepl('Q3 and Q4', northsea_ices$survey_age_evidence[4], fixed = TRUE),
  grepl('April NSwhiting_2026n', northsea_ices$catch_age_evidence[5], fixed = TRUE),
  all(file.exists(file.path('source_reviews',
    c('ices_herring_north_sea.md', 'ices_haddock_north_sea.md',
      'ices_plaice_north_sea.md', 'ices_saithe_north_sea.md',
      'ices_whiting_north_sea_2026.md'))))
)
cat('Matched ICES North Sea identity and source-screening checks passed.\n')
dfo_matched_ids <- c(
  'DFO:Newfoundland and Labrador:Atlantic Cod - NAFO 3Ps',
  'DFO:Gulf:Atlantic Cod - NAFO 4TVn',
  'DFO:Maritimes:Haddock - NAFO 4X5Y',
  'DFO:Pacific:Pacific Hake - Offshore')
dfo_matched <- register[match(dfo_matched_ids, register$candidate_id), , drop = FALSE]
stopifnot(
  !anyNA(dfo_matched$candidate_id),
  identical(dfo_matched$matched_stock_id, c('ck_dfo_morhua_3ps',
    'dfo_cod_4t4vn', 'ck_dfo_aeglefinus_4x5y', 'joint_hake_coastal')),
  all(dfo_matched$match_status == 'matched'),
  all(dfo_matched$screening_status == 'screened'),
  all(dfo_matched$eligibility == 'eligible'),
  all(dfo_matched$import_status == 'imported'),
  grepl('2025 HYBRID update', dfo_matched$decision_reason[1], fixed = TRUE),
  grepl('separately', dfo_matched$decision_reason[2], fixed = TRUE),
  grepl('summary-only', dfo_matched$decision_reason[3], fixed = TRUE),
  grepl('composition-based', dfo_matched$decision_reason[4], fixed = TRUE),
  all(file.exists(file.path('source_reviews',
    c('dfo_cod_3ps_2024.md', 'dfo_cod_4t4vn.md',
      'dfo_haddock_4x5y.md', 'joint_hake_coastal.md'))))
)
cat('Matched DFO identity and source-screening checks passed.\n')
nwwg_match_ids <- c('ICES:pok.27.5a', 'ICES:had.27.5a', 'ICES:cod.27.5b1',
  'ICES:had.27.5b', 'ICES:pok.27.5b')
nwwg_matches <- register[match(nwwg_match_ids, register$candidate_id), , drop = FALSE]
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  !anyNA(nwwg_matches$candidate_id),
  identical(nwwg_matches$matched_stock_id, c('ck_ices_nwwg_virens_fa5a',
    'ices_haddock_iceland', 'ck_ices_nwwg_morhua_fapl5b1',
    'ck_ices_nwwg_aeglefinus_fa5b', 'ck_ices_nwwg_virens_fa5b')),
  all(nwwg_matches$match_status == 'matched'),
  all(nwwg_matches$screening_status == 'screened'),
  all(nwwg_matches$eligibility == 'eligible'),
  all(nwwg_matches$import_status == 'imported'),
  grepl('3-14+', nwwg_matches$catch_age_evidence[1], fixed = TRUE),
  grepl('IS-SMB', nwwg_matches$survey_age_evidence[2], fixed = TRUE),
  grepl('1959-2025', nwwg_matches$catch_age_evidence[3], fixed = TRUE),
  grepl('official 2025 SAM production run', nwwg_matches$decision_reason[4], fixed = TRUE),
  grepl('1961-2025', nwwg_matches$catch_age_evidence[5], fixed = TRUE),
  all(file.exists(file.path('source_reviews',
    c('ices_saithe_iceland_2026.md', 'ices_haddock_iceland_2026.md',
      'ices_cod_faroe_plateau_2025.md', 'ices_haddock_faroe_2025.md',
      'ices_saithe_faroe_2025.md')))),
  sum(ices_progress$inventory_rows) == 274L,
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$new) == 212L,
  sum(ices_progress$ambiguous) == 3L,
  sum(ices_progress$identity_unreviewed) == 0L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched Iceland/Faroe ICES identity and source-screening checks passed.\n')
wgcse_distinct <- register[match(c('ICES:ple.27.7h-k', 'ICES:had.27.7a',
  'ICES:cod.27.6b', 'ICES:ple.27.7bc', 'ICES:sol.27.7bc'), register$candidate_id), , drop = FALSE]
wgcse_ambiguous <- register[match(c('ICES:lez.27.4a6a', 'ICES:lez.27.6b'),
  register$candidate_id), , drop = FALSE]
stopifnot(
  !anyNA(wgcse_distinct$candidate_id),
  all(wgcse_distinct$match_status == 'new'),
  all(is.na(wgcse_distinct$matched_stock_id)),
  all(wgcse_distinct$screening_status == 'screened'),
  all(wgcse_distinct$eligibility == 'ineligible'),
  all(wgcse_distinct$import_status == 'not_started'),
  all(grepl('cross-organization reconciliation', wgcse_distinct$notes, fixed = TRUE)),
  !anyNA(wgcse_ambiguous$candidate_id),
  all(wgcse_ambiguous$match_status == 'ambiguous'),
  all(is.na(wgcse_ambiguous$matched_stock_id)),
  all(wgcse_ambiguous$screening_status == 'screened'),
  all(wgcse_ambiguous$eligibility == 'ineligible'),
  all(grepl('Lepidorhombus spp.', wgcse_ambiguous$notes, fixed = TRUE)),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$ambiguous) == 3L,
  sum(ices_progress$identity_unreviewed) == 0L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L
)
cat('ICES WGCSE identity reconciliation checks passed.\n')
dfo_plaice <- lookup('DFO:Gulf:American Plaice - NAFO 4T')
dfo_progress <- progress[progress$organization == 'DFO', , drop = FALSE]
stopifnot(
  nrow(dfo_plaice) == 1L,
  dfo_plaice$matched_stock_id == 'ck_dfo_platessoides_4t',
  dfo_plaice$match_status == 'matched',
  dfo_plaice$screening_status == 'screened',
  dfo_plaice$eligibility == 'eligible',
  dfo_plaice$import_status == 'imported',
  grepl('1976-2015', dfo_plaice$catch_age_evidence, fixed = TRUE),
  grepl('uncalibrated vessel', dfo_plaice$survey_age_evidence, fixed = TRUE),
  grepl('0.075', dfo_plaice$mortality_evidence, fixed = TRUE),
  grepl('2025 indicator update', dfo_plaice$decision_reason, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ck_dfo_platessoides_4t.md')),
  sum(dfo_progress$matched) == 20L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L
)
cat('Matched DFO Gulf American plaice source-screening checks passed.\n')
channel_plaice <- lookup('ICES:ple.27.7d')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(channel_plaice) == 1L,
  channel_plaice$matched_stock_id == 'ck_ices_wgnssk_platessa_ns_7d',
  channel_plaice$match_status == 'matched',
  channel_plaice$screening_status == 'screened',
  channel_plaice$eligibility == 'eligible',
  channel_plaice$import_status == 'imported',
  grepl('1980-2025', channel_plaice$catch_age_evidence, fixed = TRUE),
  grepl('UK BTS', channel_plaice$survey_age_evidence, fixed = TRUE),
  grepl('0.875', channel_plaice$timing_evidence, fixed = TRUE),
  grepl('N-at-age, F-at-age', channel_plaice$output_evidence, fixed = TRUE),
  grepl('native fitted-object endpoint was unavailable', channel_plaice$decision_reason, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_plaice_english_channel_7d_2026.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Division 7.d plaice source-screening checks passed.\n')
northeast_arctic_haddock <- lookup('ICES:had.27.1-2')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(northeast_arctic_haddock) == 1L,
  northeast_arctic_haddock$matched_stock_id == 'ck_ices_afwg_aeglefinus_nea_1_2',
  northeast_arctic_haddock$match_status == 'matched',
  northeast_arctic_haddock$screening_status == 'screened',
  northeast_arctic_haddock$eligibility == 'eligible',
  northeast_arctic_haddock$import_status == 'imported',
  grepl('836 residual catch-at-age', northeast_arctic_haddock$catch_age_evidence, fixed = TRUE),
  grepl('790 non-missing observations', northeast_arctic_haddock$survey_age_evidence, fixed = TRUE),
  grepl('0.133', northeast_arctic_haddock$timing_evidence, fixed = TRUE),
  grepl('fixed in the final fit', northeast_arctic_haddock$mortality_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'jrn_afwg_haddock_northeast_arctic_2026.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Northeast Arctic haddock source-screening checks passed.\n')
norpout <- lookup('ICES:nop.27.3a4')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(norpout) == 1L,
  norpout$matched_stock_id == 'ices_norway_pout_north_sea',
  norpout$match_status == 'matched',
  norpout$screening_status == 'screened',
  norpout$eligibility == 'eligible',
  norpout$import_status == 'imported',
  grepl('1984-2025 Q3', norpout$catch_age_evidence, fixed = TRUE),
  grepl('424 survey rows', norpout$survey_age_evidence, fixed = TRUE),
  grepl('not estimated by SESAM', norpout$mortality_evidence, fixed = TRUE),
  grepl('not an estimated output', norpout$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_norway_pout_north_sea.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES North Sea Norway pout source-screening checks passed.\n')
nssh <- lookup('ICES:her.27.1-24a514a')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(nssh) == 1L,
  nssh$matched_stock_id == 'ices_herring_norwegian_spring_spawning',
  nssh$match_status == 'matched',
  nssh$screening_status == 'screened',
  nssh$eligibility == 'eligible',
  nssh$import_status == 'imported',
  grepl('1950-2025', nssh$catch_age_evidence, fixed = TRUE),
  grepl('NASF acoustic', nssh$survey_age_evidence, fixed = TRUE),
  grepl('M deviations', nssh$mortality_evidence, fixed = TRUE),
  grepl('through 2026', nssh$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_herring_norwegian_spring_spawning.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Norwegian spring-spawning herring source-screening checks passed.\n')
golden_redfish <- lookup('ICES:reg.27.1-2')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(golden_redfish) == 1L,
  golden_redfish$matched_stock_id == 'ck_ices_afwg_norvegicus_deep1_2',
  golden_redfish$match_status == 'matched',
  golden_redfish$screening_status == 'screened',
  golden_redfish$eligibility == 'ineligible',
  golden_redfish$import_status == 'imported',
  grepl('total commercial landings', golden_redfish$catch_age_evidence, fixed = TRUE),
  grepl('aggregate bottom-trawl biomass index', golden_redfish$survey_age_evidence, fixed = TRUE),
  grepl('replaced the historical age-length Gadget model', golden_redfish$decision_reason, fixed = TRUE),
  grepl('B/BMSY', golden_redfish$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_golden_redfish_northeast_arctic.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Northeast Arctic golden redfish screening checks passed.\n')
gulf_riga_herring <- lookup('ICES:her.27.28')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(gulf_riga_herring) == 1L,
  gulf_riga_herring$matched_stock_id == 'ck_ices_wgbfas_harengus_bs_28_1',
  gulf_riga_herring$match_status == 'matched',
  gulf_riga_herring$screening_status == 'screened',
  gulf_riga_herring$eligibility == 'eligible',
  gulf_riga_herring$import_status == 'imported',
  grepl('1977-2025', gulf_riga_herring$catch_age_evidence, fixed = TRUE),
  grepl('GRAHS acoustic', gulf_riga_herring$survey_age_evidence, fixed = TRUE),
  grepl('0.675', gulf_riga_herring$timing_evidence, fixed = TRUE),
  grepl('conditional N/F state uncertainty', gulf_riga_herring$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_herring_gulf_riga_2026.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Gulf of Riga herring source-screening checks passed.\n')
sandeel_ids <- c('ICES:san.sa.1r', 'ICES:san.sa.2r', 'ICES:san.sa.3r')
sandeels <- register[match(sandeel_ids, register$candidate_id), , drop = FALSE]
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  !anyNA(sandeels$candidate_id),
  identical(sandeels$matched_stock_id, c('ices_sandeel_area_1r',
    'ices_sandeel_area_2r', 'ices_sandeel_area_3r')),
  all(sandeels$match_status == 'matched'),
  all(sandeels$screening_status == 'screened'),
  all(sandeels$eligibility == 'eligible'),
  all(sandeels$import_status == 'imported'),
  grepl('1983-2025', sandeels$catch_age_evidence[1], fixed = TRUE),
  grepl('RTM indices', sandeels$survey_age_evidence[1], fixed = TRUE),
  grepl('long-term multispecies averages', sandeels$mortality_evidence[2], fixed = TRUE),
  grepl('2025 source zeros are retained', sandeels$catch_age_evidence[3], fixed = TRUE),
  grepl('acoustic ages 1-4+', sandeels$survey_age_evidence[3], fixed = TRUE),
  all(file.exists(file.path('source_reviews',
    c('ices_sandeel_area_1r.md', 'ices_sandeel_area_2r.md', 'ices_sandeel_area_3r.md')))),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Sandeel Areas 1r-3r source-screening checks passed.\n')
area4_sandeel <- lookup('ICES:san.sa.4')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(area4_sandeel) == 1L,
  area4_sandeel$matched_stock_id == 'ices_sandeel_area_4',
  area4_sandeel$match_status == 'matched',
  area4_sandeel$screening_status == 'screened',
  area4_sandeel$eligibility == 'eligible',
  area4_sandeel$import_status == 'imported',
  grepl('1993-2024', area4_sandeel$catch_age_evidence, fixed = TRUE),
  grepl('Dredge and Dredge2', area4_sandeel$survey_age_evidence, fixed = TRUE),
  grepl('separate 2026 category-5 advice update', area4_sandeel$output_evidence, fixed = TRUE),
  grepl('2026 summary event separate', area4_sandeel$notes, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_sandeel_area_4.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Sandeel Area 4 source-screening checks passed.\n')
north_sea_sole <- lookup('ICES:sol.27.4')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(north_sea_sole) == 1L,
  north_sea_sole$matched_stock_id == 'ck_ices_wgnssk_solea_ns_4',
  north_sea_sole$match_status == 'matched',
  north_sea_sole$screening_status == 'screened',
  north_sea_sole$eligibility == 'unresolved',
  north_sea_sole$import_status == 'imported',
  grepl('1957-2025', north_sea_sole$catch_age_evidence, fixed = TRUE),
  grepl('aggregate BTS', north_sea_sole$survey_age_evidence, fixed = TRUE),
  grepl('not recovered', north_sea_sole$survey_age_evidence, fixed = TRUE),
  grepl('prior 2025 age-index inputs are not substituted', north_sea_sole$survey_age_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_sole_north_sea.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES North Sea sole source-screening checks passed.\n')
baltic_sole <- lookup('ICES:sol.27.20-24')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(baltic_sole) == 1L,
  baltic_sole$matched_stock_id == 'ck_ices_wgbfas_solea_ns_iiia_22_24',
  baltic_sole$match_status == 'matched',
  baltic_sole$screening_status == 'screened',
  baltic_sole$eligibility == 'eligible',
  baltic_sole$import_status == 'imported',
  grepl('1984-2025', baltic_sole$catch_age_evidence, fixed = TRUE),
  grepl('Age-specific Q4 survey indices', baltic_sole$survey_age_evidence, fixed = TRUE),
  grepl('exact timing and observation precision are not reported', baltic_sole$survey_age_evidence, fixed = TRUE),
  grepl('fixed at 0.1', baltic_sole$mortality_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_sole_20_24_2026.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Baltic sole source-screening checks passed.\n')
blue_whiting <- lookup('ICES:whb.27.1-91214')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(blue_whiting) == 1L,
  blue_whiting$matched_stock_id == 'ices_bluewhiting_northeast_atlantic',
  blue_whiting$match_status == 'matched',
  blue_whiting$screening_status == 'screened',
  blue_whiting$eligibility == 'eligible',
  blue_whiting$import_status == 'imported',
  grepl('1981-2026', blue_whiting$catch_age_evidence, fixed = TRUE),
  grepl('ages 1-8', blue_whiting$survey_age_evidence, fixed = TRUE),
  grepl('0.245', blue_whiting$timing_evidence, fixed = TRUE),
  grepl('fixed at 0.2', blue_whiting$mortality_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_bluewhiting_northeast_atlantic_2026.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES blue whiting source-screening checks passed.\n')
icelandic_summer_herring <- lookup('ICES:her.27.5a')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(icelandic_summer_herring) == 1L,
  icelandic_summer_herring$matched_stock_id == 'ck_ices_nwwg_harengus_ice_summer',
  icelandic_summer_herring$match_status == 'matched',
  icelandic_summer_herring$screening_status == 'screened',
  icelandic_summer_herring$eligibility == 'unresolved',
  icelandic_summer_herring$import_status == 'imported',
  grepl('1980-2023', icelandic_summer_herring$catch_age_evidence, fixed = TRUE),
  grepl('mapping to the production run is unresolved', icelandic_summer_herring$survey_age_evidence, fixed = TRUE),
  grepl('infection-related', icelandic_summer_herring$mortality_evidence, fixed = TRUE),
  grepl('not splice later raw catch/acoustic', icelandic_summer_herring$notes, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ck_ices_nwwg_harengus_ice_summer.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched Icelandic summer-spawning herring source-screening checks passed.\n')
baltic_sprat <- lookup('ICES:spr.27.22-32')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(baltic_sprat) == 1L,
  baltic_sprat$matched_stock_id == 'ices_sprat_baltic',
  baltic_sprat$match_status == 'matched',
  baltic_sprat$screening_status == 'screened',
  baltic_sprat$eligibility == 'eligible',
  baltic_sprat$import_status == 'imported',
  grepl('1974-2025', baltic_sprat$catch_age_evidence, fixed = TRUE),
  grepl('Four age-specific tuning fleets', baltic_sprat$survey_age_evidence, fixed = TRUE),
  grepl('cod predation', baltic_sprat$mortality_evidence, fixed = TRUE),
  grepl('confidence levels are unspecified', baltic_sprat$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_sprat_baltic.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Baltic sprat source-screening checks passed.\n')
southern_horse_mackerel <- lookup('ICES:hom.27.9a')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(southern_horse_mackerel) == 1L,
  southern_horse_mackerel$matched_stock_id == 'ck_ices_wghansa_trachurus_sp9a',
  southern_horse_mackerel$match_status == 'matched',
  southern_horse_mackerel$screening_status == 'screened',
  southern_horse_mackerel$eligibility == 'unresolved',
  southern_horse_mackerel$import_status == 'imported',
  grepl('1992-2023', southern_horse_mackerel$catch_age_evidence, fixed = TRUE),
  grepl('commercial CPUE and aggregate IBTS biomass series were not recovered',
    southern_horse_mackerel$survey_age_evidence, fixed = TRUE),
  grepl('exact sampling time', southern_horse_mackerel$timing_evidence, fixed = TRUE),
  grepl('no numerical age-specific N/F outputs', southern_horse_mackerel$output_evidence, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_horse_mackerel_9a.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Southern horse mackerel source-screening checks passed.\n')
northeast_arctic_cod <- lookup('ICES:cod.27.1-2')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(northeast_arctic_cod) == 1L,
  northeast_arctic_cod$matched_stock_id == 'ices_cod_northeast_arctic',
  northeast_arctic_cod$match_status == 'matched',
  northeast_arctic_cod$screening_status == 'screened',
  northeast_arctic_cod$eligibility == 'eligible',
  northeast_arctic_cod$import_status == 'imported',
  grepl('1946-2025', northeast_arctic_cod$catch_age_evidence, fixed = TRUE),
  grepl('five age-specific index series', northeast_arctic_cod$survey_age_evidence, fixed = TRUE),
  grepl('externally iterated cannibalism', northeast_arctic_cod$mortality_evidence, fixed = TRUE),
  grepl('2026 JRN-AFWG', northeast_arctic_cod$decision_reason, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_cod_northeast_arctic.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES Northeast Arctic cod source-screening checks passed.\n')
sole_7d <- lookup('ICES:sol.27.7d')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(sole_7d) == 1L,
  sole_7d$matched_stock_id == 'ck_ices_wgnssk_solea_ns_7d',
  sole_7d$match_status == 'matched',
  sole_7d$screening_status == 'screened',
  sole_7d$eligibility == 'eligible',
  sole_7d$import_status == 'imported',
  grepl('1982-2025', sole_7d$catch_age_evidence, fixed = TRUE),
  grepl('UK BTS indices', sole_7d$survey_age_evidence, fixed = TRUE),
  grepl('fixed at 0.1', sole_7d$mortality_evidence, fixed = TRUE),
  grepl('0.02%', sole_7d$output_evidence, fixed = TRUE),
  grepl('non-converged tinyAM fit', sole_7d$notes, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_sole_eastern_channel_7d_2026.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched ICES 7.d sole source-screening checks passed.\n')
western_baltic_herring <- lookup('ICES:her.27.20-24')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(western_baltic_herring) == 1L,
  western_baltic_herring$matched_stock_id == 'ices_herring_western_baltic',
  western_baltic_herring$match_status == 'matched',
  western_baltic_herring$screening_status == 'screened',
  western_baltic_herring$eligibility == 'eligible',
  western_baltic_herring$import_status == 'imported',
  grepl('1991-2025', western_baltic_herring$catch_age_evidence, fixed = TRUE),
  grepl('372 finite survey observations', western_baltic_herring$survey_age_evidence, fixed = TRUE),
  grepl('0.168 and 0.25', western_baltic_herring$timing_evidence, fixed = TRUE),
  grepl('0-5+', western_baltic_herring$notes, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_herring_western_baltic_2026.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched western Baltic herring source-screening checks passed.\n')
beaked_redfish <- lookup('ICES:reb.27.1-2')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(beaked_redfish) == 1L,
  beaked_redfish$matched_stock_id == 'ck_ices_afwg_mentella_deep_1_2',
  beaked_redfish$match_status == 'matched',
  beaked_redfish$screening_status == 'screened',
  beaked_redfish$eligibility == 'unresolved',
  beaked_redfish$import_status == 'imported',
  grepl('1992-2025', beaked_redfish$catch_age_evidence, fixed = TRUE),
  grepl('year class', beaked_redfish$survey_age_evidence, fixed = TRUE),
  grepl('0.05 per year', beaked_redfish$mortality_evidence, fixed = TRUE),
  grepl('JRN-AFWG 2026', beaked_redfish$decision_reason, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ck_ices_afwg_mentella_deep_1_2.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Matched Northeast Arctic beaked redfish source-screening checks passed.\n')

celtic_herring <- lookup('ICES:her.27.irls')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(celtic_herring) == 1L,
  is.na(celtic_herring$matched_stock_id),
  celtic_herring$match_status == 'new',
  celtic_herring$screening_status == 'screened',
  celtic_herring$eligibility == 'eligible',
  celtic_herring$import_status == 'not_started',
  grepl('1958-2025', celtic_herring$catch_age_evidence, fixed = TRUE),
  grepl('ages 2-7', celtic_herring$survey_age_evidence, fixed = TRUE),
  grepl('October', celtic_herring$timing_evidence, fixed = TRUE),
  grepl('unquantified mixing', celtic_herring$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'ices_celtic_herring_2026.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('ICES Celtic Sea herring source-screening checks passed.\n')

irish_herring <- lookup('ICES:her.27.nirs')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(irish_herring) == 1L,
  is.na(irish_herring$matched_stock_id),
  irish_herring$match_status == 'new',
  irish_herring$screening_status == 'screened',
  irish_herring$eligibility == 'eligible',
  irish_herring$import_status == 'not_started',
  grepl('1980-2025', irish_herring$catch_age_evidence, fixed = TRUE),
  grepl('ages 1-8+', irish_herring$survey_age_evidence, fixed = TRUE),
  grepl('borrowed from North Sea', irish_herring$mortality_evidence, fixed = TRUE),
  grepl('2.7 to 4.9', irish_herring$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'ices_irish_sea_herring_2026.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('ICES Irish Sea herring source-screening checks passed.\n')

northern_shelf_cod <- lookup('ICES:cod.27.46a7d20')
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(northern_shelf_cod) == 1L,
  northern_shelf_cod$matched_stock_id == 'ices_cod_north_sea',
  northern_shelf_cod$match_status == 'matched',
  northern_shelf_cod$screening_status == 'screened',
  northern_shelf_cod$eligibility == 'unresolved',
  northern_shelf_cod$import_status == 'not_started',
  grepl('cn_WS.dat', northern_shelf_cod$catch_age_evidence, fixed = TRUE),
  grepl('codData210926.Rdata', northern_shelf_cod$survey_age_evidence, fixed = TRUE),
  grepl('26001-26003', northern_shelf_cod$output_evidence, fixed = TRUE),
  grepl('2026-10-09', northern_shelf_cod$decision_reason, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_cod_north_sea.md')),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('ICES Northern Shelf cod 2026 source screening checks passed.\n')

reviewed_ices <- c(
  'ICES:ane.27.9aS', 'ICES:ane.27.9aW', 'ICES:cod.27.1-2.coastN',
  'ICES:cod.27.2.coastS', 'ICES:cod.27.22-24', 'ICES:her.27.25-2932',
  'ICES:her.27.3031', 'ICES:her.27.6aN', 'ICES:her.27.6aS7bc',
  'ICES:pil.27.8abd', 'ICES:ple.27.21-32', 'ICES:pok.27.1-2'
)
reviewed <- register[match(reviewed_ices, register$candidate_id), , drop = FALSE]
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(reviewed) == 12L,
  all(reviewed$screening_status == 'screened'),
  all(reviewed$import_status == 'imported'),
  identical(reviewed$eligibility, c(
    'unresolved', 'ineligible', 'eligible', 'ineligible', 'eligible',
    'eligible', 'eligible', 'ineligible', 'ineligible', 'unresolved',
    'eligible', 'eligible'
  )),
  grepl('not recovered', reviewed$survey_age_evidence[1], fixed = TRUE),
  grepl('category-3.2', reviewed$decision_reason[2], fixed = TRUE),
  grepl('1994-2025', reviewed$output_evidence[3], fixed = TRUE),
  grepl('SPiCT', reviewed$decision_reason[4], fixed = TRUE),
  grepl('central 90%', reviewed$output_evidence[5], fixed = TRUE),
  grepl('central 90%', reviewed$output_evidence[6], fixed = TRUE),
  grepl('0.75 as an explicit approximation', reviewed$timing_evidence[7], fixed = TRUE),
  grepl('survey-biomass trend', reviewed$decision_reason[8], fixed = TRUE),
  grepl('exploratory age-based', reviewed$decision_reason[9], fixed = TRUE),
  grepl('omits the production numerical input files', reviewed$decision_reason[10], fixed = TRUE),
  grepl('0.1507111', reviewed$timing_evidence[11], fixed = TRUE),
  grepl('sampling time of 0.8', reviewed$timing_evidence[12], fixed = TRUE),
  all(file.exists(file.path('source_reviews',
    c('ices_anchovy_gulf_cadiz.md', 'ices_anchovy_west_iberia_2026.md',
      'ices_cod_northern_coastal_2026.md', 'ices_cod_southern_coastal_2026.md',
      'ck_ices_wgbfas_morhua_bs.md',
      'ck_ices_wgbfas_harengus_bs_25_29_32.md',
      'ices_herring_gulf_bothnia_2026.md',
      'ck_ices_hawg_harengus_cs_6a_n.md',
      'ck_ices_hawg_harengus_cs6_a_s_7b_c.md',
      'ck_ices_wghansa_pilchardus_sp8abd.md',
      'ices_plaice_baltic_21_32_2026.md',
      'ck_ices_afwg_virens_nea_1_2.md')))),
  sum(ices_progress$matched) == 59L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
cat('Twelve previously matched ICES candidates passed source-screening checks.\n')

pacific_herring_ids <- c(
  'DFO:Pacific:Pacific Herring - Central Coast',
  'DFO:Pacific:Pacific Herring - Haida Gwaii',
  'DFO:Pacific:Pacific Herring - Prince Rupert District',
  'DFO:Pacific:Pacific Herring - West Coast of Vancouver Island'
)
pacific_herring <- register[match(pacific_herring_ids, register$candidate_id), , drop = FALSE]
stopifnot(
  nrow(pacific_herring) == 4L,
  identical(pacific_herring$official_stock_id, c('CC', 'HG', 'PRD', 'WCVI')),
  identical(pacific_herring$scientific_name, rep('Clupea pallasii', 4L)),
  identical(pacific_herring$match_status, rep('new', 4L)),
  identical(pacific_herring$screening_status, rep('screened', 4L)),
  identical(pacific_herring$eligibility, rep('ineligible', 4L)),
  identical(pacific_herring$import_status, rep('not_started', 4L)),
  all(grepl('aggregate', pacific_herring$survey_age_evidence, fixed = TRUE)),
  all(grepl('2026-014|2026-006', pacific_herring$detailed_source_url)),
  all(grepl('2026-10-29', pacific_herring$review_date, fixed = TRUE)),
  file.exists(file.path('source_reviews',
    'dfo_pacific_herring_areas_discovery.md')),
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L)
cat('DFO Pacific herring regional identity and source-screening checks passed.\n')

gulf_yellowtail <- lookup('DFO:Gulf:Yellowtail Flounder - NAFO 4T')
stopifnot(
  nrow(gulf_yellowtail) == 1L,
  is.na(gulf_yellowtail$official_stock_id),
  gulf_yellowtail$scientific_name == 'Myzopsetta ferruginea',
  gulf_yellowtail$inventory_assessment_year == 2025L,
  gulf_yellowtail$assessment_area == 'NAFO Division 4T, southern Gulf of St. Lawrence',
  gulf_yellowtail$match_status == 'new',
  is.na(gulf_yellowtail$matched_stock_id),
  gulf_yellowtail$screening_status == 'screened',
  gulf_yellowtail$eligibility == 'eligible',
  gulf_yellowtail$import_status == 'not_started',
  grepl('1985-2022', gulf_yellowtail$catch_age_evidence, fixed = TRUE),
  grepl('1985-2025', gulf_yellowtail$survey_age_evidence, fixed = TRUE),
  grepl('age-aggregated', gulf_yellowtail$survey_age_evidence, fixed = TRUE),
  grepl('4-7, 8-9 and 10+', gulf_yellowtail$mortality_evidence, fixed = TRUE),
  grepl('8,269 t', gulf_yellowtail$output_evidence, fixed = TRUE),
  grepl('2026-054', gulf_yellowtail$detailed_source_url, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'dfo_yellowtail_flounder_4t_2025.md')),
  sum(progress$new) == 663L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$screening_complete) == 905L)
cat('DFO NAFO 4T yellowtail identity and source-screening checks passed.\n')

gulf_white_hake <- lookup('DFO:Gulf:White Hake - NAFO 4T')
stopifnot(
  nrow(gulf_white_hake) == 1L,
  is.na(gulf_white_hake$official_stock_id),
  gulf_white_hake$scientific_name == 'Urophycis tenuis',
  gulf_white_hake$inventory_assessment_year == 2022L,
  gulf_white_hake$assessment_area == 'NAFO Division 4T, southern Gulf of St. Lawrence',
  gulf_white_hake$match_status == 'new',
  is.na(gulf_white_hake$matched_stock_id),
  gulf_white_hake$screening_status == 'screened',
  gulf_white_hake$eligibility == 'eligible',
  gulf_white_hake$import_status == 'not_started',
  grepl('1978-2022', gulf_white_hake$catch_age_evidence, fixed = TRUE),
  grepl('0-2', gulf_white_hake$catch_age_evidence, fixed = TRUE),
  grepl('fish/tow', gulf_white_hake$survey_age_evidence, fixed = TRUE),
  grepl('September', gulf_white_hake$timing_evidence, fixed = TRUE),
  grepl('6.1 kt', gulf_white_hake$output_evidence, fixed = TRUE),
  grepl('28963929', gulf_white_hake$detailed_source_url, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'dfo_white_hake_4t_2022.md')),
  sum(progress$new) == 663L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$screening_complete) == 905L)
cat('DFO NAFO 4T white hake identity and source-screening checks passed.\n')
noaa_sardine <- lookup('NOAA:10573')
dfo_sardine <- register[register$organization == 'DFO' &
  grepl('^DFO:Pacific:Sardine', register$candidate_id), , drop = FALSE]
pacific_sardine <- rbind(noaa_sardine, dfo_sardine)
stopifnot(
  nrow(pacific_sardine) == 2L,
  all(pacific_sardine$candidate_unit_id == 'pacific_sardine_northern_subpopulation'),
  all(pacific_sardine$match_status == 'new'),
  all(pacific_sardine$screening_status == 'screened'),
  all(pacific_sardine$eligibility == 'unresolved'),
  all(pacific_sardine$import_status == 'not_started'),
  pacific_sardine$inventory_assessment_year[1L] == 2025L,
  grepl('three commercial fleets', lookup('NOAA:10573')$catch_age_evidence, fixed = TRUE),
  grepl('not published', lookup('NOAA:10573')$catch_age_evidence, fixed = TRUE),
  grepl('age-1+ biomass', lookup('NOAA:10573')$output_evidence, fixed = TRUE),
  grepl('uses NOAA assessment biomass', dfo_sardine$decision_reason, fixed = TRUE),
  !any(stocks$scientific_name == 'Sardinops sagax'),
  file.exists(file.path('discovery', 'source_reviews',
    'pacific_sardine_northern_subpopulation_2025.md'))
)

eastern_georges_haddock <- register[
  !is.na(register$candidate_unit_id) &
    register$candidate_unit_id == 'haddock_eastern_georges_bank', , drop = FALSE
]
stopifnot(
  nrow(eastern_georges_haddock) == 2L,
  identical(sort(eastern_georges_haddock$candidate_id), sort(c(
    'DFO:Maritimes:Haddock - NAFO 5Zjm', 'NOAA:12806'
  ))),
  all(eastern_georges_haddock$match_status == 'new'),
  all(is.na(eastern_georges_haddock$matched_stock_id)),
  all(eastern_georges_haddock$screening_status == 'screened'),
  all(eastern_georges_haddock$eligibility == 'unresolved'),
  lookup('DFO:Maritimes:Haddock - NAFO 5Zjm')$official_stock_id == '5Zjm',
  lookup('DFO:Maritimes:Haddock - NAFO 5Zjm')$inventory_assessment_year == 2024L,
  lookup('NOAA:12806')$inventory_assessment_year == 2023L,
  lookup('NOAA:10520')$matched_stock_id == 'nefsc_haddock_georges_bank',
  file.exists(file.path('discovery',
    'source_reviews', 'dfo_noaa_eastern_georges_haddock.md')),
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L)
cat('Eastern Georges Bank haddock inventory crosswalk checks passed.\n')

goa_rock_sole <- register[register$candidate_unit_id %in% c(
  'noaa_goa_northern_rock_sole', 'noaa_goa_southern_rock_sole'
), , drop = FALSE]
goanrs <- goa_rock_sole[goa_rock_sole$candidate_unit_id ==
  'noaa_goa_northern_rock_sole', , drop = FALSE]
goasrs <- goa_rock_sole[goa_rock_sole$candidate_unit_id ==
  'noaa_goa_southern_rock_sole', , drop = FALSE]
stopifnot(
  nrow(goa_rock_sole) == 6L,
  identical(sort(goanrs$candidate_id), sort(c('NOAA:10836', 'NOAA:15412', 'NOAA:15413'))),
  identical(sort(goasrs$candidate_id), sort(c('NOAA:10040', 'NOAA:15414', 'NOAA:15415'))),
  all(goa_rock_sole$match_status == 'new'),
  all(goa_rock_sole$screening_status == 'screened'),
  all(goa_rock_sole$eligibility == 'ineligible'),
  lookup('NOAA:10040')$inventory_assessment_year == 2020L,
  lookup('NOAA:15414')$inventory_assessment_year == 2024L,
  lookup('NOAA:10836')$inventory_assessment_year == 2020L,
  lookup('NOAA:15412')$inventory_assessment_year == 2024L,
  all(grepl('length compositions', goa_rock_sole$catch_age_evidence, fixed = TRUE)),
  all(grepl('not catch-at-age', goa_rock_sole$catch_age_evidence, fixed = TRUE)),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_goa_northern_rock_sole.md')),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_goa_southern_rock_sole.md')),
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L)
cat('NOAA Gulf of Alaska rock sole identity and age-data screen checks passed.\n')

canary_pacific <- lookup('NOAA:10415')
stopifnot(
  nrow(canary_pacific) == 1L,
  canary_pacific$inventory_assessment_year == 2025L,
  canary_pacific$candidate_unit_id == 'noaa_stocksmart_10415',
  canary_pacific$match_status == 'new',
  is.na(canary_pacific$matched_stock_id),
  canary_pacific$screening_status == 'screened',
  canary_pacific$eligibility == 'eligible',
  canary_pacific$import_status == 'not_started',
  grepl('catch totals', canary_pacific$catch_age_evidence, fixed = TRUE),
  grepl('age-composition', canary_pacific$survey_age_evidence, fixed = TRUE),
  grepl('month 7 (July)', canary_pacific$timing_evidence, fixed = TRUE),
  grepl('2023 full assessment archive', canary_pacific$decision_reason, fixed = TRUE),
  canary_pacific$detailed_source_url == 'https://repository.library.noaa.gov/view/noaa/72904',
  lookup('DFO:Pacific:Canary Rockfish')$matched_stock_id == 'dfo_canary_bc',
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_canary_rockfish_pacific_coast.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$eligible_new) == 100L,
  sum(progress$screening_complete) == 905L)
cat('NOAA Pacific Coast Canary Rockfish identity and source-screening checks passed.\n')
english_sole <- lookup('NOAA:10046')
stopifnot(
  nrow(english_sole) == 1L,
  english_sole$inventory_assessment_year == 2013L,
  english_sole$candidate_unit_id == 'noaa_stocksmart_10046',
  english_sole$match_status == 'new',
  is.na(english_sole$matched_stock_id),
  english_sole$screening_status == 'screened',
  english_sole$eligibility == 'ineligible',
  english_sole$import_status == 'not_started',
  grepl('catch-and-survey-index-only', english_sole$catch_age_evidence, fixed = TRUE),
  grepl('does not include age-specific survey observations', english_sole$survey_age_evidence, fixed = TRUE),
  grepl('2019 catch-only projection update', english_sole$output_evidence, fixed = TRUE),
  grepl('2005/2007', english_sole$decision_reason, fixed = TRUE),
  english_sole$detailed_source_url ==
    'https://www.pcouncil.org/documents/2015/01/data-moderate-stock-assessments-for-brown-china-copper-sharpchin-stripetail-and-yellowtail-rockfishes-and-english-and-rex-soles-in-2013-published-january-2015.pdf',
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_english_sole_pacific_coast.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$excluded) == 584L,
  sum(progress$screening_complete) == 905L)
cat('NOAA Pacific Coast English Sole identity and source-screening checks passed.\n')
darkblotched <- lookup("NOAA:10562")
stopifnot(
  nrow(darkblotched) == 1L,
  darkblotched$inventory_assessment_year == 2025L,
  darkblotched$candidate_unit_id == 'noaa_stocksmart_10562',
  darkblotched$match_status == "new",
  is.na(darkblotched$matched_stock_id),
  darkblotched$screening_status == "screened",
  darkblotched$eligibility == "eligible",
  darkblotched$import_status == "not_started",
  grepl("three fleets", darkblotched$catch_age_evidence, fixed = TRUE),
  grepl("three active biomass survey-index series", darkblotched$survey_age_evidence, fixed = TRUE),
  grepl("commented out", darkblotched$survey_age_evidence, fixed = TRUE),
  grepl("fixes female natural mortality and estimates male", darkblotched$mortality_evidence, fixed = TRUE),
  grepl("2017 update", darkblotched$decision_reason, fixed = TRUE),
  grepl("2025 Stock SMART inventory year refers to a catch-only projection", darkblotched$decision_reason, fixed = TRUE),
  darkblotched$detailed_source_url == "https://www.pcouncil.org/documents/2018/01/status-of-the-darkblotched-rockfish-resource-off-the-continental-u-s-pacific-coast-in-2017-update-of-2015-assessment-model.pdf",
  file.exists(file.path("discovery", "source_reviews", "noaa_darkblotched_rockfish_pacific_coast.md")),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$eligible) == 89L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat("NOAA Pacific Coast Darkblotched Rockfish identity and source-screening checks passed.\n")
goathorny <- lookup("NOAA:10457")
stopifnot(
  nrow(goathorny) == 1L,
  goathorny$inventory_assessment_year == 2024L,
  goathorny$candidate_unit_id == 'noaa_stocksmart_10457',
  goathorny$match_status == "new",
  goathorny$screening_status == "screened",
  goathorny$eligibility == "ineligible",
  goathorny$import_status == "not_started",
  grepl("does not use catch-at-age", goathorny$catch_age_evidence, fixed = TRUE),
  grepl("regional bottom-trawl survey biomass estimates", goathorny$survey_age_evidence, fixed = TRUE),
  grepl("Natural mortality is assumed to be 0.03", goathorny$mortality_evidence, fixed = TRUE),
  grepl("59,459 t", goathorny$output_evidence, fixed = TRUE),
  grepl("age-structured assessment was suspended in 2003", goathorny$decision_reason, fixed = TRUE),
  grepl("thornyhead complex", goathorny$notes, fixed = TRUE),
  goathorny$detailed_source_url == "https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAthorny.pdf",
  file.exists(file.path("discovery", "source_reviews", "noaa_goa_thornyhead_complex_2024.md")),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(progress$new) == 663L,
  sum(progress$excluded) == 584L,
  sum(progress$screening_complete) == 905L)
cat("NOAA Gulf of Alaska Thornyhead current-method screening checks passed.\n")
shortspine <- lookup("NOAA:10458")
stopifnot(
  nrow(shortspine) == 1L,
  shortspine$inventory_assessment_year == 2025L,
  shortspine$candidate_unit_id == 'noaa_stocksmart_10458',
  shortspine$match_status == "new",
  shortspine$screening_status == "screened",
  shortspine$eligibility == "ineligible",
  shortspine$import_status == "not_started",
  grepl("does not use catch-at-age or age-composition data", shortspine$catch_age_evidence, fixed = TRUE),
  grepl("no age-composition input", shortspine$survey_age_evidence, fixed = TRUE),
  grepl("fixed at 0.04 per year for both sexes", shortspine$mortality_evidence, fixed = TRUE),
  grepl("July (month 7)", shortspine$timing_evidence, fixed = TRUE),
  grepl("derived age-specific N, catch and F outputs", shortspine$output_evidence, fixed = TRUE),
  grepl("2025 update is a catch-only projection", shortspine$decision_reason, fixed = TRUE),
  shortspine$detailed_source_url ==
    "https://www.pcouncil.org/documents/2024/02/status-of-shortspine-thornyhead-sebastolobus-alascanus-along-the-us-west-coast-in-2023.pdf; https://www.pcouncil.org/documents/shortspine-thornyhead-2023-model-files-zip-file/; https://www.pcouncil.org/documents/2025/08/g-7-attachment-3-catch-only-projection-for-shortspine-thornyhead.pdf/",
  file.exists(file.path("discovery", "source_reviews",
    "noaa_shortspine_thornyhead_pacific_coast.md")),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat("NOAA Pacific Coast Shortspine Thornyhead identity and source-screening checks passed.\n")
longspine <- lookup("NOAA:10460")
stopifnot(
  nrow(longspine) == 1L,
  longspine$inventory_assessment_year == 2019L,
  longspine$candidate_unit_id == 'noaa_stocksmart_10460',
  longspine$match_status == "new",
  longspine$screening_status == "screened",
  longspine$eligibility == "ineligible",
  longspine$import_status == "not_started",
  grepl("no age data are available", longspine$catch_age_evidence, fixed = TRUE),
  grepl("no age-composition input", longspine$survey_age_evidence, fixed = TRUE),
  grepl("fixes M at 0.1113 per year", longspine$mortality_evidence, fixed = TRUE),
  grepl("2019 update is catch-only", longspine$decision_reason, fixed = TRUE),
  grepl("DFO inventory also lists Longspine Thornyhead", longspine$notes, fixed = TRUE),
  file.exists(file.path("discovery", "source_reviews",
    "noaa_longspine_thornyhead_pacific_coast.md")),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
california_scorpionfish <- lookup("NOAA:10461")
stopifnot(
  nrow(california_scorpionfish) == 1L,
  california_scorpionfish$match_status == "new",
  is.na(california_scorpionfish$matched_stock_id),
  california_scorpionfish$screening_status == "screened",
  california_scorpionfish$eligibility == "eligible",
  california_scorpionfish$import_status == "not_started",
  grepl("CAAL data from the NWFSC trawl survey (2005-2016)", california_scorpionfish$catch_age_evidence, fixed = TRUE),
  grepl("no fishery age compositions", california_scorpionfish$catch_age_evidence, fixed = TRUE),
  grepl("ages 0-21, 2005-2016", california_scorpionfish$survey_age_evidence, fixed = TRUE),
  grepl("fixed at 0.235 per year", california_scorpionfish$mortality_evidence, fixed = TRUE),
  grepl("July (month 7; year fraction 0.5)", california_scorpionfish$timing_evidence, fixed = TRUE),
  grepl("F-at-age is derived as Z minus fixed M", california_scorpionfish$output_evidence, fixed = TRUE),
  grepl("2017-california-scorpionfish-model-files", california_scorpionfish$detailed_source_url, fixed = TRUE),
  file.exists(file.path("discovery", "source_reviews",
    "noaa_california_scorpionfish_southern_california_2017.md")),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$eligible) == 89L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(progress$new) == 663L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$screening_complete) == 905L)
cat("NOAA California Scorpionfish identity and source-screening checks passed.\n")
cat("NOAA Pacific Coast Longspine Thornyhead identity and source-screening checks passed.\n")
kelp_greenling <- lookup("NOAA:10462")
stopifnot(
  nrow(kelp_greenling) == 1L,
  kelp_greenling$match_status == "new",
  is.na(kelp_greenling$matched_stock_id),
  kelp_greenling$screening_status == "screened",
  kelp_greenling$eligibility == "eligible",
  kelp_greenling$import_status == "not_started",
  grepl("commercial age compositions (2003-2013)", kelp_greenling$catch_age_evidence, fixed = TRUE),
  grepl("recreational ocean-boat compositions (2005-2013)", kelp_greenling$catch_age_evidence, fixed = TRUE),
  grepl("Three fishery-dependent aggregate CPUE indices", kelp_greenling$survey_age_evidence, fixed = TRUE),
  grepl("No fishery-independent survey", kelp_greenling$survey_age_evidence, fixed = TRUE),
  grepl("0.360 per year for females and 0.318 for males", kelp_greenling$mortality_evidence, fixed = TRUE),
  grepl("year fraction 0.5", kelp_greenling$timing_evidence, fixed = TRUE),
  grepl("316 mt", kelp_greenling$output_evidence, fixed = TRUE),
  grepl("age-grid discrepancy", kelp_greenling$decision_reason, fixed = TRUE),
  file.exists(file.path("discovery", "source_reviews",
    "noaa_oregon_kelp_greenling_2015.md")),
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$eligible) == 89L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat("NOAA Oregon Kelp Greenling identity and source-screening checks passed.\n")
rex_sole <- register[!is.na(register$candidate_unit_id) &
  register$candidate_unit_id == "noaa_goa_rex_sole", , drop = FALSE]
rex_pacific <- lookup("NOAA:10059")
dfo_rebs <- lookup("DFO:Pacific:Rougheye Rockfish")
stopifnot(
  identical(sort(rex_sole$candidate_id), sort(c("NOAA:10058", "NOAA:15410", "NOAA:15411"))),
  nrow(rex_sole) == 3L,
  all(rex_sole$scientific_name == "Glyptocephalus zachirus"),
  all(rex_sole$match_status == "new"),
  all(rex_sole$screening_status == "screened"),
  all(rex_sole$eligibility == "eligible"),
  all(rex_sole$import_status == "not_started"),
  all(grepl("age compositions", rex_sole$catch_age_evidence, fixed = TRUE)),
  all(grepl("conditional age-at-length", rex_sole$survey_age_evidence, fixed = TRUE)),
  all(grepl("0.17 per year", rex_sole$mortality_evidence, fixed = TRUE)),
  all(grepl("Appendix F", rex_sole$output_evidence, fixed = TRUE)),
  all(grepl("2026", rex_sole$decision_reason, fixed = TRUE)),
  is.na(rex_sole$matched_stock_id),
  nrow(rex_pacific) == 1L,
  rex_pacific$candidate_unit_id == "noaa_pacific_rex_sole",
  rex_pacific$match_status == "new",
  rex_pacific$screening_status == "screened",
  rex_pacific$eligibility == "eligible",
  rex_pacific$import_status == "not_started",
  grepl("no fishery age-composition", rex_pacific$catch_age_evidence, fixed = TRUE),
  grepl("2007-2019", rex_pacific$survey_age_evidence, fixed = TRUE),
  grepl("numbers-at-age", rex_pacific$output_evidence, fixed = TRUE),
  !any(stocks$scientific_name == "Glyptocephalus zachirus"),
  file.exists(file.path("discovery", "source_reviews",
    "noaa_goa_rex_sole_2026.md")),
  file.exists(file.path("discovery", "source_reviews",
    "noaa_pacific_rex_sole_2023.md")),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(progress$new) == 663L,
  sum(progress$eligible_new) == 100L,
  sum(progress$screening_complete) == 905L)
cat("NOAA rex sole identity and source-screening checks passed.\n")
stopifnot(
  nrow(dfo_rebs) == 1L,
  dfo_rebs$match_status == "ambiguous",
  is.na(dfo_rebs$candidate_unit_id),
  is.na(dfo_rebs$official_stock_id),
  dfo_rebs$screening_status == "screened",
  dfo_rebs$eligibility == "unresolved",
  dfo_rebs$inventory_assessment_year == 2020,
  dfo_rebs$scientific_name == "Sebastes aleutianus; Sebastes melanostictus",
  grepl("weighted age proportions", dfo_rebs$catch_age_evidence, fixed = TRUE),
  grepl("WCHG", dfo_rebs$survey_age_evidence, fixed = TRUE),
  grepl("0.035, 0.045 and 0.055", dfo_rebs$mortality_evidence, fixed = TRUE),
  grepl("machine-readable run object", dfo_rebs$output_evidence, fixed = TRUE),
  grepl("two current BC units", dfo_rebs$decision_reason, fixed = TRUE),
  file.exists(file.path("discovery", "source_reviews",
    "dfo_rougheye_blackspotted_bc_2020.md")),
  sum(dfo_progress$matched) == 20L,
  sum(dfo_progress$ambiguous) == 18L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat("DFO Rougheye/Blackspotted identity and age-data screening checks passed.\n")

anchovy <- lookup("NOAA:10574")
historical_iberian_anchovy <- stocks[stocks$stock_id == "ck_ices_wghansa_mordax_sp9a", , drop = FALSE]
stopifnot(
  nrow(anchovy) == 1L,
  anchovy$candidate_unit_id == "noaa_northern_anchovy_central_subpopulation",
  anchovy$match_status == "new",
  is.na(anchovy$matched_stock_id),
  anchovy$screening_status == "screened",
  anchovy$eligibility == "eligible",
  anchovy$import_status == "not_started",
  grepl("Southern Pacific Coast", anchovy$assessment_area, fixed = TRUE),
  grepl("not direct catch numbers-at-age", anchovy$catch_age_evidence, fixed = TRUE),
  grepl("lognormal errors", anchovy$survey_age_evidence, fixed = TRUE),
  grepl("0.726, 0.931, 0.985 and 0.997", anchovy$maturity_evidence, fixed = TRUE),
  grepl("0.414 per year", anchovy$mortality_evidence, fixed = TRUE),
  grepl("2015-2021", anchovy$timing_evidence, fixed = TRUE),
  grepl("Tables 11-14", anchovy$output_evidence, fixed = TRUE),
  grepl("No numerical data have been imported", anchovy$decision_reason, fixed = TRUE),
  nrow(historical_iberian_anchovy) == 1L,
  historical_iberian_anchovy$scientific_name == "Engraulis encrasicolus",
  !any(stocks$scientific_name == "Engraulis mordax"),
  file.exists(file.path("discovery", "source_reviews",
    "noaa_northern_anchovy_central_subpopulation_2021.md")),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$eligible) == 89L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat("NOAA northern anchovy identity and source-screening checks passed.\n")

red_porgy <- lookup("NOAA:10100")
stopifnot(
  nrow(red_porgy) == 1L,
  red_porgy$candidate_unit_id == "noaa_south_atlantic_red_porgy",
  red_porgy$match_status == "new",
  is.na(red_porgy$matched_stock_id),
  red_porgy$screening_status == "screened",
  red_porgy$eligibility == "eligible",
  red_porgy$import_status == "not_started",
  grepl("1,000 lb whole weight", red_porgy$catch_age_evidence, fixed = TRUE),
  grepl("pooled length composition only", red_porgy$catch_age_evidence, fixed = TRUE),
  grepl("1973-1998", red_porgy$survey_age_evidence, fixed = TRUE),
  grepl("Table 15", red_porgy$weights_evidence, fixed = TRUE),
  grepl("0.167", red_porgy$timing_evidence, fixed = TRUE),
  grepl("Table 16", red_porgy$output_evidence, fixed = TRUE),
  grepl("digitizing published composition figures", red_porgy$decision_reason, fixed = TRUE),
  !any(stocks$scientific_name == "Pagrus pagrus"),
  file.exists(file.path("discovery", "source_reviews",
    "noaa_south_atlantic_red_porgy_2020.md"))
)
cat("NOAA South Atlantic red porgy source-screening checks passed.\n")

halibut <- lookup("DFO:Maritimes:Atlantic Halibut - NAFO 3NOPs4VWX5Z")
stopifnot(
  nrow(halibut) == 1L,
  halibut$candidate_unit_id == "dfo_atlantic_halibut_3nops4vwx5zc",
  halibut$scientific_name == "Hippoglossus hippoglossus",
  halibut$match_status == "new",
  is.na(halibut$matched_stock_id),
  halibut$screening_status == "screened",
  halibut$eligibility == "ineligible",
  halibut$import_status == "not_started",
  grepl("catch-at-length", halibut$catch_age_evidence, fixed = TRUE),
  grepl("A50=11.5", halibut$maturity_evidence, fixed = TRUE),
  grepl("time-varying natural mortality", halibut$mortality_evidence, fixed = TRUE),
  grepl("2025/003", halibut$notes, fixed = TRUE),
  grepl("one-to-one", halibut$notes, fixed = TRUE),
  !any(stocks$scientific_name == "Hippoglossus hippoglossus"),
  file.exists(file.path("discovery", "source_reviews",
    "dfo_atlantic_halibut_3nops4vwx5zc_2022.md"))
)
cat("DFO Atlantic halibut unit and catch-at-length screen checks passed.\n")

halibut_4rst <- lookup("DFO:Quebec:Atlantic Halibut - NAFO 4RST")
stopifnot(
  nrow(halibut_4rst) == 1L,
  halibut_4rst$candidate_unit_id == "dfo_atlantic_halibut_4rst",
  halibut_4rst$scientific_name == "Hippoglossus hippoglossus",
  halibut_4rst$inventory_assessment_year == 2024,
  halibut_4rst$match_status == "new",
  halibut_4rst$screening_status == "screened",
  halibut_4rst$eligibility == "ineligible",
  halibut_4rst$import_status == "not_started",
  grepl("delay-difference model", halibut_4rst$catch_age_evidence, fixed = TRUE),
  grepl("no age-specific index", halibut_4rst$survey_age_evidence, fixed = TRUE),
  grepl("2,031 trawl-survey fish", halibut_4rst$weights_evidence, fixed = TRUE),
  grepl("not run-specific documentation", halibut_4rst$maturity_evidence, fixed = TRUE),
  grepl("natural-mortality series", halibut_4rst$mortality_evidence, fixed = TRUE),
  grepl("July-September", halibut_4rst$timing_evidence, fixed = TRUE),
  grepl("exploitable biomass", halibut_4rst$output_evidence, fixed = TRUE),
  grepl("2024 assessment is a delay-difference model", halibut_4rst$decision_reason, fixed = TRUE),
  grepl("assessment-date field lists 2023", halibut_4rst$notes, fixed = TRUE),
  file.exists(file.path("discovery", "source_reviews",
    "dfo_atlantic_halibut_4rst_2024.md")),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat("DFO 4RST halibut source-screening checks passed.\n")

greenland_halibut_4rst <- lookup("DFO:Quebec:Greenland Halibut - NAFO 4RST")
stopifnot(
  nrow(greenland_halibut_4rst) == 1L,
  greenland_halibut_4rst$candidate_unit_id == "dfo_greenland_halibut_4rst",
  greenland_halibut_4rst$scientific_name == "Reinhardtius hippoglossoides",
  greenland_halibut_4rst$inventory_assessment_year == 2025,
  greenland_halibut_4rst$match_status == "new",
  is.na(greenland_halibut_4rst$matched_stock_id),
  greenland_halibut_4rst$screening_status == "screened",
  greenland_halibut_4rst$eligibility == "ineligible",
  greenland_halibut_4rst$import_status == "not_started",
  grepl("no catch-at-age", greenland_halibut_4rst$catch_age_evidence, fixed = TRUE),
  grepl("size class, not age", greenland_halibut_4rst$survey_age_evidence, fixed = TRUE),
  grepl("no run-specific weight-at-age", greenland_halibut_4rst$weights_evidence, fixed = TRUE),
  grepl("no age-specific maturity input", greenland_halibut_4rst$maturity_evidence, fixed = TRUE),
  grepl("does not estimate an age-structured natural-mortality", greenland_halibut_4rst$mortality_evidence, fixed = TRUE),
  grepl("August", greenland_halibut_4rst$timing_evidence, fixed = TRUE),
  grepl("7,320 t", greenland_halibut_4rst$output_evidence, fixed = TRUE),
  grepl("age-1 recruitment index", greenland_halibut_4rst$output_evidence, fixed = TRUE),
  grepl("2026/013", greenland_halibut_4rst$notes, fixed = TRUE),
  file.exists(file.path("discovery", "source_reviews",
    "dfo_greenland_halibut_4rst_2025_update.md")),
  !any(stocks$scientific_name == "Reinhardtius hippoglossoides"),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat("DFO 4RST Greenland halibut source-screening checks passed.\n")

greenland_halibut_2_3klmno <- lookup('DFO:Newfoundland and Labrador:Greenland Halibut (Turbot) - NAFO 2 + 3KLMNO')
stopifnot(
  nrow(greenland_halibut_2_3klmno) == 1L,
  greenland_halibut_2_3klmno$candidate_unit_id == 'dfo_greenland_halibut_2_3klmno',
  greenland_halibut_2_3klmno$scientific_name == 'Reinhardtius hippoglossoides',
  greenland_halibut_2_3klmno$inventory_assessment_year == 2025,
  greenland_halibut_2_3klmno$match_status == 'new',
  is.na(greenland_halibut_2_3klmno$matched_stock_id),
  greenland_halibut_2_3klmno$screening_status == 'screened',
  greenland_halibut_2_3klmno$eligibility == 'eligible',
  greenland_halibut_2_3klmno$import_status == 'not_started',
  grepl('1975-2021', greenland_halibut_2_3klmno$catch_age_evidence, fixed = TRUE),
  grepl('mean numbers per tow', greenland_halibut_2_3klmno$survey_age_evidence, fixed = TRUE),
  grepl('Catch weights-at-age', greenland_halibut_2_3klmno$weights_evidence, fixed = TRUE),
  grepl('proportion-mature-at-age', greenland_halibut_2_3klmno$maturity_evidence, fixed = TRUE),
  grepl('M = 0.12', greenland_halibut_2_3klmno$mortality_evidence, fixed = TRUE),
  grepl('fraction of year', greenland_halibut_2_3klmno$timing_evidence, fixed = TRUE),
  grepl('14,729 t', greenland_halibut_2_3klmno$output_evidence, fixed = TRUE),
  grepl('not the 2025 production advice fit', greenland_halibut_2_3klmno$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_greenland_halibut_2_3klmno_2025.md')),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO 2+3KLMNO Greenland halibut source-screening checks passed.\n')
herring_4rsw_spring <- lookup('DFO:Newfoundland and Labrador:Atlantic Herring - NAFO 4R (Spring Spawner)')
herring_4rsw_fall <- lookup('DFO:Newfoundland and Labrador:Atlantic Herring - NAFO 4R (Fall Spawner)')
herring_4rsw <- rbind(herring_4rsw_spring, herring_4rsw_fall)
stopifnot(
  nrow(herring_4rsw) == 2L,
  identical(herring_4rsw$candidate_unit_id,
    c('dfo_herring_4rsw_spring', 'dfo_herring_4rsw_fall')),
  identical(herring_4rsw$scientific_name, rep('Clupea harengus', 2L)),
  all(herring_4rsw$assessment_area == 'NAFO divisions 4RSw (4R and 4Sw; west coast Newfoundland and Lower North Shore Quebec)'),
  all(herring_4rsw$inventory_assessment_year == 2024),
  all(herring_4rsw$match_status == 'new'),
  all(is.na(herring_4rsw$matched_stock_id)),
  all(herring_4rsw$screening_status == 'screened'),
  all(herring_4rsw$eligibility == 'unresolved'),
  all(herring_4rsw$import_status == 'not_started'),
  all(grepl('1966-2024', herring_4rsw$catch_age_evidence, fixed = TRUE)),
  all(grepl('2019-2024', herring_4rsw$survey_age_evidence, fixed = TRUE)),
  all(grepl('component-specific weight-at-age', herring_4rsw$weights_evidence, fixed = TRUE)),
  all(grepl('assumed constant', herring_4rsw$mortality_evidence, fixed = TRUE)),
  all(grepl('within-year timing', herring_4rsw$timing_evidence, fixed = TRUE)),
  all(grepl('age-2 recruitment', herring_4rsw$output_evidence, fixed = TRUE)),
  grepl('2025/065', herring_4rsw_spring$catch_age_evidence, fixed = TRUE),
  grepl('2025/065', herring_4rsw_fall$catch_age_evidence, fixed = TRUE),
  all(grepl('WHAM state-space', herring_4rsw$decision_reason, fixed = TRUE)),
  all(grepl('4RSw', herring_4rsw$notes, fixed = TRUE)),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_herring_4rsw_2024.md')),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO 4RSw spring/fall herring source-screening checks passed.\n')
yellowtail_3lno <- lookup('DFO:Newfoundland and Labrador:Yellowtail Flounder - NAFO 3LNO')
stopifnot(
  nrow(yellowtail_3lno) == 1L,
  yellowtail_3lno$candidate_unit_id == 'dfo_yellowtail_flounder_3lno',
  yellowtail_3lno$scientific_name == 'Limanda ferruginea',
  yellowtail_3lno$assessment_area == 'NAFO divisions 3LNO',
  yellowtail_3lno$inventory_assessment_year == 2025,
  yellowtail_3lno$match_status == 'new',
  is.na(yellowtail_3lno$matched_stock_id),
  yellowtail_3lno$screening_status == 'screened',
  yellowtail_3lno$eligibility == 'ineligible',
  yellowtail_3lno$import_status == 'not_started',
  grepl('No catch-at-age', yellowtail_3lno$catch_age_evidence, fixed = TRUE),
  grepl('No age-specific survey index', yellowtail_3lno$survey_age_evidence, fixed = TRUE),
  grepl('No weight-at-age', yellowtail_3lno$weights_evidence, fixed = TRUE),
  grepl('No maturity-at-age', yellowtail_3lno$maturity_evidence, fixed = TRUE),
  grepl('no age-specific natural mortality', yellowtail_3lno$mortality_evidence, fixed = TRUE),
  grepl('B/BMSY', yellowtail_3lno$output_evidence, fixed = TRUE),
  yellowtail_3lno$detailed_source_url == 'https://www.nafo.int/Portals/0/PDFs/sc/2025/scr25-026.pdf',
  yellowtail_3lno$review_date == '2026-10-29',
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_yellowtail_flounder_3lno_2025.md')),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO 3LNO yellowtail flounder source-screening checks passed.
')
witch_3no <- lookup('DFO:Newfoundland and Labrador:Witch Flounder - NAFO 3NO')
stopifnot(
  nrow(witch_3no) == 1L,
  witch_3no$candidate_unit_id == 'dfo_witch_flounder_3no',
  witch_3no$scientific_name == 'Glyptocephalus cynoglossus',
  witch_3no$assessment_area == 'NAFO divisions 3NO',
  witch_3no$inventory_assessment_year == 2024,
  witch_3no$match_status == 'new',
  is.na(witch_3no$matched_stock_id),
  witch_3no$screening_status == 'screened',
  witch_3no$eligibility == 'ineligible',
  witch_3no$import_status == 'not_started',
  grepl('No catch-at-age', witch_3no$catch_age_evidence, fixed = TRUE),
  grepl('No age-specific survey index', witch_3no$survey_age_evidence, fixed = TRUE),
  grepl('Age-specific weights are not inputs', witch_3no$weights_evidence, fixed = TRUE),
  grepl('Age-specific maturity is not an input', witch_3no$maturity_evidence, fixed = TRUE),
  grepl('No age-specific natural mortality', witch_3no$mortality_evidence, fixed = TRUE),
  grepl('B/BMSY', witch_3no$output_evidence, fixed = TRUE),
  witch_3no$detailed_source_url == 'https://www.nafo.int/Portals/0/PDFs/sc/2024/scr24-018.pdf',
  witch_3no$review_date == '2026-10-29',
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_witch_flounder_3no_2024.md')),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO NAFO 3NO witch flounder source-screening checks passed.
')
yellowtail_5z <- lookup('DFO:Maritimes:Yellowtail Flounder - NAFO 5Z')
stopifnot(
  nrow(yellowtail_5z) == 1L,
  yellowtail_5z$scientific_name == 'Limanda ferruginea',
  yellowtail_5z$assessment_area == 'NAFO Division 5Z (Georges Bank)',
  yellowtail_5z$inventory_assessment_year == 2025,
  yellowtail_5z$match_status == 'matched',
  yellowtail_5z$matched_stock_id == 'ck_dfo_nefsc_ferruginea_gb',
  yellowtail_5z$screening_status == 'screened',
  yellowtail_5z$eligibility == 'unresolved',
  yellowtail_5z$import_status == 'imported',
  grepl('run-matched catch-at-age', yellowtail_5z$catch_age_evidence, fixed = TRUE),
  grepl('NEFSC spring/fall and DFO spring', yellowtail_5z$survey_age_evidence, fixed = TRUE),
  grepl('age-based estimated M', yellowtail_5z$mortality_evidence, fixed = TRUE),
  grepl('Aggregate catch, SSB', yellowtail_5z$output_evidence, fixed = TRUE),
  grepl('NOAA:10033', yellowtail_5z$notes, fixed = TRUE),
  grepl('Georges-Bank-Yellowtail-Flounder-Assessment-Update-2025.pdf', yellowtail_5z$detailed_source_url, fixed = TRUE),
  lookup('NOAA:10033')$matched_stock_id == yellowtail_5z$matched_stock_id,
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_yellowtail_5z_crosswalk.md')),
  sum(dfo_progress$matched) == 20L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$matched) == 107L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO 5Z yellowtail crosswalk and source-screening checks passed.
')
nl_herring <- lookup('DFO:Newfoundland and Labrador:Atlantic Herring - NAFO 2J3KLPs')
assessments <- read.csv('database/assessments.csv', stringsAsFactors = FALSE)
stopifnot(
  nrow(nl_herring) == 1L,
  nl_herring$official_stock_id == 'NAFO 2J3KLPs',
  nl_herring$scientific_name == 'Clupea harengus',
  nl_herring$inventory_assessment_year == 2025,
  is.na(nl_herring$candidate_unit_id),
  nl_herring$match_status == 'ambiguous',
  nl_herring$screening_status == 'screened',
  nl_herring$eligibility == 'ineligible',
  nl_herring$import_status == 'not_started',
  grepl('annual commercial catch numbers-at-age', nl_herring$catch_age_evidence, fixed = TRUE),
  grepl('age-4 recruitment index', nl_herring$survey_age_evidence, fixed = TRUE),
  grepl('not age-specific abundance indices', nl_herring$survey_age_evidence, fixed = TRUE),
  grepl('survey-level mean weights', nl_herring$weights_evidence, fixed = TRUE),
  grepl('maturity-at-age surface', nl_herring$maturity_evidence, fixed = TRUE),
  grepl('no population-level', nl_herring$mortality_evidence, fixed = TRUE),
  grepl('April 1 and July 31', nl_herring$timing_evidence, fixed = TRUE),
  grepl('no fitted', nl_herring$output_evidence, fixed = TRUE),
  grepl('41311899.pdf', nl_herring$detailed_source_url, fixed = TRUE),
  nl_herring$review_date == '2026-10-29',
  file.exists('discovery/source_reviews/dfo_nl_herring_3klps_2025.md'),
  !any(grepl('2J3KLPs', assessments$assessment_id, fixed = TRUE)),
  sum(dfo_progress$matched) == 20L,
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$ambiguous) == 18L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$matched) == 107L,
  sum(progress$new) == 663L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$excluded) == 584L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO Newfoundland 2J3KLPs herring source-screening checks passed.\n')

dfo_4vwx_herring_components <- register[register$candidate_id %in% c(
  'DFO:Maritimes:Atlantic Herring - Coastal Nova Scotia',
  'DFO:Maritimes:Atlantic Herring - Offshore Scotian Shelf',
  'DFO:Maritimes:Atlantic Herring - Southwest Nova Scotia / Bay of Fundy'
), , drop = FALSE]
sw_nb_migrants <- lookup(
  'DFO:Maritimes:Atlantic Herring - Southwest New Brunswick (migrant juveniles)'
)
stopifnot(
  nrow(dfo_4vwx_herring_components) == 3L,
  all(dfo_4vwx_herring_components$candidate_unit_id == 'dfo_herring_4vwx_management_unit'),
  all(dfo_4vwx_herring_components$matched_stock_id == 'ck_dfo_mar_harengus_4vwx'),
  all(dfo_4vwx_herring_components$match_status == 'matched'),
  all(dfo_4vwx_herring_components$screening_status == 'screened'),
  all(dfo_4vwx_herring_components$eligibility == 'unresolved'),
  all(dfo_4vwx_herring_components$import_status == 'imported'),
  nrow(sw_nb_migrants) == 1L,
  sw_nb_migrants$match_status == 'ambiguous',
  sw_nb_migrants$screening_status == 'screened',
  sw_nb_migrants$eligibility == 'ineligible',
  sw_nb_migrants$import_status == 'imported',
  grepl('not indicative of abundance', sw_nb_migrants$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_4vwx_herring_component_crosswalk_2025.md')),
  sum(dfo_progress$matched) == 20L,
  sum(dfo_progress$ambiguous) == 18L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$matched) == 107L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO 4VWX herring component crosswalk checks passed.\n')

dfo_mackerel <- lookup('DFO:National Capital Region:Atlantic Mackerel')
stopifnot(
  nrow(dfo_mackerel) == 1L,
  dfo_mackerel$candidate_unit_id == 'dfo_northern_contingent_atlantic_mackerel',
  dfo_mackerel$scientific_name == 'Scomber scombrus',
  dfo_mackerel$matched_stock_id == 'ck_dfo_qc_scombrus_4t',
  dfo_mackerel$match_status == 'matched',
  dfo_mackerel$screening_status == 'screened',
  dfo_mackerel$eligibility == 'eligible',
  dfo_mackerel$import_status == 'imported',
  grepl('ages 1-10+', dfo_mackerel$catch_age_evidence, fixed = TRUE),
  grepl('aggregate total egg production index', dfo_mackerel$survey_age_evidence, fixed = TRUE),
  grepl('0.28 per year', dfo_mackerel$mortality_evidence, fixed = TRUE),
  grepl('N-at-age and F-at-age', dfo_mackerel$output_evidence, fixed = TRUE),
  lookup('NOAA:10164')$matched_stock_id == 'nefsc_atlantic_mackerel',
  file.exists(file.path('source_reviews',
    'dfo_northern_mackerel_2025.md')),
  sum(dfo_progress$matched) == 20L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$matched) == 107L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO Atlantic mackerel inventory crosswalk checks passed.\n')

quebec_4s_herring <- lookup('DFO:Quebec:Atlantic Herring - Herring Fishing Area 15')
stopifnot(
  nrow(quebec_4s_herring) == 1L,
  quebec_4s_herring$candidate_unit_id == 'dfo_quebec_4s_herring',
  quebec_4s_herring$official_stock_id == paste(
    'Quebec North Shore (NAFO Division 4S) spring- and fall-spawning stocks'),
  quebec_4s_herring$scientific_name == 'Clupea harengus',
  quebec_4s_herring$inventory_assessment_year == 2024,
  is.na(quebec_4s_herring$matched_stock_id),
  quebec_4s_herring$match_status == 'ambiguous',
  quebec_4s_herring$screening_status == 'screened',
  quebec_4s_herring$eligibility == 'ineligible',
  quebec_4s_herring$import_status == 'not_started',
  grepl('through 2024', quebec_4s_herring$catch_age_evidence, fixed = TRUE),
  grepl('age-specific abundances', quebec_4s_herring$survey_age_evidence, fixed = TRUE),
  grepl('unavailable', quebec_4s_herring$mortality_evidence, fixed = TRUE),
  grepl('do not provide', quebec_4s_herring$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_quebec_herring_4s_2025.md')),
  sum(dfo_progress$ambiguous) == 18L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO Quebec North Shore herring screening checks passed.\n')

western_pollock <- lookup('DFO:Maritimes:Pollock - NAFO 4X5 (Western Component)')
stopifnot(
  nrow(western_pollock) == 1L,
  western_pollock$candidate_unit_id == 'dfo_western_component_pollock_4xopqrs5',
  western_pollock$official_stock_id == 'Western Component Pollock (4Xopqrs + 5Yb + 5Zc)',
  western_pollock$scientific_name == 'Pollachius virens',
  western_pollock$inventory_assessment_year == 2024,
  western_pollock$match_status == 'new',
  is.na(western_pollock$matched_stock_id),
  western_pollock$screening_status == 'screened',
  western_pollock$eligibility == 'eligible',
  western_pollock$import_status == 'not_started',
  grepl('ages 2-13 in 1982-2020', western_pollock$catch_age_evidence, fixed = TRUE),
  grepl('acoustic biomass-at-age', western_pollock$survey_age_evidence, fixed = TRUE),
  grepl('four-block natural-mortality matrix', western_pollock$mortality_evidence, fixed = TRUE),
  grepl('J_M4B', western_pollock$output_evidence, fixed = TRUE),
  grepl('Fs70-5-2026-025-eng.pdf', western_pollock$detailed_source_url, fixed = TRUE),
  grepl('Fs70-5-2026-029-eng.pdf', western_pollock$detailed_source_url, fixed = TRUE),
  lookup('NOAA:10515')$match_status == 'matched',
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_western_component_pollock_2022.md')),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO western-component Pollock source-screening checks passed.\n')

capelin <- lookup('DFO:Newfoundland and Labrador:Capelin - NAFO 2J3KL')
stopifnot(
  nrow(capelin) == 1L,
  capelin$candidate_unit_id == 'dfo_capelin_2j3kl',
  capelin$official_stock_id == '2J+3KL Capelin',
  capelin$scientific_name == 'Mallotus villosus',
  capelin$inventory_assessment_year == 2025,
  capelin$match_status == 'new',
  is.na(capelin$matched_stock_id),
  capelin$screening_status == 'screened',
  capelin$eligibility == 'ineligible',
  capelin$import_status == 'not_started',
  grepl('catch-at-age reconstructed', capelin$catch_age_evidence, fixed = TRUE),
  grepl('age-disaggregated abundance', capelin$survey_age_evidence, fixed = TRUE),
  grepl('ages 1-6', capelin$weights_evidence, fixed = TRUE),
  grepl('age-2 fish maturing', capelin$maturity_evidence, fixed = TRUE),
  grepl('age-specific natural-mortality assumption', capelin$mortality_evidence, fixed = TRUE),
  grepl('766 kt', capelin$output_evidence, fixed = TRUE),
  grepl('2026-025-eng.pdf', capelin$detailed_source_url, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_capelin_2j3kl_2025.md')),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$excluded) == 584L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO 2J3KL Capelin source-screening checks passed.\n')

capelin_4rst <- lookup('DFO:Newfoundland and Labrador:Capelin - NAFO 4RST')
stopifnot(
  nrow(capelin_4rst) == 1L,
  capelin_4rst$candidate_unit_id == 'dfo_capelin_4rst',
  capelin_4rst$official_stock_id == 'Estuary and Gulf of St. Lawrence Capelin (4RST)',
  capelin_4rst$scientific_name == 'Mallotus villosus',
  capelin_4rst$inventory_assessment_year == 2025,
  capelin_4rst$match_status == 'new',
  is.na(capelin_4rst$matched_stock_id),
  capelin_4rst$screening_status == 'screened',
  capelin_4rst$eligibility == 'ineligible',
  capelin_4rst$import_status == 'not_started',
  grepl('no catch-at-age series', capelin_4rst$catch_age_evidence, fixed = TRUE),
  grepl('Age data are unavailable', capelin_4rst$survey_age_evidence, fixed = TRUE),
  grepl('no weight-at-age', capelin_4rst$weights_evidence, fixed = TRUE),
  grepl('no maturity-at-age', capelin_4rst$maturity_evidence, fixed = TRUE),
  grepl('q = 0.01', capelin_4rst$mortality_evidence, fixed = TRUE),
  grepl('95% confidence intervals', capelin_4rst$output_evidence, fixed = TRUE),
  grepl('2026-014-eng.pdf', capelin_4rst$detailed_source_url, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_capelin_4rst_2025.md')),
  lookup('DFO:Newfoundland and Labrador:Capelin - NAFO 2J3KL')$candidate_unit_id ==
    'dfo_capelin_2j3kl',
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$excluded) == 584L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('DFO 4RST Capelin source-screening checks passed.\n')

albacore <- register[register$candidate_id %in% c('NOAA:11682',
  'DFO:Pacific:Albacore Tuna - North Pacific'), , drop = FALSE]
stopifnot(
  nrow(albacore) == 2L,
  length(unique(albacore$candidate_unit_id)) == 1L,
  albacore$candidate_unit_id[1] == 'north_pacific_albacore',
  all(albacore$match_status == 'new'),
  all(is.na(albacore$matched_stock_id)),
  all(albacore$screening_status == 'screened'),
  all(albacore$eligibility == 'ineligible'),
  all(albacore$import_status == 'not_started'),
  grepl('does not fit observed', albacore$catch_age_evidence[1], fixed = TRUE),
  grepl('fishery index, not a survey', albacore$survey_age_evidence[1], fixed = TRUE),
  grepl('50% at age 5', albacore$maturity_evidence[1], fixed = TRUE),
  grepl('0.38 per year', albacore$mortality_evidence[1], fixed = TRUE),
  grepl('Quarter 2', albacore$timing_evidence[1], fixed = TRUE),
  grepl('no historical numeric N-at-age table', albacore$output_evidence[1], fixed = TRUE),
  grepl('2026 ISC benchmark', albacore$decision_reason[1], fixed = TRUE),
  grepl('ISC26/ISC26_ANNEX_08', albacore$detailed_source_url[1], fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_dfo_north_pacific_albacore_2026.md')),
  sum(dfo_progress$inventory_rows) == 199L,
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$excluded) == 147L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(noaa_progress$inventory_rows) == 432L,
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$excluded) == 584L,
  sum(progress$screening_complete) == 905L)
cat('North Pacific albacore cross-agency screening checks passed.\n')

halibut <- register[register$candidate_id %in% c('NOAA:11082',
  'DFO:Pacific:Pacific Halibut'), , drop = FALSE]
stopifnot(
  nrow(halibut) == 2L,
  length(unique(halibut$candidate_unit_id)) == 1L,
  all(halibut$candidate_unit_id == 'iphc_pacific_halibut'),
  all(halibut$match_status == 'new'),
  all(is.na(halibut$matched_stock_id)),
  all(halibut$screening_status == 'screened'),
  all(halibut$eligibility == 'eligible'),
  all(halibut$import_status == 'not_started'),
  grepl('TSD-031', halibut$catch_age_evidence[1], fixed = TRUE),
  grepl('TSD-007', halibut$catch_age_evidence[1], fixed = TRUE),
  grepl('365,576', halibut$survey_age_evidence[1], fixed = TRUE),
  grepl('NPUE', halibut$survey_age_evidence[1], fixed = TRUE),
  grepl('histology', halibut$maturity_evidence[1], fixed = TRUE),
  grepl('0.15/year', halibut$mortality_evidence[1], fixed = TRUE),
  grepl('late May-September', halibut$timing_evidence[1], fixed = TRUE),
  grepl('spawning-biomass', halibut$output_evidence[1], fixed = TRUE),
  grepl('2025 assessment', halibut$decision_reason[1], fixed = TRUE),
  grepl('2026-06', halibut$catch_age_evidence[1], fixed = TRUE),
  grepl('IPHC-2026-SA-01.pdf', halibut$detailed_source_url[1], fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_dfo_pacific_halibut_iphc_2025.md')),
  sum(dfo_progress$new) == 63L,
  sum(dfo_progress$identity_unreviewed) == 98L,
  sum(dfo_progress$eligible) == 21L,
  sum(dfo_progress$eligibility_unresolved) == 31L,
  sum(dfo_progress$screening_complete) == 199L,
  sum(dfo_progress$screening_not_started) == 0L,
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligible) == 89L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
cat('Pacific halibut NOAA/DFO cross-agency screening checks passed.\n')

units <- read.csv(file.path('discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE)
halibut_unit <- units[units$candidate_unit_id == 'iphc_pacific_halibut', , drop = FALSE]
horse_mackerel <- lookup('ICES:hom.27.4bc7d')
horse_mackerel_unit <- units[units$candidate_unit_id ==
  'ices_north_sea_horse_mackerel', , drop = FALSE]
whiting_3a <- lookup('ICES:whg.27.3a')
whiting_3a_unit <- units[units$candidate_unit_id == 'ices_whiting_3a', , drop = FALSE]
redfish_3ln <- lookup('DFO:Newfoundland and Labrador:Redfish - NAFO 3LN')
redfish_3ln_unit <- units[units$candidate_unit_id == 'nafo_redfish_3ln', , drop = FALSE]
redfish_3o <- lookup('DFO:Newfoundland and Labrador:Redfish - NAFO 3O')
redfish_3o_unit <- units[units$candidate_unit_id == 'nafo_redfish_3o', , drop = FALSE]
gom_snapper <- lookup('NOAA:10230')
south_atlantic_snapper <- lookup('NOAA:10231')
lane_snapper <- lookup('NOAA:10239')
gray_triggerfish <- lookup('NOAA:10062')
south_atlantic_gray <- lookup('NOAA:10063')
greater_amberjack <- lookup('NOAA:10207')
gom_snapper_unit <- units[units$candidate_unit_id == 'noaa_gulf_red_snapper', , drop = FALSE]
gray_triggerfish_unit <- units[units$candidate_unit_id == 'noaa_gulf_gray_triggerfish', , drop = FALSE]
south_atlantic_gray_unit <- units[units$candidate_unit_id == 'noaa_south_atlantic_gray_triggerfish', , drop = FALSE]
greater_amberjack_unit <- units[units$candidate_unit_id == 'noaa_gulf_greater_amberjack', , drop = FALSE]
western_bluefin <- register[!is.na(register$candidate_unit_id) &
  register$candidate_unit_id == 'western_atlantic_bluefin_tuna', , drop = FALSE]
western_bluefin_unit <- units[!is.na(units$candidate_unit_id) &
  units$candidate_unit_id == 'western_atlantic_bluefin_tuna', , drop = FALSE]
stopifnot(
  !anyDuplicated(units$unit_key),
  sum(units$inventory_entries) == sum(!is.na(register$matched_stock_id) & nzchar(register$matched_stock_id) |
    !is.na(register$candidate_unit_id) & nzchar(register$candidate_unit_id)),
  nrow(halibut_unit) == 1L,
  halibut_unit$inventory_entries == 2L,
  halibut_unit$organizations == 'DFO | NOAA',
  halibut_unit$eligibility == 'eligible',
  nrow(horse_mackerel) == 1L,
  horse_mackerel$candidate_unit_id == 'ices_north_sea_horse_mackerel',
  horse_mackerel$match_status == 'new',
  horse_mackerel$screening_status == 'screened',
  horse_mackerel$eligibility == 'unresolved',
  horse_mackerel$import_status == 'not_started',
  grepl('hom.27.3a4bc7d', horse_mackerel$decision_reason, fixed = TRUE),
  grepl('25921', horse_mackerel$output_evidence, fixed = TRUE),
  grepl('2002-2025', horse_mackerel$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'ices_north_sea_horse_mackerel_2026.md')),
  nrow(horse_mackerel_unit) == 1L,
  horse_mackerel_unit$inventory_entries == 1L,
  horse_mackerel_unit$eligibility == 'unresolved',
  nrow(whiting_3a) == 1L,
  whiting_3a$candidate_unit_id == 'ices_whiting_3a',
  whiting_3a$match_status == 'new',
  whiting_3a$screening_status == 'screened',
  whiting_3a$eligibility == 'ineligible',
  whiting_3a$import_status == 'not_started',
  grepl('Category 3', whiting_3a$decision_reason, fixed = TRUE),
  grepl('B_index', whiting_3a$survey_age_evidence, fixed = TRUE),
  grepl('1975-2025', whiting_3a$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'ices_whiting_3a_2026.md')),
  nrow(whiting_3a_unit) == 1L,
  whiting_3a_unit$inventory_entries == 1L,
  whiting_3a_unit$eligibility == 'ineligible',
  nrow(redfish_3ln) == 1L,
  redfish_3ln$candidate_unit_id == 'nafo_redfish_3ln',
  redfish_3ln$official_stock_id == 'NAFO Divisions 3LN redfish',
  redfish_3ln$inventory_assessment_year == 2024L,
  redfish_3ln$match_status == 'new',
  redfish_3ln$screening_status == 'screened',
  redfish_3ln$eligibility == 'ineligible',
  grepl('index-based', redfish_3ln$decision_reason, fixed = TRUE),
  grepl('catch-at-length', redfish_3ln$catch_age_evidence, fixed = TRUE),
  grepl('scr25-002.pdf', redfish_3ln$detailed_source_url, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'dfo_redfish_3ln_2024.md')),
  nrow(redfish_3ln_unit) == 1L,
  redfish_3ln_unit$organizations == 'DFO',
  redfish_3ln_unit$eligibility == 'ineligible',
  nrow(redfish_3o) == 1L,
  redfish_3o$candidate_unit_id == 'nafo_redfish_3o',
  redfish_3o$official_stock_id == 'NAFO Division 3O redfish',
  redfish_3o$inventory_assessment_year == 2025L,
  redfish_3o$match_status == 'new',
  redfish_3o$screening_status == 'screened',
  redfish_3o$eligibility == 'ineligible',
  grepl('age-structured population model', redfish_3o$decision_reason, fixed = TRUE),
  grepl('length samples', redfish_3o$catch_age_evidence, fixed = TRUE),
  grepl('SCR Doc. 25/045', redfish_3o$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'dfo_redfish_3o_2025.md')),
  nrow(redfish_3o_unit) == 1L,
  redfish_3o_unit$organizations == 'DFO',
  redfish_3o_unit$eligibility == 'ineligible',
  nrow(gom_snapper) == 1L,
  gom_snapper$candidate_unit_id == 'noaa_gulf_red_snapper',
  gom_snapper$official_stock_id == '10230',
  gom_snapper$inventory_assessment_year == 2021L,
  gom_snapper$match_status == 'new',
  gom_snapper$screening_status == 'screened',
  gom_snapper$eligibility == 'eligible',
  gom_snapper$import_status == 'not_started',
  grepl('conditional age-at-length', gom_snapper$catch_age_evidence, fixed = TRUE),
  grepl('1950-2023', gom_snapper$output_evidence, fixed = TRUE),
  grepl('N-at-age or F-at-age', gom_snapper$output_evidence, fixed = TRUE),
  grepl('2021', gom_snapper$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_gulf_red_snapper_2026.md')),
  nrow(gom_snapper_unit) == 1L,
  gom_snapper_unit$inventory_entries == 1L,
  gom_snapper_unit$organizations == 'NOAA',
  gom_snapper_unit$eligibility == 'eligible',
  nrow(south_atlantic_snapper) == 1L,
  south_atlantic_snapper$candidate_unit_id == 'noaa_south_atlantic_red_snapper',
  south_atlantic_snapper$inventory_assessment_year == 2024L,
  south_atlantic_snapper$match_status == 'new',
  south_atlantic_snapper$screening_status == 'screened',
  south_atlantic_snapper$eligibility == 'eligible',
  south_atlantic_snapper$import_status == 'not_started',
  grepl('catch-age model', south_atlantic_snapper$catch_age_evidence, fixed = TRUE),
  grepl('no age-specific abundance index', south_atlantic_snapper$survey_age_evidence, fixed = TRUE),
  grepl('1-20+', south_atlantic_snapper$output_evidence, fixed = TRUE),
  grepl('1e8 eggs', south_atlantic_snapper$output_evidence, fixed = TRUE),
  grepl('SEDAR 90 is in progress', south_atlantic_snapper$decision_reason, fixed = TRUE),
  !any(stocks$scientific_name == 'Lutjanus campechanus'),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_south_atlantic_red_snapper_2024.md')),
  nrow(lane_snapper) == 1L,
  lane_snapper$candidate_unit_id == 'noaa_gulf_lane_snapper',
  lane_snapper$inventory_assessment_year == 2023L,
  lane_snapper$match_status == 'new',
  lane_snapper$screening_status == 'screened',
  lane_snapper$eligibility == 'ineligible',
  lane_snapper$import_status == 'not_started',
  grepl('2026', lane_snapper$decision_reason, fixed = TRUE),
  grepl('No age-specific', lane_snapper$decision_reason, fixed = TRUE),
  grepl('ages and lengths', lane_snapper$survey_age_evidence, fixed = TRUE),
  grepl('1,336,445 lb', lane_snapper$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_gulf_lane_snapper_2026.md')),
  nrow(gray_triggerfish) == 1L,
  gray_triggerfish$candidate_unit_id == 'noaa_gulf_gray_triggerfish',
  gray_triggerfish$inventory_assessment_year == 2020L,
  gray_triggerfish$match_status == 'new',
  is.na(gray_triggerfish$matched_stock_id),
  gray_triggerfish$screening_status == 'screened',
  gray_triggerfish$eligibility == 'eligible',
  gray_triggerfish$import_status == 'not_started',
  grepl('conditional age-at-length', gray_triggerfish$catch_age_evidence, fixed = TRUE),
  grepl('N=519', gray_triggerfish$survey_age_evidence, fixed = TRUE),
  grepl('length compositions rather than an age-composition likelihood',
    gray_triggerfish$survey_age_evidence, fixed = TRUE),
  grepl('1945-2024', gray_triggerfish$output_evidence, fixed = TRUE),
  grepl('not instantaneous F-at-age', gray_triggerfish$output_evidence, fixed = TRUE),
  grepl('formal management adoption was not confirmed', gray_triggerfish$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_gulf_gray_triggerfish_2026.md')),
  nrow(gray_triggerfish_unit) == 1L,
  gray_triggerfish_unit$organizations == 'NOAA',
  gray_triggerfish_unit$eligibility == 'eligible',
  nrow(south_atlantic_gray) == 1L,
  south_atlantic_gray$candidate_unit_id == 'noaa_south_atlantic_gray_triggerfish',
  south_atlantic_gray$inventory_assessment_year == 2016L,
  south_atlantic_gray$match_status == 'new',
  is.na(south_atlantic_gray$matched_stock_id),
  south_atlantic_gray$screening_status == 'screened',
  south_atlantic_gray$eligibility == 'unresolved',
  south_atlantic_gray$import_status == 'not_started',
  grepl('1-5+', south_atlantic_gray$catch_age_evidence, fixed = TRUE),
  grepl('1-8+', south_atlantic_gray$catch_age_evidence, fixed = TRUE),
  grepl('1990-2021', south_atlantic_gray$survey_age_evidence, fixed = TRUE),
  grepl('May-September', south_atlantic_gray$timing_evidence, fixed = TRUE),
  grepl('egg-production', south_atlantic_gray$output_evidence, fixed = TRUE),
  grepl('operational assessment', south_atlantic_gray$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_south_atlantic_gray_triggerfish_2024.md')),
  nrow(south_atlantic_gray_unit) == 1L,
  south_atlantic_gray_unit$inventory_entries == 1L,
  south_atlantic_gray_unit$organizations == 'NOAA',
  south_atlantic_gray_unit$eligibility == 'unresolved',
  nrow(greater_amberjack) == 1L,
  greater_amberjack$candidate_unit_id == 'noaa_gulf_greater_amberjack',
  greater_amberjack$inventory_assessment_year == 2021L,
  greater_amberjack$match_status == 'new',
  is.na(greater_amberjack$matched_stock_id),
  greater_amberjack$screening_status == 'screened',
  greater_amberjack$eligibility == 'unresolved',
  greater_amberjack$import_status == 'not_started',
  grepl('ages 0-10+', greater_amberjack$catch_age_evidence, fixed = TRUE),
  grepl('handline in 2001-2017', greater_amberjack$catch_age_evidence, fixed = TRUE),
  grepl('1995-1997, 2002, and 2004-2018', greater_amberjack$survey_age_evidence, fixed = TRUE),
  grepl('no greater-amberjack survey age-composition', greater_amberjack$survey_age_evidence, fixed = TRUE),
  grepl('M=0.28 per year', greater_amberjack$mortality_evidence, fixed = TRUE),
  grepl('May-November', greater_amberjack$timing_evidence, fixed = TRUE),
  grepl('1950-2018', greater_amberjack$output_evidence, fixed = TRUE),
  grepl('not instantaneous F-at-age', greater_amberjack$output_evidence, fixed = TRUE),
  grepl('Eligibility remains unresolved', greater_amberjack$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_gulf_greater_amberjack_2021.md')),
  nrow(greater_amberjack_unit) == 1L,
  greater_amberjack_unit$inventory_entries == 1L,
  greater_amberjack_unit$organizations == 'NOAA',
  greater_amberjack_unit$eligibility == 'unresolved',
  nrow(western_bluefin) == 2L,
  setequal(western_bluefin$candidate_id, c(
    'NOAA:10165',
    'DFO:National Capital Region:Bluefin Tuna - Western Atlantic')),
  all(western_bluefin$match_status == 'new'),
  all(western_bluefin$screening_status == 'screened'),
  all(western_bluefin$eligibility == 'unresolved'),
  all(western_bluefin$import_status == 'not_started'),
  all(is.na(western_bluefin$matched_stock_id)),
  !any(stocks$scientific_name == 'Thunnus thynnus'),
  grepl('Japan longline catch-at-age', western_bluefin$catch_age_evidence[1], fixed = TRUE),
  grepl('diagnostics', western_bluefin$catch_age_evidence[1], fixed = TRUE),
  grepl('age-specific survey-index likelihood', western_bluefin$survey_age_evidence[1], fixed = TRUE),
  grepl('2021 Stock Synthesis', western_bluefin$decision_reason[1], fixed = TRUE),
  grepl('VPA supplied age-specific tables', western_bluefin$decision_reason[1], fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'iccat_west_atlantic_bluefin_2021.md')),
  nrow(western_bluefin_unit) == 1L,
  western_bluefin_unit$inventory_entries == 2L,
  western_bluefin_unit$organizations == 'DFO | NOAA',
  western_bluefin_unit$eligibility == 'unresolved',
  all(c('matched_units', 'crosswalked_candidate_units', 'identity_unlinked_rows',
    'eligible_new_units', 'ineligible_new_units', 'unresolved_new_units',
    'mixed_new_units', 'other_candidate_units') %in% names(progress)),
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(progress$identity_unlinked_rows) > 0L
)
cat('Inventory unit crosswalk and distinct-unit checks passed.\n')

western_skipjack <- lookup('NOAA:10158')
western_skipjack_unit <- units[units$candidate_unit_id == 'iccat_west_atlantic_skipjack', , drop = FALSE]
noaa_sefsc <- progress[progress$organization == 'NOAA' & progress$source_region == 'SEFSC', , drop = FALSE]
stopifnot(
  nrow(western_skipjack) == 1L,
  western_skipjack$candidate_unit_id == 'iccat_west_atlantic_skipjack',
  western_skipjack$match_status == 'new',
  western_skipjack$screening_status == 'screened',
  western_skipjack$eligibility == 'ineligible',
  western_skipjack$import_status == 'not_started',
  grepl('catch-at-age was not planned', western_skipjack$catch_age_evidence, fixed = TRUE),
  grepl('five aggregate relative-abundance indices', western_skipjack$survey_age_evidence, fixed = TRUE),
  grepl('No age-specific index', western_skipjack$survey_age_evidence, fixed = TRUE),
  grepl('model is age-structured internally', western_skipjack$decision_reason, fixed = TRUE),
  grepl('Length compositions alone do not meet', western_skipjack$decision_reason, fixed = TRUE),
  grepl('1952-2020', western_skipjack$notes, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'iccat_west_atlantic_skipjack_2022.md')),
  nrow(western_skipjack_unit) == 1L,
  western_skipjack_unit$inventory_entries == 1L,
  western_skipjack_unit$organizations == 'NOAA',
  western_skipjack_unit$eligibility == 'ineligible',
  nrow(noaa_sefsc) == 1L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$excluded == 51L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('Western Atlantic skipjack screen checks passed.\n')

eastern_skipjack <- lookup('NOAA:10160')
eastern_skipjack_unit <- units[
  units$candidate_unit_id == 'iattc_eastern_pacific_skipjack', , drop = FALSE
]
noaa_swfsc <- progress[
  progress$organization == 'NOAA' & progress$source_region == 'SWFSC', , drop = FALSE
]
stopifnot(
  nrow(eastern_skipjack) == 1L,
  eastern_skipjack$candidate_unit_id == 'iattc_eastern_pacific_skipjack',
  eastern_skipjack$match_status == 'new',
  eastern_skipjack$screening_status == 'screened',
  eastern_skipjack$eligibility == 'ineligible',
  eastern_skipjack$import_status == 'not_started',
  grepl('not observed catch-at-age', eastern_skipjack$catch_age_evidence, fixed = TRUE),
  grepl('neither is age-specific', eastern_skipjack$survey_age_evidence, fixed = TRUE),
  grepl('derives age from assumed growth', eastern_skipjack$notes, fixed = TRUE),
  grepl('quarterly Stock Synthesis', eastern_skipjack$decision_reason, fixed = TRUE),
  grepl('17,809 metric tonnes', eastern_skipjack$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_eastern_pacific_skipjack_2024.md')),
  nrow(eastern_skipjack_unit) == 1L,
  eastern_skipjack_unit$inventory_entries == 1L,
  eastern_skipjack_unit$organizations == 'NOAA',
  eastern_skipjack_unit$eligibility == 'ineligible',
  nrow(noaa_swfsc) == 1L,
  noaa_swfsc$screening_complete == 6L,
  noaa_swfsc$excluded == 3L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('Eastern Pacific skipjack screen checks passed.\n')


pacific_mackerel <- lookup('NOAA:10163')
pacific_mackerel_unit <- units[
  units$candidate_unit_id == 'noaa_pacific_mackerel_pacific_coast', , drop = FALSE
]
stopifnot(
  nrow(pacific_mackerel) == 1L,
  is.na(pacific_mackerel$matched_stock_id),
  pacific_mackerel$match_status == 'new',
  pacific_mackerel$screening_status == 'screened',
  pacific_mackerel$eligibility == 'eligible',
  pacific_mackerel$import_status == 'not_started',
  grepl('age-composition likelihoods', pacific_mackerel$catch_age_evidence, fixed = TRUE),
  grepl('0-8+', pacific_mackerel$catch_age_evidence, fixed = TRUE),
  grepl('model month 1.6', pacific_mackerel$survey_age_evidence, fixed = TRUE),
  grepl('July-June', pacific_mackerel$timing_evidence, fixed = TRUE),
  grepl('not located', pacific_mackerel$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_pacific_mackerel_2025.md')),
  nrow(pacific_mackerel_unit) == 1L,
  pacific_mackerel_unit$inventory_entries == 1L,
  pacific_mackerel_unit$eligibility == 'eligible',
  nrow(noaa_swfsc) == 1L,
  noaa_swfsc$inventory_rows == 6L,
  noaa_swfsc$eligible == 2L,
  noaa_swfsc$screening_complete == 6L
)
cat('Pacific mackerel candidate screening checks passed.\n')


eastern_yellowfin <- lookup('NOAA:10168')
eastern_yellowfin_unit <- units[
  units$candidate_unit_id == 'iattc_eastern_pacific_yellowfin', , drop = FALSE
]
stopifnot(
  nrow(eastern_yellowfin) == 1L,
  is.na(eastern_yellowfin$matched_stock_id),
  eastern_yellowfin$match_status == 'new',
  eastern_yellowfin$screening_status == 'screened',
  eastern_yellowfin$eligibility == 'ineligible',
  eastern_yellowfin$import_status == 'not_started',
  grepl('does not fit observed catch-at-age', eastern_yellowfin$catch_age_evidence, fixed = TRUE),
  grepl('No age-specific abundance index', eastern_yellowfin$survey_age_evidence, fixed = TRUE),
  grepl('tagging cohort analysis', eastern_yellowfin$mortality_evidence, fixed = TRUE),
  grepl('probabilistic', eastern_yellowfin$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_eastern_pacific_yellowfin_2025.md')),
  nrow(eastern_yellowfin_unit) == 1L,
  eastern_yellowfin_unit$eligibility == 'ineligible',
  noaa_swfsc$inventory_rows == 6L,
  noaa_swfsc$new == 6L,
  noaa_swfsc$identity_unreviewed == 0L,
  noaa_swfsc$screening_not_started == 0L
)
cat('Eastern Pacific yellowfin source-screening checks passed.\n')

bocaccio <- lookup('NOAA:10413')
bocaccio_unit <- units[
  units$candidate_unit_id == 'noaa_bocaccio_southern_pacific_coast', , drop = FALSE
]
stopifnot(
  nrow(bocaccio) == 1L,
  is.na(bocaccio$matched_stock_id),
  bocaccio$candidate_unit_id == 'noaa_bocaccio_southern_pacific_coast',
  bocaccio$match_status == 'new',
  bocaccio$screening_status == 'screened',
  bocaccio$eligibility == 'eligible',
  bocaccio$import_status == 'not_started',
  grepl('conditional age-at-length', bocaccio$catch_age_evidence, fixed = TRUE),
  grepl('not direct marginal', bocaccio$catch_age_evidence, fixed = TRUE),
  grepl('Ages 0-21', bocaccio$catch_age_evidence, fixed = TRUE),
  grepl('ten aggregate abundance indices', bocaccio$survey_age_evidence, fixed = TRUE),
  grepl('fixed length-weight', bocaccio$weights_evidence, fixed = TRUE),
  grepl('maturity and fecundity relationships', bocaccio$maturity_evidence, fixed = TRUE),
  grepl('lognormal prior', bocaccio$mortality_evidence, fixed = TRUE),
  grepl('2025 catch-only projection', bocaccio$output_evidence, fixed = TRUE),
  grepl('latest fitted assessment is the 2017 update', bocaccio$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_bocaccio_southern_pacific_2017.md')),
  nrow(bocaccio_unit) == 1L,
  bocaccio_unit$inventory_entries == 1L,
  bocaccio_unit$organizations == 'NOAA',
  bocaccio_unit$eligibility == 'eligible',
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('Southern Pacific Coast bocaccio source-screening checks passed.\n')

bogoslof_pollock <- lookup('NOAA:10512')
bogoslof_pollock_unit <- units[units$candidate_unit_id == 'noaa_pollock_bogoslof', , drop = FALSE]
seo_pollock <- lookup('NOAA:10514')
seo_pollock_unit <- units[units$candidate_unit_id == 'noaa_pollock_southeast_outside', , drop = FALSE]
noaa_alaska <- progress[progress$organization == 'NOAA' & progress$source_region == 'AFSC', , drop = FALSE]
stopifnot(
  nrow(bogoslof_pollock) == 1L,
  is.na(bogoslof_pollock$matched_stock_id),
  bogoslof_pollock$match_status == 'new',
  bogoslof_pollock$screening_status == 'screened',
  bogoslof_pollock$eligibility == 'ineligible',
  bogoslof_pollock$import_status == 'not_started',
  grepl('age-structured research model', bogoslof_pollock$survey_age_evidence, fixed = TRUE),
  grepl('247,137 t', bogoslof_pollock$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_bogoslof_pollock_2024.md')),
  nrow(bogoslof_pollock_unit) == 1L,
  bogoslof_pollock_unit$inventory_entries == 1L,
  bogoslof_pollock_unit$eligibility == 'ineligible',
  nrow(seo_pollock) == 1L,
  is.na(seo_pollock$matched_stock_id),
  seo_pollock$match_status == 'new',
  seo_pollock$screening_status == 'screened',
  seo_pollock$eligibility == 'ineligible',
  seo_pollock$import_status == 'not_started',
  grepl('west of 140', seo_pollock$catch_age_evidence, fixed = TRUE),
  grepl('1990-2023', seo_pollock$survey_age_evidence, fixed = TRUE),
  grepl('43,328 t', seo_pollock$output_evidence, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_pollock_southeast_outside_2024.md')),
  nrow(seo_pollock_unit) == 1L,
  seo_pollock_unit$inventory_entries == 1L,
  seo_pollock_unit$eligibility == 'ineligible',
  nrow(noaa_alaska) == 1L,
  noaa_alaska$new == 73L,
  noaa_alaska$excluded == 67L,
  noaa_alaska$screening_complete == 89L,
  noaa_alaska$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('Bogoslof and Southeast Outside pollock source-screening checks passed.\n')

silver_hake_noaa <- register[register$candidate_id %in% c('NOAA:10521', 'NOAA:10522'), , drop = FALSE]
silver_hake_dfo <- lookup('DFO:Maritimes:Silver Hake - NAFO 4VWX')
noaa_silver_hake_units <- units[units$candidate_unit_id %in% c(
  'noaa_silver_hake_northern', 'noaa_silver_hake_southern'), , drop = FALSE]
dfo_silver_hake_unit <- units[units$candidate_unit_id == 'dfo_silver_hake_4vwx', , drop = FALSE]
noaa_nefsc <- progress[progress$organization == 'NOAA' & progress$source_region == 'NEFSC', , drop = FALSE]
dfo_maritimes <- progress[progress$organization == 'DFO' & progress$source_region == 'Maritimes', , drop = FALSE]
stopifnot(
  nrow(silver_hake_noaa) == 2L,
  all(silver_hake_noaa$scientific_name == 'Merluccius bilinearis'),
  all(silver_hake_noaa$match_status == 'new'),
  all(silver_hake_noaa$screening_status == 'screened'),
  all(silver_hake_noaa$eligibility == 'ineligible'),
  all(silver_hake_noaa$import_status == 'not_started'),
  all(grepl('not catch-at-age', silver_hake_noaa$catch_age_evidence, fixed = TRUE)),
  all(grepl('not peer reviewed in fall 2023', silver_hake_noaa$decision_reason, fixed = TRUE)),
  nrow(noaa_silver_hake_units) == 2L,
  all(noaa_silver_hake_units$organizations == 'NOAA'),
  all(noaa_silver_hake_units$eligibility == 'ineligible'),
  nrow(silver_hake_dfo) == 1L,
  silver_hake_dfo$official_stock_id == 'NAFO 4VWX',
  silver_hake_dfo$scientific_name == 'Merluccius bilinearis',
  silver_hake_dfo$match_status == 'new',
  silver_hake_dfo$screening_status == 'screened',
  silver_hake_dfo$eligibility == 'ineligible',
  grepl('published in March 2026', silver_hake_dfo$decision_reason, fixed = TRUE),
  nrow(dfo_silver_hake_unit) == 1L,
  dfo_silver_hake_unit$organizations == 'DFO',
  noaa_nefsc$inventory_rows == 55L,
  noaa_nefsc$new == 39L,
  noaa_nefsc$screening_complete == 55L,
  noaa_nefsc$screening_not_started == 0L,
  dfo_maritimes$inventory_rows == 42L,
  dfo_maritimes$new == 10L,
  dfo_maritimes$screening_complete == 42L,
  dfo_maritimes$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_silver_hake_2023.md')),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_silver_hake_4vwx_2025.md'))
)
cat('Silver hake source-screening checks passed.\n')

thorny_skate <- lookup('DFO:Newfoundland and Labrador:Thorny Skate - NAFO 3LNO')
white_hake <- lookup('DFO:Newfoundland and Labrador:White Hake - NAFO 3NOPs')
nafo_nl_units <- units[units$candidate_unit_id %in% c(
  'nafo_thorny_skate_3lnops', 'nafo_white_hake_3nops'), , drop = FALSE]
dfo_newfoundland <- progress[progress$organization == 'DFO' &
  progress$source_region == 'Newfoundland and Labrador', , drop = FALSE]
stopifnot(
  nrow(thorny_skate) == 1L,
  thorny_skate$candidate_unit_id == 'nafo_thorny_skate_3lnops',
  thorny_skate$official_stock_id == 'NAFO 3LNOPs',
  thorny_skate$scientific_name == 'Amblyraja radiata',
  thorny_skate$stock_name == 'Thorny skate - NAFO 3LNOPs',
  thorny_skate$inventory_assessment_year == 2026L,
  thorny_skate$match_status == 'new',
  thorny_skate$screening_status == 'screened',
  thorny_skate$eligibility == 'ineligible',
  grepl('not catch-at-age', thorny_skate$catch_age_evidence, fixed = TRUE),
  grepl('age-specific instantaneous', thorny_skate$mortality_evidence, fixed = TRUE),
  grepl('one biological stock', thorny_skate$decision_reason, fixed = TRUE),
  grepl('marked DRAFT', thorny_skate$notes, fixed = TRUE),
  nrow(white_hake) == 1L,
  white_hake$candidate_unit_id == 'nafo_white_hake_3nops',
  white_hake$official_stock_id == 'NAFO 3NOPs',
  white_hake$scientific_name == 'Urophycis tenuis',
  white_hake$stock_name == 'White hake - NAFO 3NOPs',
  white_hake$inventory_assessment_year == 2026L,
  white_hake$match_status == 'new',
  white_hake$screening_status == 'screened',
  white_hake$eligibility == 'ineligible',
  grepl('Age determination', white_hake$catch_age_evidence, fixed = TRUE),
  grepl('does not use age-specific', white_hake$survey_age_evidence, fixed = TRUE),
  grepl('no full assessment or interim', white_hake$decision_reason, ignore.case = TRUE),
  grepl('not to cite it', white_hake$notes, fixed = TRUE),
  nrow(nafo_nl_units) == 2L,
  all(nafo_nl_units$eligibility == 'ineligible'),
  all(nafo_nl_units$inventory_entries == 1L),
  dfo_newfoundland$inventory_rows == 23L,
  dfo_newfoundland$new == 11L,
  dfo_newfoundland$identity_unreviewed == 8L,
  dfo_newfoundland$screening_complete == 23L,
  dfo_newfoundland$screening_not_started == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_nafo_thorny_skate_2026.md')),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_nafo_white_hake_2026.md'))
)
cat('DFO thorny-skate and white-hake source-screening checks passed.\n')

inside_yelloweye <- lookup('DFO:Pacific:Yelloweye Rockfish - Inside Waters')
outside_yelloweye <- lookup('DFO:Pacific:Yelloweye Rockfish - Outside Waters')
yelloweye_units <- units[units$candidate_unit_id %in% c(
  'dfo_yelloweye_inside_bc', 'dfo_yelloweye_outside_bc'), , drop = FALSE]
dfo_pacific <- progress[progress$organization == 'DFO' &
  progress$source_region == 'Pacific', , drop = FALSE]
stopifnot(
  nrow(inside_yelloweye) == 1L,
  inside_yelloweye$candidate_unit_id == 'dfo_yelloweye_inside_bc',
  inside_yelloweye$match_status == 'new',
  inside_yelloweye$screening_status == 'screened',
  inside_yelloweye$eligibility == 'unresolved',
  grepl('one 1989 fishing trip', inside_yelloweye$catch_age_evidence, fixed = TRUE),
  grepl('survey age compositions', inside_yelloweye$survey_age_evidence, fixed = TRUE),
  nrow(outside_yelloweye) == 1L,
  outside_yelloweye$candidate_unit_id == 'dfo_yelloweye_outside_bc',
  outside_yelloweye$match_status == 'new',
  outside_yelloweye$screening_status == 'screened',
  outside_yelloweye$eligibility == 'unresolved',
  grepl('archived-information', outside_yelloweye$output_evidence, fixed = TRUE),
  nrow(yelloweye_units) == 2L,
  all(yelloweye_units$eligibility == 'unresolved'),
  nrow(dfo_pacific) == 1L,
  dfo_pacific$inventory_rows == 58L,
  dfo_pacific$new == 31L,
  dfo_pacific$identity_unreviewed == 13L,
  dfo_pacific$eligibility_unresolved == 19L,
  dfo_pacific$screening_complete == 58L,
  dfo_pacific$screening_not_started == 0L,
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_yelloweye_inside_2020.md')),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_yelloweye_outside_2024.md'))
)
cat('DFO Yelloweye Rockfish identity and source-screening checks passed.\n')
yellowmouth <- lookup('DFO:Pacific:Yellowmouth Rockfish')
yellowmouth_unit <- units[units$candidate_unit_id == 'dfo_yellowmouth_bc', , drop = FALSE]
stopifnot(
  nrow(yellowmouth) == 1L,
  yellowmouth$candidate_unit_id == 'dfo_yellowmouth_bc',
  yellowmouth$official_stock_id == 'DFO Yellowmouth Rockfish - BC coastwide',
  yellowmouth$scientific_name == 'Sebastes reedi',
  yellowmouth$assessment_area == 'PMFC areas 3CD and 5ABCDE; excludes 4B',
  yellowmouth$inventory_assessment_year == 2021L,
  yellowmouth$match_status == 'new',
  yellowmouth$screening_status == 'screened',
  yellowmouth$eligibility == 'eligible',
  yellowmouth$import_status == 'not_started',
  grepl('commercial age-frequency samples from 28 years', yellowmouth$catch_age_evidence, fixed = TRUE),
  grepl('four aggregate trawl biomass-index series', yellowmouth$survey_age_evidence, fixed = TRUE),
  grepl('five component runs', yellowmouth$mortality_evidence, fixed = TRUE),
  grepl('B2022 quantiles', yellowmouth$output_evidence, fixed = TRUE),
  grepl('41091449.pdf', yellowmouth$detailed_source_url, fixed = TRUE),
  nrow(yellowmouth_unit) == 1L,
  yellowmouth_unit$eligibility == 'eligible',
  nrow(dfo_pacific) == 1L,
  dfo_pacific$new == 31L,
  dfo_pacific$eligible_new == 2L,
  dfo_pacific$identity_unreviewed == 13L,
  dfo_pacific$eligibility_unresolved == 19L,
  dfo_pacific$screening_complete == 58L,
  dfo_pacific$screening_not_started == 0L,
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_yellowmouth_2021.md'))
)
cat('DFO Yellowmouth Rockfish assessment source-screening checks passed.\n')
inside_dogfish <- lookup('DFO:Pacific:Dogfish - Inside waters')
inside_dogfish_unit <- units[units$candidate_unit_id == 'dfo_dogfish_inside_bc', , drop = FALSE]
stopifnot(
  nrow(inside_dogfish) == 1L,
  inside_dogfish$candidate_unit_id == 'dfo_dogfish_inside_bc',
  inside_dogfish$scientific_name == 'Squalus suckleyi',
  inside_dogfish$inventory_assessment_year == 2010L,
  inside_dogfish$match_status == 'new',
  inside_dogfish$screening_status == 'screened',
  inside_dogfish$eligibility == 'ineligible',
  inside_dogfish$import_status == 'not_started',
  grepl('paucity of catch-age data', inside_dogfish$catch_age_evidence, fixed = TRUE),
  grepl('B2009', inside_dogfish$output_evidence, fixed = TRUE),
  grepl('344050.pdf', inside_dogfish$detailed_source_url, fixed = TRUE),
  nrow(inside_dogfish_unit) == 1L,
  inside_dogfish_unit$eligibility == 'ineligible',
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_dogfish_inside_2010.md')),
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  dfo_pacific$new == 31L,
  dfo_pacific$identity_unreviewed == 13L,
  dfo_pacific$eligibility_unresolved == 19L,
  dfo_pacific$screening_complete == 58L,
  dfo_pacific$screening_not_started == 0L
)
cat('DFO Inside Pacific Spiny Dogfish source-screening checks passed.\n')
noaa_sanddab <- lookup('NOAA:10190')
sanddab_unit <- units[units$candidate_unit_id == 'noaa_pacific_sanddab_us', , drop = FALSE]
noaa_progress <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(
  nrow(noaa_sanddab) == 1L,
  noaa_sanddab$candidate_unit_id == 'noaa_pacific_sanddab_us',
  noaa_sanddab$scientific_name == 'Citharichthys sordidus',
  noaa_sanddab$inventory_assessment_year == 2013L,
  noaa_sanddab$match_status == 'new',
  noaa_sanddab$screening_status == 'screened',
  noaa_sanddab$eligibility == 'unresolved',
  noaa_sanddab$import_status == 'not_started',
  grepl('age samples are from retained fish only', noaa_sanddab$catch_age_evidence, fixed = TRUE),
  grepl('conditional age-at-length', noaa_sanddab$survey_age_evidence, fixed = TRUE),
  grepl('status determination only', noaa_sanddab$output_evidence, fixed = TRUE),
  grepl('Category 3', noaa_sanddab$decision_reason, fixed = TRUE),
  nrow(sanddab_unit) == 1L,
  sanddab_unit$eligibility == 'unresolved',
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_pacific_sanddab_2013.md')),
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L)
cat('NOAA Pacific sanddab identity and source-screening checks passed.\n')
megrim_north <- lookup('ICES:meg.27.7b-k8abd')
megrim_north_unit <- units[units$candidate_unit_id == 'ices_megrim_north_7b_k8abd', , drop = FALSE]
ices_progress <- progress[progress$organization == 'ICES', , drop = FALSE]
stopifnot(
  nrow(megrim_north) == 1L,
  is.na(megrim_north$matched_stock_id),
  megrim_north$candidate_unit_id == 'ices_megrim_north_7b_k8abd',
  megrim_north$scientific_name == 'Lepidorhombus whiffiagonis',
  megrim_north$inventory_assessment_year == 2025L,
  megrim_north$match_status == 'new',
  megrim_north$screening_status == 'screened',
  megrim_north$eligibility == 'unresolved',
  megrim_north$import_status == 'not_started',
  grepl('run-matched numeric catch-age', megrim_north$catch_age_evidence, fixed = TRUE),
  grepl('G9527_G7212', megrim_north$survey_age_evidence, fixed = TRUE),
  grepl('M = 0.2', megrim_north$mortality_evidence, fixed = TRUE),
  grepl('2018', megrim_north$maturity_evidence, fixed = TRUE),
  grepl('21222', megrim_north$decision_reason, fixed = TRUE),
  grepl('23261078', megrim_north$detailed_source_url, fixed = TRUE),
  nrow(megrim_north_unit) == 1L,
  megrim_north_unit$eligibility == 'unresolved',
  file.exists(file.path('discovery', 'source_reviews',
    'ices_megrim_7b_k8abd_2025.md')),
  sum(ices_progress$inventory_rows) == 274L,
  sum(ices_progress$new) == 212L,
  sum(ices_progress$identity_unreviewed) == 0L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('ICES northern megrim source-screening checks passed.\n')

butterfish <- lookup('NOAA:10187')
butterfish_unit <- units[units$candidate_unit_id == 'noaa_butterfish_gom_cape_hatteras', , drop = FALSE]
noaa_progress <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(
  nrow(butterfish) == 1L,
  butterfish$scientific_name == 'Peprilus triacanthus',
  butterfish$inventory_assessment_year == 2024L,
  butterfish$candidate_unit_id == 'noaa_butterfish_gom_cape_hatteras',
  butterfish$match_status == 'new',
  butterfish$screening_status == 'screened',
  butterfish$eligibility == 'eligible',
  butterfish$import_status == 'not_started',
  grepl('proportions by weight', butterfish$catch_age_evidence, fixed = TRUE),
  grepl('1989-2023', butterfish$survey_age_evidence, fixed = TRUE),
  grepl('kg', butterfish$weights_evidence, fixed = TRUE),
  grepl('1989-2019', butterfish$maturity_evidence, fixed = TRUE),
  grepl('M = 1.278', butterfish$mortality_evidence, fixed = TRUE),
  grepl('spring and fall', butterfish$timing_evidence, fixed = TRUE),
  grepl('CVs', butterfish$output_evidence, fixed = TRUE),
  nrow(butterfish_unit) == 1L,
  butterfish_unit$eligibility == 'eligible',
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_butterfish_2024.md')),
  sum(noaa_progress$inventory_rows) == 432L,
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligible) == 89L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('NOAA butterfish source-screening checks passed.\n')
lingcod <- lookup('DFO:Pacific:Lingcod - Outside waters')
lingcod_unit <- units[units$candidate_unit_id == 'dfo_lingcod_outside_bc', , drop = FALSE]
dfo_pacific <- progress[progress$organization == 'DFO' & progress$source_region == 'Pacific', , drop = FALSE]
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  nrow(lingcod) == 1L,
  lingcod$scientific_name == 'Ophiodon elongatus',
  lingcod$inventory_assessment_year == 2025L,
  grepl('excluding Area 4B', lingcod$assessment_area, fixed = TRUE),
  lingcod$candidate_unit_id == 'dfo_lingcod_outside_bc',
  lingcod$match_status == 'new',
  lingcod$screening_status == 'screened',
  lingcod$eligibility == 'unresolved',
  lingcod$import_status == 'not_started',
  grepl('1996-2024', lingcod$catch_age_evidence, fixed = TRUE),
  grepl('four abundance indices', lingcod$survey_age_evidence, fixed = TRUE),
  grepl('not tabulated', lingcod$weights_evidence, fixed = TRUE),
  grepl('not provided', lingcod$maturity_evidence, fixed = TRUE),
  grepl('not given', lingcod$timing_evidence, fixed = TRUE),
  grepl('Table 1', lingcod$output_evidence, fixed = TRUE),
  nrow(lingcod_unit) == 1L,
  lingcod_unit$eligibility == 'unresolved',
  !any(stocks$stock_id == 'dfo_lingcod_outside_bc'),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_lingcod_outside_2025.md')),
  dfo_pacific$inventory_rows == 58L,
  dfo_pacific$new == 31L,
  dfo_pacific$identity_unreviewed == 13L,
  dfo_pacific$eligibility_unresolved == 19L,
  dfo_pacific$screening_complete == 58L,
  dfo_pacific$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('DFO outside lingcod source-screening checks passed.\n')
herring <- lookup('NOAA:10572')
herring_unit <- units[units$candidate_unit_id == 'noaa_atlantic_herring_gom_georges_bank', , drop = FALSE]
noaa_progress <- progress[progress$organization == 'NOAA', , drop = FALSE]
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  nrow(herring) == 1L,
  herring$official_stock_id == '10572',
  herring$scientific_name == 'Clupea harengus',
  herring$assessment_area == 'U.S. Gulf of Maine and Georges Bank stock complex',
  herring$inventory_assessment_year == 2026L,
  herring$candidate_unit_id == 'noaa_atlantic_herring_gom_georges_bank',
  herring$match_status == 'new',
  herring$screening_status == 'screened',
  herring$eligibility == 'unresolved',
  herring$import_status == 'not_started',
  grepl('proportions', herring$catch_age_evidence, fixed = TRUE),
  grepl('ages 1-8', herring$catch_age_evidence, fixed = TRUE),
  grepl('1987-2025', herring$catch_age_evidence, fixed = TRUE),
  grepl('annual index values', herring$survey_age_evidence, fixed = TRUE),
  grepl('not tabulated', herring$weights_evidence, fixed = TRUE),
  grepl('does not give its numeric value', herring$mortality_evidence, fixed = TRUE),
  grepl('timing values', herring$timing_evidence, fixed = TRUE),
  grepl('2018-2025', herring$output_evidence, fixed = TRUE),
  nrow(herring_unit) == 1L,
  herring_unit$match_status == 'new',
  herring_unit$eligibility == 'unresolved',
  herring_unit$screening_status == 'screened',
  !any(stocks$authority == 'NOAA' & stocks$authority_stock_id == '10572', na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_atlantic_herring_2026.md')),
  sum(noaa_progress$inventory_rows) == 432L,
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('NOAA Atlantic herring 2026 source-screening checks passed.\n')

spanish_mackerel <- lookup('NOAA:10173')
spanish_unit <- units[units$candidate_unit_id == 'noaa_gulf_spanish_mackerel', , drop = FALSE]
noaa_progress <- progress[progress$organization == 'NOAA', , drop = FALSE]
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  nrow(spanish_mackerel) == 1L,
  spanish_mackerel$official_stock_id == '10173',
  spanish_mackerel$scientific_name == 'Scomberomorus maculatus',
  spanish_mackerel$assessment_area == 'Gulf of Mexico',
  spanish_mackerel$inventory_assessment_year == 2023L,
  spanish_mackerel$candidate_unit_id == 'noaa_gulf_spanish_mackerel',
  spanish_mackerel$match_status == 'new',
  spanish_mackerel$screening_status == 'screened',
  spanish_mackerel$eligibility == 'unresolved',
  spanish_mackerel$import_status == 'not_started',
  grepl('conditional age-at-length', spanish_mackerel$catch_age_evidence, fixed = TRUE),
  grepl('ages 0-11', spanish_mackerel$catch_age_evidence, fixed = TRUE),
  grepl('not age-specific', spanish_mackerel$survey_age_evidence, fixed = TRUE),
  grepl('Lorenzen', spanish_mackerel$mortality_evidence, fixed = TRUE),
  grepl('1986-2021', spanish_mackerel$output_evidence, fixed = TRUE),
  nrow(spanish_unit) == 1L,
  spanish_unit$eligibility == 'unresolved',
  spanish_unit$screening_status == 'screened',
  !any(stocks$authority == 'NOAA' & stocks$authority_stock_id == '10173', na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_gulf_spanish_mackerel_2023.md')),
  sum(noaa_progress$inventory_rows) == 432L,
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('NOAA Gulf Spanish mackerel SEDAR 81 source-screening checks passed.\n')

witch_4rst <- lookup('DFO:Gulf:Witch Flounder - NAFO 4RST')
witch_4rst_unit <- units[units$candidate_unit_id == 'dfo_witch_flounder_4rst', , drop = FALSE]
dfo_gulf <- progress[progress$organization == 'DFO' & progress$source_region == 'Gulf', , drop = FALSE]
stocks <- read.csv(file.path('database', 'stocks.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  nrow(witch_4rst) == 1L,
  witch_4rst$candidate_unit_id == 'dfo_witch_flounder_4rst',
  witch_4rst$scientific_name == 'Glyptocephalus cynoglossus',
  witch_4rst$assessment_area == 'Gulf of St. Lawrence, NAFO Divisions 4RST',
  witch_4rst$inventory_assessment_year == 2022L,
  witch_4rst$match_status == 'new',
  witch_4rst$screening_status == 'screened',
  witch_4rst$eligibility == 'ineligible',
  witch_4rst$import_status == 'not_started',
  grepl('landings by gear in tonnes', witch_4rst$catch_age_evidence, fixed = TRUE),
  grepl('does not use age-specific catch', witch_4rst$catch_age_evidence, fixed = TRUE),
  grepl('three aggregate trawlable-biomass indices', witch_4rst$survey_age_evidence, fixed = TRUE),
  grepl('not age-specific', witch_4rst$survey_age_evidence, fixed = TRUE),
  grepl('does not estimate or use age-specific natural mortality', witch_4rst$mortality_evidence, fixed = TRUE),
  grepl('posterior medians', witch_4rst$output_evidence, fixed = TRUE),
  grepl('No SSB, N-at-age or F-at-age', witch_4rst$output_evidence, fixed = TRUE),
  grepl('2024 update reports interim survey indicators', witch_4rst$decision_reason, fixed = TRUE),
  nrow(witch_4rst_unit) == 1L,
  witch_4rst_unit$eligibility == 'ineligible',
  witch_4rst_unit$screening_status == 'screened',
  !any(stocks$stock_id == 'dfo_witch_flounder_4rst'),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_witch_flounder_4rst_2022.md')),
  dfo_gulf$inventory_rows == 13L,
  dfo_gulf$new == 4L,
  dfo_gulf$identity_unreviewed == 4L,
  dfo_gulf$excluded == 6L,
  dfo_gulf$eligibility_unresolved == 0L,
  dfo_gulf$screening_complete == 13L,
  dfo_gulf$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('DFO 4RST witch flounder assessment screening checks passed.\n')

quillback_register <- read.csv(file.path('discovery', 'candidates.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
quillback_units <- read.csv(file.path('discovery', 'inventory_units.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
quillback_progress <- read.csv(file.path('discovery', 'inventory_progress.csv'),
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
inside_quillback <- quillback_register[
  quillback_register$candidate_id == 'DFO:Pacific:Quillback Rockfish - Inside waters', , drop = FALSE]
outside_quillback <- quillback_register[
  quillback_register$candidate_id == 'DFO:Pacific:Quillback Rockfish - Outside waters', , drop = FALSE]
inside_quillback_unit <- quillback_units[
  !is.na(quillback_units$candidate_unit_id) &
    quillback_units$candidate_unit_id == 'dfo_quillback_inside', , drop = FALSE]
outside_quillback_unit <- quillback_units[
  !is.na(quillback_units$candidate_unit_id) &
    quillback_units$candidate_unit_id == 'dfo_quillback_outside', , drop = FALSE]
dfo_summary <- quillback_progress[quillback_progress$organization == 'DFO', , drop = FALSE]
dfo_pacific_summary <- quillback_progress[
  quillback_progress$organization == 'DFO' & quillback_progress$source_region == 'Pacific', , drop = FALSE]
stopifnot(
  nrow(inside_quillback) == 1L,
  inside_quillback$candidate_unit_id == 'dfo_quillback_inside',
  inside_quillback$scientific_name == 'Sebastes maliger',
  inside_quillback$inventory_assessment_year == 2021L,
  inside_quillback$match_status == 'new',
  inside_quillback$screening_status == 'screened',
  inside_quillback$eligibility == 'unresolved',
  inside_quillback$import_status == 'not_started',
  grepl('1984-1994', inside_quillback$catch_age_evidence, fixed = TRUE),
  grepl('2000-2001', inside_quillback$catch_age_evidence, fixed = TRUE),
  grepl('Age-composition likelihoods', inside_quillback$survey_age_evidence, fixed = TRUE),
  grepl('0.055, 0.067, and 0.088', inside_quillback$mortality_evidence, fixed = TRUE),
  nrow(outside_quillback) == 1L,
  outside_quillback$candidate_unit_id == 'dfo_quillback_outside',
  outside_quillback$scientific_name == 'Sebastes maliger',
  outside_quillback$inventory_assessment_year == 2021L,
  outside_quillback$match_status == 'new',
  outside_quillback$screening_status == 'screened',
  outside_quillback$eligibility == 'unresolved',
  outside_quillback$import_status == 'not_started',
  grepl('age compositions from fisheries and surveys', outside_quillback$catch_age_evidence, fixed = TRUE),
  grepl('0.046 and 0.056', outside_quillback$mortality_evidence, fixed = TRUE),
  nrow(inside_quillback_unit) == 1L,
  inside_quillback_unit$match_status == 'new',
  inside_quillback_unit$eligibility == 'unresolved',
  inside_quillback_unit$screening_status == 'screened',
  nrow(outside_quillback_unit) == 1L,
  outside_quillback_unit$match_status == 'new',
  outside_quillback_unit$eligibility == 'unresolved',
  outside_quillback_unit$screening_status == 'screened',
  !any(stocks$stock_id %in% c('dfo_quillback_inside', 'dfo_quillback_outside')),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_quillback_inside_2021.md')),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_quillback_outside_2021.md')),
  sum(dfo_summary$inventory_rows) == 199L,
  sum(dfo_summary$new) == 63L,
  sum(dfo_summary$identity_unreviewed) == 98L,
  sum(dfo_summary$eligibility_unresolved) == 31L,
  sum(dfo_summary$screening_complete) == 199L,
  sum(dfo_summary$screening_not_started) == 0L,
  dfo_pacific_summary$inventory_rows == 58L,
  dfo_pacific_summary$new == 31L,
  dfo_pacific_summary$eligibility_unresolved == 19L,
  dfo_pacific_summary$screening_complete == 58L,
  dfo_pacific_summary$screening_not_started == 0L,
  nrow(quillback_units) == 736L,
  sum(quillback_units$inventory_entries) == 775L,
  sum(!is.na(quillback_units$candidate_unit_id) & nzchar(quillback_units$candidate_unit_id)) == 636L)
cat('DFO Inside and Outside Quillback source-screening checks passed.\n')

longspine <- register[
  register$candidate_id == 'DFO:Pacific:Longspine Thornyhead', , drop = FALSE]
longspine_unit <- quillback_units[
  !is.na(quillback_units$candidate_unit_id) &
    quillback_units$candidate_unit_id == 'dfo_longspine_thornyhead_bc', , drop = FALSE]
stopifnot(
  nrow(longspine) == 1L,
  longspine$candidate_unit_id == 'dfo_longspine_thornyhead_bc',
  longspine$scientific_name == 'Sebastolobus altivelis',
  is.na(longspine$inventory_assessment_year),
  longspine$match_status == 'new',
  longspine$screening_status == 'screened',
  longspine$eligibility == 'ineligible',
  longspine$import_status == 'not_started',
  grepl('34,488', longspine$catch_age_evidence, fixed = TRUE),
  grepl('none aged', longspine$catch_age_evidence, fixed = TRUE),
  grepl('age-specific survey index', longspine$survey_age_evidence, fixed = TRUE),
  grepl('Fs97-6-3722-eng.pdf', longspine$detailed_source_url, fixed = TRUE),
  grepl('no current age', longspine$decision_reason, fixed = TRUE),
  grepl('redirected to an archived-information notice', longspine$notes, fixed = TRUE),
  nrow(longspine_unit) == 1L,
  longspine_unit$match_status == 'new',
  longspine_unit$eligibility == 'ineligible',
  longspine_unit$screening_status == 'screened',
  !any(stocks$scientific_name == 'Sebastolobus altivelis' &
    grepl('longspine', tolower(stocks$common_name)), na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_longspine_thornyhead_bc.md')),
  sum(dfo_summary$new) == 63L,
  sum(dfo_summary$identity_unreviewed) == 98L,
  sum(dfo_summary$excluded) == 147L,
  sum(dfo_summary$eligibility_unresolved) == 31L,
  sum(dfo_summary$screening_complete) == 199L,
  sum(dfo_summary$screening_not_started) == 0L,
  dfo_pacific_summary$new == 31L,
  dfo_pacific_summary$excluded == 32L,
  dfo_pacific_summary$eligibility_unresolved == 19L,
  dfo_pacific_summary$screening_complete == 58L,
  dfo_pacific_summary$screening_not_started == 0L,
  nrow(quillback_units) == 736L,
  sum(quillback_units$inventory_entries) == 775L,
  sum(!is.na(quillback_units$candidate_unit_id) & nzchar(quillback_units$candidate_unit_id)) == 636L)
cat('DFO British Columbia Longspine Thornyhead screening checks passed.\n')

greenland_halibut_0 <- register[
  register$candidate_id == 'DFO:Arctic:Greenland Halibut - NAFO 0A and 0B', , drop = FALSE]
greenland_halibut_0_unit <- quillback_units[
  !is.na(quillback_units$candidate_unit_id) &
    quillback_units$candidate_unit_id == 'greenland_halibut_sa0_1_offshore', , drop = FALSE]
dfo_arctic_summary <- quillback_progress[
  quillback_progress$organization == 'DFO' &
    quillback_progress$source_region == 'Arctic', , drop = FALSE]
stopifnot(
  nrow(greenland_halibut_0) == 1L,
  greenland_halibut_0$candidate_unit_id == 'greenland_halibut_sa0_1_offshore',
  is.na(greenland_halibut_0$official_stock_id),
  greenland_halibut_0$scientific_name == 'Reinhardtius hippoglossoides',
  greenland_halibut_0$inventory_assessment_year == 2025L,
  greenland_halibut_0$match_status == 'new',
  greenland_halibut_0$screening_status == 'screened',
  greenland_halibut_0$eligibility == 'ineligible',
  greenland_halibut_0$import_status == 'not_started',
  grepl('aggregate commercial catch', greenland_halibut_0$catch_age_evidence, fixed = TRUE),
  grepl('age-1 abundance indicator', greenland_halibut_0$survey_age_evidence, fixed = TRUE),
  grepl('not an age-composition', greenland_halibut_0$survey_age_evidence, fixed = TRUE),
  grepl('no age-specific', greenland_halibut_0$mortality_evidence, fixed = TRUE),
  grepl('no fitted N-at-age or F-at-age', greenland_halibut_0$output_evidence, fixed = TRUE),
  grepl('full production assessment is an aggregate SPiCT model',
    greenland_halibut_0$decision_reason, fixed = TRUE),
  grepl('Cumberland Sound', greenland_halibut_0$notes, fixed = TRUE),
  nrow(greenland_halibut_0_unit) == 1L,
  greenland_halibut_0_unit$eligibility == 'ineligible',
  greenland_halibut_0_unit$screening_status == 'screened',
  !any(stocks$scientific_name == 'Reinhardtius hippoglossoides' &
    grepl('NAFO Subarea 0|0A.*0B|0\\+1 offshore',
      paste(stocks$area, stocks$region, stocks$notes), ignore.case = TRUE), na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_greenland_halibut_0a0b_2025.md')),
  dfo_arctic_summary$inventory_rows == 23L,
  dfo_arctic_summary$new == 2L,
  dfo_arctic_summary$identity_unreviewed == 18L,
  dfo_arctic_summary$excluded == 22L,
  dfo_arctic_summary$eligibility_unresolved == 1L,
  dfo_arctic_summary$screening_complete == 23L,
  dfo_arctic_summary$screening_not_started == 0L,
  dfo_arctic_summary$crosswalked_candidate_units == 2L,
  dfo_arctic_summary$identity_unlinked_rows == 21L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(quillback_units) == 736L,
  sum(quillback_units$inventory_entries) == 775L,
  sum(!is.na(quillback_units$candidate_unit_id) & nzchar(quillback_units$candidate_unit_id)) == 636L)
cat('DFO Greenland halibut Subarea 0 screening checks passed.\n')

cambridge_char <- lookup('DFO:Arctic:Arctic Char - Cambridge Bay')
cambridge_char_cache <- file.path('source_cache',
  'discovery_dfo_arctic_char_cambridge_bay_2026')
stopifnot(
  nrow(cambridge_char) == 1L,
  is.na(cambridge_char$candidate_unit_id),
  is.na(cambridge_char$official_stock_id),
  cambridge_char$scientific_name == 'Salvelinus alpinus',
  cambridge_char$inventory_assessment_year == 2021L,
  cambridge_char$match_status == 'ambiguous',
  cambridge_char$screening_status == 'screened',
  cambridge_char$eligibility == 'ineligible',
  cambridge_char$import_status == 'not_started',
  grepl('does not use catch numbers-at-age', cambridge_char$catch_age_evidence, fixed = TRUE),
  grepl('no age-specific abundance index', cambridge_char$survey_age_evidence, fixed = TRUE),
  grepl('age-at-maturity', cambridge_char$maturity_evidence, fixed = TRUE),
  grepl('not estimated as part of an age-structured population model',
    cambridge_char$mortality_evidence, fixed = TRUE),
  grepl('does not provide fitted population N-at-age', cambridge_char$output_evidence, fixed = TRUE),
  grepl('five current commercial river waterbodies', cambridge_char$notes, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_arctic_char_cambridge_bay.md')),
  !any(stocks$scientific_name == 'Salvelinus alpinus' &
    grepl('Cambridge Bay|Halokvik|Jayko|Lauchlan|Ekalluk|Paliryuak',
      paste(stocks$area, stocks$region, stocks$notes), ignore.case = TRUE), na.rm = TRUE),
  dfo_arctic_summary$ambiguous == 3L,
  dfo_arctic_summary$identity_unreviewed == 18L,
  dfo_arctic_summary$excluded == 22L,
  dfo_arctic_summary$eligibility_unresolved == 1L,
  dfo_arctic_summary$screening_complete == 23L,
  dfo_arctic_summary$screening_not_started == 0L,
  dfo_arctic_summary$crosswalked_candidate_units == 2L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(quillback_units) == 736L,
  sum(quillback_units$inventory_entries) == 775L,
  sum(!is.na(quillback_units$candidate_unit_id) & nzchar(quillback_units$candidate_unit_id)) == 636L)
if (dir.exists(cambridge_char_cache)) {
  cambridge_char_sources <- read.csv(file.path(cambridge_char_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  stopifnot(
    nrow(cambridge_char_sources) == 5L,
    all(file.exists(file.path(cambridge_char_cache, cambridge_char_sources$file_name)))
  )
}
cat('DFO Cambridge Bay Arctic Char screening checks passed.\n')

cumberland_char <- lookup('DFO:Arctic:Arctic Char - Cumberland Sound')
cumberland_char_cache <- file.path('source_cache',
  'discovery_dfo_arctic_char_cumberland_sound_2026')
stopifnot(
  nrow(cumberland_char) == 1L,
  is.na(cumberland_char$candidate_unit_id),
  is.na(cumberland_char$official_stock_id),
  cumberland_char$scientific_name == 'Salvelinus alpinus',
  cumberland_char$inventory_assessment_year == 2017L,
  cumberland_char$match_status == 'ambiguous',
  cumberland_char$screening_status == 'screened',
  cumberland_char$eligibility == 'ineligible',
  cumberland_char$import_status == 'not_started',
  grepl('does not provide or fit catch numbers-at-age',
    cumberland_char$catch_age_evidence, fixed = TRUE),
  grepl('not used in the quantitative model',
    cumberland_char$survey_age_evidence, fixed = TRUE),
  grepl('No numerical population weight-at-age',
    cumberland_char$weights_evidence, fixed = TRUE),
  grepl('does not provide a run-matched maturity-at-age vector',
    cumberland_char$maturity_evidence, fixed = TRUE),
  grepl('does not separate age-specific fishing and natural',
    cumberland_char$mortality_evidence, fixed = TRUE),
  grepl('does not report annual N-at-age',
    cumberland_char$output_evidence, fixed = TRUE),
  grepl('Baranov, Catch-MSY and depletion-corrected',
    cumberland_char$decision_reason, fixed = TRUE),
  grepl('Ijaruvung Lake (PG003)', cumberland_char$notes, fixed = TRUE),
  grepl('Iqalujjuaq Fiord (PG027)', cumberland_char$notes, fixed = TRUE),
  grepl('Irvine Inlet (PG018)', cumberland_char$notes, fixed = TRUE),
  grepl('Ikaluit Lake (Robert Peel Inlet)', cumberland_char$notes, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_arctic_char_cumberland_sound.md')),
  !any(stocks$scientific_name == 'Salvelinus alpinus' &
    grepl('Ijaruvung|Iqalujjuaq|Irvine Inlet',
      paste(stocks$scientific_name, stocks$area, stocks$region, stocks$notes),
      ignore.case = TRUE), na.rm = TRUE),
  dfo_arctic_summary$ambiguous == 3L,
  dfo_arctic_summary$identity_unreviewed == 18L,
  dfo_arctic_summary$excluded == 22L,
  dfo_arctic_summary$eligibility_unresolved == 1L,
  dfo_arctic_summary$screening_complete == 23L,
  dfo_arctic_summary$screening_not_started == 0L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
if (dir.exists(cumberland_char_cache)) {
  cumberland_char_sources <- read.csv(file.path(cumberland_char_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  stopifnot(
    nrow(cumberland_char_sources) == 6L,
    all(file.exists(file.path(cumberland_char_cache, cumberland_char_sources$file_name)))
  )
}
cat('DFO Cumberland Sound Arctic Char screening checks passed.\n')

cumberland_halibut <- lookup(
  'DFO:Arctic:Greenland Halibut - Cumberland Sound Turbot Management Area')
cumberland_halibut_cache <- file.path('source_cache',
  'discovery_dfo_greenland_halibut_cumberland_sound_2026')
stopifnot(
  nrow(cumberland_halibut) == 1L,
  cumberland_halibut$candidate_unit_id == 'greenland_halibut_cumberland_sound_tma',
  is.na(cumberland_halibut$official_stock_id),
  cumberland_halibut$scientific_name == 'Reinhardtius hippoglossoides',
  cumberland_halibut$inventory_assessment_year == 2019L,
  cumberland_halibut$match_status == 'new',
  cumberland_halibut$screening_status == 'screened',
  cumberland_halibut$eligibility == 'ineligible',
  cumberland_halibut$import_status == 'not_started',
  grepl('no run-matched catch numbers-at-age',
    cumberland_halibut$catch_age_evidence, fixed = TRUE),
  grepl('aggregate abundance and biomass indices',
    cumberland_halibut$survey_age_evidence, fixed = TRUE),
  grepl('No accepted population model estimates',
    cumberland_halibut$mortality_evidence, fixed = TRUE),
  grepl('poor convergence', cumberland_halibut$decision_reason, fixed = TRUE),
  grepl('movement and emigration', cumberland_halibut$notes, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_greenland_halibut_cumberland_sound_2019.md')),
  !any(stocks$scientific_name == 'Reinhardtius hippoglossoides' &
    grepl('Cumberland Sound|CSTMA|Turbot Management Area',
      paste(stocks$area, stocks$region, stocks$notes), ignore.case = TRUE), na.rm = TRUE),
  dfo_arctic_summary$new == 2L,
  dfo_arctic_summary$identity_unreviewed == 18L,
  dfo_arctic_summary$excluded == 22L,
  dfo_arctic_summary$eligibility_unresolved == 1L,
  dfo_arctic_summary$screening_complete == 23L,
  dfo_arctic_summary$screening_not_started == 0L,
  dfo_arctic_summary$crosswalked_candidate_units == 2L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(quillback_units) == 736L,
  sum(quillback_units$inventory_entries) == 775L,
  sum(!is.na(quillback_units$candidate_unit_id) & nzchar(quillback_units$candidate_unit_id)) == 636L)
if (dir.exists(cumberland_halibut_cache)) {
  cumberland_halibut_sources <- read.csv(file.path(cumberland_halibut_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  stopifnot(
    nrow(cumberland_halibut_sources) == 4L,
    all(file.exists(file.path(cumberland_halibut_cache, cumberland_halibut_sources$file_name))),
    all(nzchar(cumberland_halibut_sources$source_url)),
    all(nzchar(cumberland_halibut_sources$sha256))
  )
}
cat('DFO Cumberland Sound Greenland Halibut screening checks passed.\n')

north_slope_dolly <- lookup(
  'DFO:Arctic:North Slope Dolly Varden - Big Fish, Rat, Firth, Babbage, Vittrekwa')
north_slope_cache <- file.path('source_cache',
  'discovery_dfo_north_slope_dolly_varden_20261029')
stopifnot(
  nrow(north_slope_dolly) == 1L,
  is.na(north_slope_dolly$candidate_unit_id),
  is.na(north_slope_dolly$official_stock_id),
  north_slope_dolly$scientific_name == 'Salvelinus malma malma',
  is.na(north_slope_dolly$inventory_assessment_year),
  north_slope_dolly$match_status == 'ambiguous',
  north_slope_dolly$screening_status == 'screened',
  north_slope_dolly$eligibility == 'unresolved',
  north_slope_dolly$import_status == 'not_started',
  grepl('catch-at-age proportions', north_slope_dolly$catch_age_evidence, fixed = TRUE),
  grepl('fishery-dependent CPUE', north_slope_dolly$survey_age_evidence, fixed = TRUE),
  grepl('age-specific natural mortality', north_slope_dolly$mortality_evidence, fixed = TRUE),
  grepl('0.62', north_slope_dolly$timing_evidence, fixed = TRUE),
  grepl('multiple river populations', north_slope_dolly$decision_reason, fixed = TRUE),
  grepl('separate Big Fish, Rat', north_slope_dolly$notes, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_north_slope_dolly_varden.md')),
  !any(grepl('Dolly Varden|Salvelinus malma',
    paste(stocks$scientific_name, stocks$area, stocks$region, stocks$notes),
    ignore.case = TRUE), na.rm = TRUE),
  dfo_arctic_summary$ambiguous == 3L,
  dfo_arctic_summary$identity_unreviewed == 18L,
  dfo_arctic_summary$excluded == 22L,
  dfo_arctic_summary$eligibility_unresolved == 1L,
  dfo_arctic_summary$screening_complete == 23L,
  dfo_arctic_summary$screening_not_started == 0L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(quillback_units) == 736L,
  sum(quillback_units$inventory_entries) == 775L)
if (dir.exists(north_slope_cache)) {
  north_slope_sources <- read.csv(file.path(north_slope_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  stopifnot(
    nrow(north_slope_sources) == 6L,
    all(file.exists(file.path(north_slope_cache, north_slope_sources$file_name))),
    all(nzchar(north_slope_sources$source_url)),
    all(nzchar(north_slope_sources$sha256))
  )
}
cat('DFO North Slope Dolly Varden inventory screening checks passed.\n')
units_redfish <- register[register$candidate_id %in% c(
  'DFO:National Capital Region:Redfish (Sebastes mentella) Unit 1 + 2',
  'DFO:National Capital Region:Redfish (Sebastes fasciatus) Unit 1 + 2'
), , drop = FALSE]
ncr_redfish <- progress[progress$organization == 'DFO' &
  progress$source_region == 'National Capital Region', , drop = FALSE]
redfish_cache <- file.path('source_cache',
  'discovery_dfo_redfish_units_1_2_2024')
stopifnot(
  nrow(units_redfish) == 2L,
  setequal(units_redfish$scientific_name, c('Sebastes mentella', 'Sebastes fasciatus')),
  setequal(units_redfish$candidate_unit_id,
    c('dfo_redfish_s_mentella_units_1_2', 'dfo_redfish_s_fasciatus_units_1_2')),
  all(units_redfish$match_status == 'new'),
  all(units_redfish$screening_status == 'screened'),
  all(units_redfish$eligibility == 'ineligible'),
  all(units_redfish$import_status == 'not_started'),
  all(is.na(units_redfish$official_stock_id)),
  all(grepl('index-based', units_redfish$decision_reason, fixed = TRUE)),
  all(grepl('2026/037', units_redfish$notes, fixed = TRUE)),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_redfish_units_1_2_2024.md')),
  nrow(ncr_redfish) == 1L,
  ncr_redfish$inventory_rows == 16L,
  ncr_redfish$new == 3L,
  ncr_redfish$identity_unreviewed == 12L,
  ncr_redfish$excluded == 14L,
  ncr_redfish$screening_complete == 16L,
  ncr_redfish$screening_not_started == 0L,
  ncr_redfish$crosswalked_candidate_units == 4L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(quillback_units) == 736L,
  sum(quillback_units$inventory_entries) == 775L,
  sum(!is.na(quillback_units$candidate_unit_id) & nzchar(quillback_units$candidate_unit_id)) == 636L)
redfish_sources <- read.csv(file.path(redfish_cache, 'sources.csv'),
  stringsAsFactors = FALSE)
stopifnot(
  nrow(redfish_sources) == 2L,
  all(file.exists(file.path(redfish_cache, redfish_sources$file))),
  all(file.info(file.path(redfish_cache, redfish_sources$file))$size > 0),
  all(nzchar(redfish_sources$url)),
  all(nzchar(redfish_sources$sha256))
)
cat('DFO Units 1 and 2 redfish screening checks passed.\n')

gulf_salmon <- lookup('DFO:Gulf:Atlantic Salmon - Gulf')
nl_salmon <- lookup('DFO:Newfoundland and Labrador:Atlantic Salmon - NL')
dfo_gulf <- progress[progress$organization == 'DFO' &
  progress$source_region == 'Gulf', , drop = FALSE]
dfo_newfoundland <- progress[progress$organization == 'DFO' &
  progress$source_region == 'Newfoundland and Labrador', , drop = FALSE]
stopifnot(
  nrow(gulf_salmon) == 1L,
  nrow(nl_salmon) == 1L,
  all(is.na(c(gulf_salmon$candidate_unit_id, nl_salmon$candidate_unit_id))),
  all(is.na(c(gulf_salmon$official_stock_id, nl_salmon$official_stock_id))),
  all(c(gulf_salmon$scientific_name, nl_salmon$scientific_name) == 'Salmo salar'),
  all(c(gulf_salmon$inventory_assessment_year, nl_salmon$inventory_assessment_year) == 2025L),
  all(c(gulf_salmon$match_status, nl_salmon$match_status) == 'ambiguous'),
  all(c(gulf_salmon$screening_status, nl_salmon$screening_status) == 'screened'),
  all(c(gulf_salmon$eligibility, nl_salmon$eligibility) == 'ineligible'),
  all(c(gulf_salmon$import_status, nl_salmon$import_status) == 'not_started'),
  grepl('No catch-numbers-at-age', gulf_salmon$catch_age_evidence, fixed = TRUE),
  grepl('age-specific abundance', gulf_salmon$survey_age_evidence, fixed = TRUE),
  grepl('age-specific abundance', nl_salmon$survey_age_evidence, fixed = TRUE),
  grepl('anticipated in late 2026', nl_salmon$notes, fixed = TRUE),
  grepl('composite row only', gulf_salmon$decision_reason, fixed = TRUE),
  grepl('separate river', nl_salmon$decision_reason, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_atlantic_salmon_gulf_2025.md')),
  file.exists(file.path('discovery', 'source_reviews',
    'dfo_atlantic_salmon_nl_2026.md')),
  nrow(dfo_gulf) == 1L,
  dfo_gulf$inventory_rows == 13L,
  dfo_gulf$ambiguous == 1L,
  dfo_gulf$identity_unreviewed == 4L,
  dfo_gulf$excluded == 6L,
  dfo_gulf$eligibility_unresolved == 0L,
  dfo_gulf$screening_complete == 13L,
  dfo_gulf$screening_not_started == 0L,
  nrow(dfo_newfoundland) == 1L,
  dfo_newfoundland$inventory_rows == 23L,
  dfo_newfoundland$ambiguous == 2L,
  dfo_newfoundland$identity_unreviewed == 8L,
  dfo_newfoundland$excluded == 18L,
  dfo_newfoundland$eligibility_unresolved == 2L,
  dfo_newfoundland$screening_complete == 23L,
  dfo_newfoundland$screening_not_started == 0L,
  sum(progress$ambiguous) == 35L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L)
salmon_cache <- file.path('source_cache',
  'discovery_dfo_atlantic_salmon_2025')
if (file.exists(file.path(salmon_cache, 'sources.csv'))) {
  salmon_sources <- read.csv(file.path(salmon_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  cached_salmon_sources <- salmon_sources[salmon_sources$status == 'cached', , drop = FALSE]
  stopifnot(
    nrow(cached_salmon_sources) == 2L,
    all(file.exists(file.path(salmon_cache, cached_salmon_sources$file))),
    all(file.info(file.path(salmon_cache, cached_salmon_sources$file))$size > 0),
    all(grepl('^[[:xdigit:]]{64}$', cached_salmon_sources$sha256))
  )
}
cat('DFO Atlantic salmon regional inventory screening checks passed.\n')

south_atlantic_bass <- lookup('NOAA:10310')
mid_atlantic_bass <- lookup('NOAA:10311')
noaa_progress <- progress[progress$organization == 'NOAA', , drop = FALSE]
stopifnot(
  nrow(south_atlantic_bass) == 1L,
  nrow(mid_atlantic_bass) == 1L,
  !any(stocks$scientific_name == 'Centropristis striata', na.rm = TRUE),
  all(c(south_atlantic_bass$official_stock_id, mid_atlantic_bass$official_stock_id) %in%
    c('10310', '10311')),
  all(c(south_atlantic_bass$candidate_unit_id, mid_atlantic_bass$candidate_unit_id) ==
    c('noaa_south_atlantic_black_sea_bass', 'noaa_mid_atlantic_black_sea_bass')),
  all(c(south_atlantic_bass$scientific_name, mid_atlantic_bass$scientific_name) ==
    'Centropristis striata'),
  all(c(south_atlantic_bass$match_status, mid_atlantic_bass$match_status) == 'new'),
  all(c(south_atlantic_bass$screening_status, mid_atlantic_bass$screening_status) == 'screened'),
  all(c(south_atlantic_bass$eligibility, mid_atlantic_bass$eligibility) == 'unresolved'),
  all(c(south_atlantic_bass$import_status, mid_atlantic_bass$import_status) == 'not_started'),
  grepl('N-at-age', south_atlantic_bass$output_evidence, fixed = TRUE),
  grepl('F-at-age', south_atlantic_bass$output_evidence, fixed = TRUE),
  grepl('revision', south_atlantic_bass$decision_reason, fixed = TRUE),
  grepl('numbers-at-age states', mid_atlantic_bass$survey_age_evidence, fixed = TRUE),
  grepl('final run package', mid_atlantic_bass$notes, fixed = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_black_sea_bass_south_atlantic_2025.md')),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_black_sea_bass_mid_atlantic_2025.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
bass_cache <- file.path('source_cache',
  'discovery_noaa_black_sea_bass_2025')
if (file.exists(file.path(bass_cache, 'sources.csv'))) {
  bass_sources <- read.csv(file.path(bass_cache, 'sources.csv'), stringsAsFactors = FALSE)
  stopifnot(
    nrow(bass_sources) == 5L,
    all(bass_sources$status == 'cached'),
    all(file.exists(file.path(bass_cache, bass_sources$file))),
    all(file.info(file.path(bass_cache, bass_sources$file))$size == bass_sources$bytes),
    all(nzchar(bass_sources$url)),
    all(grepl('^[[:xdigit:]]{64}$', bass_sources$sha256))
  )
}
cat('NOAA black sea bass assessment-unit screening checks passed.\n')

ices_plaice <- lookup('ICES:ple.27.5a')
ices_plaice_units <- units[units$candidate_unit_id == 'ices_plaice_iceland_5a', , drop = FALSE]
stopifnot(
  nrow(ices_plaice) == 1L,
  ices_plaice$candidate_unit_id == 'ices_plaice_iceland_5a',
  ices_plaice$official_stock_id == 'ple.27.5a',
  ices_plaice$scientific_name == 'Pleuronectes platessa',
  ices_plaice$match_status == 'new',
  ices_plaice$screening_status == 'screened',
  ices_plaice$eligibility == 'eligible',
  ices_plaice$import_status == 'not_started',
  grepl('catch-at-age', ices_plaice$catch_age_evidence, fixed = TRUE),
  grepl('age-disaggregated', ices_plaice$survey_age_evidence, fixed = TRUE),
  grepl('0.15', ices_plaice$mortality_evidence, fixed = TRUE),
  grepl('with uncertainty', ices_plaice$output_evidence, fixed = TRUE),
  grepl('digitization', ices_plaice$decision_reason, fixed = TRUE),
  nrow(ices_plaice_units) == 1L,
  ices_plaice_units$match_status == 'new',
  ices_plaice_units$eligibility == 'eligible',
  file.exists(file.path('discovery', 'source_reviews',
    'ices_plaice_iceland_2026.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
plaice_cache <- file.path('source_cache',
  'discovery_ices_iceland_plaice_2026')
if (file.exists(file.path(plaice_cache, 'sources.csv'))) {
  plaice_sources <- read.csv(file.path(plaice_cache, 'sources.csv'), stringsAsFactors = FALSE)
  stopifnot(
    nrow(plaice_sources) == 6L,
    all(plaice_sources$status == 'cached'),
    all(file.exists(file.path(plaice_cache, plaice_sources$file))),
    all(file.info(file.path(plaice_cache, plaice_sources$file))$size == plaice_sources$bytes),
    all(nzchar(plaice_sources$url)),
    all(grepl('^[[:xdigit:]]{64}$', plaice_sources$sha256)),
    any(grepl('22531', plaice_sources$revision, fixed = TRUE)),
    any(grepl('20132660', plaice_sources$revision, fixed = TRUE))
  )
}
cat('Icelandic plaice 2026 inventory screening checks passed.\n')

ices_wolffish <- lookup('ICES:caa.27.5a')
ices_wolffish_units <- units[
  units$candidate_unit_id == 'ices_atlantic_wolffish_iceland_5a', , drop = FALSE]
stopifnot(
  nrow(ices_wolffish) == 1L,
  ices_wolffish$candidate_unit_id == 'ices_atlantic_wolffish_iceland_5a',
  ices_wolffish$official_stock_id == 'caa.27.5a',
  ices_wolffish$scientific_name == 'Anarhichas lupus',
  ices_wolffish$match_status == 'new',
  ices_wolffish$screening_status == 'screened',
  ices_wolffish$eligibility == 'eligible',
  ices_wolffish$import_status == 'not_started',
  grepl('1981-1997', ices_wolffish$catch_age_evidence, fixed = TRUE),
  grepl('0.17', ices_wolffish$timing_evidence, fixed = TRUE),
  grepl('0.83', ices_wolffish$timing_evidence, fixed = TRUE),
  grepl('0.15', ices_wolffish$mortality_evidence, fixed = TRUE),
  grepl('22633', ices_wolffish$output_evidence, fixed = TRUE),
  grepl('2026', ices_wolffish$output_evidence, fixed = TRUE),
  grepl('fitfromweb', ices_wolffish$notes, fixed = TRUE),
  nrow(ices_wolffish_units) == 1L,
  ices_wolffish_units$match_status == 'new',
  ices_wolffish_units$eligibility == 'eligible',
  file.exists(file.path('discovery', 'source_reviews',
    'ices_atlantic_wolffish_iceland_2026.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L
)
wolffish_cache <- file.path('source_cache',
  'discovery_ices_iceland_wolffish_2026')
if (file.exists(file.path(wolffish_cache, 'sources.csv'))) {
  wolffish_sources <- read.csv(file.path(wolffish_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  wolffish_paths <- file.path(wolffish_cache, wolffish_sources$file)
  stopifnot(
    nrow(wolffish_sources) == 6L,
    all(wolffish_sources$status %in% c('cached', 'cached_reference')),
    all(file.exists(wolffish_paths)),
    all(file.info(wolffish_paths)$size == wolffish_sources$bytes),
    all(nzchar(wolffish_sources$url)),
    all(grepl('^[[:xdigit:]]{64}$', wolffish_sources$sha256)),
    any(grepl('22633', wolffish_sources$revision, fixed = TRUE)),
    any(grepl('22819988', wolffish_sources$revision, fixed = TRUE)),
    any(wolffish_sources$status == 'cached_reference')
  )
}
cat('Icelandic Atlantic wolffish 2026 inventory screening checks passed.\n')

red_grouper <- lookup('NOAA:10331')
red_grouper_unit <- units[
  units$candidate_unit_id == 'noaa_red_grouper_gom', , drop = FALSE]
stopifnot(
  nrow(red_grouper) == 1L,
  red_grouper$candidate_unit_id == 'noaa_red_grouper_gom',
  red_grouper$scientific_name == 'Epinephelus morio',
  red_grouper$inventory_assessment_year == 2026L,
  red_grouper$match_status == 'new',
  red_grouper$screening_status == 'screened',
  red_grouper$eligibility == 'unresolved',
  red_grouper$import_status == 'not_started',
  grepl('1991-2022', red_grouper$catch_age_evidence, fixed = TRUE),
  grepl('does not list age compositions', red_grouper$survey_age_evidence, fixed = TRUE),
  grepl('0.186', red_grouper$mortality_evidence, fixed = TRUE),
  grepl('August', red_grouper$timing_evidence, fixed = TRUE),
  grepl('do not define one fractional timing', red_grouper$timing_evidence, fixed = TRUE),
  grepl('egg production', red_grouper$output_evidence, fixed = TRUE),
  grepl('14350', red_grouper$notes, fixed = TRUE),
  nrow(red_grouper_unit) == 1L,
  red_grouper_unit$match_status == 'new',
  red_grouper_unit$eligibility == 'unresolved',
  red_grouper_unit$screening_status == 'screened',
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_red_grouper_gom_2025.md')),
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
cat('NOAA Gulf red grouper SEDAR 88 source-screening checks passed.\n')

north_sea_turbot <- lookup('ICES:tur.27.4')
turbot_index <- match('ck_ices_wgnssk_maximus_ns_4', stocks$stock_id)
stopifnot(
  nrow(north_sea_turbot) == 1L,
  north_sea_turbot$official_stock_id == 'tur.27.4',
  north_sea_turbot$matched_stock_id == 'ck_ices_wgnssk_maximus_ns_4',
  north_sea_turbot$match_status == 'matched',
  north_sea_turbot$screening_status == 'screened',
  north_sea_turbot$eligibility == 'eligible',
  north_sea_turbot$import_status == 'imported',
  stocks$authority_stock_id[turbot_index] == 'tur.27.4',
  grepl('2026 advice summary', north_sea_turbot$decision_reason, fixed = TRUE),
  grepl('2025 M9 benchmark', north_sea_turbot$decision_reason, fixed = TRUE),
  file.exists(file.path('source_reviews',
    'ices_turbot_north_sea.md'))
)
cat('ICES North Sea turbot inventory crosswalk checks passed.\n')

turbot_3a <- lookup('ICES:tur.27.3a')
turbot_3a_unit <- units[units$candidate_unit_id == 'ices_turbot_3a', , drop = FALSE]
stopifnot(
  nrow(turbot_3a) == 1L,
  turbot_3a$official_stock_id == 'tur.27.3a',
  turbot_3a$candidate_unit_id == 'ices_turbot_3a',
  turbot_3a$match_status == 'new',
  turbot_3a$screening_status == 'screened',
  turbot_3a$eligibility == 'ineligible',
  turbot_3a$import_status == 'not_started',
  grepl('SPiCT', turbot_3a$catch_age_evidence, fixed = TRUE),
  grepl('no age-specific abundance', turbot_3a$survey_age_evidence, fixed = TRUE),
  grepl('95% intervals', turbot_3a$output_evidence, fixed = TRUE),
  grepl('stock identity', turbot_3a$notes, fixed = TRUE),
  !any(stocks$authority_stock_id == 'tur.27.3a', na.rm = TRUE),
  nrow(turbot_3a_unit) == 1L,
  turbot_3a_unit$screening_status == 'screened',
  turbot_3a_unit$eligibility == 'ineligible',
  file.exists(file.path('discovery', 'source_reviews',
    'ices_turbot_3a_2026.md'))
)
turbot_3a_cache <- file.path('source_cache',
  'ices_turbot_3a_2026')
if (file.exists(file.path(turbot_3a_cache, 'manifest.csv'))) {
  turbot_3a_sources <- read.csv(file.path(turbot_3a_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  stopifnot(
    nrow(turbot_3a_sources) == 3L,
    all(file.exists(turbot_3a_sources$file)),
    all(file.info(turbot_3a_sources$file)$size > 0),
    all(nzchar(turbot_3a_sources$url)),
    all(grepl('^[[:xdigit:]]{64}$', turbot_3a_sources$sha256))
  )
}
cat('ICES Division 3.a turbot aggregate-only screening checks passed.\n')

ices_northern_hake <- lookup('ICES:hke.27.3a46-8abd')
ices_northern_hake_unit <- units[
  units$candidate_unit_id == 'ices_northern_hake', , drop = FALSE]
stopifnot(
  nrow(ices_northern_hake) == 1L,
  ices_northern_hake$official_stock_id == 'hke.27.3a46-8abd',
  ices_northern_hake$candidate_unit_id == 'ices_northern_hake',
  ices_northern_hake$match_status == 'new',
  ices_northern_hake$screening_status == 'screened',
  ices_northern_hake$eligibility == 'ineligible',
  ices_northern_hake$import_status == 'not_started',
  grepl('no catch-at-age', tolower(ices_northern_hake$catch_age_evidence), fixed = TRUE),
  grepl('no age-specific abundance', tolower(ices_northern_hake$survey_age_evidence), fixed = TRUE),
  grepl('90% intervals', ices_northern_hake$output_evidence, fixed = TRUE),
  grepl('TAF', ices_northern_hake$decision_reason, fixed = TRUE),
  !any(stocks$authority_stock_id == 'hke.27.3a46-8abd', na.rm = TRUE),
  nrow(ices_northern_hake_unit) == 1L,
  ices_northern_hake_unit$match_status == 'new',
  ices_northern_hake_unit$screening_status == 'screened',
  ices_northern_hake_unit$eligibility == 'ineligible',
  file.exists(file.path('discovery', 'source_reviews',
    'ices_northern_hake_2026.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L)
ices_hake_cache <- file.path('source_cache',
  'ices_northern_hake_2026')
if (file.exists(file.path(ices_hake_cache, 'manifest.csv'))) {
  ices_hake_sources <- read.csv(file.path(ices_hake_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  ices_hake_paths <- file.path(ices_hake_cache, basename(ices_hake_sources$file))
  stopifnot(
    nrow(ices_hake_sources) == 3L,
    all(file.exists(ices_hake_paths)),
    all(file.info(ices_hake_paths)$size > 0),
    all(nzchar(ices_hake_sources$url)),
    all(grepl('^[[:xdigit:]]{64}$', ices_hake_sources$sha256)),
    any(grepl('66353060', ices_hake_sources$url, fixed = TRUE)),
    any(grepl('66071894', ices_hake_sources$url, fixed = TRUE))
  )
}
cat('ICES northern hake 2026 screening checks passed.\n')

ices_iberian_sardine <- lookup('ICES:pil.27.8c9a')
ices_iberian_sardine_unit <- units[
  units$candidate_unit_id == 'ices_iberian_sardine_8c9a', , drop = FALSE]
stopifnot(
  nrow(ices_iberian_sardine) == 1L,
  ices_iberian_sardine$official_stock_id == 'pil.27.8c9a',
  ices_iberian_sardine$candidate_unit_id == 'ices_iberian_sardine_8c9a',
  ices_iberian_sardine$inventory_assessment_year == 2025L,
  ices_iberian_sardine$match_status == 'new',
  ices_iberian_sardine$screening_status == 'screened',
  ices_iberian_sardine$eligibility == 'unresolved',
  ices_iberian_sardine$import_status == 'not_started',
  grepl('ages 0-6+', ices_iberian_sardine$catch_age_evidence, fixed = TRUE),
  grepl('Cadiz', ices_iberian_sardine$catch_age_evidence, fixed = TRUE),
  grepl('ages 1-6+', ices_iberian_sardine$survey_age_evidence, fixed = TRUE),
  grepl('age-0', ices_iberian_sardine$survey_age_evidence, fixed = TRUE),
  grepl('1991-1995', ices_iberian_sardine$weights_evidence, fixed = TRUE),
  grepl('0.98, 0.61, 0.47', ices_iberian_sardine$mortality_evidence, fixed = TRUE),
  grepl('fractional-year', ices_iberian_sardine$timing_evidence, fixed = TRUE),
  grepl('95% intervals', ices_iberian_sardine$output_evidence, fixed = TRUE),
  grepl('ages 2-5', ices_iberian_sardine$output_evidence, fixed = TRUE),
  grepl('TAF', ices_iberian_sardine$decision_reason, fixed = TRUE),
  !any(stocks$authority_stock_id == 'pil.27.8c9a', na.rm = TRUE),
  nrow(ices_iberian_sardine_unit) == 1L,
  ices_iberian_sardine_unit$match_status == 'new',
  ices_iberian_sardine_unit$screening_status == 'screened',
  ices_iberian_sardine_unit$eligibility == 'unresolved',
  file.exists(file.path('discovery', 'source_reviews',
    'ices_iberian_sardine_2025.md')),
  sum(ices_progress$inventory_rows) == 274L,
  sum(ices_progress$new) == 212L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L,
  sum(progress$inventory_rows) == 905L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
ices_sardine_cache <- file.path('source_cache',
  'ices_iberian_sardine_2025')
if (file.exists(file.path(ices_sardine_cache, 'manifest.csv'))) {
  ices_sardine_sources <- read.csv(file.path(ices_sardine_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  ices_sardine_paths <- file.path(ices_sardine_cache, basename(ices_sardine_sources$file))
  stopifnot(
    nrow(ices_sardine_sources) == 4L,
    all(file.exists(ices_sardine_paths)),
    all(file.info(ices_sardine_paths)$size == ices_sardine_sources$bytes),
    all(nzchar(ices_sardine_sources$url)),
    all(grepl('^[[:xdigit:]]{64}$', ices_sardine_sources$sha256)),
    any(grepl('29335520.v3', ices_sardine_sources$revision, fixed = TRUE)),
    any(grepl('31305346.v1', ices_sardine_sources$revision, fixed = TRUE)),
    any(grepl('21259', ices_sardine_sources$url, fixed = TRUE))
  )
}
cat('ICES Iberian sardine 2025 source-screening checks passed.\n')

windowpane_north <- lookup('NOAA:10192')
windowpane_south <- lookup('NOAA:10193')
windowpane_units <- units[units$candidate_unit_id %in% c(
  'noaa_windowpane_north_gom_gb', 'noaa_windowpane_south_sne_ma'), , drop = FALSE]
stopifnot(
  nrow(windowpane_north) == 1L,
  nrow(windowpane_south) == 1L,
  windowpane_north$scientific_name == 'Scophthalmus aquosus',
  windowpane_south$scientific_name == 'Scophthalmus aquosus',
  windowpane_north$candidate_unit_id == 'noaa_windowpane_north_gom_gb',
  windowpane_south$candidate_unit_id == 'noaa_windowpane_south_sne_ma',
  windowpane_north$assessment_area == 'Gulf of Maine / Georges Bank',
  windowpane_south$assessment_area == 'Southern New England / Mid-Atlantic',
  all(c(windowpane_north$match_status, windowpane_south$match_status) == 'new'),
  all(c(windowpane_north$screening_status, windowpane_south$screening_status) == 'screened'),
  all(c(windowpane_north$eligibility, windowpane_south$eligibility) == 'ineligible'),
  grepl('empirical method', windowpane_north$decision_reason, fixed = TRUE),
  grepl('AIM', windowpane_south$decision_reason, fixed = TRUE),
  grepl('age-specific', windowpane_north$output_evidence, fixed = TRUE),
  grepl('age-specific', windowpane_south$output_evidence, fixed = TRUE),
  nrow(windowpane_units) == 2L,
  !any(stocks$authority_stock_id %in% c('10192', '10193'), na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_windowpane_2023.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_nefsc$new == 39L,
  noaa_nefsc$screening_complete == 55L,
  noaa_nefsc$screening_not_started == 0L
)
windowpane_cache <- file.path('source_cache',
  'noaa_windowpane_2023')
if (file.exists(file.path(windowpane_cache, 'manifest.csv'))) {
  windowpane_sources <- read.csv(file.path(windowpane_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  windowpane_paths <- file.path(windowpane_cache, basename(windowpane_sources$file))
  stopifnot(
    nrow(windowpane_sources) == 2L,
    all(file.exists(windowpane_paths)),
    all(file.info(windowpane_paths)$size == windowpane_sources$bytes),
    all(nzchar(windowpane_sources$url)),
    all(grepl('^[[:xdigit:]]{64}$', windowpane_sources$sha256)),
    all(grepl('fileId=90', windowpane_sources$url, fixed = TRUE))
  )
}
cat('NOAA Windowpane source-screening checks passed.\n')

atlantic_yellowfin <- lookup('NOAA:10166')
atlantic_bigeye <- lookup('NOAA:10169')
assessment_records <- read.csv('database/assessments.csv',
  stringsAsFactors = FALSE)
input_records <- read.csv('database/inputs.csv',
  stringsAsFactors = FALSE)
output_records <- read.csv('database/outputs.csv',
  stringsAsFactors = FALSE)
atlantic_tuna_units <- units[units$candidate_unit_id %in% c(
  'iccat_atlantic_yellowfin_tuna', 'iccat_atlantic_bigeye_tuna'), , drop = FALSE]
noaa_sefsc <- noaa_progress[noaa_progress$source_region == 'SEFSC', , drop = FALSE]
stopifnot(
  nrow(atlantic_yellowfin) == 1L,
  nrow(atlantic_bigeye) == 1L,
  atlantic_yellowfin$candidate_unit_id == 'iccat_atlantic_yellowfin_tuna',
  atlantic_bigeye$candidate_unit_id == 'iccat_atlantic_bigeye_tuna',
  atlantic_yellowfin$scientific_name == 'Thunnus albacares',
  atlantic_bigeye$scientific_name == 'Thunnus obesus',
  atlantic_yellowfin$inventory_assessment_year == 2024L,
  atlantic_bigeye$inventory_assessment_year == 2025L,
  all(c(atlantic_yellowfin$match_status, atlantic_bigeye$match_status) == 'new'),
  all(c(atlantic_yellowfin$screening_status, atlantic_bigeye$screening_status) == 'screened'),
  all(c(atlantic_yellowfin$eligibility, atlantic_bigeye$eligibility) == 'unresolved'),
  grepl('Conditional age-at-length', atlantic_yellowfin$catch_age_evidence, fixed = TRUE),
  grepl('not age-stratified', atlantic_bigeye$survey_age_evidence, fixed = TRUE),
  grepl('derived', atlantic_bigeye$output_evidence, fixed = TRUE),
  nrow(atlantic_tuna_units) == 2L,
  sum(atlantic_tuna_units$inventory_entries) == 2L,
  !any(stocks$scientific_name %in% c('Thunnus albacares', 'Thunnus obesus')),
  !any(assessment_records$assessment_id %in% c('iccat_atlantic_yellowfin_tuna',
    'iccat_atlantic_bigeye_tuna')),
  !any(input_records$assessment_id %in% c('iccat_atlantic_yellowfin_tuna',
    'iccat_atlantic_bigeye_tuna')),
  !any(output_records$assessment_id %in% c('iccat_atlantic_yellowfin_tuna',
    'iccat_atlantic_bigeye_tuna')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_sefsc$new == 87L,
  noaa_sefsc$identity_unreviewed == 0L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_iccat_atlantic_tunas_2024_2025.md'))
)

iccat_tuna_cache <- file.path('source_cache',
  'noaa_iccat_tunas_2024_2025')
if (file.exists(file.path(iccat_tuna_cache, 'manifest.csv'))) {
  iccat_tuna_sources <- read.csv(file.path(iccat_tuna_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  iccat_tuna_paths <- file.path(iccat_tuna_cache, basename(iccat_tuna_sources$file))
  stopifnot(
    nrow(iccat_tuna_sources) == 4L,
    all(file.exists(iccat_tuna_paths)),
    all(file.info(iccat_tuna_paths)$size == iccat_tuna_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', iccat_tuna_sources$sha256)),
    all(grepl('iccat.int', iccat_tuna_sources$url, fixed = TRUE)),
    all(grepl('2024|2025', iccat_tuna_sources$revision))
  )
}
cat('NOAA ICCAT Atlantic tuna source-screening checks passed.\n')

scamp_gulf <- lookup('NOAA:10324')
scamp_south_atlantic <- lookup('NOAA:10326')
scamp_units <- units[units$candidate_unit_id %in% c(
  'noaa_scamp_yellowmouth_gulf_complex',
  'noaa_scamp_yellowmouth_south_atlantic_complex'), , drop = FALSE]
noaa_sefsc <- noaa_progress[noaa_progress$source_region == 'SEFSC', , drop = FALSE]
stopifnot(
  nrow(scamp_gulf) == 1L,
  nrow(scamp_south_atlantic) == 1L,
  scamp_gulf$candidate_unit_id == 'noaa_scamp_yellowmouth_gulf_complex',
  scamp_south_atlantic$candidate_unit_id == 'noaa_scamp_yellowmouth_south_atlantic_complex',
  scamp_gulf$assessment_area == 'Gulf of Mexico',
  scamp_south_atlantic$assessment_area == 'Southern Atlantic Coast',
  all(c(scamp_gulf$scientific_name, scamp_south_atlantic$scientific_name) ==
    'Mycteroperca phenax'),
  all(c(scamp_gulf$match_status, scamp_south_atlantic$match_status) == 'new'),
  all(c(scamp_gulf$screening_status, scamp_south_atlantic$screening_status) == 'screened'),
  all(c(scamp_gulf$eligibility, scamp_south_atlantic$eligibility) == 'unresolved'),
  all(c(scamp_gulf$import_status, scamp_south_atlantic$import_status) == 'not_started'),
  grepl('Yellowmouth Grouper jointly', scamp_gulf$notes, fixed = TRUE),
  grepl('figures rather than numeric', scamp_gulf$catch_age_evidence, fixed = TRUE),
  grepl('Table 6', scamp_south_atlantic$output_evidence, fixed = TRUE),
  grepl('Table 12', scamp_south_atlantic$output_evidence, fixed = TRUE),
  nrow(scamp_units) == 2L,
  sum(scamp_units$inventory_entries) == 2L,
  !any(stocks$scientific_name %in% c('Mycteroperca phenax', 'Mycteroperca interstitialis')),
  !any(assessment_records$assessment_id %in% c(
    'noaa_scamp_yellowmouth_gulf_complex',
    'noaa_scamp_yellowmouth_south_atlantic_complex')),
  !any(input_records$assessment_id %in% c(
    'noaa_scamp_yellowmouth_gulf_complex',
    'noaa_scamp_yellowmouth_south_atlantic_complex')),
  !any(output_records$assessment_id %in% c(
    'noaa_scamp_yellowmouth_gulf_complex',
    'noaa_scamp_yellowmouth_south_atlantic_complex')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_sefsc$new == 87L,
  noaa_sefsc$identity_unreviewed == 0L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_scamp_sedar68oa_2022.md'))
)

scamp_cache <- file.path('source_cache',
  'noaa_scamp_sedar68oa')
if (file.exists(file.path(scamp_cache, 'manifest.csv'))) {
  scamp_sources <- read.csv(file.path(scamp_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  scamp_source_paths <- file.path(scamp_cache, basename(scamp_sources$file))
  stopifnot(
    nrow(scamp_sources) == 8L,
    all(file.exists(scamp_source_paths)),
    all(file.info(scamp_source_paths)$size == scamp_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', scamp_sources$sha256)),
    all(grepl('sedarweb.org|fisheries.noaa.gov|gulf-council-media',
      scamp_sources$url)),
    any(grepl('2022', scamp_sources$revision)),
    any(grepl('April 2025', scamp_sources$revision))
  )
}
cat('NOAA SEDAR 68OA Scamp identity and source-screening checks passed.\n')


yellowedge <- lookup('NOAA:10323')
yellowedge_units <- units[units$candidate_unit_id == 'noaa_yellowedge_gulf', , drop = FALSE]
noaa_sefsc <- noaa_progress[noaa_progress$source_region == 'SEFSC', , drop = FALSE]
stopifnot(
  nrow(yellowedge) == 1L,
  yellowedge$candidate_unit_id == 'noaa_yellowedge_gulf',
  yellowedge$scientific_name == 'Epinephelus flavolimbatus',
  yellowedge$assessment_area == 'Gulf of Mexico',
  yellowedge$match_status == 'new',
  yellowedge$screening_status == 'screened',
  yellowedge$eligibility == 'unresolved',
  yellowedge$import_status == 'not_started',
  grepl('40+ group', yellowedge$catch_age_evidence, fixed = TRUE),
  grepl('plots age proportions', yellowedge$catch_age_evidence, fixed = TRUE),
  grepl('2000-2021', yellowedge$survey_age_evidence, fixed = TRUE),
  grepl('0.073', yellowedge$mortality_evidence, fixed = TRUE),
  grepl('August', yellowedge$timing_evidence, fixed = TRUE),
  grepl('annual SSB, recruitment', yellowedge$output_evidence, fixed = TRUE),
  nrow(yellowedge_units) == 1L,
  yellowedge_units$inventory_entries == 1L,
  !any(stocks$scientific_name %in% c('Epinephelus flavolimbatus', 'Hyporthodus flavolimbatus')),
  !any(assessment_records$assessment_id == 'noaa_yellowedge_gulf', na.rm = TRUE),
  !any(input_records$assessment_id == 'noaa_yellowedge_gulf', na.rm = TRUE),
  !any(output_records$assessment_id == 'noaa_yellowedge_gulf', na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_yellowedge_sedar85_2023.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_sefsc$new == 87L,
  noaa_sefsc$identity_unreviewed == 0L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

yellowedge_cache <- file.path('source_cache',
  'noaa_yellowedge_sedar85_2023')
if (file.exists(file.path(yellowedge_cache, 'manifest.csv'))) {
  yellowedge_sources <- read.csv(file.path(yellowedge_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  yellowedge_source_paths <- file.path(yellowedge_cache, basename(yellowedge_sources$file))
  stopifnot(
    nrow(yellowedge_sources) == 7L,
    all(file.exists(yellowedge_source_paths)),
    all(file.info(yellowedge_source_paths)$size == yellowedge_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', yellowedge_sources$sha256)),
    all(grepl('sedarweb.org', yellowedge_sources$url, fixed = TRUE)),
    any(grepl('November 2023', yellowedge_sources$revision, fixed = TRUE)),
    any(grepl('2024', yellowedge_sources$revision, fixed = TRUE))
  )
}
cat('NOAA SEDAR 85 Yellowedge Grouper source-screening checks passed.\n')


gag <- lookup('NOAA:10348')
gag_units <- units[units$candidate_unit_id == 'noaa_gag_gulf', , drop = FALSE]
noaa_sefsc <- noaa_progress[noaa_progress$source_region == 'SEFSC', , drop = FALSE]
stopifnot(
  nrow(gag) == 1L,
  gag$candidate_unit_id == 'noaa_gag_gulf',
  gag$scientific_name == 'Mycteroperca microlepis',
  gag$assessment_area == 'Gulf of Mexico',
  gag$match_status == 'new',
  gag$screening_status == 'screened',
  gag$eligibility == 'eligible',
  gag$import_status == 'not_started',
  grepl('age composition data', gag$catch_age_evidence, fixed = TRUE),
  grepl('20+', gag$survey_age_evidence, fixed = TRUE),
  grepl('0.159', gag$mortality_evidence, fixed = TRUE),
  grepl('3.9 years', gag$maturity_evidence, fixed = TRUE),
  grepl('1963-2019', gag$output_evidence, fixed = TRUE),
  grepl('SEDAR 105 is underway in 2026', gag$decision_reason, fixed = TRUE),
  grepl('Do not merge it with the distinct South Atlantic Gag unit', gag$notes, fixed = TRUE),
  nrow(gag_units) == 1L,
  gag_units$screening_status == 'screened',
  gag_units$eligibility == 'eligible',
  !any(stocks$scientific_name == 'Mycteroperca microlepis', na.rm = TRUE),
  !any(assessment_records$assessment_id == 'noaa_gag_gulf', na.rm = TRUE),
  !any(input_records$assessment_id == 'noaa_gag_gulf', na.rm = TRUE),
  !any(output_records$assessment_id == 'noaa_gag_gulf', na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_gag_sedar72_2022.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_sefsc$new == 87L,
  noaa_sefsc$identity_unreviewed == 0L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

gag_cache <- file.path('source_cache',
  'noaa_gag_sedar72_2022')
if (file.exists(file.path(gag_cache, 'manifest.csv'))) {
  gag_sources <- read.csv(file.path(gag_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  gag_source_paths <- file.path(gag_cache, basename(gag_sources$file))
  stopifnot(
    nrow(gag_sources) == 5L,
    all(file.exists(gag_source_paths)),
    all(file.info(gag_source_paths)$size == gag_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', gag_sources$sha256)),
    all(grepl('sedarweb.org', gag_sources$url, fixed = TRUE)),
    any(grepl('September 2022', gag_sources$revision, fixed = TRUE)),
    any(grepl('May 2021', gag_sources$revision, fixed = TRUE))
  )
}

gag_south_atlantic <- lookup('NOAA:10349')
gag_south_atlantic_units <- units[
  units$candidate_unit_id == 'noaa_gag_south_atlantic', , drop = FALSE]
stopifnot(
  nrow(gag_south_atlantic) == 1L,
  gag_south_atlantic$candidate_unit_id == 'noaa_gag_south_atlantic',
  gag_south_atlantic$scientific_name == 'Mycteroperca microlepis',
  gag_south_atlantic$assessment_area == 'Southern Atlantic Coast',
  gag_south_atlantic$inventory_assessment_year == 2021L,
  gag_south_atlantic$match_status == 'new',
  gag_south_atlantic$screening_status == 'screened',
  gag_south_atlantic$eligibility == 'eligible',
  gag_south_atlantic$import_status == 'not_started',
  gag_south_atlantic$candidate_unit_id != gag$candidate_unit_id,
  grepl('1962-2019', gag_south_atlantic$catch_age_evidence, fixed = TRUE),
  grepl('digitized observed', gag_south_atlantic$catch_age_evidence, fixed = TRUE),
  grepl('does not fit a direct', gag_south_atlantic$survey_age_evidence, fixed = TRUE),
  grepl('about 4.6 years', gag_south_atlantic$maturity_evidence, fixed = TRUE),
  grepl('ages 5+', gag_south_atlantic$mortality_evidence, fixed = TRUE),
  grepl('M = 0.15', gag_south_atlantic$mortality_evidence, fixed = TRUE),
  grepl('through 2019', gag_south_atlantic$output_evidence, fixed = TRUE),
  grepl('SEDAR 106 assessment', gag_south_atlantic$decision_reason, fixed = TRUE),
  grepl('delayed', gag_south_atlantic$decision_reason, fixed = TRUE),
  nrow(gag_south_atlantic_units) == 1L,
  gag_south_atlantic_units$screening_status == 'screened',
  gag_south_atlantic_units$eligibility == 'eligible',
  !any(stocks$scientific_name == 'Mycteroperca microlepis', na.rm = TRUE),
  !any(assessment_records$assessment_id == 'noaa_gag_south_atlantic', na.rm = TRUE),
  !any(input_records$assessment_id == 'noaa_gag_south_atlantic', na.rm = TRUE),
  !any(output_records$assessment_id == 'noaa_gag_south_atlantic', na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_gag_sedar71_2021.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_sefsc$new == 87L,
  noaa_sefsc$identity_unreviewed == 0L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

gag_south_atlantic_cache <- file.path('source_cache',
  'noaa_gag_sedar71_2021')
if (file.exists(file.path(gag_south_atlantic_cache, 'manifest.csv'))) {
  gag_south_atlantic_sources <- read.csv(
    file.path(gag_south_atlantic_cache, 'manifest.csv'), stringsAsFactors = FALSE)
  gag_south_atlantic_paths <- file.path(gag_south_atlantic_cache,
    basename(gag_south_atlantic_sources$file))
  stopifnot(
    nrow(gag_south_atlantic_sources) == 5L,
    all(file.exists(gag_south_atlantic_paths)),
    all(file.info(gag_south_atlantic_paths)$size == gag_south_atlantic_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', gag_south_atlantic_sources$sha256)),
    all(grepl('sedarweb.org', gag_south_atlantic_sources$url, fixed = TRUE)),
    any(grepl('April 2021', gag_south_atlantic_sources$revision, fixed = TRUE)),
    any(grepl('1990-2019', gag_south_atlantic_sources$revision, fixed = TRUE))
  )
}
cat('NOAA SEDAR 71 South Atlantic Gag Grouper source-screening checks passed.\n')

cat('NOAA SEDAR 72 Gulf Gag Grouper source-screening checks passed.\n')

snowy <- lookup('NOAA:10339')
snowy_units <- units[units$candidate_unit_id == 'noaa_snowy_grouper_south_atlantic',
  , drop = FALSE]
stopifnot(
  nrow(snowy) == 1L,
  snowy$candidate_unit_id == 'noaa_snowy_grouper_south_atlantic',
  snowy$scientific_name == 'Epinephelus niveatus',
  snowy$assessment_area == 'Southern Atlantic Coast',
  snowy$inventory_assessment_year == 2021L,
  snowy$match_status == 'new',
  snowy$screening_status == 'screened',
  snowy$eligibility == 'eligible',
  snowy$import_status == 'not_started',
  grepl('commercial handline', snowy$catch_age_evidence, fixed = TRUE),
  grepl('digitization', snowy$catch_age_evidence, fixed = TRUE),
  grepl('1996-2018', snowy$survey_age_evidence, fixed = TRUE),
  grepl('age 25', snowy$weights_evidence, fixed = TRUE),
  grepl('5.6 years', snowy$maturity_evidence, fixed = TRUE),
  grepl('M = 0.08', snowy$mortality_evidence, fixed = TRUE),
  grepl('Table 6', snowy$output_evidence, fixed = TRUE),
  grepl('Table 11', snowy$output_evidence, fixed = TRUE),
  grepl('2027 statement of work', snowy$decision_reason, fixed = TRUE),
  nrow(snowy_units) == 1L,
  snowy_units$screening_status == 'screened',
  snowy_units$eligibility == 'eligible',
  !any(stocks$scientific_name %in% c('Epinephelus niveatus', 'Hyporthodus niveatus'),
    na.rm = TRUE),
  !any(assessment_records$assessment_id == 'noaa_snowy_grouper_south_atlantic',
    na.rm = TRUE),
  !any(input_records$assessment_id == 'noaa_snowy_grouper_south_atlantic',
    na.rm = TRUE),
  !any(output_records$assessment_id == 'noaa_snowy_grouper_south_atlantic',
    na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_snowy_grouper_sedar36u_2021.md')),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$eligible_new) == 75L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_sefsc$new == 87L,
  noaa_sefsc$identity_unreviewed == 0L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
snowy_cache <- file.path('source_cache',
  'noaa_snowy_grouper_sedar36u_2021')
if (file.exists(file.path(snowy_cache, 'manifest.csv'))) {
  snowy_sources <- read.csv(file.path(snowy_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  snowy_source_paths <- file.path(snowy_cache, basename(snowy_sources$file))
  stopifnot(
    nrow(snowy_sources) == 3L,
    all(file.exists(snowy_source_paths)),
    all(file.info(snowy_source_paths)$size == snowy_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', snowy_sources$sha256)),
    all(grepl('sedarweb.org', snowy_sources$url, fixed = TRUE)),
    any(grepl('revised January 2021', snowy_sources$revision, fixed = TRUE)),
    any(grepl('submitted April 24, 2020', snowy_sources$revision, fixed = TRUE))
  )
}
cat('NOAA SEDAR 36 Update South Atlantic Snowy Grouper source-screening checks passed.\n')


blueline_south <- lookup('NOAA:10381')
blueline_mid <- lookup('NOAA:14922')
blueline_units <- units[units$candidate_unit_id %in% c(
  'noaa_blueline_tilefish_south_atlantic',
  'noaa_blueline_tilefish_mid_atlantic'), , drop = FALSE]
blueline_stocksmart_env <- new.env(parent = emptyenv())
load(file.path('source_cache',
  'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'),
  envir = blueline_stocksmart_env)
blueline_stocksmart <- blueline_stocksmart_env$stock_assessment_summary
blueline_latest <- blueline_stocksmart[
  blueline_stocksmart$stock_id %in% c(10381, 14922) &
    blueline_stocksmart$assessment_year == 2025, , drop = FALSE]
stopifnot(
  nrow(blueline_south) == 1L,
  blueline_south$candidate_unit_id == 'noaa_blueline_tilefish_south_atlantic',
  blueline_south$assessment_area == 'Southern Atlantic Coast',
  blueline_south$match_status == 'new',
  is.na(blueline_south$matched_stock_id),
  blueline_south$screening_status == 'screened',
  blueline_south$eligibility == 'ineligible',
  blueline_south$import_status == 'not_started',
  grepl('fishery age-composition likelihood', blueline_south$catch_age_evidence, fixed = TRUE),
  grepl('aggregate CPUE', blueline_south$survey_age_evidence, fixed = TRUE),
  grepl('not an observed', blueline_south$weights_evidence, fixed = TRUE),
  grepl('maturity-at-age', blueline_south$maturity_evidence, fixed = TRUE),
  grepl('M = 0.17', blueline_south$mortality_evidence, fixed = TRUE),
  grepl('population-at-age', blueline_south$output_evidence, fixed = TRUE),
  grepl('assessment 13944', blueline_south$decision_reason, fixed = TRUE),
  nrow(blueline_mid) == 1L,
  blueline_mid$candidate_unit_id == 'noaa_blueline_tilefish_mid_atlantic',
  blueline_mid$assessment_area == 'Mid-Atlantic Coast',
  blueline_mid$match_status == 'new',
  is.na(blueline_mid$matched_stock_id),
  blueline_mid$screening_status == 'screened',
  blueline_mid$eligibility == 'ineligible',
  blueline_mid$import_status == 'not_started',
  grepl('no valid age', blueline_mid$catch_age_evidence, fixed = TRUE),
  grepl('no valid abundance indices', blueline_mid$survey_age_evidence, fixed = TRUE),
  grepl('catch-limit distributions', blueline_mid$output_evidence, fixed = TRUE),
  grepl('assessment 13772', blueline_mid$decision_reason, fixed = TRUE),
  grepl('North Carolina/Virginia boundary', blueline_mid$notes, fixed = TRUE),
  blueline_south$candidate_unit_id != blueline_mid$candidate_unit_id,
  nrow(blueline_units) == 2L,
  all(blueline_units$screening_status == 'screened'),
  all(blueline_units$eligibility == 'ineligible'),
  !any(stocks$scientific_name == 'Caulolatilus microps', na.rm = TRUE),
  !any(assessment_records$assessment_id %in% c('noaa_blueline_tilefish_south_atlantic',
    'noaa_blueline_tilefish_mid_atlantic'), na.rm = TRUE),
  !any(input_records$assessment_id %in% c('noaa_blueline_tilefish_south_atlantic',
    'noaa_blueline_tilefish_mid_atlantic'), na.rm = TRUE),
  !any(output_records$assessment_id %in% c('noaa_blueline_tilefish_south_atlantic',
    'noaa_blueline_tilefish_mid_atlantic'), na.rm = TRUE),
  nrow(blueline_latest) == 2L,
  setequal(blueline_latest$assessment_id, c(13944L, 13772L)),
  all(grepl('Reject', blueline_latest$review_result, fixed = TRUE)),
  all(file.exists(file.path('discovery',
    'source_reviews', 'noaa_blueline_tilefish_sedar92_2025.md'))),
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$eligibility_unresolved) == 91L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  noaa_sefsc$screening_complete == 90L,
  noaa_sefsc$screening_not_started == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
blueline_cache <- file.path('source_cache',
  'noaa_blueline_tilefish_sedar92_2025')
if (file.exists(file.path(blueline_cache, 'manifest.csv'))) {
  blueline_sources <- read.csv(file.path(blueline_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  blueline_source_paths <- file.path(blueline_cache, basename(blueline_sources$file))
  stopifnot(
    nrow(blueline_sources) == 4L,
    all(file.exists(blueline_source_paths)),
    all(file.info(blueline_source_paths)$size == blueline_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', blueline_sources$sha256)),
    all(grepl('sedarweb.org|safmc.net', blueline_sources$url)),
    any(grepl('May 23 2025', blueline_sources$revision, fixed = TRUE)),
    any(grepl('northern model only', blueline_sources$revision, fixed = TRUE))
  )
}
cat('NOAA SEDAR 92 Atlantic Blueline Tilefish source-screening checks passed.\n')
golden_tilefish <- read.csv(file.path('discovery',
  'candidates.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
golden_tilefish <- golden_tilefish[golden_tilefish$candidate_id %in%
  c('NOAA:10384', 'NOAA:10385'), , drop = FALSE]
golden_stocks <- read.csv(file.path('database',
  'stocks.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
golden_assessments <- read.csv(file.path('database',
  'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
golden_inputs <- read.csv(file.path('database',
  'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
golden_outputs <- read.csv(file.path('database',
  'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
golden_progress <- read.csv(file.path('discovery',
  'inventory_progress.csv'), stringsAsFactors = FALSE)
golden_units <- read.csv(file.path('discovery',
  'inventory_units.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
golden_noaa <- golden_progress[golden_progress$organization == 'NOAA', , drop = FALSE]
golden_new_units <- golden_units[golden_units$match_status == 'new', , drop = FALSE]
stopifnot(
  nrow(golden_tilefish) == 2L,
  !anyDuplicated(golden_tilefish$candidate_id),
  !anyDuplicated(golden_tilefish$candidate_unit_id),
  setequal(golden_tilefish$candidate_unit_id, c(
    'noaa_golden_tilefish_south_atlantic', 'noaa_golden_tilefish_mid_atlantic')),
  all(golden_tilefish$scientific_name == 'Lopholatilus chamaeleonticeps'),
  identical(as.integer(golden_tilefish$inventory_assessment_year[match(
    c('NOAA:10384', 'NOAA:10385'), golden_tilefish$candidate_id)]), c(2025L, 2024L)),
  all(golden_tilefish$match_status == 'new'),
  all(golden_tilefish$screening_status == 'screened'),
  all(golden_tilefish$eligibility == 'eligible'),
  all(golden_tilefish$import_status == 'not_started'),
  grepl('ages 1-20+', golden_tilefish$catch_age_evidence[golden_tilefish$candidate_id ==
    'NOAA:10384'], fixed = TRUE),
  grepl('MARMAP age compositions', golden_tilefish$survey_age_evidence[
    golden_tilefish$candidate_id == 'NOAA:10384'], fixed = TRUE),
  grepl('ages 1-10+', golden_tilefish$catch_age_evidence[golden_tilefish$candidate_id ==
    'NOAA:10385'], fixed = TRUE),
  grepl('chart-based', golden_tilefish$decision_reason[
    golden_tilefish$candidate_id == 'NOAA:10385'], fixed = TRUE),
  !any(grepl('tilefish', golden_stocks$common_name, ignore.case = TRUE), na.rm = TRUE),
  !any(golden_tilefish$candidate_unit_id %in% golden_assessments$assessment_id, na.rm = TRUE),
  !any(golden_tilefish$candidate_unit_id %in% golden_inputs$assessment_id, na.rm = TRUE),
  !any(golden_tilefish$candidate_unit_id %in% golden_outputs$assessment_id, na.rm = TRUE),
  file.exists(file.path('discovery', 'source_reviews',
    'noaa_golden_tilefish_2024_2025.md')),
  file.exists(file.path('scripts', 'database',
    '333_screen_noaa_golden_tilefish_2024_2025.R')),
  sum(golden_noaa$inventory_rows) == 432L,
  sum(golden_noaa$new) == 388L,
  sum(golden_noaa$identity_unreviewed) == 2L,
  sum(golden_noaa$eligible) == 89L,
  sum(golden_noaa$eligibility_unresolved) == 91L,
  sum(golden_noaa$screening_complete) == 432L,
  sum(golden_noaa$screening_not_started) == 0L,
  nrow(golden_progress) == 75L,
  sum(golden_progress$inventory_rows) == 905L,
  sum(golden_progress$new) == 663L,
  sum(golden_progress$identity_unreviewed) == 100L,
  sum(golden_progress$eligible) == 170L,
  sum(golden_progress$eligibility_unresolved) == 151L,
  sum(golden_progress$screening_complete) == 905L,
  sum(golden_progress$screening_not_started) == 0L,
  nrow(golden_units) == 736L,
  sum(golden_units$inventory_entries) == 775L,
  sum(!is.na(golden_units$candidate_unit_id) & nzchar(golden_units$candidate_unit_id)) == 636L,
  sum(golden_new_units$eligibility == 'eligible') == 90L,
  sum(golden_new_units$eligibility == 'ineligible') == 421L,
  sum(golden_new_units$eligibility == 'unresolved') == 118L,
  sum(golden_new_units$eligibility == 'mixed') == 3L
)
golden_cache <- file.path('source_cache',
  'noaa_golden_tilefish_2025')
if (file.exists(file.path(golden_cache, 'manifest.csv'))) {
  golden_sources <- read.csv(file.path(golden_cache, 'manifest.csv'),
    stringsAsFactors = FALSE)
  golden_source_paths <- file.path(golden_cache, basename(golden_sources$file))
  stopifnot(
    nrow(golden_sources) == 8L,
    all(file.exists(golden_source_paths)),
    all(file.info(golden_source_paths)$size == golden_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', golden_sources$sha256)),
    any(grepl('sedarweb.org', golden_sources$url, fixed = TRUE)),
    any(grepl('fisheries.noaa.gov', golden_sources$url, fixed = TRUE))
  )
}
cat('NOAA golden tilefish candidate-screening checks passed.\n')

acadian <- lookup('NOAA:10455')
acadian_unit <- 'noaa_acadian_redfish_gom_gb'
acadian_assessments <- read.csv(file.path('database', 'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
acadian_inputs <- read.csv(file.path('database', 'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
acadian_outputs <- read.csv(file.path('database', 'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  nrow(acadian) == 1L,
  acadian$candidate_unit_id == acadian_unit,
  acadian$match_status == 'new',
  acadian$screening_status == 'screened',
  acadian$eligibility == 'eligible',
  acadian$import_status == 'not_started',
  grepl('annual total catch', acadian$catch_age_evidence, fixed = TRUE),
  grepl('proportions-at-age', acadian$catch_age_evidence, fixed = TRUE),
  grepl('spring and fall abundance indices', acadian$survey_age_evidence, fixed = TRUE),
  grepl('three weight-at-age matrices', acadian$weights_evidence, fixed = TRUE),
  grepl('fixed at 0.05', acadian$mortality_evidence, fixed = TRUE),
  grepl('not historical fitted outputs', acadian$output_evidence, fixed = TRUE),
  !any(stocks$stock_id == acadian_unit),
  !any(acadian_assessments$assessment_id == acadian_unit),
  !any(acadian_inputs$assessment_id == acadian_unit),
  !any(acadian_outputs$assessment_id == acadian_unit),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_acadian_redfish_2025.md')),
  file.exists(file.path('scripts', 'database',
    '334_screen_noaa_acadian_redfish_2025.R'))
)
acadian_cache <- file.path('source_cache',
  'discovery_noaa_acadian_redfish_2025')
if (file.exists(file.path(acadian_cache, 'sources.csv'))) {
  acadian_sources <- read.csv(file.path(acadian_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  acadian_source_paths <- file.path(acadian_cache, acadian_sources$file)
  stopifnot(
    nrow(acadian_sources) == 6L,
    all(file.exists(acadian_source_paths)),
    all(file.info(acadian_source_paths)$size == acadian_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', acadian_sources$sha256)),
    any(grepl('2025_RED_UNIT_MOD_BaseWHAMInput.DAT', acadian_sources$file, fixed = TRUE)),
    any(grepl('fisheries.noaa.gov', acadian_sources$url, fixed = TRUE))
  )
}
cat('NOAA Acadian redfish candidate-screening checks passed.\n')

bluefish <- lookup('NOAA:10388')
bluefish_unit <- 'noaa_bluefish_atlantic_coast'
bluefish_assessments <- read.csv(file.path('database', 'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
bluefish_inputs <- read.csv(file.path('database', 'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
bluefish_outputs <- read.csv(file.path('database', 'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  nrow(bluefish) == 1L,
  bluefish$candidate_unit_id == bluefish_unit,
  bluefish$match_status == 'new',
  bluefish$screening_status == 'screened',
  bluefish$eligibility == 'eligible',
  bluefish$import_status == 'not_started',
  grepl('age-composition proportions', bluefish$catch_age_evidence, fixed = TRUE),
  grepl('1985-2024', bluefish$catch_age_evidence, fixed = TRUE),
  grepl('rescaled', bluefish$survey_age_evidence, fixed = TRUE),
  grepl('nine aggregate index series', bluefish$survey_age_evidence, fixed = TRUE),
  grepl('weight-at-age surfaces', bluefish$weights_evidence, fixed = TRUE),
  grepl('maturity-at-age', bluefish$maturity_evidence, fixed = TRUE),
  grepl('Lorenzen', bluefish$mortality_evidence, fixed = TRUE),
  grepl('fractional-year', bluefish$timing_evidence, fixed = TRUE),
  grepl('abundance-at-age', bluefish$output_evidence, fixed = TRUE),
  !any(stocks$scientific_name == 'Pomatomus saltatrix'),
  !any(stocks$stock_id == bluefish_unit),
  !any(bluefish_assessments$assessment_id == bluefish_unit),
  !any(bluefish_inputs$assessment_id == bluefish_unit),
  !any(bluefish_outputs$assessment_id == bluefish_unit),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_bluefish_2025.md')),
  file.exists(file.path('scripts', 'database',
    '335_screen_noaa_bluefish_2025.R'))
)
bluefish_cache <- file.path('source_cache',
  'discovery_noaa_bluefish_2025')
if (file.exists(file.path(bluefish_cache, 'sources.csv'))) {
  bluefish_sources <- read.csv(file.path(bluefish_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  bluefish_source_paths <- file.path(bluefish_cache, bluefish_sources$file)
  stopifnot(
    nrow(bluefish_sources) == 12L,
    all(file.exists(bluefish_source_paths)),
    all(file.info(bluefish_source_paths)$size == bluefish_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', bluefish_sources$sha256)),
    any(grepl('2025_BLF_UNIT_FIG_input_data.pdf', bluefish_sources$file, fixed = TRUE)),
    any(grepl('2025_BLF_UNIT_TAB_wham_par_tables.pdf', bluefish_sources$file, fixed = TRUE)),
    any(grepl('fisheries.noaa.gov', bluefish_sources$url, fixed = TRUE))
  )
}
cat('NOAA Atlantic Bluefish candidate-screening checks passed.\n')

gray_snapper <- lookup('NOAA:10221')
gray_snapper_unit <- 'noaa_gray_snapper_gulf_mexico'
gray_snapper_assessments <- read.csv(file.path('database', 'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
gray_snapper_inputs <- read.csv(file.path('database', 'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
gray_snapper_outputs <- read.csv(file.path('database', 'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
stopifnot(
  nrow(gray_snapper) == 1L,
  gray_snapper$candidate_unit_id == gray_snapper_unit,
  gray_snapper$match_status == 'new',
  gray_snapper$screening_status == 'screened',
  gray_snapper$eligibility == 'eligible',
  gray_snapper$import_status == 'not_started',
  grepl('age compositions', gray_snapper$catch_age_evidence, fixed = TRUE),
  grepl('FWRI', gray_snapper$survey_age_evidence, fixed = TRUE),
  grepl('fixed', gray_snapper$mortality_evidence, fixed = TRUE),
  grepl('July-December', gray_snapper$timing_evidence, fixed = TRUE),
  grepl('age-0 recruitment', gray_snapper$output_evidence, fixed = TRUE),
  grepl('No numeric fitted N-at-age', gray_snapper$output_evidence, fixed = TRUE),
  !any(stocks$scientific_name == 'Lutjanus griseus'),
  !any(stocks$stock_id == gray_snapper_unit),
  !any(gray_snapper_assessments$assessment_id == gray_snapper_unit),
  !any(gray_snapper_inputs$assessment_id == gray_snapper_unit),
  !any(gray_snapper_outputs$assessment_id == gray_snapper_unit),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_gray_snapper_2022.md')),
  file.exists(file.path('scripts', 'database',
    '336_screen_noaa_gray_snapper_2022.R'))
)
gray_snapper_cache <- file.path('source_cache',
  'discovery_noaa_gray_snapper_2022')
if (file.exists(file.path(gray_snapper_cache, 'sources.csv'))) {
  gray_snapper_sources <- read.csv(file.path(gray_snapper_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  gray_snapper_source_paths <- file.path(gray_snapper_cache, gray_snapper_sources$file)
  stopifnot(
    nrow(gray_snapper_sources) == 7L,
    all(file.exists(gray_snapper_source_paths)),
    all(file.info(gray_snapper_source_paths)$size == gray_snapper_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', gray_snapper_sources$sha256)),
    any(grepl('sedarweb.org', gray_snapper_sources$url, fixed = TRUE)),
    any(grepl('SEDAR 75', gray_snapper_sources$revision, fixed = TRUE))
  )
}
cat('NOAA Gulf of Mexico Gray Snapper candidate-screening checks passed.\n')

vermilion_snapper <- lookup('NOAA:10256')
vermilion_unit <- 'noaa_vermilion_snapper_gulf_mexico'
vermilion_assessments <- read.csv(file.path('database', 'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
vermilion_inputs <- read.csv(file.path('database', 'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
vermilion_outputs <- read.csv(file.path('database', 'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
vermilion_stocks <- read.csv(file.path('database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
vermilion_south_atlantic <- lookup('NOAA:10257')
vermilion_stocksmart_env <- new.env(parent = emptyenv())
load(file.path('source_cache',
  'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'),
  envir = vermilion_stocksmart_env)
vermilion_stocksmart <- vermilion_stocksmart_env$stock_assessment_summary
vermilion_accepted_run <- vermilion_stocksmart[
  vermilion_stocksmart$stock_id == 10256 & vermilion_stocksmart$assessment_id == 10102,
  , drop = FALSE]
vermilion_monitoring_update <- vermilion_stocksmart[
  vermilion_stocksmart$stock_id == 10256 & vermilion_stocksmart$assessment_id == 13023,
  , drop = FALSE]
stopifnot(
  nrow(vermilion_snapper) == 1L,
  vermilion_snapper$candidate_unit_id == vermilion_unit,
  vermilion_snapper$match_status == 'new',
  vermilion_snapper$screening_status == 'screened',
  vermilion_snapper$eligibility == 'eligible',
  vermilion_snapper$import_status == 'not_started',
  vermilion_snapper$assessment_area == 'Gulf of Mexico',
  grepl('SEDAR 67', vermilion_snapper$catch_age_evidence, fixed = TRUE),
  grepl('metric tons', vermilion_snapper$catch_age_evidence, fixed = TRUE),
  grepl('G-FISHER', vermilion_snapper$survey_age_evidence, fixed = TRUE),
  grepl('egg production', vermilion_snapper$maturity_evidence, fixed = TRUE),
  grepl('Lorenzen', vermilion_snapper$mortality_evidence, fixed = TRUE),
  grepl('no numeric N-at-age', vermilion_snapper$output_evidence, fixed = TRUE),
  nrow(vermilion_south_atlantic) == 1L,
  vermilion_south_atlantic$scientific_name == vermilion_snapper$scientific_name,
  vermilion_south_atlantic$assessment_area == 'Southern Atlantic Coast',
  nrow(vermilion_accepted_run) == 1L,
  vermilion_accepted_run$assessment_year == 2020L,
  vermilion_accepted_run$last_data_year == 2017L,
  vermilion_accepted_run$review_result == 'Full acceptance',
  nrow(vermilion_monitoring_update) == 1L,
  vermilion_monitoring_update$assessment_year == 2023L,
  vermilion_monitoring_update$assessment_type == 'Stock Monitoring Update',
  vermilion_monitoring_update$review_result ==
    'Accept previous approach, remand new attempt',
  !any(vermilion_stocks$scientific_name == 'Rhomboplites aurorubens'),
  !any(vermilion_assessments$assessment_id == vermilion_unit),
  !any(vermilion_inputs$assessment_id == vermilion_unit),
  !any(vermilion_outputs$assessment_id == vermilion_unit),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_vermilion_snapper_gulf_2020.md')),
  file.exists(file.path('scripts', 'database',
    '337_screen_noaa_vermilion_snapper_gom_2020.R'))
)
vermilion_cache <- file.path('source_cache',
  'discovery_noaa_vermilion_snapper_gom_2020')
if (file.exists(file.path(vermilion_cache, 'sources.csv'))) {
  vermilion_sources <- read.csv(file.path(vermilion_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  vermilion_source_paths <- file.path(vermilion_cache, vermilion_sources$file)
  stopifnot(
    nrow(vermilion_sources) == 6L,
    all(file.exists(vermilion_source_paths)),
    all(file.info(vermilion_source_paths)$size == vermilion_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', vermilion_sources$sha256)),
    any(grepl('sedarweb.org', vermilion_sources$url, fixed = TRUE)),
    any(grepl('Gulf Council SSC', vermilion_sources$revision, fixed = TRUE)),
    any(grepl('2027', vermilion_sources$revision, fixed = TRUE))
  )
}
cat('NOAA Gulf of Mexico Vermilion Snapper candidate-screening checks passed.\n')

gulf_king_mackerel <- lookup('NOAA:10171')
king_mackerel_unit <- 'noaa_gulf_king_mackerel'
king_mackerel_assessments <- read.csv(file.path('database', 'assessments.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
king_mackerel_inputs <- read.csv(file.path('database', 'inputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
king_mackerel_outputs <- read.csv(file.path('database', 'outputs.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
king_mackerel_stocks <- read.csv(file.path('database', 'stocks.csv'), stringsAsFactors = FALSE, na.strings = c('', 'NA'))
king_mackerel_south_atlantic <- lookup('NOAA:10172')
king_mackerel_stocksmart_env <- new.env(parent = emptyenv())
load(file.path('source_cache',
  'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'),
  envir = king_mackerel_stocksmart_env)
king_mackerel_stocksmart <- king_mackerel_stocksmart_env$stock_assessment_summary
king_mackerel_accepted_run <- king_mackerel_stocksmart[
  king_mackerel_stocksmart$stock_id == 10171 &
    king_mackerel_stocksmart$assessment_id == 10686, , drop = FALSE]
king_mackerel_monitoring_update <- king_mackerel_stocksmart[
  king_mackerel_stocksmart$stock_id == 10171 &
    king_mackerel_stocksmart$assessment_id == 13022, , drop = FALSE]
stopifnot(
  nrow(gulf_king_mackerel) == 1L,
  gulf_king_mackerel$candidate_unit_id == king_mackerel_unit,
  gulf_king_mackerel$match_status == 'new',
  gulf_king_mackerel$screening_status == 'screened',
  gulf_king_mackerel$eligibility == 'unresolved',
  gulf_king_mackerel$import_status == 'not_started',
  gulf_king_mackerel$assessment_area == 'Gulf of Mexico',
  grepl('conditional age-at-length', gulf_king_mackerel$catch_age_evidence,
    fixed = TRUE),
  grepl('not age-specific', gulf_king_mackerel$survey_age_evidence, fixed = TRUE),
  grepl('2017-2018', gulf_king_mackerel$output_evidence, fixed = TRUE),
  grepl('September 2027', gulf_king_mackerel$decision_reason, fixed = TRUE),
  nrow(king_mackerel_south_atlantic) == 1L,
  king_mackerel_south_atlantic$scientific_name == gulf_king_mackerel$scientific_name,
  king_mackerel_south_atlantic$assessment_area == 'Southern Atlantic Coast',
  nrow(king_mackerel_accepted_run) == 1L,
  king_mackerel_accepted_run$assessment_year == 2020L,
  king_mackerel_accepted_run$last_data_year == 2017L,
  king_mackerel_accepted_run$review_result == 'Full acceptance',
  nrow(king_mackerel_monitoring_update) == 1L,
  king_mackerel_monitoring_update$assessment_year == 2023L,
  king_mackerel_monitoring_update$assessment_type == 'Stock Monitoring Update',
  king_mackerel_monitoring_update$review_result ==
    'Accept previous approach, remand new attempt',
  !any(king_mackerel_stocks$scientific_name == 'Scomberomorus cavalla'),
  !any(king_mackerel_stocks$stock_id == king_mackerel_unit),
  !any(king_mackerel_assessments$assessment_id == king_mackerel_unit),
  !any(king_mackerel_inputs$assessment_id == king_mackerel_unit),
  !any(king_mackerel_outputs$assessment_id == king_mackerel_unit),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_gulf_king_mackerel_sedar38_2020.md')),
  file.exists(file.path('scripts', 'database',
    '338_screen_noaa_gulf_king_mackerel_2020.R'))
)
king_mackerel_cache <- file.path('source_cache',
  'discovery_noaa_gulf_king_mackerel_2020')
if (file.exists(file.path(king_mackerel_cache, 'sources.csv'))) {
  king_mackerel_sources <- read.csv(file.path(king_mackerel_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  king_mackerel_source_paths <- file.path(king_mackerel_cache, king_mackerel_sources$file)
  stopifnot(
    nrow(king_mackerel_sources) == 4L,
    all(file.exists(king_mackerel_source_paths)),
    all(file.info(king_mackerel_source_paths)$size == king_mackerel_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', king_mackerel_sources$sha256)),
    any(grepl('sedarweb.org', king_mackerel_sources$url, fixed = TRUE)),
    any(grepl('2027', king_mackerel_sources$revision, fixed = TRUE))
  )
}
cat('NOAA Gulf king mackerel candidate-screening checks passed.\n')

south_atlantic_king <- lookup('NOAA:10172')
gulf_king <- lookup('NOAA:10171')
south_atlantic_king_run <- king_mackerel_stocksmart[
  king_mackerel_stocksmart$stock_id == 10172 &
    king_mackerel_stocksmart$assessment_id == 10687, , drop = FALSE]
stopifnot(
  nrow(south_atlantic_king) == 1L,
  south_atlantic_king$candidate_unit_id == 'noaa_south_atlantic_king_mackerel',
  south_atlantic_king$match_status == 'new',
  south_atlantic_king$screening_status == 'screened',
  south_atlantic_king$eligibility == 'unresolved',
  south_atlantic_king$import_status == 'not_started',
  south_atlantic_king$scientific_name == gulf_king$scientific_name,
  south_atlantic_king$assessment_area == 'Southern Atlantic Coast',
  south_atlantic_king$candidate_unit_id != gulf_king$candidate_unit_id,
  grepl('conditional age-at-length', south_atlantic_king$catch_age_evidence,
    fixed = TRUE),
  grepl('age-0 trawl', south_atlantic_king$survey_age_evidence, fixed = TRUE),
  grepl('0.657', south_atlantic_king$mortality_evidence, fixed = TRUE),
  grepl('millions of eggs', south_atlantic_king$output_evidence, fixed = TRUE),
  grepl('N-at-age', south_atlantic_king$output_evidence, fixed = TRUE),
  nrow(south_atlantic_king_run) == 1L,
  south_atlantic_king_run$assessment_year == 2020L,
  south_atlantic_king_run$last_data_year == 2017L,
  south_atlantic_king_run$assessment_type == 'Operational',
  south_atlantic_king_run$review_result == 'Full acceptance',
  !any(king_mackerel_stocks$scientific_name == 'Scomberomorus cavalla'),
  !any(king_mackerel_assessments$assessment_id == south_atlantic_king$candidate_unit_id),
  !any(king_mackerel_inputs$assessment_id == south_atlantic_king$candidate_unit_id),
  !any(king_mackerel_outputs$assessment_id == south_atlantic_king$candidate_unit_id),
  file.exists(file.path('discovery',
    'source_reviews', 'noaa_south_atlantic_king_mackerel_sedar38_2020.md')),
  file.exists(file.path('scripts', 'database',
    '339_screen_noaa_south_atlantic_king_mackerel_2020.R'))
)
south_atlantic_king_cache <- file.path('source_cache',
  'discovery_noaa_south_atlantic_king_mackerel_2020')
if (file.exists(file.path(south_atlantic_king_cache, 'sources.csv'))) {
  south_atlantic_king_sources <- read.csv(file.path(south_atlantic_king_cache, 'sources.csv'),
    stringsAsFactors = FALSE)
  south_atlantic_king_paths <- file.path(south_atlantic_king_cache,
    south_atlantic_king_sources$file)
  stopifnot(
    nrow(south_atlantic_king_sources) == 2L,
    all(file.exists(south_atlantic_king_paths)),
    all(file.info(south_atlantic_king_paths)$size == south_atlantic_king_sources$bytes),
    all(grepl('^[[:xdigit:]]{64}$', south_atlantic_king_sources$sha256)),
    any(grepl('sedarweb.org', south_atlantic_king_sources$url, fixed = TRUE)),
    any(grepl('2026-2027', south_atlantic_king_sources$revision, fixed = TRUE))
  )
}
cat('NOAA South Atlantic king mackerel candidate-screening checks passed.\n')
south_atlantic_spanish <- lookup('NOAA:10174')
gulf_spanish <- lookup('NOAA:10173')
spanish_stocksmart_env <- new.env(parent = emptyenv())
load(file.path('source_cache',
  'discovery_noaa_stocksmart', 'stock_assessment_summary.rda'),
  envir = spanish_stocksmart_env)
spanish_stocksmart <- spanish_stocksmart_env$stock_assessment_summary
spanish_run <- spanish_stocksmart[
  spanish_stocksmart$stock_id == 10174 &
    spanish_stocksmart$assessment_id == 12822, , drop = FALSE]
spanish_units <- read.csv('discovery/inventory_units.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
spanish_unit <- spanish_units[
  spanish_units$unit_key == 'candidate:noaa_south_atlantic_spanish_mackerel', , drop = FALSE]
spanish_assessments <- read.csv('database/assessments.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
spanish_inputs <- read.csv('database/inputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
spanish_outputs <- read.csv('database/outputs.csv',
  stringsAsFactors = FALSE, na.strings = c('', 'NA'))
spanish_cache <- file.path('source_cache',
  'discovery_noaa_south_atlantic_spanish_mackerel_2022')
spanish_sources <- read.csv(file.path(spanish_cache, 'sources.csv'),
  stringsAsFactors = FALSE)
spanish_source_paths <- file.path(spanish_cache, spanish_sources$file)
stopifnot(
  nrow(south_atlantic_spanish) == 1L,
  south_atlantic_spanish$candidate_unit_id == 'noaa_south_atlantic_spanish_mackerel',
  south_atlantic_spanish$match_status == 'new',
  south_atlantic_spanish$screening_status == 'screened',
  south_atlantic_spanish$eligibility == 'eligible',
  south_atlantic_spanish$import_status == 'not_started',
  south_atlantic_spanish$scientific_name == gulf_spanish$scientific_name,
  south_atlantic_spanish$assessment_area == 'Southern Atlantic Coast',
  south_atlantic_spanish$candidate_unit_id != gulf_spanish$candidate_unit_id,
  grepl('ages 0-10+', south_atlantic_spanish$catch_age_evidence, fixed = TRUE),
  grepl('pooled across years', south_atlantic_spanish$catch_age_evidence, fixed = TRUE),
  grepl('age-0', south_atlantic_spanish$survey_age_evidence, fixed = TRUE),
  grepl('June 1', south_atlantic_spanish$timing_evidence, fixed = TRUE),
  grepl('end of July', south_atlantic_spanish$timing_evidence, fixed = TRUE),
  nrow(spanish_run) == 1L,
  spanish_run$assessment_year == 2023L,
  spanish_run$last_data_year == 2020L,
  spanish_run$assessment_type == 'Operational',
  spanish_run$assessment_model == 'BAM',
  spanish_run$review_result == 'Full acceptance',
  nrow(spanish_unit) == 1L,
  spanish_unit$eligibility == 'eligible',
  !any(spanish_assessments$assessment_id == south_atlantic_spanish$candidate_unit_id),
  !any(spanish_inputs$assessment_id == south_atlantic_spanish$candidate_unit_id),
  !any(spanish_outputs$assessment_id == south_atlantic_spanish$candidate_unit_id),
  nrow(spanish_sources) == 5L,
  all(file.exists(spanish_source_paths)),
  all(file.info(spanish_source_paths)$size == spanish_sources$bytes),
  all(grepl('^[[:xdigit:]]{64}$', spanish_sources$sha256)),
  all(spanish_sources$retrieved_utc == '2026-10-30'),
  file.exists('discovery/source_reviews/noaa_south_atlantic_spanish_mackerel_2022.md'),
  file.exists('scripts/database/340_screen_noaa_south_atlantic_spanish_mackerel_2022.R'),
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
cat('NOAA South Atlantic Spanish mackerel candidate-screening checks passed.\n')

sprat_english_channel <- lookup('ICES:spr.27.7de')
sprat_english_channel_unit <- units[
  units$candidate_unit_id == 'ices_sprat_english_channel', , drop = FALSE]
stopifnot(
  nrow(sprat_english_channel) == 1L,
  sprat_english_channel$match_status == 'new',
  sprat_english_channel$screening_status == 'screened',
  sprat_english_channel$eligibility == 'ineligible',
  sprat_english_channel$import_status == 'not_started',
  sprat_english_channel_unit$inventory_entries == 1L,
  sprat_english_channel_unit$eligibility == 'ineligible',
  grepl('not yet used', sprat_english_channel$survey_age_evidence, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'ices_sprat_english_channel_2026.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$identity_unreviewed) == 0L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
cat('ICES English Channel sprat inventory audit checks passed.\n')

sprat_celtic_seas <- lookup('ICES:spr.27.67a-cf-k')
sprat_celtic_seas_unit <- units[
  units$candidate_unit_id == 'ices_sprat_celtic_seas', , drop = FALSE]
stopifnot(
  nrow(sprat_celtic_seas) == 1L,
  sprat_celtic_seas$match_status == 'new',
  sprat_celtic_seas$screening_status == 'screened',
  sprat_celtic_seas$eligibility == 'ineligible',
  sprat_celtic_seas$import_status == 'not_started',
  sprat_celtic_seas_unit$inventory_entries == 1L,
  sprat_celtic_seas_unit$eligibility == 'ineligible',
  grepl('Category 5.2', sprat_celtic_seas$catch_age_evidence, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'ices_sprat_celtic_seas_2025.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$identity_unreviewed) == 0L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
cat('ICES Celtic Seas sprat inventory audit checks passed.\n')

bay_biscay_seabass <- lookup('ICES:bss.27.8ab')
bay_biscay_seabass_unit <- units[
  units$candidate_unit_id == 'ices_seabass_8ab', , drop = FALSE]
stopifnot(
  nrow(bay_biscay_seabass) == 1L,
  bay_biscay_seabass$match_status == 'new',
  bay_biscay_seabass$screening_status == 'screened',
  bay_biscay_seabass$eligibility == 'eligible',
  bay_biscay_seabass$import_status == 'not_started',
  bay_biscay_seabass_unit$inventory_entries == 1L,
  bay_biscay_seabass_unit$eligibility == 'eligible',
  grepl('conditional age-at-length', bay_biscay_seabass$catch_age_evidence,
    fixed = TRUE),
  grepl('ages 1-4', bay_biscay_seabass$survey_age_evidence, fixed = TRUE),
  grepl('0.840918', bay_biscay_seabass$mortality_evidence, fixed = TRUE),
  file.exists(file.path('discovery',
    'source_reviews', 'ices_seabass_8ab_2026.md')),
  sum(ices_progress$new) == 212L,
  sum(ices_progress$identity_unreviewed) == 0L,
  sum(ices_progress$eligible) == 60L,
  sum(ices_progress$excluded) == 185L,
  sum(ices_progress$eligibility_unresolved) == 29L,
  sum(ices_progress$screening_complete) == 274L,
  sum(ices_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$eligible) == 170L,
  sum(progress$eligible_new) == 100L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)
cat('ICES Bay of Biscay sea bass inventory audit checks passed.\n')


sharpchin_goa <- lookup('NOAA:10434')
stopifnot(
  nrow(sharpchin_goa) == 1L,
  sharpchin_goa$candidate_unit_id == 'noaa_goa_sharpchin_goa',
  sharpchin_goa$match_status == 'new',
  sharpchin_goa$screening_status == 'screened',
  sharpchin_goa$eligibility == 'ineligible',
  sharpchin_goa$import_status == 'not_started',
  sum(noaa_progress$new) == 388L,
  sum(noaa_progress$identity_unreviewed) == 2L,
  sum(noaa_progress$excluded) == 252L,
  sum(noaa_progress$screening_complete) == 432L,
  sum(noaa_progress$screening_not_started) == 0L,
  sum(progress$new) == 663L,
  sum(progress$identity_unreviewed) == 100L,
  sum(progress$excluded) == 584L,
  sum(progress$eligibility_unresolved) == 151L,
  sum(progress$screening_complete) == 905L,
  sum(progress$screening_not_started) == 0L,
  nrow(units) == 736L,
  sum(units$inventory_entries) == 775L,
  sum(!is.na(units$candidate_unit_id) & nzchar(units$candidate_unit_id)) == 636L)

source(file.path(root, 'tests', 'test_noaa_aurora_rockfish_2013.R'))

source(file.path(root, 'tests', 'test_noaa_brown_rockfish_2013.R'))

source(file.path(root, 'tests', 'test_noaa_shortraker_2023_2024.R'))

source(file.path(root, 'tests', 'test_ices_herring_7ef_2026.R'))

source(file.path(root, 'tests', 'test_ices_thornback_ray_7e_2024.R'))

source(file.path(root, 'tests', 'test_ices_blonde_ray_7e_2024.R'))

source(file.path(root, 'tests', 'test_noaa_dusky_rockfish_2024_screen.R'))

source(file.path(root, 'tests', 'test_dfo_american_eel_screen.R'))

source(file.path(root, 'tests', 'test_dfo_maritimes_gaspereau_screen.R'))

source(file.path(root, 'tests', 'test_dfo_yukon_chinook_screen.R'))

source(file.path(root, 'tests', 'test_dfo_north_coast_chinook_screen.R'))

source(file.path(root, 'tests', 'test_dfo_interior_fraser_coho_screen.R'))

source(file.path(root, 'tests', 'test_dfo_striped_bass_bay_of_fundy_screen.R'))
source(file.path(root, 'tests', 'test_dfo_eulachon_fraser_screen.R'))
source(file.path(root, 'tests', 'test_dfo_fraser_chum_screen.R'))

source(file.path(root, 'tests', 'test_dfo_pacific_salmon_remaining_screen.R'))


source(file.path(root, 'tests', 'test_ices_bay_biscay_elasmobranchs_2026.R'))

source(file.path(root, 'tests', 'test_ices_iberian_sole_indicators_2026.R'))

source(file.path(root, 'tests', 'test_ices_baltic_flatfish_2026.R'))
source(file.path(root, 'tests', 'test_ices_baltic_remaining_2026.R'))

source(file.path(root, 'tests', 'test_noaa_west_coast_chinook_2026.R'))

source(file.path(root, 'tests', 'test_noaa_ocean_pout_2022.R'))

source(file.path(root, 'tests', 'test_noaa_vermilion_snapper_sa_2018_screen.R'))

source(file.path(root, 'tests', 'test_noaa_monkfish_2022.R'))

source(file.path(root, 'tests', 'test_noaa_atlantic_salmon_gom_2025.R'))

source(file.path(root, 'tests', 'test_noaa_greater_amberjack_south_atlantic_2020_screen.R'))
source(file.path(root, 'tests', 'test_noaa_lingcod_2021_screen.R'))
source(file.path(root, 'tests', 'test_noaa_cabezon_2019_screen.R'))
source(file.path(root, 'tests', 'test_noaa_pacific_spiny_dogfish_2021_screen.R'))
source(file.path(root, 'tests', 'test_noaa_copper_california_2023_screen.R'))
source(file.path(root, 'tests', 'test_noaa_copper_washington_oregon_2021_screen.R'))
source(file.path(root, 'tests', 'test_noaa_gulf_cobia_2020_screen.R'))
source(file.path(root, 'tests', 'test_noaa_southeastern_mutton_snapper_sedar79_2024_screen.R'))
source(file.path(root, 'tests', 'test_ices_thornback_ray_6_2026_screen.R'))

source(file.path(root, 'tests', 'test_ices_greater_silver_smelt_5b6a_2026_screen.R'))

source(file.path(root, 'tests', 'test_ices_initial_data_limited_group_2026_screen.R'))

source(file.path(root, 'tests', 'test_ices_elasmobranch_group_2026_screen.R'))
source(file.path(root, 'tests', 'test_ices_pelagic_redfish_2026_screen.R'))

source(file.path(root, 'tests', 'test_ices_ling_faroe_5b_2026.R'))

source(file.path(root, 'tests', 'test_ices_ling_1_2_2025_screen.R'))

source(file.path(root, 'tests', 'test_ices_blue_ling_5b6712_2026_screen.R'))

source(file.path(root, 'tests', 'test_ices_spurdog_nea_2026_screen.R'))

source(file.path(root, 'tests', 'test_noaa_wreckfish_2014_screen.R'))

source(file.path(root, 'tests', 'test_noaa_gulf_golden_tilefish_sedar22_2011_screen.R'))

source(file.path(root, 'tests', 'test_noaa_bank_rockfish_california_2010_screen.R'))

source(file.path(root, 'tests', 'test_ices_saithe_7_10_2025_screen.R'))


source(file.path(root, 'tests', 'test_ices_ray_method_group_2026.R'))
source(file.path(root, 'tests', 'test_ices_unstarted_non_age_methods_2026.R'))
source(file.path(root, 'tests', 'test_ices_final_five_2026.R'))
source(file.path(root, 'tests', 'test_noaa_longnose_skate_2019_screen.R'))
source(file.path(root, 'tests', 'test_noaa_china_rockfish_2015_screen.R'))

source(file.path(root, 'tests', 'test_noaa_nefsc_skates_2023_screen.R'))
source(file.path(root, 'tests', 'test_noaa_atlantic_wolffish_2022_screen.R'))
source(file.path(root, 'tests', 'test_noaa_offshore_hake_2023_screen.R'))

source(file.path(root, 'tests', 'test_noaa_pacific_grenadier_2010_screen.R'))

source('scripts/database/515_screen_noaa_caribbean_queen_triggerfish_2024.R')
source('tests/test_noaa_caribbean_queen_triggerfish_2024_screen.R')

source('scripts/database/516_screen_noaa_goa_skate_complex_2023_2026.R')
source('tests/test_noaa_goa_skate_complex_2023_2026_screen.R')

source('scripts/database/517_reconcile_noaa_goa_shallow_flatfish_legacy_2016.R')
source('tests/test_noaa_goa_shallow_flatfish_legacy_2016_screen.R')

source('scripts/database/527_screen_noaa_sedar_sharks_2007_2018.R')
source('scripts/database/528_screen_noaa_atlantic_cobia_sedar58_2020.R')
source('scripts/database/535_screen_noaa_remaining_2026.R')
source('scripts/database/536_assign_candidate_unit_keys_2026.R')
source('scripts/database/195_summarize_discovery.R')
source('scripts/database/196_summarize_inventory_units.R')
source('tests/test_noaa_sedar_shark_screen.R')
source('tests/test_noaa_atlantic_cobia_sedar58_screen.R')
source('tests/test_noaa_remaining_unscreened_2026.R')
source('tests/test_candidate_unit_keys_2026.R')

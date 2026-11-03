root <- "."
register_path <- file.path(root, 'discovery', 'candidates.csv')
register <- read.csv(register_path, stringsAsFactors = FALSE,
  na.strings = c('', 'NA'), check.names = FALSE)
source(file.path(root, 'scripts', 'database', 'candidate_register_io.R'))

source_urls <- paste(
  'https://iccat.int/Documents/Meetings/Docs/2023/REPORTS/2023_BSH_ENG.pdf;',
  'https://sedarweb.org/docs/sar/CaribData_Final_0.pdf;',
  'https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAIskate.pdf;',
  'https://meetings.wcpfc.int/file/6120/download;',
  'https://repository.library.noaa.gov/view/noaa/18085;',
  'https://meetings.wcpfc.int/system/files/2025-07/SC21-SA-WP-08_2025%20Oceanic%20whitetip%20shark%20assesment_neubauer-Rev1.pdf;',
  'https://sedarweb.org/assessments/sedar-77/;',
  'https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/;',
  'https://www.fisheries.noaa.gov/s3/2021-04/Appendix-D.pdf',
  sep = ' ')

ids <- paste0('NOAA:', c(10689, 10989, 11402, 11444, 11712, 11714,
  11724, 11763, 14821, 14822, 15052, 15310, 15335, 15351, 15439,
  15512, 15577))
units <- c(
  'noaa_blue_shark_north_atlantic',
  'noaa_caribbean_parrotfishes_complex',
  'noaa_bsai_skates_legacy_aggregate',
  'noaa_bsai_other_skates',
  'noaa_pacific_bigeye_thresher',
  'noaa_common_thresher_pacific_coast',
  'noaa_oceanic_whitetip_wcpo',
  'noaa_scalloped_hammerhead_atlantic_gulf',
  'noaa_blue_deacon_california',
  'noaa_blue_deacon_oregon',
  'noaa_gopher_black_yellow_northern_california',
  'noaa_vermilion_sunset_southern_california',
  'noaa_vermilion_sunset_northern_california',
  'noaa_blue_rockfish_southern_california',
  'noaa_st_thomas_st_john_grouper_unit_3',
  'noaa_st_croix_grouper_unit_4',
  'noaa_puerto_rico_grouper_unit_6')

eligibility <- c('ineligible', 'ineligible', 'ineligible', 'ineligible',
  'ineligible', 'unresolved', 'ineligible', 'unresolved', 'eligible',
  'eligible', 'eligible', 'eligible', 'eligible', 'ineligible',
  'ineligible', 'ineligible', 'ineligible')
match_status <- rep('new', length(ids))
match_status[ids == 'NOAA:11402'] <- 'ambiguous'

review <- data.frame(
  candidate_id = ids,
  candidate_unit_id = units,
  match_status = match_status,
  screening_status = 'screened',
  eligibility = eligibility,
  import_status = 'not_started',
  catch_age_evidence = c(
    'The 2023 ICCAT assessment documents catches, CPUE, and size-composition inputs; it reports no age-composition or catch-at-age likelihood input.',
    'The 2009 Caribbean Fisheries Data Evaluation is a data-evaluation workshop, not an accepted age-structured production assessment for this complex.',
    'The 2007 NOAA inventory row is a legacy aggregate; the current complex has separate Alaska skate and Other Skates assessment approaches.',
    'The latest Other Skates assessment uses aggregate catch and survey biomass with the Tier 5 REMA model; it has no age-specific likelihood inputs.',
    'The WCPFC risk assessment relies on catch, CPUE, observer, and size information; age data are explicitly limited and no age-structured population fit was made.',
    'The 2018 Stock Synthesis assessment reports catch and length inputs with paired age-length information; exact run-matched input arrays and their use for a defensible tinyAM age series remain unverified.',
    'The 2025 Stock Synthesis assessment documents catch, CPUE, and length compositions; no age-composition likelihood or catch-at-age input is reported.',
    'The latest accepted operational assessment in the inventory is a surplus-production model; the later SEDAR 77 age-structured work was not recommended for OFL advice.',
    'The 2017 assessment and public model archive contain catch totals, length compositions, and age information used by the California blue/deacon model; age-specific reconstruction should be checked from the native files.',
    'The 2017 assessment and public model archive contain catch totals, length compositions, and age information used by the Oregon blue/deacon model; age-specific reconstruction should be checked from the native files.',
    'The 2019 Stock Synthesis assessment and public model files contain catch, length and age information; the exact catch-at-age reconstruction should be checked from the native files.',
    'The 2021 Stock Synthesis assessment and public model archive use catch, length compositions, and age compositions conditioned on length.',
    'The 2021 Stock Synthesis assessment and public model archive use catch, length compositions, and age compositions conditioned on length.',
    'The latest inventory assessment is a data-limited DCAC analysis, not an age-structured production assessment.',
    'The 2014 assessment uses a non-equilibrium mean-length estimator; age-specific catch inputs are not part of that model.',
    'The 2014 assessment uses a non-equilibrium mean-length estimator; age-specific catch inputs are not part of that model.',
    'The 2014 assessment uses a non-equilibrium mean-length estimator; age-specific catch inputs are not part of that model.'),
  survey_age_evidence = c(
    'Abundance information is aggregate CPUE; the 2023 assessment report does not identify annual age-specific survey observations or survey age compositions.',
    'The workshop does not provide an accepted abundance-index-at-age likelihood for this complex.',
    'The 2023 assessment splits harvest advice between an age-structured Alaska skate model and an aggregate Tier 5 Other Skates biomass model; the legacy row does not map to one current unit.',
    'The assessment estimates aggregate biomass from survey indices; no survey age-composition or abundance-index-at-age series is reported.',
    'Observer and CPUE indices are aggregate; age observations are insufficient for an age-structured population assessment.',
    'The assessment uses aggregate abundance indices and paired age-length data; an age-specific index would require a documented reconstruction not established by the reviewed source files.',
    'The 2025 assessment uses aggregate CPUE and length compositions, not survey age compositions or an abundance index at age.',
    'The SEDAR 77 age data do not establish an accepted production assessment for current management advice; the latest accepted operational model is aggregate.',
    'The California assessment reports aggregate abundance indices and age-length observations; the model archive is available for checking any reconstruction.',
    'The Oregon assessment reports aggregate abundance indices and age-length observations; the model archive is available for checking any reconstruction.',
    'The assessment uses aggregate indices and age data in the Stock Synthesis fit; retain the native composition likelihood rather than calling these observations an index-at-age.',
    'The assessment includes five aggregate abundance indices and conditional age-at-length observations; it does not report direct index-at-age observations.',
    'The assessment includes aggregate abundance indices and conditional age-at-length observations; it does not report direct index-at-age observations.',
    'No age-specific survey index is reported for the data-limited DCAC assessment.',
    'The mean-length estimator is not an age-specific abundance-index model.',
    'The mean-length estimator is not an age-specific abundance-index model.',
    'The mean-length estimator is not an age-specific abundance-index model.'),
  weights_evidence = c(
    'Biological inputs are reported for the ICCAT assessment, but they do not supply age-disaggregated fishery observations.',
    'Run-specific weight-at-age inputs were not identified in the workshop record.',
    'The 2023 report gives separate fixed mortality values and age-structured biology for Alaska skate, but the 11402 legacy aggregate overlaps two current components.',
    'A fixed M assumption is reported, but the current Other Skates fit is aggregate biomass only.',
    'Life-history information supports the risk assessment but not age-specific population inputs.',
    'Growth and age-length information are documented; exact run-specific weight and maturity vectors require source-file review.',
    'The assessment documents biological inputs, but not age-specific observation series.',
    'The latest accepted operational model does not use age-specific biological surfaces.',
    'Age-specific biology is documented in the assessment and model archive; exact matrices remain for source curation.',
    'Age-specific biology is documented in the assessment and model archive; exact matrices remain for source curation.',
    'Age-specific biology and sex structure are described in the assessment and model archive.',
    'The assessment documents weight, maturity, fecundity and estimated sex-specific M; values should be extracted from the native files.',
    'The assessment documents weight, maturity, fecundity and estimated sex-specific M; values should be extracted from the native files.',
    'Age-specific weights and maturity are not inputs to the DCAC assessment.',
    'Age-specific weights and maturity are not inputs to the non-equilibrium mean-length estimator.',
    'Age-specific weights and maturity are not inputs to the non-equilibrium mean-length estimator.',
    'Age-specific weights and maturity are not inputs to the non-equilibrium mean-length estimator.'),
  maturity_evidence = c(
    'The assessment does not report age-specific maturity as an observation series.',
    'No accepted age-based maturity schedule was identified for this complex.',
    'Age-specific biology is available for Alaska skate, but the legacy aggregate has no unambiguous mapping to the current subunits.',
    'No age-specific maturity schedule is used for the aggregate Tier 5 biomass model.',
    'No age-specific maturity schedule is used in the risk assessment.',
    'The assessment uses life-history relationships, but the run-matched values have not been extracted.',
    'Age-specific maturity is not a reported observation input to the 2025 model.',
    'Age-specific maturity is not used by the accepted aggregate surplus-production model.',
    'Age-specific maturity is available in the age-structured assessment materials; exact values remain to be checked in source files.',
    'Age-specific maturity is available in the age-structured assessment materials; exact values remain to be checked in source files.',
    'Age-specific maturity is documented in the assessment/model files.',
    'The 2021 model documents maturity-at-length and fecundity-at-length; exact model values are in the public model archive.',
    'The 2021 model documents maturity-at-length and fecundity-at-length; exact model values are in the public model archive.',
    'No age-specific maturity input is used by the data-limited method.',
    'No age-specific maturity input is used by the mean-length method.',
    'No age-specific maturity input is used by the mean-length method.',
    'No age-specific maturity input is used by the mean-length method.'),
  mortality_evidence = c(
    'Stock productivity and mortality assumptions are reported but do not provide the missing age-disaggregated observation data.',
    'No age-specific natural-mortality assumption was identified for an accepted age-structured assessment.',
    'The 2023 report uses M = 0.13 for Alaska skate and M = 0.10 for Other Skates; the 2007 aggregate cannot be treated as one current M surface.',
    'The Tier 5 aggregate biomass model does not estimate an age-specific M surface.',
    'The risk assessment does not estimate annual age-specific M or population states.',
    'Natural-mortality assumptions are documented in the assessment; run-specific values need source-file review.',
    'The assessment documents mortality assumptions, but has no age-based observation likelihood.',
    'The accepted surplus-production assessment does not provide age-specific M.',
    'The model archive documents age-structured mortality assumptions; exact inputs remain to be extracted.',
    'The model archive documents age-structured mortality assumptions; exact inputs remain to be extracted.',
    'The model files document age-structured mortality assumptions; exact inputs remain to be extracted.',
    'Natural mortality is estimated separately by sex in the 2021 assessment.',
    'Natural mortality is estimated separately by sex in the 2021 assessment.',
    'The DCAC method does not estimate an age-specific M surface.',
    'The mean-length assessment does not estimate age-specific M.',
    'The mean-length assessment does not estimate age-specific M.',
    'The mean-length assessment does not estimate age-specific M.'),
  timing_evidence = c(
    'Annual model timing is documented; no age-specific survey timing can be assigned because the accepted fit uses aggregate indices.',
    'No age-structured survey timing applies to the data-evaluation record.',
    'Annual assessment timing is documented, but the legacy aggregate does not identify one current age-structured unit.',
    'The aggregate biomass index model does not provide age-specific observation timing.',
    'The risk assessment does not define age-specific survey timing.',
    'Annual assessment timing is described; the within-year timing for aggregate indices remains to be verified.',
    'The assessment is annual; timing of aggregate indices does not create an age-specific observation series.',
    'The accepted aggregate model has no age-specific timing specification.',
    'Annual time step; native fleet and index timing should be verified from the model files.',
    'Annual time step; native fleet and index timing should be verified from the model files.',
    'Annual time step; native timing remains to be extracted from the model files.',
    'Annual time step; survey-specific timing should be checked in the native model inputs.',
    'Annual time step; survey-specific timing should be checked in the native model inputs.',
    'No age-specific survey timing applies to the DCAC method.',
    'No age-specific survey timing applies to the mean-length method.',
    'No age-specific survey timing applies to the mean-length method.',
    'No age-specific survey timing applies to the mean-length method.'),
  output_evidence = c(
    'The 2023 report provides aggregate population and mortality results, not annual N-at-age or F-at-age output series.',
    'No accepted age-structured population or mortality outputs were identified.',
    'The 2023 report reports outputs for two current units; the old 2007 aggregate has no one-to-one current-unit output series.',
    'The 2023 assessment reports aggregate biomass and harvest advice; no age-specific population or mortality output is produced.',
    'Risk metrics and fishing mortality summaries are not age-specific annual population outputs.',
    'The assessment reports population summaries; numeric age-specific output files and run-matched input data remain unverified.',
    'The 2025 assessment reports aggregate biomass, depletion and F outputs, not age-specific population surfaces.',
    'The accepted operational model provides aggregate results; SEDAR 77 results are not an accepted OFL basis.',
    'The assessment report provides aggregate outputs and the public model archive supports later extraction of age-specific surfaces.',
    'The assessment report provides aggregate outputs and the public model archive supports later extraction of age-specific surfaces.',
    'The assessment report and model archive provide age-structured model outputs and stock-summary results.',
    'The assessment reports spawning output and the model archive provides age-structured fitted quantities.',
    'The assessment reports spawning output and the model archive provides age-structured fitted quantities.',
    'The data-limited assessment reports yield advice, not age-specific population or mortality outputs.',
    'The mean-length assessment reports aggregate status/yield results, not age-specific population outputs.',
    'The mean-length assessment reports aggregate status/yield results, not age-specific population outputs.',
    'The mean-length assessment reports aggregate status/yield results, not age-specific population outputs.'),
  detailed_source_url = source_urls,
  review_date = '2026-11-02',
  decision_reason = c(
    'Ineligible: the latest accepted assessment does not provide age-disaggregated population observations or outputs; biological age information alone is insufficient.',
    'Ineligible: the source is a historical data-evaluation workshop, not a current age-structured production assessment with age-specific inputs and outputs.',
    'Ambiguous legacy identity and ineligible as an independent current case: the old aggregate overlaps two current skate components assessed with different methods.',
    'Ineligible: the current Other Skates assessment is an aggregate Tier 5 biomass-index model with no age-disaggregated likelihood or output.',
    'Ineligible: the WCPFC product is a sustainability risk assessment rather than an age-structured population assessment, and the report says age data are limited.',
    'Unresolved: paired age-length data are documented, but the run-matched inputs and a defensible reconstruction of age-specific tinyAM observations and outputs were not verified.',
    'Ineligible: the latest production assessment uses aggregate CPUE and length compositions without age-disaggregated likelihood inputs or outputs.',
    'Unresolved: SEDAR 77 provides age-structured assessment material, but NOAA reports that CIE reviewers recommended against using it for OFL advice; the latest accepted operational model is aggregate.',
    'Eligible for source curation: the accepted age-structured fit has public native model files, age observations, abundance indices, biological assumptions, and comparable population outputs.',
    'Eligible for source curation: the accepted age-structured fit has public native model files, age observations, abundance indices, biological assumptions, and comparable population outputs.',
    'Eligible for source curation: the accepted age-structured fit has public native model files, age observations, abundance indices, biological assumptions, and comparable population outputs.',
    'Eligible for source curation: the accepted age-structured fit has public native model files, age observations, abundance indices, biological assumptions, and comparable population outputs.',
    'Eligible for source curation: the accepted age-structured fit has public native model files, age observations, abundance indices, biological assumptions, and comparable population outputs.',
    'Ineligible: the latest assessment is a data-limited DCAC analysis and does not provide age-disaggregated inputs or fitted outputs.',
    'Ineligible: the assessment uses a mean-length estimator, not age-disaggregated population inputs or outputs.',
    'Ineligible: the assessment uses a mean-length estimator, not age-disaggregated population inputs or outputs.',
    'Ineligible: the assessment uses a mean-length estimator, not age-disaggregated population inputs or outputs.'),
  notes = c(
    'Current North Atlantic blue shark unit. The detailed assessment report and input tables were reviewed; no canonical numerical records were added.',
    'Keep the named complex as an inventory candidate, but treat the 2009 SEDAR data evaluation as historical/non-assessment evidence. No canonical records were added.',
    'The 2007 assessment row predates the current two-unit skate approach. Do not map it to either current assessment unit without a defensible boundary crosswalk. No canonical records were added.',
    'The 2023 Other Skates assessment is distinct from Alaska skate and is index-based. No canonical records were added.',
    'The 2018 WCPFC risk assessment is not an accepted age-structured production assessment. No canonical records were added.',
    'NOAA report and StockSMART refer to the Pacific coast common thresher unit. No canonical records were added pending source-data verification.',
    'The 2025 WCPFC assessment is the latest detailed production assessment found for this unit. No canonical records were added.',
    'Do not use the SEDAR 77 age-structured model as official management output while NOAA advises against using it for OFL advice. No canonical records were added.',
    'California 2017 Stock Synthesis assessment; 2019 catch update is a projection/update, not a new population-model fit. California and Oregon remain separate assessment units. No canonical records were added.',
    'Oregon 2017 Stock Synthesis assessment; keep separate from the California unit. No canonical records were added.',
    'Current Northern California Gopher/Black-and-Yellow Rockfish complex. No canonical records were added.',
    'Southern California assessment is south of Point Conception; preserve the combined Vermilion/Sunset assessment unit. No canonical records were added.',
    'Northern California assessment is north of Point Conception; preserve the combined Vermilion/Sunset assessment unit. No canonical records were added.',
    'The Southern California blue rockfish record is separate from the 2017 blue/deacon models spanning Point Conception to Oregon. No canonical records were added.',
    'Legacy NOAA Stock SMART grouper unit; current assessment method is mean-length based. No canonical records were added.',
    'Legacy NOAA Stock SMART grouper unit; current assessment method is mean-length based. No canonical records were added.',
    'Legacy NOAA Stock SMART grouper unit; current assessment method is mean-length based. No canonical records were added.'),
  stringsAsFactors = FALSE)

if (anyDuplicated(register$candidate_id) || anyDuplicated(review$candidate_id))
  stop('NOAA candidate identifiers are duplicated.', call. = FALSE)
if (anyDuplicated(review$candidate_unit_id))
  stop('Reviewed assessment unit identifiers must be unique.', call. = FALSE)

blank <- function(x) length(x) != 1L || is.na(x) || !nzchar(x)
is_same <- function(x, y) {
  x <- as.character(x)
  y <- as.character(y)
  length(x) == length(y) && all((is.na(x) & is.na(y)) |
    (!is.na(x) & !is.na(y) & x == y))
}
for (i in seq_len(nrow(review))) {
  id <- review$candidate_id[i]
  row_index <- match(id, register$candidate_id)
  if (is.na(row_index)) stop('Candidate is missing: ', id, '.', call. = FALSE)
  old <- register[row_index, , drop = FALSE]
  initial <- old$match_status == 'unreviewed' &&
    old$screening_status == 'not_started' && old$eligibility == 'unresolved' &&
    old$import_status == 'not_started' && blank(old$candidate_unit_id)
  corrected_hammerhead <- id == 'NOAA:11763' &&
    old$match_status == 'new' && old$screening_status == 'screened' &&
    old$eligibility == 'ineligible' && old$import_status == 'not_started'
  unchanged <- all(vapply(setdiff(names(review), 'candidate_id'),
    function(name) is_same(register[[name]][row_index], review[[name]][i]),
    logical(1L)))
  if (!initial && !corrected_hammerhead && !unchanged)
    stop('Candidate has an unexpected review state: ', id, '.', call. = FALSE)
  for (name in setdiff(names(review), 'candidate_id'))
    register[[name]][row_index] <- review[[name]][i]
  if (!unchanged && !identical(Sys.getenv('TAM_SOURCE_DRY_RUN'), '1'))
    replace_candidate_register_row(register_path, row_index,
      register[row_index, , drop = FALSE], id)
}

source(file.path(root, 'scripts', 'database', '195_summarize_discovery.R'))
source(file.path(root, 'scripts', 'database', '196_summarize_inventory_units.R'))
cat('Screened the remaining 17 NOAA candidate rows against assessment and stock-boundary sources.\n')

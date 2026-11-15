root <- "."
path <- file.path(root, 'discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'), check.names = FALSE)

review <- data.frame(
  candidate_id = c('NOAA:10014','NOAA:10019','NOAA:10029','NOAA:10031','NOAA:10033','NOAA:10034',
    'NOAA:10191','NOAA:10286','NOAA:10506','NOAA:10510','NOAA:10511','NOAA:10513',
    'NOAA:10515','NOAA:10518','NOAA:10520','NOAA:10523','NOAA:11050','NOAA:11055',
    'NOAA:11662','NOAA:12745','NOAA:12746'),
  matched_stock_id = c('nefsc_witch_flounder_unit','ck_nefsc_platessoides_5yz','ck_nefsc_americanus_5z',
    'afsc_yellowfin_sole_ebs','ck_dfo_nefsc_ferruginea_gb','ck_nefsc_garmiii_ferruginea_sne_ma',
    'nefsc_summer_flounder','ck_nefsc_saw_chrysops_usatl','afsc_cod_goa','afsc_pollock_ebs',
    'afsc_pollock_ai','afsc_pollock_goa','ck_nefsc_virens_5yz','ck_nefsc_garmiii_tenuis_gom_gb',
    'nefsc_haddock_georges_bank','joint_hake_coastal','afsc_northern_rock_sole_ebs','afsc_pop_bsai',
    'afsc_atka_mackerel_bsai','afsc_cod_ai','afsc_cod_ebs'),
  eligibility = c('ineligible','unresolved','eligible','eligible','unresolved','unresolved',
    'eligible','eligible','ineligible','eligible','eligible','eligible','eligible','eligible',
    'unresolved','eligible','eligible','eligible','eligible','ineligible','ineligible'),
  source_review = c('nefsc_witch_flounder_unit.md','nefsc_american_plaice_5yz.md',
    'nefsc_winter_flounder_georges_bank.md','afsc_yellowfin_sole_ebs.md','ck_dfo_nefsc_ferruginea_gb.md',
    'ck_nefsc_garmiii_ferruginea_sne_ma.md','nefsc_summer_flounder.md','ck_nefsc_saw_chrysops_usatl.md',
    'afsc_cod_goa.md','afsc_pollock_ebs.md','afsc_pollock_ai.md','afsc_pollock_goa.md',
    'nefsc_atlantic_pollock_5yz.md','ck_nefsc_garmiii_tenuis_gom_gb.md','nefsc_haddock_georges_bank.md',
    'joint_hake_coastal.md','afsc_northern_rock_sole_ebs.md','afsc_pop_bsai.md',
    'afsc_atka_mackerel_bsai.md','afsc_cod_ai.md','afsc_cod_ebs.md'),
  stringsAsFactors = FALSE
)

urls <- c(
  'https://d23h0vhsm26o6d.cloudfront.net/13d.-2024_WIT_UNIT_RPT_09_02_203738.pdf',
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=2&stock_id=4&review_type_id=2',
  'https://repository.library.noaa.gov/view/noaa/55264/noaa_55264_DS1.pdf',
  'https://files.npfmc.org/SAFE/2024/BSAIyfin.pdf',
  'https://d23h0vhsm26o6d.cloudfront.net/Georges-Bank-Yellowtail-Flounder-Assessment-Update-2025.pdf',
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi.php?year=2025&species_id=13&stock_id=11&review_type_id=3',
  'https://repository.library.noaa.gov/view/noaa/23031/noaa_23031_DS1.pdf',
  'https://repository.library.noaa.gov/view/noaa/4975/noaa_4975_DS1.pdf',
  'https://meetings.npfmc.org/Meeting/Details/8165',
  'https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/EBSpollock.pdf',
  'https://files.npfmc.org/SAFE/2024/AIpollock.pdf',
  'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=GOA+Pollock+2024.pdf&p=bd9a9aa2-3a33-4841-9133-d9ccf593e051.pdf',
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2024&species_id=7&stock_id=6&review_type_id=3',
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=8&stock_id=6&review_type_id=3',
  'https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=1&review_type_id=6',
  'https://repository.library.noaa.gov/view/noaa/67186/noaa_67186_DS1.pdf',
  'https://files.npfmc.org/SAFE/2024/BSAIrocksole.pdf',
  'https://files.npfmc.org/SAFE/2024/BSAIpop.pdf',
  'https://files.npfmc.org/SAFE/2024/BSAIatka.pdf',
  'https://www.fisheries.noaa.gov/alaska/population-assessments/2024-north-pacific-groundfish-stock-assessments',
  'https://www.fisheries.noaa.gov/alaska/population-assessments/2024-north-pacific-groundfish-stock-assessments'
)
review$detailed_source_url <- urls

review$catch_age_evidence <- c(
  '2024 empirical assessment reports aggregate catch only; no accepted catch-at-age series is reported.',
  '2022 Run29F4 has catch totals and age proportions, but its status as the advice-run model is unresolved; 2026 MT3 age inputs are not recovered.',
  '2022 RunSpring22 native input contains catch-at-age for ages 1-6 and 7+; the 2025 WHAM update has summary outputs only.',
  '2024 Model 23.0 supplies catch biomass and age compositions; annual catch weights support an explicitly derived catch-at-age series.',
  '2025 selected age-based-M production run has no verified catch-at-age or source composition arrays; earlier constant-M files are not the selected model.',
  '2025 management update changed the M model; complete run-matched catch age inputs are not available. The 2024 framework is a separate run.',
  '2018 F2018_BASE_V2 tables provide fishery catch-at-age; 2025 update is summary-only.',
  '2015 S60_BASE_18 tables provide catch-at-age for four fleets; the 2025 update provides aggregate summaries.',
  '2026 Model 24.0 uses total catch and length compositions with conditional age-at-length; no catch-at-age or catch age proportions were verified.',
  '2024 Model 23.0 preserves total catch and fishery age compositions; source-supported catch-at-age reconstruction is possible with the supplied weights.',
  '2024 Model 15.1 provides catch totals and fishery age compositions; source report and weights support age-specific reconstruction.',
  '2024 Model 23d provides catch totals and fishery age compositions; report age catches are retained separately and native grouping is documented.',
  '2024 Run10 native ASAP inputs provide catch numbers-at-age for ages 1-9+ and separate discard numbers-at-age.',
  '2025 Run_005 ASAP inputs include catch numbers-at-age for ages 1-9+ in years with positive composition sample size.',
  '2026 management-track report identifies age inputs but its public bundle contains no numerical catch-at-age or composition arrays.',
  '2025 SS3 data contain catch age compositions and the source model age structure; canonical records preserve native totals/compositions.',
  '2024 Model 24.2 source provides fishery age compositions and catch inputs; source review documents the age grouping.',
  '2024 Model 24 source provides total catch and fishery age compositions; canonical inputs retain the source likelihood structure.',
  '2024 Model 16.0b provides catch totals and age compositions; expanded catch-at-age is retained as a distinct source quantity.',
  '2024 Model 24.1 fits length compositions and conditional age-at-length, not catch-at-age or age proportions for catch reconstruction.',
  '2024 Model 24.1 has fishery length compositions and conditional age-at-length; the source does not provide catch-at-age.'
)
review$survey_age_evidence <- c(
  'The current empirical assessment uses seasonal swept-area biomass, not an age-specific abundance index.',
  'Run29F4 has aggregate survey biomass and age compositions; the composition basis is available only for a research-track candidate.',
  'Native data include NEFSC/DFO spring indices and age-specific NEFSC fall index streams; timing is labelled 1 January.',
  'VAST biomass and joint survey age compositions are supplied; the age-specific index is reconstructable from the same run.',
  'No run-matched age-specific survey observations for the selected 2025 model have been recovered.',
  'The selected 2025 update does not expose complete age-specific survey arrays; 2024 framework data are not substituted.',
  '2018 report tables provide NEFSC Bigelow spring and fall age indices; the other active survey streams remain unimported.',
  '2015 report Table A32 provides NEFSC fall abundance-at-age; several other active survey streams remain unimported.',
  'Bottom-trawl/longline surveys include aggregate indices and conditional age-at-length, not unconditional abundance-at-age.',
  '2024 bottom-trawl and acoustic-trawl aggregate observations and age compositions are available for source-supported reconstruction.',
  'NRA survey biomass and survey age compositions are reported for the active survey years.',
  'Four active survey biomass series and age compositions are documented; model-ready groupings are retained.',
  'Four active spring/fall survey biomass and age-specific inputs are present in the native ASAP files.',
  'Five aggregate survey indices and age-composition inputs are present in the official ASAP input.',
  '2026 report identifies three surveys and age-composition streams, but numerical observation arrays were not recovered.',
  '2025 acoustic biomass index and age compositions are supplied; the age-1 index is inactive in the official model.',
  '2024 report/native files provide survey observations and age compositions for the fitted model.',
  '2024 assessment includes two survey abundance series and age compositions; native streams are preserved.',
  '2024 assessment supplies survey biomass and design-expanded survey abundance-at-age with its sample-size column.',
  'Survey data include biomass and conditional age-at-length; no unconditional age-specific index was verified.',
  'The 2024 model has survey indices and marginal survey age rows, but lacks qualifying catch-at-age evidence.'
)
review$weights_evidence <- c(
  'No age-specific weight input for an age-structured production model was identified.',
  'Run29F4 has survey-specific weights; current 2026 management-track biological arrays are not fully recovered.',
  'Native input contains annual catch weights and population weights by age.',
  '2024 production input supplies empirical catch, population and survey weights at age.',
  'Updated 2025 maturity/biology is not available as run-matched numeric arrays.',
  'Complete weight-at-age surfaces for the selected 2025 model remain unavailable.',
  'The 2018 record includes age-specific SSB weights for 2013-2017; remaining biological coverage is documented as partial.',
  '2015 source provides annual catch/SSB weights-at-age; biological coverage and transformations are documented.',
  'Stock and fleet weights are modelled from length-growth inputs, but this does not resolve the missing age observations.',
  'Annual fishery and stock weights are in the native input; survey weights are retained by stream.',
  'Annual fishery and survey weights are supplied in the 2024 report.',
  'Annual fishery, survey and population weight inputs are documented from the 2024 assessment.',
  'Three annual age-weight matrices are supplied for catch, spawning biomass and survey/population use.',
  'Three annual weight matrices distinguish catch, SSB/survey and January 1 population biomass.',
  'Weight-at-age is identified in the 2026 input inventory, but the fitted numerical arrays are not public in the bundle.',
  '2025 source includes empirical weights by age for catch and survey biomass calculations.',
  'Annual population and catch weights are retained from the 2024 source.',
  'Fishery and survey weights are included in the native 2024 Model 24 files.',
  'Population, catch and survey weights are preserved as separate source series.',
  'No qualifying age-specific source weights are paired with age-disaggregated catch/index observations.',
  'Length-based growth weights do not provide the missing age-specific catch inputs.'
)
review$maturity_evidence <- c(
  'No age-specific maturity schedule is used by the current empirical assessment.',
  'Run29F4 maturity inputs are documented; updated 2026 management-track biology is not resolved.',
  'Native VPA input contains annual maturity-at-age proportions.',
  'Female maturity-at-age is supplied annually by the production assessment.',
  'The 2025 report updates the maturity ogive, but selected-run numeric values are unavailable.',
  'The selected 2025 model’s updated maturity surface is not available as a complete numeric series.',
  'The 2018 official model fixes maturity by age; source schedule and coverage are documented.',
  'The 2015 official run uses the MAT3 maturity schedule; source schedule is retained.',
  'Maturity is length-logistic in the 2026 control; no verified age-specific observation basis for an age-only fit.',
  'Supplied maturity vector is documented from the official 2024 source.',
  'Adopted GOA maturity-at-age is specified in the 2024 report.',
  'Supplied maturity-at-age is documented and source-specific.',
  'Maturity is fixed by age in the native ASAP input.',
  'Maturity is fixed by age in the production ASAP input.',
  'The report confirms maturity-at-age inputs but the exact numerical schedule was not recovered.',
  'Maturity-at-age is supplied in the 2025 SS3 inputs.',
  'Female maturity-at-age is supplied in Model 24.2.',
  'Maturity is estimated from biological samples using the official model; not substituted with fixed values.',
  'Female maturity ogive is supplied in the 2024 source.',
  'The official model uses a length ogive; report age-maturity table is derived, not an input schedule.',
  'Maturity is represented by a length-based ogive rather than a verified age-specific source input.'
)
review$mortality_evidence <- c(
  'The accepted empirical assessment does not estimate age-specific natural mortality.',
  'Run29F4 mortality settings are recorded; selected 2026 advice-run status remains unresolved.',
  'M fixed at 0.3 per year across ages and years in RunSpring22.',
  'Female M fixed at 0.12; male M is estimated in the 2024 production model.',
  'Selected 2025 age-specific-M model has no verified numeric run-matched surface.',
  '2025 selected revised model estimates age-specific M; complete numeric run output is unavailable.',
  'M fixed by age in the official 2018 model; exact values are listed in its source review.',
  'M fixed at 0.20 per year in the 2015 S60_BASE_18 run.',
  'Natural mortality is estimated in a temporal block; source-level age surface and matching observations are incomplete.',
  'Natural mortality vector is fixed at 0.9, 0.45, then 0.3 by age.',
  'M and steepness assumptions are documented in the 2024 assessment report.',
  'Natural mortality and temporal processes are documented from the official 2024 source.',
  'M fixed at 0.20 per year for ages 1-9+.',
  'M fixed at 0.20 per year for ages 1-9+.',
  'The report gives the model’s mortality assumptions, but fitted numerical age inputs are missing.',
  'Natural mortality settings are available from the official 2025 SS3 files.',
  'Female and male M estimates are reported for the 2024 model.',
  'M is estimated as one constant under the official model prior.',
  'Natural mortality is fixed at 0.3 per year.',
  'The final 2024 model estimates M, but selected-run input/output arrays are not recovered.',
  'M is fixed at 0.3866; the missing catch-age inputs still prevent eligibility.'
)
review$timing_evidence <- c(
  'Survey biomass combines seasonal spring/fall observations; no age-specific survey process to time.',
  'Run29F4 and current MT3 timing details are not reconciled to a selected production run.',
  'Native survey records are labelled 1-JAN and retained at fraction 0.0.',
  'Survey month July (fraction 0.5); spawning time is May 1 (4/12).',
  'Selected 2025 assessment timing is not fully verified from run-matched numeric inputs.',
  'Timing is described, but exact fitted observation arrays and selected-run alignment remain unavailable.',
  'Survey timing in the 2018 source is documented; seasonal midpoints are explicitly identified as approximations.',
  'The report identifies September-November fall sampling.',
  'Native timing definitions are known; age-specific observations are not available in a form suitable for reconstruction.',
  'Native source documents survey timing; monthly timing and transformations are recorded in the stock review.',
  'Summer survey observation timing is approximated at 0.5; the source report and model settings are retained.',
  'Survey timing is retained from the native 2024 inputs and source review.',
  'Native survey month codes map to spring 0.25 and fall 0.75.',
  'ASAP month codes map to April 0.25, July 0.50 and October 0.75.',
  'The 2026 input inventory identifies survey timing, but full fitted series are unavailable.',
  'Acoustic survey month 7; timing fraction 0.5.',
  'Spawning fraction February 1 (1/12); survey timing is specified in the source review.',
  'Survey sampling timing and biological timing are documented from the official 2024 files.',
  '2024 survey timing is documented; seasonal timing is retained by survey.',
  'Survey observations are indexed by month, but conditional age-at-length cannot be converted to an age index.',
  'Survey timing is available, but catch age and biological data do not support a minimal age-structured input set.'
)
review$output_evidence <- c(
  '2024 report provides exploitable biomass and exploitation ratios, not comparable N-at-age or instantaneous F outputs.',
  '2026 MT3 reports aggregate outputs, but its advice-run identity and age inputs remain unresolved.',
  '2022 report provides SSB, age-1 recruitment and FFull for 2012-2021; N-at-age/F-at-age outputs were not recovered.',
  'Native 2024 report outputs include annual N-at-age, F-at-age, SSB, recruitment and biomass.',
  '2025 report provides aggregate outputs only; official age-based-M age surfaces are unavailable.',
  '2025 update provides summary outputs; run-matched N/F-at-age and uncertainty surfaces are not available.',
  'Official 2018 run provides annual N/F-at-age and aggregate output tables; 2025 update is summary-only.',
  'Official 2015 run provides N-at-age, F-at-age, SSB and recruitment; 2025 summary outputs are separate.',
  '2026 report reconstruction provides N/F-at-age and aggregate outputs, but inputs do not meet age-data criteria.',
  '2024 SAFE tables provide official N-at-age, SSB and recruitment; source review records output grouping/uncertainty caveats.',
  '2024 official report provides population and mortality outputs; age-specific uncertainty is limited.',
  '2024 report provides N-at-age, SSB, recruitment and partial F-at-age; derived surfaces are explicitly labelled.',
  'Native ASAP output supplies N-at-age, F-at-age, biomass and SSB; uncertainty surfaces are partial.',
  'Official report provides SSB, fully selected F, recruitment and age-structured model outputs.',
  '2026 report provides aggregate SSB, Fbar and recruitment, but not full age-specific output arrays.',
  'Official 2025 SS3 reference outputs include historical N/F-at-age, SSB and recruitment.',
  '2024 Model 24.2 report provides annual age-specific population and mortality outputs.',
  'Native 2024 Model 24 outputs include population, mortality, SSB, biomass and recruitment surfaces.',
  '2024 report provides SSB, biomass, recruitment and age-specific mortality outputs; some early age cells remain unavailable.',
  '2024 report has aggregate SSB and recruitment, but no run-matched full N/F-at-age surfaces.',
  '2024 Model 24.1 provides age-structured fitted outputs, but there is no qualifying age-specific catch input.'
)
review$decision_reason <- c(
  'Matched the current official witch-flounder unit. The 2024 assessment used seasonal swept-area biomass and aggregate catch, while the rejected analytical models do not establish a current age-structured input set; source review: nefsc_witch_flounder_unit.md.',
  'Matched 5YZ American plaice. The 2026 MT3 source gives summary outputs but not age-specific inputs, while the detailed 2022 WHAM object is a research-track candidate whose advice-run selection is unresolved; source review: nefsc_american_plaice_5yz.md.',
  'Matched Georges Bank winter flounder. The 2025 assessment is latest but summary-only; the separate official 2022 RunSpring22 record supplies native age inputs and aggregate SSB, recruitment and FFull outputs, already represented in the database; source review: nefsc_winter_flounder_georges_bank.md.',
  'Matched Eastern Bering Sea yellowfin sole. The final 2024 Model 23.0 has source age compositions, biological inputs and official age/population outputs; source review: afsc_yellowfin_sole_ebs.md.',
  'Matched combined US-Canada Georges Bank yellowtail. The selected 2025 age-based-M production run lacks run-matched numeric arrays; available constant-M or research-track files are not substituted; source review: ck_dfo_nefsc_ferruginea_gb.md.',
  'Matched Southern New England/Mid-Atlantic yellowtail. The 2025 applied update changed the M model, but its full arrays are unavailable; the detailed 2024 framework is kept separate; source review: ck_nefsc_garmiii_ferruginea_sne_ma.md.',
  'Matched the current summer-flounder unit. The 2018 official ASAP record has age-specific source data and outputs; the newer 2025 update is retained as a separate summary record; source review: nefsc_summer_flounder.md.',
  'Matched US Atlantic scup. The 2015 official S60_BASE_18 benchmark supplies age-specific catch/survey data and outputs; the 2025 update is a separate summary-only record; source review: ck_nefsc_saw_chrysops_usatl.md.',
  'Matched Gulf of Alaska Pacific cod. The current 2026 run has length compositions and conditional age-at-length, not catch-at-age or an unconditional survey age index; source review: afsc_cod_goa.md.',
  'Matched Eastern Bering Sea walleye pollock. The current 2024 production run supplies aggregate catches, age compositions, biological inputs, survey streams and official population outputs; preserve totals/compositions rather than treating observer counts as model catch-at-age; source review: afsc_pollock_ebs.md.',
  'Matched Aleutian Islands walleye pollock. The official 2024 report provides catch totals and fishery/survey age compositions with biological inputs and comparable outputs; source review: afsc_pollock_ai.md.',
  'Matched Western/Central/West Yakutat Gulf of Alaska pollock. The official 2024 Model 23d has source catch/composition and survey streams; recovered outputs and derived quantities are explicitly distinguished; source review: afsc_pollock_goa.md.',
  'Matched Atlantic pollock in 5YZ. The official 2024 Run10 ASAP input and output files provide catch-at-age, age-specific survey data, biology and comparable outputs; source review: nefsc_atlantic_pollock_5yz.md.',
  'Matched Gulf of Maine/Georges Bank white hake. The official 2025 Run_005 ASAP source includes catch-age, survey age information, biology and reported outputs; source review: ck_nefsc_garmiii_tenuis_gom_gb.md.',
  'Matched Georges Bank haddock. The 2026 assessment is current, but its public bundle/report lacks numerical age-specific input arrays and the age-structured outputs needed for source-ready screening; source review: nefsc_haddock_georges_bank.md.',
  'Matched the joint US-Canada coastal Pacific hake stock. The 2025 base model archive includes source age compositions, acoustic index, biology, assumptions and official reference outputs; source review: joint_hake_coastal.md.',
  'Matched Eastern Bering Sea northern rock sole. The final 2024 Model 24.2 source includes age-specific observations, biological inputs and reported population/mortality outputs; source review: afsc_northern_rock_sole_ebs.md.',
  'Matched Bering Sea/Aleutian Islands Pacific ocean perch. The official 2024 Model 24 native source and report provide age compositions, survey inputs, biological data and comparable outputs; source review: afsc_pop_bsai.md.',
  'Matched Bering Sea/Aleutian Islands Atka mackerel. The official 2024 Model 16.0b report provides catch/survey totals and age compositions, biological inputs, and comparable outputs; source review: afsc_atka_mackerel_bsai.md.',
  'Matched Aleutian Islands Pacific cod. The final 2024 Model 24.1 uses length compositions and conditional age-at-length; catch-at-age, age proportions for catch reconstruction, and unconditional survey age indices are not verified; source review: afsc_cod_ai.md.',
  'Matched Eastern Bering Sea Pacific cod. The official 2024 model uses fishery lengths and conditional age-at-length rather than catch-at-age; marginal survey age rows do not fill the catch-age requirement; source review: afsc_cod_ebs.md.'
)
review$notes <- paste0('Source screening is based on the current/represented assessment distinctions in source_reviews/', review$source_review, '.')

row_index <- match(review$candidate_id, x$candidate_id)
if (anyNA(row_index) || anyDuplicated(review$candidate_id)) stop('Candidate IDs are missing or duplicated.', call. = FALSE)
if (any(x$matched_stock_id[row_index] != review$matched_stock_id)) stop('Matched stock identity changed.', call. = FALSE)
if (any(!file.exists(file.path(root, 'source_reviews', review$source_review)))) stop('A required source review is missing.', call. = FALSE)
already_screened <- x$screening_status[row_index] == 'screened'
if (any(already_screened & !grepl('Source screening is based on the current/represented assessment distinctions in source_reviews/',
  x$notes[row_index], fixed = TRUE))) stop('A candidate was already screened; review the register before rerunning.', call. = FALSE)

for (field in c('catch_age_evidence','survey_age_evidence','weights_evidence','maturity_evidence',
                'mortality_evidence','timing_evidence','output_evidence','detailed_source_url',
                'decision_reason','notes')) x[[field]][row_index] <- review[[field]]
x$screening_status[row_index] <- 'screened'
x$eligibility[row_index] <- review$eligibility
x$import_status[row_index] <- 'imported'
x$review_date[row_index] <- as.character(Sys.Date())

eligible <- row_index[review$eligibility == 'eligible']
for (field in c('catch_age_evidence','survey_age_evidence','weights_evidence','maturity_evidence',
                'mortality_evidence','timing_evidence','output_evidence','detailed_source_url')) {
  if (any(is.na(x[[field]][eligible]) | !nzchar(x[[field]][eligible]))) stop('Eligible rows need evidence in every required field.', call. = FALSE)
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
tmp <- tempfile(fileext = '.csv')
for (i in row_index) {
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  lines[i + 1L] <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[[2L]]
}
unlink(tmp)
writeLines(lines, path, useBytes = TRUE)
cat('Screened', length(row_index), 'matched NOAA inventory entries.\n')

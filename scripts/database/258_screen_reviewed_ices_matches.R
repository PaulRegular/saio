path <- file.path('discovery', 'candidates.csv')
x <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'))

reviews <- list(
  'ICES:ane.27.9aS' = list(
    stock = 'ices_anchovy_gulf_cadiz', eligibility = 'unresolved',
    catch = 'The 2025 SS3 source tables give annual total catch and Spanish annual catch-at-age for ages 0-3 in 1995-2024; 2025 fishery ages are excluded from the current model and whole-stock quarterly catch-at-age is only available for 2024.',
    survey = 'PELAGO and ECOCADIZ provide biomass indices and published expanded survey abundances for ages 0-4 in million fish. The current quarterly likelihood compositions, adjusted sample sizes, and complete run-matched composition series were not recovered.',
    weights = 'Raw quarterly catch weights are available for 2024 only. The current SS3 empirical stock-weight surface is not available.',
    maturity = 'The source reports fixed maturity proportions of 0, 1, 1 and 1 for ages 0-3.',
    mortality = 'The source reports fixed M values of 2.97, 1.6, 2.48 and 2.48 per year for ages 0-3; these are inputs, not estimated outputs.',
    timing = 'Survey seasons are described, but exact current SS3 sampling fractions are unavailable.',
    output = 'SAG key 21266 reports annual SSB, July age-0 recruitment and age-3 F with uncertainty where available. F is not an age-specific surface; fitted N-at-age and full F-at-age were not recovered.',
    urls = 'https://doi.org/10.17895/ices.pub.29335520.v3; https://doi.org/10.17895/ices.pub.28053362; https://sag.ices.dk/SAG_API/StockXmlDownload/21266; https://github.com/ices-advice/2025_ane.27.9aS/tree/075ed16570d08be9378848ddabe15c3b64feb07b',
    reason = 'The latest production SS3 assessment has substantial published age and survey information, but current stock weights and native quarterly compositions are missing and the published expanded survey ages are not verified as the fitted likelihood. Retain as unresolved until run-matched input coverage is verified.',
    notes = 'Screened against the 2025 southern 9.a production assessment; the 2026 WGHANSA report covers the western successor, not this stock. See source_reviews/ices_anchovy_gulf_cadiz.md.'
  ),
  'ICES:ane.27.9aW' = list(
    stock = 'ices_anchovy_west_iberia', eligibility = 'ineligible',
    catch = 'WGHANSA 2026 reports regional catch and Spanish North catch-at-age for ages 0-3 in selected years. These age tables are supporting information, not observations in the current biomass-index harvest-rule model.',
    survey = 'The 2026 assessment uses a combined acoustic biomass index from PELACUS and PELAGO; it does not fit an age-specific abundance index.',
    weights = 'No age-structured population model uses age-specific weights in the current assessment.',
    maturity = 'No age-structured population model uses maturity-at-age in the current assessment.',
    mortality = 'The current category-3.2 assessment uses a constant harvest-rate rule and does not estimate or use population M-at-age.',
    timing = 'The 2026 acoustic surveys occurred in March-April; a single fitted age-structured observation time is not applicable.',
    output = 'The official result is an acoustic biomass index and harvest-rate advice. No fitted population N-at-age, F-at-age, recruitment, or SSB surface is produced.',
    urls = 'https://doi.org/10.17895/ices.pub.32614524.v2; https://sag.ices.dk/SAG_API/StockXmlDownload/23750; https://asd.ices.dk/viewAdvice/7195',
    reason = 'The latest official 2026 assessment is a category-3.2 biomass-index harvest rule, not an age-structured population assessment. Supporting age tables do not change the official model structure.',
    notes = 'Current unit is distinct from the southern 9.a anchovy stock and historical combined catalogue row. See source_reviews/ices_anchovy_west_iberia_2026.md.'
  ),
  'ICES:cod.27.1-2.coastN' = list(
    stock = 'ices_cod_northern_coastal', eligibility = 'eligible',
    catch = 'AFWG 2026 identifies total catch-at-age and age-specific catch weights among the final SAM tuning inputs; the numerical source tables cover the 2026 run through 2025.',
    survey = 'The run uses an age-specific swept-area abundance index for ages 2-10+ and an aggregate acoustic biomass index. The final tuning table omits 2021 from the acoustic series.',
    weights = 'The report provides catch, stock, landings and discard weights-at-age for ages 3-12; M is derived using stock weight.',
    maturity = 'The report provides age-specific maturity-at-age for the final SAM run.',
    mortality = 'Natural mortality is fixed and age-specific, derived from stock weights using Lorenzen (1996); it is not estimated by the current fit.',
    timing = 'The age-specific swept survey and aggregate acoustic index use sampling time 0.8; the 2026 production configuration is described in the AFWG source review.',
    output = 'AFWG tables provide age-specific N-at-age and F-at-age for 1994-2025 and aggregate recruitment, SSB, Fbar and total biomass; key aggregate outputs include reported uncertainty.',
    urls = 'https://doi.org/10.17895/ices.pub.32134696.v1; https://doi.org/10.17895/ices.pub.7920; https://standardgraphs.ices.dk/ViewCharts.aspx?key=22637',
    reason = 'The latest official 2026 SAM assessment provides numerical age-based catch and survey information, biological inputs, mortality assumptions, survey timing and comparable age-specific and aggregate outputs. The exact fitted object is unavailable, but detailed report inputs and outputs support source curation.',
    notes = 'Matched to the split northern coastal cod unit; do not pool it with the southern component or the historical composite catalogue record. See source_reviews/ices_cod_northern_coastal_2026.md.'
  ),
  'ICES:cod.27.2.coastS' = list(
    stock = 'ices_cod_southern_coastal', eligibility = 'ineligible',
    catch = 'AFWG tables report catch and age-disaggregated supporting data, but the current 2026 SPiCT assessment fits combined annual catch rather than catch-at-age.',
    survey = 'The 2026 fit uses two aggregate biomass indices for coastal cod at least 50 cm; no age-specific survey likelihood is fitted.',
    weights = 'Commercial catch weights-at-age are published as supporting data, but are not inputs to the current aggregate SPiCT fit.',
    maturity = 'Age-specific maturity is not used by the current aggregate SPiCT assessment.',
    mortality = 'The current assessment is a SPiCT surplus-production model and does not estimate age-specific natural mortality.',
    timing = 'The trawl index is a quarter-4 survey; exact within-year timing for the indices is not recovered and does not define an age-specific likelihood.',
    output = 'The official assessment reports B/Bmsy and F/Fmsy, not absolute SSB, instantaneous F, recruitment or population numbers-at-age.',
    urls = 'https://doi.org/10.17895/ices.pub.32134696.v1; https://asd.ices.dk/viewAdvice/7204; https://sag.ices.dk/SAG_API/StockXmlDownload/23775; https://doi.org/10.17895/ices.pub.24998858',
    reason = 'The latest official 2026 production assessment is SPiCT. Age tables are supporting information rather than likelihood inputs, and the model does not produce age-structured population outputs.',
    notes = 'Keep distinct from northern coastal cod and the historical composite coastal-cod catalogue record. See source_reviews/ices_cod_southern_coastal_2026.md.'
  ),
  'ICES:cod.27.22-24' = list(
    stock = 'ck_ices_wgbfas_morhua_bs', eligibility = 'eligible',
    catch = 'WGBFAS 2026 gives total catch and commercial catch-at-age for ages 1-8+ during 1974-2025. The SS3 likelihood combines total catch with age composition; Russian age compositions are unavailable for 2022-2025.',
    survey = 'The BIAS acoustic input reports age-specific abundance for ages 1-8+ in 2000, 2006-2007 and 2009-2025; published October timing is not an exact within-year fraction.',
    weights = 'Catch and stock weights are reported for ages 0-8+ during 1974-2025; the assessment sets stock weight equal to catch weight.',
    maturity = 'Annual maturity-at-age is reported for ages 0-9 during 1974-2025.',
    mortality = 'The official assessment supplies low, medium and high age/year-specific fixed M scenarios; the advice assessment is an ensemble across three SS3 models.',
    timing = 'The acoustic survey is described as October, but exact observation time is not stated.',
    output = 'WGBFAS 2026 provides aggregate recruitment, SSB and Fbar (ages 3-6) with central 90% ensemble intervals through 2025. Age-specific fitted N/F/M arrays were not recovered.',
    urls = 'https://doi.org/10.17895/ices.pub.32455056.v3; https://doi.org/10.17895/ices.pub.23260658.v2; https://doi.org/10.17895/ices.pub.23216492; https://sg.ices.dk/ViewSourceData.aspx?key=23758',
    reason = 'The current age-based SS3 ensemble has detailed numerical catch, acoustic-age, biological and fixed-M source tables plus comparable annual population summaries. Missing age-composition weights and fitted age-specific outputs are documented limitations, not blockers to source curation.',
    notes = 'This is the western Baltic stock in subdivisions 22-24, distinct from eastern Baltic cod and other western Baltic species records. See source_reviews/ck_ices_wgbfas_morhua_bs.md.'
  ),
  'ICES:her.27.25-2932' = list(
    stock = 'ck_ices_wgbfas_harengus_bs_25_29_32', eligibility = 'eligible',
    catch = 'WGBFAS 2026 reports total catch for 1904-2025 and commercial catch-at-age for ages 1-8+ in 1974-2025; some Russian age compositions are missing in 2022-2025.',
    survey = 'The BIAS acoustic input gives age-specific abundance for ages 1-8+ in 2000, 2006-2007 and 2009-2025. A trapnet series is aggregate and partly digitized from the 2021 benchmark figure.',
    weights = 'Catch weights are reported for ages 0-8+ in 1974-2025 and are also used as stock weights by the SS3 assessment.',
    maturity = 'Maturity-at-age is reported for ages 0-9 in 1974-2025, with table/prose differences documented in the source review.',
    mortality = 'Three fixed M scenarios (low, medium and high) are reported by age and year; the official advice uses an ensemble of the three SS3 fits.',
    timing = 'The BIAS survey is conducted in October; an exact observation fraction is unavailable.',
    output = 'The report provides annual recruitment, SSB and Fbar ages 3-6 with central 90% ensemble intervals through 2025. No fitted age-specific N, F or M output array was recovered.',
    urls = 'https://doi.org/10.17895/ices.pub.32455056.v3; https://doi.org/10.17895/ices.pub.23260658.v2; https://sg.ices.dk/ViewSourceData.aspx?key=23758',
    reason = 'The official age-based SS3 ensemble has published age-specific catch and survey inputs, biological data, fixed-M scenarios and annual population summaries. Missing composition weights and age-specific fitted outputs remain documented gaps; source curation is supportable.',
    notes = 'The current combined subdivisions 25-29 and 32 unit supersedes older subdivision-level catalogue entries; those historical components are not separate current cases. See source_reviews/ck_ices_wgbfas_harengus_bs_25_29_32.md.'
  ),
  'ICES:her.27.3031' = list(
    stock = 'ices_herring_gulf_bothnia', eligibility = 'eligible',
    catch = 'WGBFAS 2026 reports annual catch-at-age in thousand fish for ages 1-14 and 15+ during 1980-2025, with total catch in tonnes during 1963-2025. Age proportions are reconstructed for the SS3 composition input.',
    survey = 'The BIAS acoustic survey provides age-specific abundance for ages 0-15+ during 2007-2025; a trapnet index is available only as an approximate aggregate digitization for 1990-2006.',
    weights = 'Annual catch weights-at-age in kg/fish are available for ages 0-16 and 17+ in 1963-2025; a separate production stock-weight surface was not recovered.',
    maturity = 'Annual maturity-at-age is reported for ages 1-16 and 17+ during 1980-2025.',
    mortality = 'A time-invariant age-varying M curve is reconstructed from the 2021 benchmark and used as fixed mortality; exact 2026 production values are not independently available.',
    timing = 'The acoustic survey is late September to early October; the recipe uses 0.75 as an explicit approximation, not a source-stated SAM time.',
    output = 'ICES SAG key 22377 reports age-0 recruitment, SSB and Fbar (ages 3-7) through 2025 with central 90% intervals. No fitted N-at-age, F-at-age or estimated M-at-age surfaces were recovered.',
    urls = 'https://literatur.thuenen.de/digbib_extern/dn071152.pdf; https://sg.ices.dk/ViewSourceData.aspx?key=22377; https://sag.ices.dk/SAG_API/StockXmlDownload/22377; https://doi.org/10.17895/ices.pub.5989; https://jukuri.luke.fi/bitstreams/adfbdc03-5e3b-45f2-8492-ec5bf7085724/download',
    reason = 'The latest official age-based SS3 model has recoverable catch age, acoustic age abundance, biology, a documented fixed-M proxy and comparable aggregate outputs. Catch weights proxy for unrecovered stock weights and exact survey timing is approximated; these limitations are explicit in the source review.',
    notes = 'The current stock combines subdivisions 30 and 31. Older catalogue rows for each subdivision are not separate current assessments. See source_reviews/ices_herring_gulf_bothnia_2026.md.'
  ),
  'ICES:her.27.6aN' = list(
    stock = 'ck_ices_hawg_harengus_cs_6a_n', eligibility = 'ineligible',
    catch = 'The current 6.a North assessment is a survey-biomass trend rule; age-related tables are supporting biological information rather than catch-at-age likelihood inputs.',
    survey = 'The official assessment uses a biomass trend/index and target harvest rate, not an age-specific population abundance index.',
    weights = 'Weights-at-age are not inputs to the current survey-biomass harvest rule.',
    maturity = 'Maturity-at-age is not part of the current survey-biomass rule.',
    mortality = 'The official rule does not estimate population natural mortality.',
    timing = 'The assessment is based on survey biomass and a rule; no age-structured observation timing applies.',
    output = 'Official outputs are survey-biomass indicators and harvest advice, not N/F/M-at-age, SSB, or recruitment from an age-structured population fit.',
    urls = 'https://doi.org/10.17895/ices.pub.31424315; https://doi.org/10.17895/ices.advice.32133673; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21289; https://asd.ices.dk/viewAdvice/4061',
    reason = 'The latest official production method for 6.a North is a survey-biomass trend harvest rule. Exploratory age-based analyses are not the published official assessment used for advice.',
    notes = 'Current North of 56 degrees stock is distinct from southern 6.a herring and the historical combined 6.a/7.b-c record. See source_reviews/ck_ices_hawg_harengus_cs_6a_n.md.'
  ),
  'ICES:her.27.6aS7bc' = list(
    stock = 'ck_ices_hawg_harengus_cs6_a_s_7b_c', eligibility = 'ineligible',
    catch = 'The current 6.a South/7.b-c official assessment is a catch/harvest-rate rule, not an age-structured likelihood; age tables in WGHANSA are supporting or exploratory data.',
    survey = 'The official assessment uses a biomass indicator for its harvest rule rather than an age-specific abundance index.',
    weights = 'The available biological tables do not establish a fitted age-structured stock-weight input for the official rule.',
    maturity = 'Maturity-related information is reported for biological context, but is not an input to an age-structured official population likelihood.',
    mortality = 'The published rule does not estimate age-specific natural mortality; exploratory age-based fits are not official assessment outputs.',
    timing = 'Survey seasons and annual dates provide context, but no age-structured observation time applies to the official rule.',
    output = 'The assessment reports harvest-rule indicators and advice, not fitted population N/F/M-at-age or age-structured recruitment/SSB surfaces.',
    urls = 'https://doi.org/10.17895/ices.pub.31424315; https://doi.org/10.17895/ices.advice.32133760; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21289; https://asd.ices.dk/viewAdvice/4061',
    reason = 'The latest official assessment used for advice applies a catch/harvest-rate rule; exploratory age-based assessment versions are not the accepted production outputs. It is ineligible for the age-structured comparison screen.',
    notes = 'Keep distinct from the North of 56 degrees stock and the historical combined stock. See source_reviews/ck_ices_hawg_harengus_cs6_a_s_7b_c.md.'
  ),
  'ICES:pil.27.8abd' = list(
    stock = 'ck_ices_wghansa_pilchardus_sp8abd', eligibility = 'unresolved',
    catch = 'The official 2025 SS3 assessment uses commercial catch-at-age, but its numerical assessment files are absent from the public TAF repository and no complete age series was recovered from the report.',
    survey = 'The report identifies acoustic and egg survey data and an age-based model, but the numerical survey inputs and age compositions are unavailable.',
    weights = 'Age-specific weight, fecundity and maturity files are listed in the TAF bibliography but the production numerical files were not recovered.',
    maturity = 'The SS3 assessment uses age-specific maturity/fecundity biology; run-specific numeric surfaces are unavailable.',
    mortality = 'The report identifies an age-based SS3 model, but current numerical M inputs and exact control settings were not recovered.',
    timing = 'Survey timing and run-specific likelihood timing could not be verified without production files.',
    output = 'The report and SAG provide aggregate recruitment, SSB and F(2-5), with 95% bounds where published; no age-specific fitted N/F outputs are available.',
    urls = 'https://doi.org/10.17895/ices.pub.29335520.v3; https://asd.ices.dk/viewAdvice/4007?handler=SubComm; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21258; https://github.com/ices-advice/2025_pil.27.8abd/tree/242f57e7a04cd78f30402d7c2c97fa98c197b4bc',
    reason = 'The official model is age-based, but the pinned public TAF repository omits the production numerical input files. Aggregate output tables alone do not verify the required run-specific catch-age, survey, biology, M and timing inputs; keep unresolved.',
    notes = 'The 2025 report is the latest official assessment located, used for 2026 advice. The 2025 record is summary-only; do not substitute 2024 inputs. See source_reviews/ck_ices_wghansa_pilchardus_sp8abd.md.'
  ),
  'ICES:ple.27.21-32' = list(
    stock = 'ices_plaice_baltic_21_32', eligibility = 'eligible',
    catch = 'The native 2026 SAM run contains catch-at-age for ages 1-7+ in 2002-2025, including landings and discards, on a thousand-fish scale.',
    survey = 'The native fit includes Q1 and Q4 age-specific relative survey indices over the model ages; source observation precision weights are retained per row.',
    weights = 'The native data include annual stock weights and separate landings/discard weights; stock weights are time-varying.',
    maturity = 'The native run supplies annual maturity ogives smoothed with a five-year sliding window.',
    mortality = 'M is fixed age- and year-varying Gislason mortality with a five-year sliding average, rather than an estimated process.',
    timing = 'SAM sampling fractions are Q1 0.1507111 and Q4 0.8173179; catch timing is 0.',
    output = 'WGBFAS tables provide 2002-2025 recruitment, SSB, Fbar and N/F-at-age; aggregate measures include reported 95% limits, and the native SAM fit is available.',
    urls = 'https://literatur.thuenen.de/digbib_extern/dn071152.pdf; https://literatur.thuenen.de/digbib_extern/dn069680.pdf; https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22470; https://stockassessment.org/datadisk/stockassessment/userdirs/user3/ple.27.21.32_WGBFAS_2026_SA/',
    reason = 'The current combined 2026 SAM unit has run-matched native age-based observations, biological inputs, fixed mortality, sampling times and fitted age-specific/aggregate outputs. Report-versus-object point-estimate differences are documented but do not prevent source curation.',
    notes = 'The current combined subdivisions 21-32 assessment replaces the two older component units for this review; preserve those as historical records. See source_reviews/ices_plaice_baltic_21_32_2026.md.'
  ),
  'ICES:pok.27.1-2' = list(
    stock = 'ck_ices_afwg_virens_nea_1_2', eligibility = 'eligible',
    catch = 'The 2026 SAM run contains total catch-at-age in thousand fish for ages 3-12 during 1960-2025.',
    survey = 'Two age-specific acoustic index series cover ages 3-7: FLT13 in 1994-2001 and FLT14 in 2002-2025. The native fit includes row-aligned relative precision weights for part of FLT14.',
    weights = 'The native run supplies stock, catch, landings and discard weights-at-age for ages 3-12, in kg/fish.',
    maturity = 'Annual age-specific maturity and pre-spawning mortality fractions are present for ages 3-12.',
    mortality = 'Natural mortality is fixed at 0.2 per year for modeled ages 3-12; it is an input rather than an estimated mortality surface.',
    timing = 'Both acoustic surveys use a sampling time of 0.8 in the native data object.',
    output = 'The fitted run provides N-at-age and F-at-age, predicted catch/survey series, q, recruitment, SSB, Fbar and total biomass; aggregate results reproduce the 2026 SAG values at reported precision.',
    urls = 'https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22657; https://doi.org/10.17895/ices.pub.25002470; https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NEA_saithe_2026_v2/',
    reason = 'The 2026 official native SAM run and associated data include age-based catches, two survey indices, biological inputs, fixed M, sampling times and fitted population outputs. The selected pinned object reproduces current SAG aggregates.',
    notes = 'Matched to ICES pok.27.1-2; current assessment year is 2026 although SID inventory metadata retain an older assessment year. See source_reviews/ck_ices_afwg_virens_nea_1_2.md.'
  )
)

for (id in names(reviews)) {
  i <- match(id, x$candidate_id)
  if (is.na(i)) stop(paste('Expected candidate is missing:', id), call. = FALSE)
  review <- reviews[[id]]
  if (x$match_status[i] != 'matched' || x$matched_stock_id[i] != review$stock) {
    stop(paste('Unexpected stock match for candidate:', id), call. = FALSE)
  }
  updates <- c(
    list(screening_status = 'screened', eligibility = review$eligibility,
      import_status = 'imported'),
    setNames(as.list(unlist(review[c('catch', 'survey', 'weights', 'maturity',
      'mortality', 'timing', 'output')])),
      c('catch_age_evidence', 'survey_age_evidence', 'weights_evidence',
        'maturity_evidence', 'mortality_evidence', 'timing_evidence',
        'output_evidence')),
    list(detailed_source_url = review$urls, review_date = '2026-10-29',
      decision_reason = review$reason, notes = review$notes)
  )
  for (column in names(updates)) x[[column]][i] <- updates[[column]]
}

lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
if (length(lines) != nrow(x) + 1L) stop('Multiline CSV rows require a safe update method.', call. = FALSE)
for (id in names(reviews)) {
  i <- match(id, x$candidate_id)
  tmp <- tempfile(fileext = '.csv')
  write.csv(x[i, , drop = FALSE], tmp, row.names = FALSE, na = '')
  updated <- readLines(tmp, warn = FALSE, encoding = 'UTF-8')[-1L]
  unlink(tmp)
  lines[i + 1L] <- updated
}
writeLines(lines, path, useBytes = TRUE)
cat('Screened 12 matched ICES candidates from their reviewed current assessments.\n')

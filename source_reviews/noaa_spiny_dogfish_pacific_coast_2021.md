# NOAA Pacific spiny dogfish, 2021

## Assessment unit and source run

The assessment is the U.S. West Coast coastwide unit of Pacific spiny dogfish (*Squalus suckleyi*), from the U.S.-Canada border to the U.S.-Mexico border, excluding inland waters. The 2021 assessment treats this as a single population. It notes that the population overlaps with Canadian waters, but its modeled U.S. unit is distinct from the DFO British Columbia outside-waters assessment.

The PFMC’s official groundfish assessment listing identifies the 2021 assessment, model files, supplementary tables and STAR panel report as the latest detailed production package found for this unit. The model uses data through 2020 and reports a 2021 one-year forecast. The selected archived run is the decision-table “middle state of nature,” with WCGBTS catchability fixed at 0.43. The report’s main base model estimates a different WCGBTS catchability (0.586); those alternatives are not mixed here. The archived run reproduces the report’s 2021 spawning output and recruitment point estimates.

The files are cached locally under the ignored source_cache/discovery_noaa_spiny_dogfish_pacific_2021/ folder. URLs, retrieval dates, sizes and SHA-256 checksums are recorded in provenance/noaa_spiny_dogfish_pacific_coast_2021/manifest.csv.

- [2021 assessment report](https://www.pcouncil.org/documents/2022/01/status-of-the-pacific-spiny-dogfish-shark-resource-off-the-continental-u-s-pacific-coast-in-2021-october-19-2021.pdf/)
- [Official model archive](https://www.pcouncil.org/documents/spiny-dogfish-2021-model-files-zip-file/)
- [Supplementary tables](https://www.pcouncil.org/documents/spiny-dogfish-assessment-supplementary-table-excel/)
- [STAR panel report](https://www.pcouncil.org/documents/spiny-dogfish-stock-assessment-review-star-panel-report/)
- [PFMC assessment and model listing](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)

## Inputs recovered

The model has one area, two sexes, annual timing, population ages 0–95, with age 95 as the plus group. It includes eight fishery catch-biomass series in metric tonnes for 1916–2020, five aggregate relative indices (four biomass-index scales and one numbers-index scale) for 1980–2019, 156 length-composition strata and 33 conditional age-at-length strata. The age key is a single 2010 WCGBTS sample of 515 fish, with ages 0–71 and length-conditioned age samples. CPUE values and their log-scale standard errors are preserved on their native Stock Synthesis scales. The model assigns all index observations to July (within-year time 0.5); this is the model timing code and is not evidence that every survey sampled in July.

The native model inputs do not include catch numbers-at-age or age-specific abundance-index observations. The single-year conditional age-at-length key could support a separately documented reconstruction from length compositions, but such a reconstruction would add assumptions and is not represented as observed age data in the database. The imported record therefore remains partial.

## Assumptions and outputs recovered

The assessment is a two-sex Stock Synthesis 3.30.16 model. Natural mortality is fixed at 0.065 per year for both sexes and ages. The native M-at-age output leaves age 95 blank, so that terminal plus-group value is explicitly expanded from the fixed uniform-M setting. Female maturity is specified with a fixed length-based ogive (Mat50 88.2 cm; slope -0.27); fecundity uses the fixed model relationship (parameters -7.35 and 0.107). The model uses sex-specific growth and weight-at-length, and a deterministic stock-recruit relationship without annual recruitment deviations. The source archive provides annual model-generated weight-at-age and maturity-at-age surfaces. These are model surfaces, not independent observed age-specific biological samples.

The imported outputs include beginning-year N-at-age, biomass-at-age, fleet-specific and summed F-at-age, fixed M-at-age, weight-at-age, maturity-at-age, annual spawning output, recruitment, total biomass and derived total abundance. N is in thousands of fish; biomass-at-age and total biomass are in metric tonnes; weight-at-age is kg per fish; spawning output and recruitment are in thousands of pups. The report gives 95% intervals for spawning output and recruitment over 2011–2021; age-specific uncertainty surfaces are not available.

The report’s Table ES-8 gives age-1+ biomass values that agree with the archived time series for 2011–2020. Its 2021 value (255,602 mt) is inconsistent with the archived q=0.43 run’s 2021 forecast (110,047 mt), which continues the prior trajectory and agrees with the separate native biomass output. Both values are retained with source and scenario labels; the discrepancy is not resolved by an undocumented adjustment.


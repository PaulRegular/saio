# NOAA lingcod, northern U.S. Pacific Coast, 2021

## Assessment unit and source run

The 2021 assessment covers lingcod (*Ophiodon elongatus*) north of 40°10′N along the U.S. West Coast, to the U.S.–Canada border. It is a separate unit from southern U.S. lingcod and Canadian lingcod. The assessment report says it excludes Alaskan, Canadian, and Mexican populations. The production model is Stock Synthesis 3.30.17.01 and uses data through 2020; its official status estimates and one-year forecast extend into 2021.

The 2021 report and its model archive are the latest detailed production assessment located for this current unit. NOAA’s stock page identifies the two U.S. Pacific Coast lingcod units, and PFMC’s 2026 assessment planning material identifies 2021 as the last completed assessment, with a new benchmark planned for 2027.

Authoritative PDFs and the native archive are cached under the ignored `source_cache/discovery_noaa_lingcod_northern_2021/` folder. Their URLs, retrieval dates, sizes, and SHA-256 checksums are recorded in `provenance/noaa_lingcod_northern_pacific_coast_2021/manifest.csv`.

- [2021 northern lingcod assessment report](https://www.pcouncil.org/documents/2021/12/status-of-lingcod-ophiodon-elongatus-along-the-northern-u-s-west-coast-in-2021-december-2021.pdf/)
- [2021 Stock Synthesis model files](https://www.pcouncil.org/documents/lingcod-2021-model-files-zip-file/)
- [2021 STAR panel report](https://www.pcouncil.org/documents/2021/10/lingcod-stock-assessment-review-star-panel-report.pdf/)
- [NOAA lingcod stock information](https://www.fisheries.noaa.gov/species/lingcod)
- [PFMC 2026 assessment planning material](https://www.pcouncil.org/documents/2026/05/e-4-attachment-1-groundfish-stock-assessment-considerations-and-planning-for-2027-2029-and-beyond.pdf/)

## Inputs recovered

The native north model contains five annual catch-biomass series (commercial trawl, commercial fixed gear, Washington recreational, Oregon recreational, and California recreational), in metric tonnes for 1889–2020. Five `-999` zero placeholders are not calendar-year observations and are excluded. The model assigns a 0.01 standard error to log catch.

The model contains 137 aggregate CPUE observations from ten distinct fishery and survey fleets. Source CPUE units are encoded as numbers or biomass; the observations are retained as relative indices on their native scale because the model estimates fleet-specific catchability. All observations occur in July (within-year time 0.5) and have supplied log-scale standard deviations. The index series include the Triennial and WCGBTS surveys, fishery CPUE, hook-and-line survey, Lam research sampling, and CPFV data.

The source has 383 length-composition strata and 7,115 conditional-age-at-length strata. Length data use 2-cm bins from 10 cm through the 130+ cm terminal bin. Conditional age-at-length data use ages 0–20, with age 20 as the composition plus group, and actual length bounds (`Lbin_method = 3`). Source composition vectors, sample sizes, sex codes, partitions, age-error codes, and fleet identities are retained. Of the conditional-age-at-length records, 218 have a negative fleet code: Stock Synthesis calculates their expected values for display but excludes their likelihood contributions. Source sex codes 0, 1, and 2 also contain an ignored second-sex vector; it is retained and labelled as ignored, while code 3 is the joint sex-by-age or sex-by-length sample.

The model has one area, two sexes, population ages 0–25 (age 25 is the plus group), and a single annual season. It uses sex-specific von Bertalanffy growth, a fixed age-logistic maturity relationship, and fixed weight–length relationships. The archive’s `wtatage.ss_new` provides model-generated annual body-weight-at-age and maturity–fecundity surfaces; the importer derives maturity-at-age as the maturity–fecundity surface divided by the corresponding female body weight. The control file specifies fecundity option 1 with intercept 1 and slope 0, so this ratio reproduces the model’s maturity proportion. These are fitted-model biological surfaces, not independent field observations.

Natural mortality is estimated as a constant by sex and age: 0.417839 per year for females and 0.413968 for males. Recruitment follows a Beverton–Holt relationship with estimated steepness (about 0.801) and fixed recruitment variability of 0.60. The report documents annual time-varying recruitment deviations and time blocks for selectivity and retention. Commercial discards and discard mortality are modeled; source catch totals are not treated as total dead removals.

## Outputs recovered and limits

The native `Report.sso` contains beginning-year numbers-at-age, biomass-at-age, fleet-specific fishing mortality-at-age, and model-derived body weight and maturity-at-age. The importer also derives total abundance by summing both sex-specific N-at-age surfaces. Natural mortality-at-age is expanded from the two fitted sex-specific uniform-M parameters. These derived surfaces are identified as model output and are not assigned uncertainty where none is reported.

Annual spawning biomass, recruitment, total biomass, and age-3+ biomass are retained. The report provides 95% intervals for spawning biomass and recruitment for 2011–2021; the native covariance output provides delta-method standard errors for annual SSB and recruitment. Total abundance is derived from N-at-age and has no separate uncertainty interval. Age-specific N, F, M, weight, and maturity uncertainty is not reported as a surface.

The archive’s aggregate indices and conditional age-at-length compositions are preserved in their native form. It does not provide a direct observed catch-numbers-at-age series or age-specific survey abundance indices. The source record therefore remains partial rather than filling these gaps with fitted states or reconstructed values that the assessment did not use as observations.

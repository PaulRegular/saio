# Widow rockfish off the US West Coast

## Stock identity and latest detailed assessment

NOAA Stock SMART ID 10568 is *Sebastes entomelas* off the US West Coast. The 2025 detailed assessment treats this as one coastwide unit, distinct from Canadian and Alaska stocks. No matching stock is present in the canonical database. The NOAA inventory snapshot labels its metadata row 2026; the latest detailed official assessment located is the 2025 update, with model data through 2024. The supplemental review recommended the October 2025 model as best scientific information, and the Council's later assessment listing includes the 2025 report and model files.

The 2025 assessment, official model-file ZIP and supplemental review are cached in `source_cache/noaa_pacific_coast_widow_rockfish_20261029/`. Its `sources.csv` records URLs, retrieval date, sizes and SHA-256 checksums. The model bundle includes `2025widow.dat`, `2025widow.ctl`, `Report.sso` and `ss_summary.sso`; the data file spans 1916-2024 and models two sexes and ages 0-40+.

One run-version discrepancy needs to be preserved in any source import: the assessment report identifies SS 3.30.24.1, the supplemental review's model summary says SS 3.30.23.1, and the bundled `ss_summary.sso` identifies SS 3.30.23.2 with a 2025-12-03 run date. The bundled output's estimated female and male M values (0.135 and 0.147) match the published base-model estimates, but that alone does not resolve the version labels. Keep the bundle's run identity and the discrepancy explicit.

## Inputs and assumptions recovered

The October 2025 model has three non-zero catch sources (bottom trawl, midwater trawl and at-sea hake fishery), six abundance indices (four survey and two fishery-dependent), marginal age compositions for three commercial fleets, and conditional age-at-length data for WCGBTS. The native model data provide these input structures; fishery age compositions are sampled data, not a full annual catch-numbers-at-age matrix. The WCGBTS conditional age-at-length data are not a direct age-specific abundance index; conversion from survey indices and age information would be approximate and must avoid double-counting derived marginal compositions.

The assessment uses an age-structured, single-area, two-sex Stock Synthesis model. It estimates sex-specific growth and natural mortality, with a lognormal prior for M (median 0.10 per year, log-SD 0.31). M estimates in the base model are 0.135 for females and 0.147 for males. Age at 50% maturity is 5.47 years, carried from the 2015 benchmark, and the model uses externally estimated length-weight and fecundity relationships. Steepness is fixed at 0.72 and recruitment SD at 0.60. Survey, fishery, sex, age-error, and timing distinctions are represented in the native model files and require explicit approximation decisions in a.

## Outputs and screen decision

The fitted `Report.sso` contains numbers-at-age, catch-at-age, F-at-age, biomass-at-age, and other model tables; the assessment reports recruitment and spawning output. Spawning output is reported in billions of eggs, so it should not be silently labeled or compared as spawning biomass. The published report says the Hessian was positive definite, asymptotic variance estimates were available, the final gradient was low, and 57 of 100 jittered initializations returned to the same objective value.

The candidate is screened and eligible; a partial native source import is now recorded as noaa_west_coast_widow_2025. Source values remain in native units and compositions remain separate from population indices and catch-at-age.

## Database import

The canonical record uses the 2025 production assessment and the pinned model bundle retrieved on 2026-10-29. The source manifest records each download URL, retrieval date, file size and SHA-256. The assessment data end in 2024; fitted estimates are retained through 2024 and the model forecasts through 2036 are kept and marked in output notes.

Imported inputs include 545 valid annual catch-biomass rows for 1916-2024 across five source fleets (fleets 4 and 5 are zero-catch placeholders), 90 aggregate lognormal index observations and their log-scale standard errors across six series, 162 raw length-composition samples, and 616 raw age-composition samples. The length samples use 2 cm bins from 8 to 56 cm. The age samples retain ages 0-40, source sample size, ageing-error code, month and conditional length interval. Source sex code 3 contributes female and male vectors with a shared observation ID and sample size; it is one joint sample whose sex ratio is retained, not two independent samples. Negative fleet code -8 identifies a provisional composition whose likelihood is excluded from the source model's total objective.

Catch is in metric tonnes. The native catch_se values (0.01 and 0.1) and disabled catch-multiplier settings are recorded without rescaling. Aggregate-index values remain on their source scales: Stock Synthesis units code 0 denotes numbers and code 1 denotes biomass, but the source does not state a physical multiplier. The juvenile survey is the numbers-scale index; the other five series are biomass-scale. Index months, including fractional months, are preserved, with the database sampling time calculated as (month - 1) / 12.

The model bundle supplies fitted beginning-of-year N-at-age, biomass-at-age, F-at-age by fleet, M-at-age and weight-at-age, plus fitted dead catch-at-age, annual total biomass, age-0 recruitment and spawning output. The age-40 group is retained as the accumulator. Total abundance is derived by summing N over the two sexes and ages 0-40; it has no separately calculated uncertainty. The 2025 spawning-output estimate is 10,571.7 billion eggs; the assessment report's 95% interval of 5,127-16,017 billion eggs is retained. This is egg production, not spawning biomass.

The database remains partial. Fishery age compositions are samples, not an annual catch-at-age series, and conditional WCGBTS age-at-length samples are not a direct age-specific abundance index. Beginning-of-year weights are fitted model outputs, not observed weight inputs; the pinned bundle has no separate observed weight-at-age file. Maturity and fecundity are represented in fitted biology, without a standalone observed maturity-at-age input series.

The run-version discrepancy remains unresolved: the assessment report says SS 3.30.24.1, the supplemental review says 3.30.23.1, and the bundled ss_summary.sso says 3.30.23.2 with a 2025-12-03 run date. Database outputs are explicitly tied to the cached bundle.

## Sources

- [Status of widow rockfish off the US West Coast in 2025](https://www.pcouncil.org/documents/2026/05/status-of-widow-rockfish-stock-off-u-s-west-coast-in-2025.pdf)
- [Widow Rockfish 2025 Model Files](https://www.pcouncil.org/documents/widow-rockfish-2025-model-files/)
- [Supplemental Review Panel Report for Widow Rockfish](https://www.pcouncil.org/documents/2025/10/supplemental-review-panel-report-for-widow-rockfish.pdf)
- [PFMC groundfish assessment documents](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [NOAA Stock SMART ID 10568](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10568)

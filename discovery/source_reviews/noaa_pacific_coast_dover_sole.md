# Dover sole off the U.S. West Coast

## Assessment and provenance

NOAA Stock SMART ID 10022 is *Microstomus pacificus* assessed as one U.S. West Coast management unit. It is distinct from Dover sole in Canadian waters. The selected record is the 2021 production benchmark, fitted through 2020; the assessment materials reviewed show later harvest specifications continuing to use this benchmark, with no later full assessment located for this unit.

The assessment report, 2021 STAR review, and run-matched Stock Synthesis model archive are cached under `source_cache/noaa_pacific_coast_dover_sole_20261029/`. `sources.csv` records their source URLs, retrieval dates, byte counts, and SHA-256 checksums. The native archive identifies Stock Synthesis 3.30.16.02 and the exact `2021_dover.dat`, `2021_dover.ctl`, `Report.sso`, and `ss_summary.sso` used here. The report records final phase 6, 1,185 iterations, and a final gradient of 5.48845e-05.

## Imported source inputs

The canonical import preserves native observations and their dimensions; it does not manufacture observed catch-at-age or an age-specific survey index.

- **Catch:** 220 retained-catch observations for California and Oregon/Washington, 1911-2020, in metric tonnes. Native `catch_se` values are retained separately without assuming a scale that the source field does not specify. Stock Synthesis distinguishes retained catch (landings) from the separately modeled discards.
- **Survey indices:** 35 aggregate observations across the AFSC Slope, Triennial, NWFSC Slope, and NWFSC West Coast Groundfish Bottom Trawl surveys. Values remain on their native relative-index scale; no absolute abundance multiplier is stated. The source `se_log`, month, fleet error code, and timing are preserved. Month timing is recorded as `(month - 1) / 12`; Triennial uses month 7 before 1995 and month 9 thereafter.
- **Discard observations:** 44 fleet-year fractions of total catch, with their source CVs and month fields. The fitted fleet catch basis is biomass. The data file configures a Student-t discard likelihood with 30 degrees of freedom.
- **Mean body weight:** 36 observations from 2002-2019, with source CVs. These are mean body weights for the discarded catch, in kg per fish; they are not stock weights-at-age.
- **Length and age compositions:** 175 length-composition records and 925 age-composition records, retaining fleet, year, sex code, partition, sample size, source bins, age-error code, and raw frequency values. The 2021 model has two sexes and a maximum age of 60. Composition vectors are not normalized during import. Sex code 0 uses the combined-sex vector stored in the female portion; code 3 provides separate female and male vectors for one joint observation.
- **Ageing error:** Both source age-specific standard-deviation vectors are retained, with code 1 identified as 2021 CAP and code 2 as 2021 CDFW. These vectors do not alone encode the full true-age-to-observed-age transition matrix.

The age compositions are samples, not catch-at-age observations. Survey age records are conditional age-at-length samples for the NWFSC Slope and WCGBTS surveys; the marginal WCGBTS “ghost” compositions in the native file are retained but are not independent observations. The assessment uses length-based growth, weight, maturity, and fecundity functions. It supplies no observed stock weight-at-age or maturity-at-age input. No age-specific abundance index is present in the native source.

The native composition input stores some years and fleet codes with negative signs. The canonical year and fleet dimensions use the absolute key and retain the original sign in each row's notes. In the Stock Synthesis convention, a negative year excludes that composition from the active working matrix; a negative fleet retains a predicted value but excludes the row from the likelihood. The source rows remain traceable to the cached file.

## Imported official outputs

The import contains 105,042 output rows: fitted and forecast total biomass, age-3+ summary biomass, spawning biomass, age-0 recruitment, numbers and biomass at age, fleet-specific F and dead catch at age, M at age, model-generated beginning-of-year weight at age, terminal-year maturity at age, and total abundance derived by summing reported N across sexes and ages. Fitted time series run through 2020; model forecast rows are retained through 2032 and labeled as forecasts.

The report's Tables ii and iii provide 95% intervals for spawning biomass and age-0 recruitment for 2011-2021; these bounds are retained alongside the point estimates. Uncertainty is not reported for the imported age-specific surfaces, and no intervals are invented. Total abundance is derived from N-at-age and has no uncertainty.

Female natural mortality is fixed at 0.108 per year. Male natural mortality is estimated as an offset and is 0.11398 per year in the fitted output. The age-specific M output has one row per sex and age because these values are constant over years.

## Status and limits

The stock and assessment are recorded as new and current, with source inputs, assumptions, and outputs marked **partial**. The native files provide more detail than is expanded in the canonical assumptions table: selectivity, retention, catchability, likelihood weights, variance adjustments, and parameter activation remain available in the cached control and summary files but are not all transcribed parameter by parameter.

The official assessment does not contain observed catch-at-age, a direct age-specific survey abundance index, observed stock weight-at-age, or observed maturity-at-age. A future would need documented downstream reconstructions from catches/compositions and aggregate index/composition data, and would approximate the source model's two-sex, size-structured likelihood, conditional-age-at-length observations, ageing-error treatment, and fleet structure. The fitted N/F/M and biological surfaces are outputs and must not be reused as observations.

## Sources

- [Status of Dover Sole along the U.S. West Coast in 2021](https://www.pcouncil.org/documents/2021/10/status-of-dover-sole-microstomus-pacificus-along-the-u-s-west-coast-in-2021.pdf)
- [Dover Sole 2021 Stock Synthesis model files](https://www.pcouncil.org/documents/doversole-2021-model-files-zip-file/)
- [Dover Sole 2021 STAR panel report](https://www.pcouncil.org/documents/dover-sole-stock-assessment-review-star-panel-report/)
- [NOAA Stock Synthesis 3.30 User Manual](https://repository.library.noaa.gov/view/noaa/23884/noaa_23884_DS1.pdf) (data-file conventions for catches, discards, mean weights, composition sex codes, and negative fleet/year codes)
- [PFMC groundfish assessment documents](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [NOAA Stock SMART ID 10022](https://apps-st.fisheries.noaa.gov/stocksmart/?app=browse_by_stock&stockid=10022)

# NOAA California Quillback Rockfish — 2025 assessment

## Stock and assessment

NOAA Stock SMART ID 15342 identifies the California quillback rockfish unit, which is separate from Canadian Quillback. The database record is `noaa_quillback_rockfish_california`.

The 2025 official assessment used data through 2024 and Stock Synthesis 3.30.23.1. The model has one area, one modeled sex, ages 0–80, and an age-80 plus group. Its report gives aggregate estimates for the 2025 one-year forecast. The detailed report and native model bundle were cached with retrieval dates and checksums in `provenance/discovery_noaa_quillback_ca_2025/sources.csv`.

## Inputs recovered from the native model

- **Catch:** 218 annual catch-biomass observations for CA_Commercial and CA_Recreational, 1916–2024, in metric tonnes. The native catch SD is 0.05 on the log scale.
- **Abundance indices:** 28 relative-scale CPUE observations for CA_Recreational CPUE, CA_CCFRP, and CA_ROV, 2004–2024. Source observations are recorded in July; the model places their timing at 0.5 within the annual year. The native log-scale observation SDs are retained.
- **Length compositions:** 96 observations across native length labels 10–50 cm in 2 cm increments. The frequency vectors and `Nsamp` values are unscaled. Eight negative-year records are retained and flagged as excluded; 88 positive-year records are active.
- **Conditional age-at-length:** 253 records, ages 1–60. The native `Lbin_method = 2` codes are retained as one-based indices into the data-bin vector, whose labels are lower edges in centimetres. Age-error code 1, frequency values, sample sizes, source year signs, and observation identities are preserved. The archive contains 128 active positive-year rows and 125 negative-year rows excluded from the likelihood.
- **Natural mortality:** fixed at 0.068 per year across ages 0–80.

The model does not take observed catch-at-age or an age-specific abundance index directly. Catch-at-age in `Report.sso` is a fitted model output. Weight-at-age and maturity-at-age are not direct input series: the assessment estimates growth and uses external length-weight, length-based maturity, and fecundity relationships. Those distinctions are recorded in the assumptions rather than represented as observed age-specific inputs.

## Outputs recovered

`Report.sso` provides beginning-year N-at-age, biomass-at-age, M-at-age, fleet-specific F-at-age, and dead catch numbers-at-age for 1916–2024. The imported N surface was cross-checked against the archive's `natage.csv`. Total abundance is derived by summing N-at-age; total F is derived by summing the two reported fishery-fleet F surfaces. The report time series also provides all-age biomass and its age-3+ summary biomass.

The model's spawning quantity is **spawning output in eggs**, not spawning-stock biomass. Reported spawning-output and recruitment point estimates and 95% confidence limits are retained for 2015–2025. Point estimates use the native report file; confidence limits are the rounded values in Tables ii and iii. The 2025 rows are identified as one-year forecasts.

## Gaps and limits

The public archive does not contain a fitted `.par` or covariance output. The report does not provide uncertainty surfaces for N-, F-, M-, or biomass-at-age. Raw biological sample data and direct weight-at-age and maturity-at-age input series were not recovered, so inputs and outputs remain marked partial. Do not interpret the model-generated catch-at-age or spawning output as observed catch-at-age or SSB.

## Sources

- [2025 California Quillback assessment report](https://www.pcouncil.org/documents/2026/01/status-of-quillback-rockfish-in-u-s-waters-off-california-in-2025.pdf/)
- [2025 California Quillback native model files](https://www.pcouncil.org/documents/ca-quillback-2025-model-files-zip-file/)
- [Stock Synthesis 3.30 User Manual](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html), length-bin and composition-data rules

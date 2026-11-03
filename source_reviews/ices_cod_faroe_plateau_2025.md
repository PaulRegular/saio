# Faroe Plateau cod: 2025 ICES SAM assessment

## Assessment represented

The canonical record represents the official ICES 2025 assessment of Faroe Plateau cod (`cod.27.5b1`), fitted over 1959–2025 at ages 1–10+. The age-10 group is the plus group. The fitted SAM run is the `Cod_27_5b1_2025` run on stockassessment.org, using stockassessment 0.12.0 at RemoteSha `1cc464b80f6f`.

The selected fit converged with optimizer code 0, a positive-definite Hessian, and maximum absolute fixed-effect gradient `1.97e-12`. Its 2024 and 2025 recruitment, SSB, and Fbar match the published ICES stock-graph series to the precision shown there. An earlier `Cod_27_5b1_2024` fit was not selected: its corresponding values did not match the latest 2025 assessment series.

## Sources and cached files

- [ICES 2025 advice for cod.27.5b1](https://doi.org/10.17895/ices.advice.28162805)
- [ICES 2025 published stock graphs and annual data](https://sg.ices.dk/ViewSourceData.aspx?key=21240)
- [ICES Interbenchmark Protocol on Faroese Demersal Stocks (IBPFAR, 2022)](https://doi.org/10.17895/ices.pub.21565164)
- [ICES Northwestern Working Group report (2024)](https://doi.org/10.17895/ices.pub.25605738), including the preceding Faroe cod assessment chapter
- [ICES Northwestern Working Group report (2026)](https://doi.org/10.17895/ices.pub.32414577), whose published work plan schedules the Faroe Plateau cod assessment for 28–30 October 2026 and says stock sections will be added after the autumn meetings
- [Selected native SAM run](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Cod_27_5b1_2025/)

The source files are cached locally under `source_cache/ck_ices_nwwg_morhua_fapl5b1/`. The local `manifest.csv` records URLs, retrieval date, SHA-256 checksums, and the represented assessment. The native SAM model and data objects, configuration, code, advice, stock-graph table, IBPFAR framework report, and 2026 work-plan extract are retained there. As of the 2026-10-21 source review, the 2026 NWWG assessment meeting had not yet occurred, so the 2025 official run is the latest completed assessment available for this record. The cache is gitignored.

## Inputs and assumptions

The fitted model contains 1,161 observation slots and 1,140 finite observations: 590 commercial catch-at-age, 270 summer-survey indices, and 280 spring-survey indices. Catch is recorded in thousand fish at ages 2–10+, with age 10+ as the plus group. The source data object also contains empty age-1 catch slots; these were not fitted and are not imported as observations. Both survey series cover ages 1–9, on their native index scales. Survey timing is 0.65 for FO-GFS-Q3 and 0.225 for FO-GFS-Q1. Missing observations remain missing; no finite relative precision weights are supplied.

The model's catch likelihood shares one observation variance over ages 2–9 and uses a separate variance for age 10+. For both surveys, age 1 has a separate observation variance and ages 2–9 share one. The summer survey has AR(1) observation residual correlation over ages; the spring survey and catch residuals are independent. Catchability is survey-specific and age-specific over ages 1–7, with ages 8–9 sharing a parameter; there is no age-10 survey q.

Recruitment is age 1. The N process gives age 1 its own variance key and shares another key over ages 2–10. SAM estimates F for ages 2–10, with ages 7–9 sharing one latent state and an AR(1) correlation across fitted age states. The F process variance is separate for age 2 and shared for ages 3–10. Fbar is the arithmetic mean over ages 3–7. Natural mortality is fixed at 0.2 per year at all ages and years. Annual stock, catch, landings, and discard weights, maturity, landings fractions, and spawning-time mortality fractions are retained as supplied. The pre-spawning fractions for F and M are zero.

SAM SSB is reproduced by `sum(N * stockMeanWeight * maturity)` in tonnes, total biomass by `sum(N * stockMeanWeight)`, and Fbar by averaging F over ages 3–7. Recruitment equals beginning-of-year N at age 1. These checks match the native SAM reporting tables over every fitted year. Total abundance is also stored as a derived source output by summing the official N-at-age surface over ages 1–10+; no uncertainty is assigned to this derived total.

## tinyAM approximation

The translation retains the model years and age groups, both survey identities and timing, observed catch and index scales, source age-sharing for q and observation SDs, available annual biology, and fixed source M. It uses a separate random-walk recruitment process and one shared IID SD for older cohort-survival deviations, plus correlated random-walk F with mean F defined over ages 3–7. The recruitment and survival processes each have their own SD, corresponding to SAM's separate age-1 recruitment variance and shared age-2–10 survival variance. These settings do not reproduce SAM's initial-state treatment or full covariance conventions.

tinyAM has independent index residuals, so it does not represent the summer survey's AR(1) age correlation. The source model has no estimated F state at age 1; tinyAM's F model includes age 1, so that boundary is an approximation. The source model's observation slots omitted because they are missing remain missing in tinyAM. Source values are used only as comparison references. The fit tries package defaults first and uses one aligned source-based retry only if numerical checks fail.

## tinyAM fitting result

The 2026-10-22 attempt failed with package defaults, then failed again with one source-based retry. Both `nlminb` calls stopped after NA/NaN function or gradient evaluations; neither returned optimizer diagnostics, a fixed-effect gradient, or an uncertainty report. The initial objective and gradient evaluations were finite for both starting vectors, so the invalid evaluations arose during the optimizer search. No fitted tinyAM model or dashboard was produced, and no additional starting-value retries or model changes were made.

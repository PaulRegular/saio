# Faroe haddock 2025 (had.27.5b)

Source review revision: 2026-10-23.

## Assessment represented

The current detailed record is the official ICES 2025 Faroe haddock assessment, fitted as the public SAM run NWWG2025_had. It covers 1957–2025, ages 1–10+, with age 10 as the catch plus group. The fitted model converged with optimizer code 0, a positive-definite Hessian, objective 1214.389, and maximum absolute fixed-effect gradient 7.93e-11.

The native run and its complete model data, configuration, build script, validation code, input files, and plotting code are cached locally under source_cache/ices_haddock_faroe_2025/. The README in that folder lists source URLs, retrieval date, and SHA-256 checksums. The cache is gitignored. The advice PDF is retained as a source document. The selected native run is NWWG2025_had; no newer completed detailed production run was available in the public run directory during this review.

## Inputs and assumptions

- **Catch:** The SAM data object has 690 age-year slots for 1957–2025, ages 1–10+. The source catch file contains 41 genuine zero values. Those zeros are preserved in the database; SAM excludes them from its lognormal likelihood. The remaining 649 catch observations are in thousands of fish.
- **Catch weights in the likelihood:** Catch precision weights are 1 for 1957–2024 and 0.5 for 2025. The model sets fixVarToWeight=0, so these are relative precision weights; they do not fix observation variances.
- **Summer survey:** SUMMERSURVEY is represented as FO-GFS-Q3, covering 1996–2025, ages 1–8, at sampling time 0.65. Values remain on the native survey-index scale.
- **Spring survey:** SPRINGSURVEY is represented as FO-GFS-Q1, covering 1994–2025, ages 1–7, at sampling time 0.225. Values remain on the native survey-index scale.
- **Catchability:** Summer q is separate for ages 1–6, with ages 7–8 sharing; spring q is separate for ages 1–5, with ages 6–7 sharing. There is no q for unsampled ages.
- **Observation errors:** Catch ages 1–10 share one observation variance. Summer ages 1–2 share one variance and ages 3–8 another; spring age 1 has a separate variance and ages 2–7 share one. Catch residuals are independent; both survey residuals have AR(1) age correlation.
- **Population and F:** Recruitment is at age 1 and follows the configured random-walk stock-recruitment model. N variance is separate for age 1 and shared across ages 2–10. F states are separate for ages 1–8; ages 9–10 share one state. F innovations use AR(1) correlation across ages and one process variance. Fbar is defined over ages 3–7.
- **M and biology:** M is fixed at 0.2 per year as a time-invariant age vector. Annual stock, catch, landings, and discard weights, maturity, landings fractions, and pre-spawning mortality fractions are retained from the native model data. The pre-spawning F and M fractions are zero.

## Outputs

The database stores SAM N-at-age, F-at-age, recruitment, SSB, total stock biomass, Fbar, q by survey and age, and fitted catch and index predictions. Total abundance is derived by summing N-at-age; the database leaves its uncertainty blank because the age-covariance needed to propagate it is not available in the stored output table. N and F age-specific uncertainty is the conditional random-effect standard error on the log scale, transformed to natural scale with delta-method SEs and 95% log-scale Wald limits. Reported derived quantities use the fitted SAM log-scale estimate and its uncertainty with the same interval convention.

The 2025 terminal SAM estimates are recruitment 75,509.68 thousand fish, SSB 59,250.08 tonnes, and Fbar 0.12964 per year. The Fbar rounds to 0.130 in the 2025 ICES advice. The advice's 2026 projected SSB is not substituted for the fitted 2025 SSB.

## tinyAM translation limits

The translated fit retains catch and both survey series, source timing and catch weights, the q-sharing groups, fixed M, and the annual biological surfaces. It uses tinyAM's IID N survival deviations, a separate random-walk recruitment process, and a correlated random-walk F process. tinyAM does not reproduce SAM's survey AR(1) residual correlation, initial-state integration, or all of its covariance and variance-sharing details. Those differences are recorded in the translation audit and are not adjusted by changing the source observations.

## Sources

- [ICES 2025 advice for Faroe haddock (had.27.5b)](https://doi.org/10.17895/ices.advice.30738524)
- [2025 advice PDF mirror](https://www.hav.fo/wp-content/uploads/2025/11/ICES-Hysa.pdf)
- [Selected native SAM run](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NWWG2025_had/)
- conf/model.cfg, src/datascript.R, and run/data.RData in the cached native run provide the fitted model structure, data transformations, observation weights, and original biological surfaces.

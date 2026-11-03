# Celtic Sea haddock in divisions 7.b–k, 2026

## Assessment and sources

The current assessment is ICES `had.27.7b-k`, applied for 2026 advice. The WGCSE 2026 report identifies the 2025 SAM run `HAD7bk_2026` as the final assessment and says the procedure followed the 2020 stock annex, apart from the short-term recruitment assumption for 2026–2027. The fitted series ends in 2025; forecast values are not mixed into this record.

- [WGCSE 2026 report](https://doi.org/10.17895/ices.pub.32625759), haddock section 10, especially sections 10.3–10.5 and Tables 10.3–10.8.
- [WKCELTIC 2020 benchmark](https://doi.org/10.17895/ices.pub.5983), the benchmark framework cited in the 2026 report.
- [ICES 2026 assessment record, key 22561](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22561).
- Official [HAD7bk_2026 SAM model](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/HAD7bk_2026/run/model.RData) and matching [data object](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/HAD7bk_2026/run/data.RData), configuration, and native input files.

The 2026 report chapter, official SAM model and data objects, configuration, native `.dat` inputs, and result tables are cached under `source_cache/ices_haddock_7b_k_2026/`. `manifest.csv` records retrieval URLs, times, sizes, and SHA-256 checksums. The report says the TAF repository is empty and points to the named SAM run; the SAM run is therefore the source of the fitted model and inputs.

## Inputs and assumptions

The SAM model fits 1993–2025 at ages 0–8+, with age 8 as the plus group. The residual catch fleet is the combined catch from landings and discards. Catch-at-age is in thousands of fish. The native input file lists zero catch for age-0 cells and some older-age cells; their log observations are missing in the SAM data object, so these zeros are not fitted catch observations.

One age-specific survey index is used: `FRA_IRL_IBTS`, combining French EVHOE Q4 WIBTS and Irish IGFS Q4 WIBTS, standardized with VAST. It covers 2003–2025 at ages 0–7 and is sampled at 0.875 of the year. The source labels these values as VAST survey data but gives no physical unit or abundance multiplier; the database retains their native index scale. The 2005 age-7 index cell is missing in the SAM object and remains missing in the database and translation.

Annual stock, catch, landings, and discard weights are in kg per fish. Stock weights are a three-year running average and include discards. Maturity is fixed and age-specific. Natural mortality is fixed at 1.09, 0.72, 0.58, 0.48, 0.44, 0.41, 0.40, 0.39, and 0.36 per year for ages 0–8+, respectively. Landings fractions and F/M fractions before spawning are retained from the native data; the latter are zero.

The configuration uses lognormal likelihoods for catch and survey observations, independent residual errors, and no density-dependent q power. Catch shares one observation-variance parameter across ages; its observation weights are retained as relative likelihood weights (`fixVarToWeight = 0`). Survey q is age-specific for ages 0–7. Survey observation variance is shared across ages 0–5 and separately across ages 6–7. Recruitment follows a log random walk; the N process variance separates age 0 from ages 1–8. F follows a temporal random walk with AR(1) correlation across ages; ages 1–6 have separate states and ages 7 and 8 share one state. The reported Fbar uses ages 3–5.

## Outputs and limitations

The database contains start-of-year N-at-age and F-at-age from the fitted SAM object, annual recruitment, SSB, total stock biomass, and Fbar. Natural-scale N and F standard errors are delta-method conversions of the SAM log-state standard errors. Recruitment, SSB, total biomass, and Fbar retain the Low/High limits from the native SAM summary table; its interval confidence level is not specified. Total abundance is derived by summing official N-at-age over ages 0–8+ and has no uncertainty. M remains a fixed input rather than an estimated output.

Input, assumption, and output extraction are complete for the assessment run. The canonical outputs include start-of-year N-at-age and F-at-age, recruitment, SSB, total stock biomass, Fbar, total abundance, fitted catch and survey-index predictions, and age-specific q estimates for ages 0–7. Predictions are aligned to the 448 rows in the fitted object fit$data$aux; three rows have missing observations but native SAM predictions are available, while age-0 catch rows are omitted from the fitted observation array and have no prediction here. The q surface is reconstructed from the fitted keyLogFpar mapping and log-q estimates/SEs in the same way as stockassessment::qtable(). The package qtable method drops dimensions for this single-survey fit, so the mapping is kept explicit. Natural-scale q SEs use the delta method and its limits are 95% Wald intervals on log q. The native fit reports point predictions without prediction uncertainty.

## tinyAM fit diagnostics

The package-default initialization was attempted first and failed during optimization with repeated NA/NaN gradient and function evaluations. One retry kept the same observations, formulas, and model settings, using year- and age-aligned official N-at-age, F-at-age, and index-derived q values as starting values. The initial attempts returned no optimizer status, objective, or standard errors, and no dashboard was produced. Their logs are cached locally at `results/cache/ices_haddock_celtic_sea_7b_k_2026/initialization_attempts.rds`.

Review of the failed attempts found a concrete observation mismatch: the translation passed 35 zero catch cells as observations, while the native SAM data object omits their log observations. These are the 33 age-0 cells and two older-age zeros. The stock translation now marks those exact zero catch cells as missing for fitting, while the original zero values remain unchanged in the canonical input table. The default fit and its single source-start retry were rerun after this correction on 2026-10-26; both still failed with NA/NaN gradient or function evaluations. A direct check of the corrected default starting point produced a finite TMB objective (1103.989) and finite gradient, so the invalid evaluations arise later in the optimizer search. The zero-cell mismatch was real, but it was not the only cause. Neither fit attempt returned a final objective, optimizer status, or standard errors, and the assessment is still not ready for a dashboard. No further rescue settings were tried.

The tinyAM process estimates F at age 0, whereas SAM fixes age-0 F to zero. This remains a model-structure difference and was not changed as part of the zero-observation correction.

## Discovery inventory screening

The ICES 2026 inventory entry had.27.7b-k matches this existing canonical stock and is screened eligible. The run-matched source review and canonical validation test document the required age-based inputs, assumptions, survey timing and fitted outputs. This is an existing-stock match, not an additional stock unit.

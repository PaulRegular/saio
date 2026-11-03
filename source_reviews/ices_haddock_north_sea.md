# Northern Shelf (North Sea) haddock: 2026 source review

Source verification retained from the official-run review.
Translation revision: 2026-10-14.

Status: canonical record `ices_haddock_north_sea_2026` imported. Completeness remains partial because a calibrated physical unit for the survey indices has not been established and available state uncertainty is conditional rather than fully marginal.

Charbonneau–Keith identifier: `ICES-WGNSSK_aeglefinus_NS 4-6a-20`. The 2016 catalogue identifier `ICES-WGNSSK_aeglefinus_NS 4-3a20,6a` is retained as an alias for this stock; its separate metadata-only row was removed after confirming that no assessment, input, assumption, or output records referenced it. The successive catalogue labels are consistent with the Northern Shelf haddock unit reported by WGNSSK and the current stock code `had.27.46a20` ([ICES WGNSSK 2017 report](https://www.vliz.be/imisdocs/publications/350299.pdf); [2026 assessment chapter](https://ndownloader.figshare.com/files/66104291)).

The stock covers the North Sea, West of Scotland and Skagerrak (`had.27.46a20`).

## Official-run evidence

- [Detailed 2026 assessment chapter](https://ndownloader.figshare.com/files/66104291)
- [ICES WGNSSK 2026 report](https://doi.org/10.17895/ices.pub.32676345)
- [Official native SAM object](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NShaddock_WGNSSK2026_Run1/run/model.RData)
- [WKNSCS 2022 benchmark, published in 2023](https://doi.org/10.17895/ices.pub.21558681)
- [2025 haddock assessment chapter](https://ndownloader.figshare.com/files/55607879)
- [2025 Annex 8, including survey-index review](https://ndownloader.figshare.com/files/59379713)

The `baserun/model.RData` object in the archived directory is historical and ends in 2021. It is not used as the official 2026 assessment.

The selected `run/model.RData` object spans 1972–2026. All 648 annual recruitment, SSB, Fbar and TSB estimates and interval endpoints for 1972–2025 match the final-model Table 8.3.6 within published rounding.

The report's confidence intervals use `exp(log estimate ± 2 × log-SE)` rather than the exact normal 0.975 quantile.

## Official assessment: model structure and inputs

The official fit uses SAM 0.12.0, RemoteSha `1cc464b80f6f`, with model ages 0–8+.

It contains one total-catch fleet and two delta-GAM standardized survey indices:

| Component | Coverage | Observations | Sampling fraction |
|---|---|---:|---:|
| Commercial catch, ages 0–8+ | 1972–2025 | 486 | — |
| IBTS Q1, ages 1–8+ | 1983–2026 | 352 | 0.125 |
| IBTS Q3+Q4, ages 0–8+ | 1991–2025 | 315 | 0.75 |

Native inputs, the final fitted object and detailed report are cached under `source_cache/ices_haddock_north_sea_2026/`.

### Population and fishing mortality

The 2022 benchmark selected `NShaddock_WKNSCS_2022_Run11`, with random-walk recruitment and F, age-correlated F increments, and independent observation errors.

The 2025 review updated the survey indices and assessment configuration. Its post-review settings match the official 2026 run.

The official population process has:

- A separate recruitment-process variance.
- One shared older-cohort survival-process variance for ages 1–7.
- A separate survival-process variance for the age-8+ group.

Fishing mortality follows random walks with AR(1) correlation across ages in annual increments. F states are separate by age, with one shared innovation variance.

The official model uses independent observation errors.

### Survey catchability

Catchability coefficients are separate by survey and age.

Density-dependent catchability powers are estimated at Q1 age 1 and Q3+Q4 ages 0 and 1. Other survey ages use power 1.

The official configuration's observation-variance keys and survey relative precision weights are retained in the canonical database.

The presence of density-dependent catchability is important when interpreting discrepancies between fitted abundance and survey observations.

### Survey standardization

The 2025 survey review introduced annual spatial deviations around the fixed spatial surface in the delta-GAM indices to address persistent spatial residuals.

Post-review standardizations use a `log(HaulDur + 5)` offset. The selected Q1 model additionally uses Duchon splines for depth and time of year; the selected Q3+Q4 model uses log depth.

An independent reviewer recommended the SAM settings subsequently adopted in the official 2026 configuration.

The standardized survey indices are retained on their native numerical scales because the publications do not specify calibrated physical abundance units.

## Current tinyAM translation

The recipe retains 1972–2026 and ages 0–8+, RW recruitment, IID survival
residuals, and integrated older initial abundance. `N_sd_key` in population
covariates shares survival SD over destination ages 1–7, with a separate 8+
SD. First-year recruitment remains an estimated fixed effect; SAM initial-state
integration is not claimed to be identical.

F follows `cor_rw` with one shared SD. Supplied annual M, stock weights,
maturity and zero pre-spawning mortality fractions are retained. The shared
age-correlation structure approximates SAM; first-state and integration
conventions may still differ.

Catch uses one lognormal SD. Both delta-GAM survey series retain native scales,
ages, timing and relative precision factors, with survey-by-age q and one
estimated SD level per survey. Missing observations are excluded from the
likelihood. Source density-dependent q powers at Q1 age 1 and Q3+Q4 ages 0–1
are omitted, and exact observation-variance sharing differs. Ordinary q does
not reproduce a power relationship between abundance and an index.

## Forecast distinction

The native fitted 2026 SSB is 699,809.6 tonnes.

The advice forecast uses different weights and maturity, producing an SSB estimate of 667,758 tonnes.

Recruitment is resampled from 2000–2025 for advice rather than using the fitted 2026 recruitment estimate.

Report section 8.6 explains these differences.

The fitted assessment and advice forecast are distinct products. Forecast adjustments must not be substituted into the official historical state estimates used for comparison with tinyAM.

## Age surfaces and observation-weight checks

All 486 historical F-at-age values and 495 N-at-age values match Tables 8.3.4–8.3.5 within report rounding.

The native fit contains N and F states through 2026, although historically reported F ends in 2025.

The canonical N/F records include conditional random-effect SEs, natural-scale delta-method SEs and 95% log-Wald intervals calculated from the diagonal of the cached fit's random-effect covariance.

These estimates are conditional on fitted fixed parameters and are not full marginal state uncertainty intervals.

### Survey precision weights

All 667 native survey weights match:

`weight = 1 / log(1 + CV^2)`

using the first declared number of age columns in each raw CV matrix.

The official `read.ices()` reader includes the leading value of 1 as the first modelled-age CV entry and omits the trailing extra column.

This behaviour matches the stored fitted object and is preserved in the canonical database.

The native weights are recorded in `inputs.csv` as `relative_precision_weight` rows by survey, year and age.

Matching `log_index_sd` rows retain the derived relative SD factors:

`relative_sd = 1 / sqrt(weight)`

These factors describe relative observation precision, not the final fitted observation SD.

Catch-fleet precision weights are missing by design.

## Fitted observation predictions

The final SAM fit contains 1,153 fitted catch and survey predictions in `fit$rep$predObs`, aligned to the 486 catch, 352 Q1 and 315 Q3+Q4 rows in `fit$data$aux`. These are now recorded in `outputs.csv` as `predicted_catch` and `predicted_index`, using the native thousand-fish catch scale and unspecified native survey-index scale. The predictions are exponentiated log-scale fitted values and have no reported prediction uncertainty.

## Resolved reader and plus-group construction

The saved SAM revision's `read.ices()` selects the first declared number of age columns from each matrix without stripping a survey-effort column along this file path.

The published `src/datascript.R` assigns the relative precision weight using `1 / log(CV^2 + 1)`.

The first CV column is therefore assigned to the first model age, and the trailing column is omitted.

This convention reproduces all 667 official-run weights.

The reader and source data script are cached as `SAM_reading.R` and `SAM_datascript.R`.

The source stock script constructs age 8+ before fitting by:

- Summing catch, landings and discard numbers.
- Weighting stock weight, maturity and M by catch-number composition.
- Reusing terminal composition for the added model year.
- Weighting commercial component mean weights by their corresponding component catch numbers.

Final input matrices are available in `fit$data`, so these should be used rather than reconstructing plus-group quantities from rounded report tables.

The landings fraction is derived from aggregated landings numbers divided by total catch numbers.

The original discard-number file cited by the official script is also cached.

## Canonical import and validation

The canonical record includes 6,906 inputs, 3,526 outputs and 27 assumptions.

Imported components include catch, landings fractions, stock/catch/landings/discard weights, maturity, natural mortality, both surveys, 667 native precision weights and their corresponding relative log-scale SD factors.

All 648 summary/interval checks and 981 N/F surface crosschecks passed.

Structural validation, the source-specific validator and the state-uncertainty importer passed.

The canonical assessment model and numerical inputs have not been changed by the tinyAM translation revisions.

Completeness remains partial because the physical scale of standardized survey indices and full marginal state uncertainty remain unresolved.

## Spawning definition resolved

The official object's `propF` and `propM` matrices each contain 495 cells covering 1972–2026 and ages 0–8+.

Every value is zero.

These inputs establish a beginning-of-year spawning-biomass definition and are distinct from survey sampling fractions.

Both matrices are retained as biological inputs and checked against native cached exports.

The translation therefore preserves the official spawning convention without imposing nonzero mortality fractions before spawning.

## Catchability power correction

Inspection of the official fitted object and its exact SAM implementation established that the model estimates density-dependent survey catchability powers.

The native `keyQpow` mapping activates separate powers for Q1 age 1 and Q3+Q4 ages 0 and 1. Other survey ages use power 1.

The model predicts the survey index by multiplying log abundance after survey-time survival by `exp(logQpow)` and adding the fitted log-q coefficient.

On the natural scale:

`I = q × (N at survey time)^power`

The affected q coefficients therefore cannot be interpreted as simple fractions of abundance observed by the survey.

Seventeen catchability coefficients and three power parameters were recovered from the native fixed effects and their covariance, with natural-scale delta-method SEs and 95% log-Wald intervals.

Source-specific checks confirm parameter-to-age mapping, parameter values and SE conventions.

This finding supersedes the earlier description of catchability without density dependence.

Implementation reference: [SAM predobs.hpp](https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/predobs.hpp).

The tinyAM translation does not currently include these estimated powers. They remain an important identifiable source of observation-model disagreement.

## Initial-state semantics resolved

Both native `initN` and `initF` vectors are empty, and `initState = 0`.

The official SAM implementation evaluates the ordinary N and F process transitions from the second model year onward, without adding an explicit process density for the initial log-N and log-F states.

Those first-year states remain latent random effects integrated through the Laplace approximation.

A broad first-state normal prior is added only when calculating observation residuals. It is not a regular assessment prior and should not be presented as part of the fitted assessment likelihood.

The native configuration checks pass.

tinyAM now integrates the older first-year states without an initial density;
its estimated fixed-effect r0 anchor remains distinct from SAM's first-year vector.

Implementation references:

- [SAM n.hpp](https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/n.hpp)
- [SAM f.hpp](https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/f.hpp)

## Remaining translation limitations

The revised model now approximates the principal N and F process structures of the official assessment more closely.

Remaining differences include the precise initial-state and covariance conventions, simplified catch and survey observation variances, and the omission of three density-dependent survey catchability parameters.

The official survey index observations remain on uncalibrated native scales, with their relative precision factors preserved.

The available uncertainty estimates for N and F are conditional on fitted fixed effects rather than complete marginal intervals.

The simplified model is intended to evaluate how well a compact age-structured state-space model can reproduce official population dynamics. It does not claim likelihood-level or uncertainty equivalence with the official SAM.

## Record summary

The canonical record represents the official 2026 Northern Shelf haddock SAM assessment, using the verified native model and available source inputs.

The revised tinyAM translation fits ages 0–8+ over 1972–2026, with random-walk recruitment, IID cohort-survival deviations and grouped survival-process SDs, correlated F random walks, fixed natural mortality, and both standardized survey indices.

These changes substantially narrow the difference between the two models' core population-process assumptions.

The principal remaining observation-model simplification is the omission of density-dependent catchability powers at the youngest survey ages, alongside differences in the exact variance parameterization.

The official assessment inputs, outputs and canonical source-review findings remain unchanged.

## Initial abundance

The cached official SAM fit has `initState = 0` and no `initN` parameters.
The translation uses `init = "latent"`: older first-year log-abundances are
integrated without an initial density. First-year recruitment remains an
estimated fixed effect, so this is not complete SAM initial-state equivalence.

# North Sea Norway pout: 2026 source review

Translation revision: 2026-10-14.

Stock: Norway pout in ICES Subarea 4 and Division 3.a (`nop.27.3a4`).

## Assessment selected

The selected record is the February 2026 WKBWNG benchmark assessment for Norway pout.

The benchmark report identifies the official final SESAM run as `NP_Sep2025_bench_final`. The cached fitted summary is stored under the related archive name `NP_Sep2025_bench_final_Mfor`.

The cached fitted run matches the reported final model settings and the 2012 Q4 B_lim calculation. Its SSB at 2012.75 is 30,766.56 tonnes, compared with 30,766.76 tonnes in the benchmark report.

Quarterly fitted population states span 1984 Q1–2025 Q4. Catch and survey observations extend through 2025 Q3, although individual survey series have different terminal years.

The official fitted summary reports optimizer convergence code 0, objective 1547.746 and the message "relative convergence (4)". These are native SESAM diagnostics, not diagnostics from the tinyAM translation.

The cached fit also contains 1,092 fitted observation predictions in
`fit$rep$predObs`, aligned row-for-row with the 1,092 observations in
`fit$data`. The importer exponentiates these log-scale values and stores 668
catch and 424 survey predictions with the original quarter and age grouping.
The 26 combined ages 2-3+ remain grouped. These are point predictions only;
the database does not add intervals or a lognormal bias correction.

The benchmark is distinct from the 2025 production-advice assessment. WGNSSK 2026 states that no spring advice was issued for Norway pout. The benchmark is therefore retained as the current detailed assessment, with `is_applied = FALSE`.

### Natural-mortality scenario

The official model uses the selected M-0 scenario: annually varying, age- and quarter-specific natural mortality from the North Sea SMS model for 1984–2022, with the 2022 mortality pattern carried through 2025.

The benchmark selected this configuration after considering model fit, retrospective behaviour and diagnostic results.

The native fitted object contains the quarterly natural-mortality values used over its historical input intervals.

The separate `M_forecast.csv` includes forecast values, including 2026, and is not substituted for the official historical inputs.

## Data recovered

Native files are cached under:

`source_cache/ices_norway_pout_north_sea_2026_benchmark/native/`

The principal files are:

- `sum.RData`: Final fitted SESAM summary and processed observations retained by the selected assessment.
- `obs.dat`: Broader observation file, including candidate records not necessarily used by the selected fitted run.
- `aux_input.dat`: Supporting input data.
- `xsa.dat`: Model configuration data.
- `M_forecast.csv`: Forecast natural mortality, retained separately from fitted historical inputs.

The processed native model object contains 1,092 observations across quarterly catch-at-age and five survey fleets.

The canonical importer uses the observations retained in the selected fitted run rather than combining them indiscriminately with additional candidate records.

### Catch observations

Commercial catch-at-age is reported quarterly in millions of fish, covering ages 0–3+.

Catch observations extend through 2025 Q3. The fourth quarter of 2025 is unavailable in the selected fitted data.

The tinyAM translation therefore ends in 2024, the last year with complete quarterly catch observations available for annual aggregation.

### Survey observations

| Fleet | Survey series | Coverage | Sampling time |
|---|---|---|---|
| 2 | IBTS Q1, ages 1–3+ | 1984–2025 | 0.125 |
| 3 | EGFS Q3, ages 0–3+ | 1998–2025 | 0.625 |
| 4 | SGFS Q3, age 0 in 1998–2012 and ages 1–3+ in 1998–2025 | 1998–2025 | 0.625 |
| 5 | IBTS other countries Q3, ages 0–1 and grouped ages 2–3+ | 1999–2024 in fitted object | 0.625 |
| 6 | SGFS Q3, age 0 | 2013–2025 | 0.625 |

Sampling fractions correspond to quarter midpoints, using a quarter length of 0.25 year.

The source uses separate catchability and observation-variance sharing groups for the survey fleets.

EGFS and SGFS share catchability between ages 2 and 3+, while other age-specific coefficients follow the native configuration. The post-2013 SGFS age-0 series has a separate catchability key.

### Unresolved survey observations

WKBWNG Section 2.5 lists IBTS other-countries Q3 observations through 2025, whereas the selected fitted object and cached `obs.dat` both end this series in 2024.

The canonical database retains only observations actually present in the fitted object.

No missing 2025 observations are inferred.

The IBTS other-countries Q3 series also contains an observation combining ages 2 and 3+.

This is retained in the canonical database as an age-group index, not incorrectly assigned to age 2 alone.

tinyAM does not currently implement a grouped-age index likelihood, so this observation is excluded from the translation fit.

These unresolved details keep the input completeness status partial.

## Official SESAM model structure

### Population abundance and recruitment

The official model represents population abundance at quarterly intervals.

Recruitment enters at age 0 in Q3, rather than at the beginning of the calendar year.

Population-process variance is shared across ages 0–2 and is separate for age 3+.

The age-3 state represents the plus group.

This structure requires quarterly survival and recruitment accounting that is not reproduced exactly by the annual tinyAM model.

### Fishing mortality

The official model uses quarterly random walks in log fishing mortality.

Annual changes are not the elementary process steps: F evolves between successive quarters.

The random-walk increments have AR(1) correlation across neighbouring ages.

F-process innovation variance is shared within two groups:

- Ages 0–1.
- Ages 2–3+.

F states remain distinct for each age.

Fbar is calculated over ages 1–2.

The official model also applies a large-increment adjustment. Selected F-process increments have their standard deviation multiplied by 100 when the corresponding change in `log(catch + 1)` exceeds 2.9.

This reduces the process penalty for certain unusually large changes.

### Natural mortality

Natural mortality is supplied as an external age- and quarter-specific numerical input.

It is not estimated as a stochastic mortality process by SESAM.

The processed native data contain 668 M values covering quarterly input intervals from 1984 Q1 through 2025 Q3.

The fitted-history mortality surface and forecast mortality file are retained separately.

### Catch observation errors

The official catch observation model has three variance groups:

- Age 0.
- Ages 1–2.
- Age 3+.

### Survey observation model

The survey observation model uses fleet-age catchability and observation-SD sharing described in benchmark Table 2.5.

The exact native sharing keys are represented in the canonical database.

The source's grouped-age IBTS observation cannot be directly represented by an individual-age survey likelihood.

### Spawning biomass

SESAM calculates spawning-stock biomass at the beginning of each quarter.

Maturity is constant across years:

| Age | Maturity |
|---|---:|
| 0 | 0 |
| 1 | 0.2 |
| 2 | 1 |
| 3+ | 1 |

Stock weights are age- and quarter-specific but constant across years. Catch weights vary by age, year and quarter.

The official input construction treats discard weights as catch weights, consistent with the benchmark's conclusion that discards and bycatch are negligible.

## tinyAM translation revision (2026-10-14)

The revised translation retains the annualized observations and biological inputs while improving correspondence with the official population and fishing-mortality processes.

The principal changes are:

- Free initial abundance replaces exponential initialization.
- IID older-cohort survival deviations use age-grouped process SDs.
- Correlated F random walks replace stationary AR1 F.
- Catch observation SDs retain the translated native age groups.
- Survey catchability and observation SDs retain the source-derived sharing groups.

The revised configuration is reported to produce a working fit. Updated tinyAM convergence statistics and comparison metrics should be recorded separately from the official SESAM diagnostics.

### Model period and age structure

The translation fits 1984–2024 and ages 0–3+, with age 3 as the plus group.

The model annualizes quarterly population dynamics and catch observations.

Recruitment is represented at age 0 in the annual model, while the source's Q3 recruitment timing is accounted for where possible in translating mortality exposure and survey observations.

This annualization is a substantive structural approximation.

### Population process

The revised population settings are:

`N_settings = list(process = "iid", init = "free", sd_form = ~0 + N_sd_key)`

The model estimates initial older-age abundance freely.

Older-cohort survival deviations follow IID processes, with process SDs determined by the `N_sd_key` age groups.

The source's principal older-age variance distinction is represented by a shared SD for ages 1–2 and a separate SD for age 3+.

Recruitment at age 0 retains the separate tinyAM recruitment process. The source's age-0 recruitment/survival variance cannot be combined exactly with the older-age N-process variance under this parameterization.

Consequently, the age-specific variance structure is approximated rather than reproduced exactly.

The official quarterly process is represented through annual cohort survival.

### Fishing-mortality process

The revised translation specifies:

`F_settings = list(process = "cor_rw", mu_form = NULL, mean_ages = 1:2)`

Fishing mortality follows correlated random walks on the log scale.

For each age, annual increments are:

`delta_log_F[a,t] = log(F[a,t]) - log(F[a,t-1])`

The annual increment vector follows a multivariate Normal distribution with covariance:

`Sigma[a,b] = sigma_F^2 * rho^abs(a-b)`

Here, `rho` describes AR(1) dependence between neighbouring ages, and `sigma_F` is the common annual increment SD.

This reproduces the main temporal and cross-age features of the official SESAM F process more closely than the previous stationary AR1 model.

The official model's quarterly increments, separate age-grouped F innovation variances and large-increment adjustment are not reproduced.

The annual translation uses one shared F-process SD rather than the source's two variance groups.

The initial F state remains subject to tinyAM's random-walk initial-state convention.

Fbar is calculated over ages 1–2.

### Natural mortality

The translation uses:

`M_settings = list(process = "off", mu_form = NULL, mu_supplied = ~M_assumption)`

The original quarter-specific natural mortality values are converted to annual-equivalent mortality inputs.

No natural-mortality process is estimated.

For ages 1–3+, annual exposure includes all four quarters.

For age 0, annual exposure includes only Q3 and Q4 because recruitment enters in Q3.

This accounts for the source's differing age-specific exposure periods without reproducing the entire quarterly population model.

### Catch observations

Quarterly catch numbers are summed into annual catch-at-age observations.

The translation retains the three source-derived error groups using:

`catch_settings = list(sd_form = ~0 + sd_block)`

The groups distinguish age 0, ages 1–2 and age 3+.

Observation SDs are estimated from the annualized data while preserving the source's age-group sharing.

The official quarterly catch likelihood is not reproduced: aggregating four quarterly observations changes both their temporal resolution and their error structure.

The translation also avoids treating incomplete 2025 catch as a complete annual observation.

### Survey indices

The translation uses:

`index_settings = list(q_form = ~0 + q_key, sd_form = ~0 + sd_block)`

Catchability parameters are estimated according to source-derived `q_key` groups.

Observation-error SDs are estimated using the translated `sd_block` groups.

These groupings preserve the source's main catchability and variance-sharing patterns without requiring a separate catchability coefficient for every age-fleet combination.

Survey timing is represented by quarter midpoints:

- Q1: 0.125.
- Q3: 0.625.

The model retains individual-age survey observations on their native scales.

The grouped IBTS other-countries Q3 age-2–3+ observation remains excluded from the tinyAM likelihood but is retained in the canonical record.

No missing 2025 IBTS other-countries observations are inferred.

### Biological inputs

The translation retains the official maturity schedule.

Annualized stock weights use:

- Q1 stock weights for ages 1–3+.
- Q3 stock weight for age 0.

This aligns the weights with the selected annual population-state convention while accounting for the later entry of age-0 recruits.

Natural mortality is converted using age-specific quarterly exposure.

The retained biological inputs are therefore source-based annual equivalents, not alternative estimated biological surfaces.

### Spawning-stock biomass comparison

The official SESAM assessment calculates SSB at the beginning of each quarter.

tinyAM's common-period comparison uses Q1 spawning biomass calculated from beginning-of-year abundance, the translated Q1 stock weights and the official maturity vector.

For ages contributing to SSB, these definitions align at the start of the year.

Age-0 maturity is zero, so its different within-year recruitment timing does not directly contribute to SSB.

The common-period Q1 SSB comparison is therefore more directly comparable than other quarterly-to-annual outputs.

### Abundance and recruitment comparisons

The official assessment's Q1 age-0 abundance is measured before current-year age-0 recruitment enters the population in Q3.

Consequently, that source age-0 abundance state does not correspond directly to tinyAM's annual recruitment state.

The official Q1 age-0 N row is excluded from the like-for-like age-specific abundance comparison.

Age-0 recruitment is compared separately using the source's recruitment output.

This avoids treating biologically different states as equivalent.

### Starting parameters

The revised fit retains:

`start_par = start_par`

These starting values assist numerical optimization of the annualized model.

They do not fix the population or fishing-mortality states to the official SESAM estimates.

Any official N or F values supplied as initial parameter values are re-estimated freely during the tinyAM fit.

Retaining informed starting values is reasonable for this translation, given the substantial differences between quarterly SESAM dynamics and the annual tinyAM parameterization.

### Interpretation of the revision

The revised model is a closer approximation to official SESAM in two important respects.

First, age-grouped IID survival-process SDs allow different survival variability between younger ages and the plus group.

Second, correlated F random walks reproduce the main random-walk and cross-age correlation structure used by SESAM.

These changes improve structural correspondence without reproducing the source model's quarterly dynamics, age-0 recruitment timing, grouped-age survey likelihood or special large-increment treatment.

The model should therefore be assessed primarily as an annual approximation of population dynamics and stock-status trajectories rather than as an exact reproduction of the quarterly likelihood.

Numerical success should be established using the current tinyAM convergence checks and comparison results, independently of the official benchmark fit.

## Canonical outputs and validation

The cached official SESAM fit provides:

- Quarterly abundance-at-age and fishing-mortality-at-age point estimates.
- Quarterly SSB and Fbar with 95% intervals.
- Annual age-0 recruitment with 95% intervals.

Age-specific N and F intervals were not recovered from the cached native summary.

Natural mortality is an externally supplied input surface and is not described as an estimated model output.

The canonical record preserves the quarterly source outputs.

Annualized comparison definitions are documented separately so that differing reference times and age-0 recruitment conventions are not concealed.

Thirteen native catchability point estimates are also recorded from `fit$pl$logQ`, expanded with `exp()` and mapped through the saved `fit$data$keyLogQ`. The rows preserve separate fleet keys and shared age groups; age 3 is the 3+ group. The saved object does not provide usable q uncertainty: `fit$plsd$logQ` duplicates the point estimates, so standard errors and intervals remain unavailable. The physical survey-index units are not specified.

## Remaining translation limitations

The principal differences between the official SESAM benchmark and the revised tinyAM translation are:

- Quarterly SESAM population dynamics are reduced to annual transitions.
- Recruitment enters in Q3 in the source but is represented in an annual age-0 state in tinyAM.
- The source N-process variance grouping is only partly reproduced because recruitment uses a separate process.
- The source F process is quarterly, uses two innovation-variance groups and includes large-increment adjustments.
- The translation fits annualized catch rather than quarterly catch observations.
- A grouped age-2–3+ survey index is omitted from the tinyAM likelihood.
- One reported 2025 survey-series endpoint differs between the benchmark text and the selected fitted object.
- Annual-equivalent biological inputs depend on the documented quarterly exposure conventions.
- The annual abundance comparison cannot include Q1 age-0 N on a like-for-like basis.

These differences are limitations of the simplified model, not errors in the official assessment.

## Sources

- [ICES WKBWNG 2026 benchmark report](https://doi.org/10.17895/ices.pub.32019630), particularly Sections 2.3–2.6, Tables 2.1–2.5 and Figures 2.1–2.2.
- [Benchmark report PDF](https://ices-library.figshare.com/ndownloader/files/64519302)
- [WKBWNG working documents](https://ices-library.figshare.com/articles/report/Benchmark_Workshop_on_Whiting_Norway_Pout_and_Golden_Redfish_WKBWNG_/32019630)
- [Official fitted SESAM run](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NP_Sep2025_bench_final_Mfor/run/sum.RData)
- [Official SESAM input directory](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NP_Sep2025_bench_final_Mfor/data/)
- [2025 production advice](https://doi.org/10.17895/ices.advice.27202770)
- [ICES Stock Assessment Graphs](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21230)

The benchmark report remains the authority for assessment selection and model assumptions. The selected native fitted object supplies the numerical assessment inputs and outputs used in the canonical record.

Earlier local Windows retrieval problems with the public benchmark PDF did not prevent recovery of the native fitted-object records.

## Record summary

The canonical record represents the official February 2026 SESAM benchmark for North Sea Norway pout, with quarterly fitted states extending from 1984 through 2025

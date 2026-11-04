# North Sea Norway pout: 2026 source review

Stock: Norway pout in ICES Subarea 4 and Division 3.a (`nop.27.3a4`).

## Assessment selected

The selected record is the February 2026 WKBWNG benchmark assessment for Norway pout.

The benchmark report identifies the official final SESAM run as `NP_Sep2025_bench_final`. The cached fitted summary is stored under the related archive name `NP_Sep2025_bench_final_Mfor`.

The cached fitted run matches the reported final model settings and the 2012 Q4 B_lim calculation. Its SSB at 2012.75 is 30,766.56 tonnes, compared with 30,766.76 tonnes in the benchmark report.

Quarterly fitted population states span 1984 Q1–2025 Q4. Catch and survey observations extend through 2025 Q3, although individual survey series have different terminal years.

The official fitted summary reports optimizer convergence code 0, objective 1547.746 and the message "relative convergence (4)". These are native SESAM diagnostics.

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

These unresolved details keep the input completeness status partial.

## Official SESAM model structure

### Population abundance and recruitment

The official model represents population abundance at quarterly intervals.

Recruitment enters at age 0 in Q3, rather than at the beginning of the calendar year.

Population-process variance is shared across ages 0–2 and is separate for age 3+.

The age-3 state represents the plus group.

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

## Canonical outputs and validation

The cached official SESAM fit provides:

- Quarterly abundance-at-age and fishing-mortality-at-age point estimates.
- Quarterly SSB and Fbar with 95% intervals.
- Annual age-0 recruitment with 95% intervals.

Age-specific N and F intervals were not recovered from the cached native summary.

Natural mortality is an externally supplied input surface and is not described as an estimated model output.

The canonical record preserves the quarterly source outputs.

Thirteen native catchability point estimates are also recorded from `fit$pl$logQ`, expanded with `exp()` and mapped through the saved `fit$data$keyLogQ`. The rows preserve separate fleet keys and shared age groups; age 3 is the 3+ group. The saved object does not provide usable q uncertainty: `fit$plsd$logQ` duplicates the point estimates, so standard errors and intervals remain unavailable. The physical survey-index units are not specified.

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

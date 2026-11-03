# West of Scotland cod: final standalone 2022 assessment

## Identity and production run

This is Charbonneau–Keith `ICES-WGCSE_morhua_NS6a`, retained under the existing stock ID `ck_ices_wgcse_morhua_ns6a`. The official 2022 assessment covers ICES Division 6.a, years 1981–2021 and ages 1–7+. It is the final standalone assessment before the 2023 Northern Shelf merger. It must not be counted alongside the broader Northern Shelf case as another contemporary independent stock.

The selected native run is `cod.27.6a_2022`, not the similarly named sensitivity runs. All 41 years of native SSB, recruitment and Fbar match the 2022 ICES SAG advice series (key 17399) to published rounding. Final values are SSB 3326.329 tonnes, age-1 recruitment 1973.574 thousand fish and arithmetic Fbar over ages 2–5 of 0.746561 per year. The WGCSE report Tables 3.12–3.16 independently identify the configuration, N, F and summary outputs. The original SAM fit has optimizer code 0 and a positive-definite Hessian.

## Recovered sources and inputs

Authoritative files are cached under `source_cache/ck_ices_wgcse_morhua_ns6a_2022/`, with URLs, retrieval times, byte counts and SHA-256 checksums in `manifest.csv`. They include the fitted object, original data object, individual data files, configuration, data-preparation script, 2022 advice, detailed WGCSE chapter, WKDEM 2020 framework and 2023 boundary benchmark. Model implementation checks use the source revision saved with the fitted object, `ec2c2a0c6dde`.

The database records the native residual catch in thousand fish, including landings and discards. Missing catch at ages 1 and 2 in 2021 is preserved: WGCSE excluded those values because COVID-related disruption made the discard samples unreliable. No fitted catch-scaling factors are applied to observations.

All five fitted survey series are retained:

| Native survey | Years | Ages | Timing | Model observation unit |
|---|---|---|---:|---|
| WCIBTS.Q1 | 1985–2010 | 1–6 | 0.125 | fish per hour |
| IRGFS.Q4 | 2003–2021 | 1–3 | 0.855 | fish per minute |
| WCIBTS.Q4 | 1996–2009 | 1–4 | 0.875 | fish per hour |
| SCO.Q1 | 2011–2021 | 1–6 | 0.125 | fish per hour |
| SCO.Q4 | 2011–2021 | 1–6 | 0.875 | fish per hour |

Table 3.11 expresses Scottish survey counts per ten hours; `read.ices()` divides these values by the effort column, which is 10, to obtain the actual fish-per-hour model input. Irish observations are divided by minutes towed. Source survey names have trailing spaces, which are stripped to match SAM's fleet identifiers; values are unchanged. Every imported catch and survey observation is checked against the fitted object's year, age and fleet map before writing. Zero values remain zero and source missing values remain missing.

Original annual stock/catch/landings/discard weights, maturity, fixed M, landings fractions and pre-spawning fractions are preserved. Stock weights were smoothed by the assessment authors; M follows their weight-based Lorenzen calculation. The source's 2021 age-1 and age-2 stock weights repeat 2020 values by explicit WGCSE decision. All pre-spawning mortality fractions are zero. These are supplied biological inputs, not fitted SAM biological surfaces.

## Likelihood and outputs

Recruitment follows a random walk; older N-process errors share one variance. The first-year N values are separate latent states; the ordinary N transition density begins in year two. F has separate states at ages 1, 2 and 3 and one shared state for ages 4–7. Its temporal random-walk increments have AR(1) correlation across age states, with a separate process SD for age 1. Survey lognormal observation errors are independent across ages, with one fitted SD per survey. Their q-sharing keys and timings are recorded separately for each survey.

Catch SDs distinguish age 1, ages 2–6 and age 7+. Relative precision is 0.25 from 2006 onwards, which doubles the fitted log SD. The current Scottish surveys use supplied variance estimates to calculate relative precision. Both those relative weights and the original supplied SDs are retained. `fixVarToWeight=0` means that these do not fix absolute observation variance. The pinned SAM observation code confirms SD divided by the square root of relative precision; missing weights mean no adjustment.

One catch-scaling factor is estimated for each year 1995–2006, shared across ages. The pinned prediction code subtracts `logScale` from log Baranov catch. The database therefore distinguishes native predicted recorded catch-at-age from total Baranov catch biomass and records the estimated scaling factors separately. These factors are outputs, never corrections to input observations.

Recovered outputs include N, expanded F, q, fitted observations, SSB, total biomass, recruitment, Fbar and catch-scaling factors. Estimates exponentiate native log estimates; SEs are explicitly approximate natural-scale delta-method SEs, with 95% log-scale Wald confidence limits. Derived total abundance sums all ages and has no invented uncertainty. The importer verifies native aggregate definitions from N, F and biology. Offline checks protect source cells, age/year coverage, survey rates and timings, missing catches, fixed biology, F-state sharing and uncertainty scales.

## Translation and diagnostic outcome

The initial translation retains the source grid, all five surveys, supplied M and biology, q sharing, observation-SD sharing and relative precision. It uses IID N process errors, RW recruitment and age-correlated RW F. Its F states at ages 4–7 remain separate rather than exactly shared, and it omits SAM's catch-scaling factors. These are explicit approximations; the original catches are unchanged.

The first normal-start trial used fixed free initial abundance. It failed numerical checks: optimizer code 1 (`false convergence (8)`), objective 728.1359, maximum absolute gradient 0.0071505 and a non-positive-definite Hessian. An sdreport object was returned but its covariance contains non-finite entries, so usable uncertainty was not established. This trial is retained locally and in Git history.

The retained source-oriented recipe uses `init = "latent"`, which integrates initial older-age abundance without an initial process density. First-year recruitment remains fixed in tinyAM, whereas SAM integrates that state too. Its default-start attempt fails with an undefined optimizer gradient. One retry, with the same observations, formulas and settings, initializes N, F and q from the official estimates; other starts retain package defaults. Both attempts and warnings are retained in `results/cache/ices_cod_west_scotland_2022/initialization_attempts.rds`.

The retry passes numerical checks (optimizer code 0, objective 662.5856, maximum absolute gradient 0.0001743 and a positive-definite Hessian), but is severely implausible as a replication. It estimates enormous N with F close to zero; 231 fixed-parameter pairs have absolute correlation above 0.95. Residual checks flag biased groups, uneven spread, outliers and serial correlation. This is not a successful biological approximation despite its numerical convergence flag.

| Metric | Mean absolute difference (%) | Terminal difference (%) | Trend correlation | Status |
|---|---:|---:|---:|---|
| Total abundance | 120346800 | 203466700 | 0.939 | Matched definition; severe scale failure |
| N-at-age | 4915381000 | 2552743000 | 0.933 | Matched definition; severe scale failure |
| F-at-age | 100.00 | -100.00 | -0.016 | Approximate state sharing; scale and trend failure |
| Recruitment | 52790650 | 91888160 | 0.870 | Matched definition; scale and trend failure |
| SSB | 700540800 | 948653700 | 0.972 | Matched definition; severe scale failure |

Rounded diagnostics are retained here rather than used as tuning targets. Fixed M agrees by construction. The current evidence does not isolate whether omitted catch scaling, different F-state sharing, initial-state integration or their interaction causes the pathological fit. No observation corrections, new priors or core-model changes were introduced to rescue it. The dashboard at `results/cache/ices_cod_west_scotland_2022/dashboard.html` is explicitly labelled as exploratory and unsuitable as evidence of close replication.

Validation: source checks, fitting-disabled translation checks, conditional-start helper tests and multi-assessment runner tests pass. The complete canonical database validates; other stocks and assessments are unchanged, and the importer is byte-for-byte idempotent. The full package test suite and `R CMD check --no-manual --no-vignettes` pass (0 errors, 0 warnings, 0 notes). The runner test emits two package-serialization availability warnings in its temporary parallel workers, without a failed test. No package code or model mathematics changed in this curation/translation work.

## Sources

- [2022 ICES advice](https://doi.org/10.17895/ices.advice.19447889)
- [WGCSE 2022 detailed report](https://ices-library.figshare.com/articles/report/Working_Group_for_the_Celtic_Seas_Ecoregion_WGCSE_/19863796), Section 3 and Tables 3.7–3.16
- [WKDEM 2020 framework](https://doi.org/10.17895/ices.pub.5548)
- [WKBCOD 2023 boundary benchmark](https://doi.org/10.17895/ices.pub.22591423)
- [Official SAG time series, key 17399](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=17399)
- [Native production run](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/cod.27.6a_2022/)

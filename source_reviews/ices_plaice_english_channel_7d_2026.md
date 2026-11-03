# Eastern English Channel plaice (`ple.27.7d`)

## Assessment represented

The record `ices_plaice_english_channel_7d_2026` represents the 2026 ICES advice assessment for plaice in Division 7.d, fitted through 2025 with 2026 forecast estimates. It is linked to the existing Charbonneau–Keith stock row; that catalogue record supplied a crosswalk, not evidence of assessment coverage.

The 2025 WKBNSCS benchmark selected SAM for advice, using ages 1–7 with age 7 as the plus group, age-1 recruitment, fixed age-specific natural mortality, and age-specific UK BTS and FR GFS indices. The benchmark adopted a constant histology-based maturity ogive, age-specific stock weights based on Q2 landings weights, and updated catch/discard series. The native SAM configuration and inputs are cached locally.

## Sources and cache

URLs, retrieval date, pinned revision, and checksums for the source files are recorded in the ignored `source_cache/ices_plaice_7d_2026/manifest.csv`.

- [ICES 2026 advice for `ple.27.7d`](https://doi.org/10.17895/ices.advice.30932276)
- [ICES SAG source data, assessment key 22484](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22484) · [SAG XML](https://sag.ices.dk/SAG_API/StockXmlDownload/22484)
- [WKBNSCS 2025 benchmark report](https://doi.org/10.17895/ices.pub.28715180), particularly the Division 7.d chapter and Table 1.3
- [SAM input/configuration archive](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/ple.27.7d_2026)
- [SAM repository at the locked source revision](https://github.com/fishfollower/SAM/tree/1cc464b80f6f2a4a38b35cce276f13e521761da3/stockassessment)

The archive locks `stockassessment` 0.12.0 at commit `1cc464b80f6f2a4a38b35cce276f13e521761da3`. Its `src/model.R` fits the cached native data and config, but the public `run/model.RData` fitted-object endpoint returned 404. A local fit with the locked package converged (optimizer code 0; objective 630.7586), yet its terminal recruitment and SSB were 79,099 thousand fish and 27,053 tonnes, compared with ICES SAG's 65,433 thousand fish and 21,729 tonnes. The local fit is therefore retained only in the ignored cache and is not used as an official output source.

## Curated coverage

| Record | Coverage | Unit / treatment |
|---|---|---|
| Residual catch numbers at age | 1980–2025, ages 1–7 | Thousand fish; one aggregate catch stream |
| UK BTS index | 1989–2025, ages 1–6 | Native index scale; six 2022 cells absent |
| FR GFS index | 1990–2025, ages 1–6 | Native index scale; age 5 in 1998 absent |
| Stock, catch, landings and discard weights | 1980–2025, ages 1–7 | kg per fish |
| M, maturity, landings fraction and spawning-time inputs | Ages 1–7 | Static source surfaces; M is fixed, and propF/propM are zero |
| Published recruitment, SSB and Fbar | 1980–2025; recruitment and SSB forecast to 2026 | SAG values and 95% intervals retained |

The survey index multipliers are not stated, so observations remain on their native scales. Sampling times are taken from the native SAM data object: 0.625 for the Q3 UK BTS and 0.875 for the Q4 FR GFS. The `cn.dat` heading says “Landings weight at age”, but the SAM object identifies fleet 1 as residual catch. Exponentiated catch numbers multiplied by the native catch weights reproduce the SAG annual catch totals (landings plus discards) to within rounding, supporting the interpretation as the fitted total-catch series. `lf.dat` is all 1.0; it is retained as the native SAM field and is not treated as the observed landed fraction.

The benchmark says 50% of mature Q1 plaice caught in 7.d are allocated to Division 4 and 15% to Division 7.e; recreational catches were excluded as less than 1% of commercial catch. The database preserves the resulting single catch input rather than reconstructing fleet- or quarter-specific records.

## Outputs and limitations

ICES SAG publishes age-1 recruitment, SSB, and Fbar, with a 95% interval. Its source data does not provide N-at-age, F-at-age, or total abundance. The assessment record therefore marks outputs `partial`; these quantities remain unavailable, and no local refit states or derived uncertainty are presented as official.

The archive config sets `fbarRange=3 7`, while SAG metadata defines Fbar as ages 3–6. The pinned local SAM summary also reports Fbar(3–7). The canonical output preserves the published SAG metric and labels its age group 3–6; this difference remains an unresolved source/configuration discrepancy.

The tinyAM translation uses the native observations and fixed M, a temporal random walk for N and recruitment, and a correlated random walk for F with an estimated age correlation. It retains survey-specific q groups (ages 1–4 separate; ages 5–6 shared) and one index SD per survey. These approximate SAM's process covariance and parameter sharing; they do not reproduce SAM's exact likelihood or age-6/7 shared F state. Only aggregate SSB and recruitment are directly comparable; Fbar is non-equivalent, and N-at-age, F-at-age and total abundance are unavailable.

## tinyAM fit and comparison

The package-default fit failed with `NA/NaN gradient evaluation` and returned no optimizer result. One retry used N, F and q starting values from the local refit of the pinned SAM model to the archived inputs; the same observations, settings and likelihood were retained, and tinyAM estimated all parameters freely. The retry converged with optimizer code 0 (`relative convergence (4)`), objective 592.745, maximum absolute gradient 0.000958, successful standard-error estimation and a positive-definite Hessian. The local SAM refit did not reproduce ICES SAG's aggregate recruitment and SSB, so none of its fitted states are treated as official assessment outputs.

The converged tinyAM fit has elevated parameter correlation and residual advisories: five fixed-parameter pairs have absolute correlation above 0.95, some standardized-residual groups fall outside the expected spread, some residuals exceed three standard deviations, and some adjacent-year residual correlations exceed 0.5. Across 1980–2025, age-1 recruitment differs by a mean absolute 66.2%, has a terminal difference of +68.1%, and trend correlation 0.608. Start-of-year SSB differs by a mean absolute 226.4%, has a terminal difference of +250.6%, and trend correlation 0.929. These are substantial scale disagreements; no model settings were changed to tune them.

A deterministic cohort-survival sensitivity, retaining the recruitment RW and
all other settings, failed package-default initialization and then converged
from the permitted local-SAM starting values (objective 629.905, gradient
0.001074 and positive-definite Hessian). It improved trend correlation to
0.866 for recruitment and 0.948 for SSB, but worsened median absolute percent
differences from 60.9% to 113.7% for recruitment and from 236.8% to 336.8%
for SSB. Terminal differences also increased. This alternative is rejected;
the existing N-RW translation remains the closer scale match, though neither
fit closely reproduces the published series.

## Validation

The importer and source test check the native year/age surfaces, missing survey cells, units, sample times, archive revision, SAG intervals, and catch-total consistency. The catch-to-SAG check uses catch numbers times catch weights in thousands of fish and kilograms per fish; the resulting annual tonnes agree with SAG within 1%. The source and translation tests pass, as does full database structural validation.

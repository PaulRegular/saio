# Faroe saithe 2025 (`pok.27.5b`)

Source review revision: 2026-10-23.

## Assessment represented

The canonical record represents the official 2025 ICES assessment of Faroe saithe in Division 5.b. The selected production run is `fsaithe-NWWG-2025`, a SAM fit covering 1961–2025 at ages 3–15+, with age 15 as the catch and population plus group. A later run visible on stockassessment.org was not selected because it is not the run supporting the 2025 advice and report.

The native fit used `stockassessment` 0.12.0 at RemoteSha `1cc464b80f6f`. It converged with optimizer code 0 (`relative convergence (4)`), objective -211.8084, a positive-definite Hessian, and maximum absolute fixed-effect gradient `2.46e-12`. Its 2025 recruitment, SSB, total biomass, and Fbar are 23,847.31 thousand fish, 57,508.5 tonnes, 118,011.9 tonnes, and 0.4804 per year. These agree with Table 6.5.3 of the 2025 NWWG report after its displayed rounding.

The native model, data object, configuration, R code, input files, ICES SAG XML and the NWWG chapter are cached locally in the gitignored `source_cache/ck_ices_nwwg_virens_fa5b_2025/` folder. Its `manifest.csv` records retrieval times, source URLs, byte sizes, and SHA-256 checksums.

## Inputs and assumptions

- **Catch:** The source model uses commercial catch-at-age in thousand fish for ages 3–15 from 1961–2025. Age 15 is the plus group. The source has 28 zero catches; they remain in the database and have no finite log observation in SAM. Catch observation variance is shared across ages. The 2025 catch precision weight is 0.5, compared with 1 in earlier years; `fixVarToWeight=0`, so this is a relative likelihood weight, not a fixed variance.
- **Survey indices:** The SAM inputs are age-specific survey catch rates for ages 3–10. The source table gives catch numbers-at-age and annual effort in hours. The database retains those numerators and effort values, as well as the per-effort values used by SAM (`numbers at age / effort`). SummerSurvey covers 1996–2025 and spring covers 1994–2025. The fitted sampling times are 0.65 and 0.225, respectively, the midpoints of the source windows 0.60–0.70 and 0.20–0.25. Indices remain on the source scale of fish per effort-hour.
- **Catchability and observation errors:** For both surveys, q is separate at ages 3–8 and shared at ages 9–10; there is no survey q above age 10. Each survey age has a separate observation variance. Survey residuals have AR(1) age correlation; catch residuals are independent.
- **N and F processes:** Recruitment is age 3 and follows a random walk. Age 3 has its own N-process variance; ages 4–15 share another. F states are separate at ages 3–10, with ages 11–15 sharing the oldest state. F innovations have AR(1) age correlation and one process variance across fitted ages. Fbar is the arithmetic mean of F at ages 4–8.
- **M and biological inputs:** M is fixed at 0.2 per year at ages 3–15. Annual maturity, stock weights, catch weights, landings weights, discard weights, landings fractions, and pre-spawning mortality fractions are retained. The source weight files have no 2025 stock or catch weight values; SAM estimates these surfaces internally. Original input rows are retained only where source values exist, while the model-estimated stock and catch weight surfaces are stored separately as fitted outputs.

## Outputs

The database stores native SAM N-at-age, F-at-age, q, fitted catch and survey predictions, age-3 recruitment, SSB, total biomass, and Fbar. It also stores the model-estimated stock and catch weight surfaces, including the 2025 estimates. N/F and fitted derived outputs include conditional uncertainty from the native SAM fit, with natural-scale delta-method SEs and 95% log-scale Wald intervals. Total abundance is derived by summing native N-at-age over ages 3–15+; its uncertainty is left blank because covariance for the sum is not recorded. M is fixed and is stored as an input rather than an estimated output.

SSB equals the sum of age-specific abundance times the fitted stock weight and maturity; total biomass uses abundance times fitted stock weight. Fbar is the arithmetic mean over ages 4–8, and recruitment equals age-3 N-at-age in the same calendar year. These definitions reproduce the native fitted surfaces over 1961–2025.

## Sources

- [ICES NWWG 2025 report, Faroe saithe chapter](https://doi.org/10.17895/ices.pub.29086181.v2), particularly Tables 6.2.2.2, 6.2.3.1, 6.2.4.1, 6.2.5.1 and 6.5.3
- [ICES 2025 advice record](https://asd.ices.dk/viewAdvice/4018)
- [ICES stock data for advice key 21241](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21241)
- [ICES Interbenchmark Protocol on Faroese Demersal Stocks (IBPFAR, 2022)](https://doi.org/10.17895/ices.pub.21565164)
- [Selected native SAM run](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/fsaithe-NWWG-2025/)

## Source details retained from the modelling review

During the 2026-10-23 source audit, catch and survey observations were found to have been flattened in age-major order against year-major labels. The importer now matches every observation to the native SAM year, age and fleet map before writing; regression checks include off-diagonal source cells and preserve the source zero catches. Survey numerators are corrected with their matching indices; effort, biological inputs and official outputs retain their source values. The importer can replace this assessment's existing rows without changing other assessments.

## Downstream modelling

The tinyAM settings and fitting results are maintained in [tinyAM translation notes](https://github.com/PaulRegular/tinyAM/blob/main/analysis/comp_assessments/translation_notes/ices_saithe_faroe_2025.md). They do not determine source completeness or official run selection.

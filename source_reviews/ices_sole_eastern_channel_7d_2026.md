# Eastern English Channel common sole (`sol.27.7d`), 2026

## Assessment and source coverage

The 2026 WGNSSK assessment is the latest detailed official assessment located for ICES Division 7.d. It is a SAM assessment fitted through 2025; 2026 recruitment and SSB are forecasts. The assessment report is the primary source for inputs, model settings, and age-specific outputs. The 2025 stock annex supplies survey timing windows. The ICES SAG StockXml supplies annual aggregate estimates at higher precision. The public, pinned [2026 TAF repository revision `468baf44`](https://github.com/ices-advice/2026_sol.27.7d/tree/468baf44b275c47923b0485cd67d86beb59a4b39/2026_sol.27.7d_assessment) confirms the model configuration and preprocessing, but does not include the bootstrap assessment inputs or fitted SAM object.

## Inputs and assumptions

The report gives combined catch numbers at age, catch weights, and quarter-1 stock weights for 1982–2025, ages 1–11+, with age 11 as the plus group. It reports an age-specific maturity ogive from ages 0–11+ and fixed natural mortality of 0.1 per year. Stock weights for 1982–2003 are identified as reconstructed. Input tables are rounded; original bootstrap files and exact unrounded values were not recovered.

The report also publishes three commercial LPUE series treated by SAM as fishable-stock-biomass indices: Belgium (2004–2025), France (2005–2025), and UK (1986–2025). They are preserved as inputs but excluded from the tinyAM fit because tinyAM does not support this aggregate biomass-index likelihood. Their index scale is not stated, so no rescaling is applied.

The age-specific tuning tables report UK BTS ages 1–6 (1989–2025 except 2022), UK YFS age 1 (1987–2006), and French YFS age 1 (1987–2023). BTS ages 1–3 from 2010 onward are grey and excluded from the official SAM fit. The French survey was sampled in 2024–2025, but those data were unavailable to the assessment. The source annex gives survey timing windows of 0.5–0.75 of the year; a tinyAM translation uses their midpoint, 0.625, as a single sampling-time approximation. The published tables do not state the survey-index units or scaling, so observations are retained without rescaling.

Table 17.13 reports the SAM age keys, variance sharing, independent F processes across ages, lognormal likelihoods, and a random-walk recruitment process. The full configuration is recorded in `assumptions.csv`; fitted log-q and observation-SD estimates are available in Table 17.15.

## Outputs and checks

Tables 17.17 and 17.18 provide N-at-age and F-at-age for 1982–2025. Table 17.19 reports SSB-at-age, and Table 17.16 reports annual recruitment, SSB, landings, discards, and Fbar ages 3–7 with intervals. SAG annual point estimates agree with the report to its published rounding. Total abundance and total biomass are derived from N-at-age and stock weights and have no uncertainty estimates.

Table 17.19 sums to Table 17.16 SSB within rounding for 1982–2020, but not for 2021–2025. The discrepancies are substantial and the age totals appear misaligned among the final five years; those table values are retained as published with a warning and are not used to validate aggregate SSB. Independently, N-at-age × stock weight × maturity reproduces reported total SSB within 0.02% using the rounded biological tables. Age-specific N, F, and SSB have no reported uncertainty. For these reasons the output record is marked partial.

## Translation boundary

The fitted tinyAM approximation can use catch-at-age, age-specific surveys, and source M, but cannot reproduce the SAM commercial aggregate FSB indices or all SAM variance-sharing and cross-age model details. Those are documented omissions, not reasons to alter source observations. No fitted SAM object, native bootstrap data, or age-specific uncertainty was found in the public sources reviewed.

The translation follows the age-specific observation-variance keys in Table 17.13 and the pinned TAF configuration: UK BTS age 1, age 2, and ages 3–6 share three variance parameters. Table 17.15 reports different BTS SD estimates for ages 3, 4, and 5–6 (0.0966, 0.0780, and 0.0730), which conflicts with those keys. The recipe does not use those SD estimates as starting values; the report and public TAF snapshot do not resolve the discrepancy. The index scale also remains unresolved, so source q estimates are not used as starts.

The tinyAM recipe fits the full 1982–2025 age 1–11+ grid, uses an IID N process, random-walk recruitment and F, fixed M=0.1, and the source q and observation-variance groupings where representable. BTS timing is set to 0.625, the midpoint of the reported 0.5–0.75 window. The three aggregate commercial FSB indices are retained in the database but excluded from the fit.

The package-default fit did not converge (optimizer code 1, false convergence, objective 1958.75, maximum gradient 31.61, and a non-positive-definite Hessian). An `sdreport` object was returned, but its fixed-effect standard errors were non-finite. One retry used source N-at-age and F-at-age as starting states while retaining package defaults for other parameters; its gradient evaluation was non-finite. An exploratory dashboard was rendered from the failed fit, but its estimates and comparison statistics are not suitable for inference. The comparison derives SSB-at-age from source N × weight × maturity because the published 2021–2025 age-specific SSB rows do not sum to reported annual SSB. Canonical outputs are unchanged.

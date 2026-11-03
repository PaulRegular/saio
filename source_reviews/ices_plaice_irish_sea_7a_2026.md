# Irish Sea plaice (`ple.27.7a`)

## Assessment and sources

The database record represents the 2026 ICES assessment applied for advice, fitted through 2025, with 2026 forecast SSB and recruitment. The official fitted SAM object is available from the assessment archive; its optimizer convergence code is 0. The model uses ages 1–8, with age 8 as the plus group.

- [WGCSE 2026 report](https://doi.org/10.17895/ices.pub.32625759), especially Tables 13.3–13.13
- [ICES SAG data, stock key 22655](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22655) · [machine-readable XML](https://sag.ices.dk/SAG_API/StockXmlDownload/22655)
- [WKIrish3 assessment-methods framework](https://doi.org/10.17895/ices.pub.8713)
- [SAM fitted-object archive](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/Ple.7a_26)
- [Pinned 2026 TAF repository revision](https://github.com/ices-advice/2026_ple.27.7a/tree/20246f16b79a4f4618faed4d8140aa4176a9819c)

The source files, retrieval dates, URLs, and checksums are listed in the ignored local manifest at `source_cache/ices_plaice_irish_sea_7a_2026/manifest.csv`. The fitted object is the authoritative source for the values actually used in the fit. The package version is not pinned in the public lock file, so the SAM fit is recorded by its archived object and run identifier rather than an asserted package version.

## Inputs and model assumptions

The fit has one commercial catch-at-age series for 1981–2025, ages 1–8+, with two unavailable year-age cells preserved as missing. The archived TAF data object is pre-adjustment; the fitted object contains the final data used by SAM. The TAF script applies 40% discard survival, so fitted dead catch includes landings plus 60% of discards. The canonical catch and landings-fraction rows retain the effective fitted values and document this transformation.

The UK BTS Q3 index is age-specific for ages 1–7 (224 observations). Its model sampling time is 0.8, and its absolute index multiplier is not stated. NIGFS-WIBTS Q1 and Q4 are aggregate SSB biomass indices in kg per 3 miles; their model sampling time is 0. The report provides their input series, but no age composition with which to translate them into tinyAM's age-specific index likelihood, so they remain in the database and are omitted from the fit.

The fit uses fixed age-specific M, fixed maturity, and zero pre-spawning F and M fractions. Effective stock weights equal catch weights after the TAF discard-survival adjustment. The SAM configuration has a random-walk N process with separate age-1 variance and a shared variance for ages 2–8. F follows a temporal random walk with AR(1) correlation across age states; ages 7 and 8 share the same F state. Fbar is the arithmetic mean for ages 3–6. Catch and survey observations use lognormal errors; the UK BTS variance is shared across ages, while each aggregate SSB survey has its own variance.

## Outputs and limitations

Official fitted N-at-age and F-at-age are stored for 1981–2025. Total abundance is derived by summing the complete 1–8+ N rows and has no uncertainty. SSB, recruitment, Fbar, total stock biomass, and dead catch are recovered from the native fit summary; their standard errors are delta-method approximations from the log-scale standard deviations, and the stored limits use exp(log estimate ± 2 log-scale standard errors), following the TAF report-table convention. SAG provides the 2026 forecast SSB and recruitment with its published intervals. M is fixed, so it is stored as an input rather than presented as an estimated output.

The two aggregate NIGFS SSB indices cannot be used by the current tinyAM age-specific index likelihood without an age allocation, so no such allocation is invented. The native fit now supplies nine q estimates: seven age-specific UK BTS values and one aggregate SSB-index q for each NIGFS quarter. The q estimates are exponentiated `logFpar` parameters; their standard errors are delta-method values and their intervals are 95% Wald intervals on the log scale. UK BTS's physical index scale is not stated, so its q unit remains a native index scale per thousand fish. The aggregate q units are the native survey-index units per tonne SSB.

The fit also supplies 659 fitted catch and survey predictions aligned to `fit$data$aux`. This includes seven UK BTS rows and one Q4 row with missing observations; their predictions are model outputs, not additional observations. Catch predictions are in thousand fish, UK BTS predictions remain on its unspecified native scale, and NIGFS predictions are in kg per 3 miles. The aggregate NIGFS indices remain in the database but are omitted from tinyAM because no source-supported age allocation exists. The source record is complete for the fitted data, fixed biological inputs, and recoverable population, mortality, q, and observation-prediction outputs; the translation audit separately identifies the omitted aggregate-index likelihood and other model simplifications.

## tinyAM translation

The translation retains 1981–2025 and ages 1–8+, fits the UK BTS series, and uses the official fixed M, weights, and maturity. It uses tinyAM random walks for N and recruitment, correlated-RW F, a shared UK BTS observation SD, and q by age. This approximates SAM's process covariance, boundary integration, and observation model; the exact SAM likelihood and age-state sharing are not reproduced. The aggregate NIGFS indices are omitted because they lack age composition. SSB, recruitment, abundance, and N/F-at-age can be compared on the common model grid. Fixed M is shown as an input, not treated as evidence of fitted agreement. Native arithmetic Fbar is not like-for-like with tinyAM's abundance-weighted Fbar.

The default-start fit converged (optimizer code 0, objective 302.221, maximum absolute gradient 0.000117, successful standard-error estimation, and a positive-definite Hessian). No starting values were supplied. The fit emitted a support warning because F-increment age correlation was near a boundary. Trend correlations were high for N-at-age (0.966), F-at-age (0.992), SSB (0.965), recruitment (0.974), and total abundance (0.958), but scale differences were large: mean absolute percent differences were 91.6%, 38.3%, 71.5%, 84.1%, and 59.1%, respectively. Fixed M is identical by construction and is not counted as evidence of agreement. These results indicate good trajectory shape but substantial scale disagreement under this simplified translation; no settings were tuned to the official estimates.

## Discovery inventory screening

The ICES 2026 inventory entry ple.27.7a matches the existing canonical Irish Sea plaice stock and is screened eligible. The assessment satisfies the age-structured source-readiness screen: it has fitted catch numbers-at-age, an age-specific UK BTS Q3 index, run-matched weight and fixed biological/mortality inputs, explicit survey timing, and fitted population/mortality outputs. The aggregate NIGFS Q1/Q4 indices are documented separately and do not need invented age allocations because the official fit also has an age-specific survey index. The candidate-register review date is 2026-10-29; the source review does not alter the canonical assessment data.

The 2021 stock annex is cached at source_cache/ices_plaice_irish_sea_7a_2026/ple_27_7a_stock_annex_2021.pdf; the local manifest records its Figshare URL, DOI revision, retrieval date and SHA-256.

# Irish Sea whiting: 2025 WKBNSCS benchmark

## Assessment represented

The detailed event is the 2025 ICES Working Group on the Celtic Seas Ecoregion (WGCSE/WKBNSCS) benchmark for whiting in Division 7.a, fitted through 2023. It uses a SAM age-structured state-space model for ages 0–6+, with age 6 treated as a plus group in the catch and the two NIGFS indices. The stock identity is the existing Charbonneau–Keith Master entry `ICES-WGCSE_merlangus_CS7a`; the current ICES stock code is `whg.27.7a`.

The official fitted model and data object were recovered from the public stockassessment.org run. The source run identifies `stockassessment` 0.12.0, RemoteSha `7e947decf551`. The fit has optimizer convergence code 0, a positive-definite Hessian and maximum absolute fixed-effect gradient of approximately `5.7e-13`.

## Sources and cached files

- [2025 WKBNSCS report](https://doi.org/10.17895/ices.pub.28715180), whiting 7.a assessment section and model description.
- [2022 SAM methods report](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091589.pdf), observation and state-process background.
- [Native SAM fitted model](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/whg.27.7a_WKBNSCS_final/run/model.RData), [data object](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/whg.27.7a_WKBNSCS_final/run/data.RData), configuration, version file and Makefile.
- [ICES SAG whg.27.7a summary series](https://sg.ices.dk/ViewSourceData.aspx?key=20997), kept as a separate summary-only event because its 2023 SSB differs from the detailed benchmark.

The source files are cached locally under `source_cache/ck_ices_wgcse_merlangus_cs7a/`. `manifest.csv` records each URL, retrieval date, SHA-256 checksum and represented assessment. The cache is gitignored.

## Inputs and assumptions

The fitted SAM data object contains 754 model observation slots: 308 total commercial catch-at-age records, 192 NIGFS-Q1 records, 224 NIGFS-Q4 records and 30 NIMIK age-0 slots. Two NIMIK observations are missing (2020 and 2022), leaving 752 fitted observations. Missing values were not filled. Catch is recorded in thousands of fish. Survey observations are preserved on their native SAM index scale because no independent scale multiplier is provided in the fitted object.

Survey timing is 0.23 for NIGFS-Q1, 0.855 for NIGFS-Q4 and 0.48 for NIMIK. The two NIGFS series carry 416 finite relative precision weights; SAM divides their log-observation variances by those weights. Catch and NIMIK observations have no supplied weight. NIGFS-Q1 and Q4 have AR residual correlation across ages in SAM; catch and NIMIK residuals are independent.

SAM estimates age-specific F states with AR(1) correlation across ages. Fbar is the arithmetic mean over ages 1–3. Recruitment is at age 0, with a separate age-0 process variance; ages 1–6 share another N-process variance key. Natural mortality is fixed at 2.20, 0.98, 0.75, 0.67, 0.63, 0.62 and 0.61 per year for ages 0–6. Annual stock, catch, landings and discard weights, maturity, landings fractions and spawning-time mortality fractions are retained as supplied.

The native landings-fraction surface has seven age-6 values slightly above one, with a maximum of 1.0237. These values are preserved without clipping and are explicitly documented in the input rows. SAM's pre-spawning F and M fractions are zero in every year and age.

## Outputs and checks

The database records native SAM N-at-age and F-at-age estimates with conditional random-effect uncertainty, the fitted q surface with log-scale uncertainty converted to natural-scale SEs and limits, fitted catch and index predictions, and annual recruitment, SSB, total biomass and Fbar with their reported 95% intervals. Fixed M is retained as an input rather than represented as estimated output.

The native summary definitions were checked against the reported population surfaces for every modeled year. With N in thousands of fish and weights in kg per fish, `sum(N * stock weight * maturity)` exactly reproduces SAM SSB in tonnes; `sum(N * stock weight)` exactly reproduces total biomass; and mean F over ages 1–3 exactly reproduces SAM Fbar. No extra factor of 1,000 is applied.

The separate SAG summary event spans 1980–2025. Its 2023 SSB is 1,534 tonnes, compared with 1,590.003 tonnes in the detailed benchmark. The SAG page does not provide age-specific inputs or outputs and does not identify the age range for its aggregate F series. Its F value for 2025 is blank and is omitted rather than imputed. This summary remains separate from the detailed benchmark.

# ICES Bay of Biscay sole, 2026 assessment

**Stock:** `ices_sol_27_8ab` (`sol.27.8ab`)
**Assessment:** `ices_sol_27_8ab_2026`
**Review date:** 2026-11-15
**Official source:** [WGBIE 2026, section 7](https://doi.org/10.17895/ices.pub.32790321.v1)
**Applied model:** SAM, ages 2-8+, terminal assessment year 2025.

This is the current ICES sole unit for divisions 8.a-b in the Bay of Biscay. It is distinct from Irish Sea and North Sea sole records. The pinned [ICES 2026 assessment repository](https://github.com/ices-advice/2026_sol.27.8ab/tree/e6b6c484f6c50e1199097682ca6b451f8232e235/2026_sol.27.8ab_assessment) identifies the applied SAM workflow. Its public archive does not contain the run-matched numeric input objects or fitted object.

## Data imported

The canonical database contains 1,019 input rows, 714 output rows, and 13 source-backed assumptions for this run.

- **Inputs:** Table 7.4 catch numbers-at-age for ages 2-8+ in 1984-2025; catch and stock weights-at-age in kg for ages 2-8+ in 1984-2025 (Tables 7.5-7.6); the fixed maturity ogive for ages 2-8+ (Table 7.2); the French BTS VIII age-specific standardized index at ages 2-7 for 2007-2025 (Table 7.7); and the French trawler fishable-stock-biomass index for 2010-2025 (Table 7.8).
- **Outputs:** age-0 recruitment, SSB, and Fbar for ages 3-7 (Table 7.11); estimated F-at-age (Table 7.14); and start-of-year N-at-age (Table 7.15), all through 2025. Table 7.11 reports 90% confidence intervals. Age-specific uncertainty is not tabulated.
- **M:** no M-at-age input was imported because Table 7.3 and section 7.4.2 report different vectors and the available sources do not establish which entered the production run.

All table values are preserved on their printed scale. The Table 7.4 multiplier is not stated, and Tables 7.7-7.8 do not state physical index units. No scale conversion is applied. Age 8 is the model's plus group. The pinned `data.R` gives survey timing as intervals (BTS VIII 11/12 to 1; trawler 0.1 to 2/12 of a year); the database leaves `sampling_time` blank rather than replacing an interval with a point.

## Unresolved source gaps

- **Catch scale:** Table 7.4 does not state a numeric multiplier. A plausibility check using rounded catch numbers and weights does not prove the production input scale.
- **Natural mortality:** Table 7.3 gives ages 2-8+ as 0.13, 0.12, 0.11, 0.10, 0.10, 0.10, 0.09. Section 7.4.2 instead gives 0.13, 0.12, 0.11, 0.11, 0.10, 0.09, 0.09. The 2024 benchmark corroborates the settings vector but does not identify the 2026 run input.
- **Assessment terminal year:** Tables and reported estimates end in 2025, while section 7.4.2 says the final data year is 2026. The missing run-matched input object prevents resolution; the imported tables use their documented 1984-2025 coverage.
- **Run-matched object:** the public repository references local stock and survey data objects, but does not include them. No earlier-run values were substituted.

The import is partial and eligibility remains unresolved until catch scale and the production M vector can be verified. Survey intervals and standardized scales also prevent a complete tinyAM-ready observation specification.

## Provenance

The official report, 2024 flatfish benchmark, 2021 stock annex, 2025 report, repository archive, and 2026 advice are cached under `source_cache/ices_sol_27_8ab/ices_sol_27_8ab_2026/`. Their URLs, retrieval dates, revisions, file sizes, and checksums are recorded in [`data-raw/provenance/ices_sol_27_8ab_2026/sources.csv`](../provenance/ices_sol_27_8ab_2026/sources.csv). The official report was retrieved on 2026-10-28; its SHA-256 is `1fc0302e0dfeb9438a9537dfff614ef1dc2dce1c36d8cedc1f4e0925e3b1eaa9`.

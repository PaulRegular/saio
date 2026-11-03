# Bay of Biscay anchovy (ICES `ane.27.8`)

Review date: 2026-10-30

## Stock unit and assessment

The ICES inventory and 2026 advice identify `ane.27.8` as Bay of Biscay anchovy (*Engraulis encrasicolus*) in Subarea 8. The most recent detailed production assessment located is the 2025 Stock Synthesis assessment used for 2026 advice (Standard Graphs key 21265; advice record 4005). The report identifies Stock Synthesis 3.30.22.beta. The 2025 stock annex and 2024 benchmark report document the model and input methods.

## Screening decision

This unit is **eligible for source curation** in the age-disaggregated assessment set. The official 2025 report and annex document the inputs and outputs needed for an age-structured record. No canonical numerical records are added by this screening step.

| Component | Evidence in the official assessment | Coverage and units |
|---|---|---|
| Commercial catch | Total catch biomass and catch-at-age by semester; age 0 catch excluded from the model | 1987-2025; tonnes and thousands of fish; ages 1, 2, 3+. The second-semester age composition for the assessment year is unavailable; 2025 data are provisional and documented assumptions fill some incomplete catch information. |
| PELGAS spring acoustic survey | Aggregate SSB and numbers-at-age | SSB 1989-2025 (missing 1990, 1993-1996, 1999, 2020); age-specific numbers-at-age 1, 2, 3+ in 2000-2025 (missing 2020), thousands of fish. |
| BIOMAN spring DEPM survey | Aggregate SSB and numbers-at-age | SSB 1987-2025 (missing 1993); numbers-at-age 1, 2, 3+ in 1987-2025 (missing 1993, 1996, 1999, 2000), thousands of fish. |
| JUVENA autumn acoustic survey | Age-0 abundance index | 2003-2025, thousands of fish. The survey is conducted in September-October. |
| Catch weights | Mean weight-at-age by semester | Ages 0-5, 1987-2024, grams; source tables include missing age-year values. |
| Stock weights | Weight-at-age at spawning from BIOMAN; linear interpolation for missing years | Kilograms; retain separately from fishery catch weights. |
| Maturity | 0 at age 0; 1 at ages 1, 2, and 3+ | Official age-specific schedule. |
| Natural mortality | Fixed M0=2.17, M1=0.80, M2=1.20, M3+=2.26 per year | Constant between seasons; M is assumed, not estimated. |
| Model timing | Two seasons, January-June and July-December; spawning 15 May; age-0 settlement 1 July | BIOMAN and PELGAS are spring indices represented at spawning time; JUVENA is an autumn index. N-at-age at beginning of year. F-at-age by semester | Summary outputs through 2025, with 2025 catches assumed. N-at-age (ages 0, 1, 2, 3+, thousands of fish) and F-at-age by semester through 2024. M-at-age is fixed input, not an estimated output. |

The reports provide direct age-specific survey series and detailed catch-age information. Extracting the values from the report tables and figures, reconciling the survey index scales, and preserving the 2025 provisional-data caveat are source-curation tasks. They do not require inventing age observations or treating the current assessment as aggregate-only.

## Sources

- [WGHANSA 2025 report, finalized March 2026](https://doi.org/10.17895/ices.pub.29335520.v3)
- [2025 ICES stock annex for Bay of Biscay anchovy](https://doi.org/10.17895/ices.pub.28053440.v2)
- [WKBANSP 2024 benchmark report](https://doi.org/10.17895/ices.pub.27909783.v2)
- [WGACEGG 2025 report](https://doi.org/10.17895/ices.pub.31353469.v3)
- [ICES 2025 Standard Graphs, key 21265](https://standardgraphs.ices.dk/ViewCharts.aspx?key=21265)
- [ICES 2025 source data, key 21265](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=21265)
- [ICES 2026 advice record 4005](https://asd.ices.dk/viewAdvice/4005)

The source files are cached locally under the gitignored `source_cache/discovery_ices_bay_biscay_anchovy_2025/`. Its `sources.csv` records URLs, retrieval date, source revision, file size, and SHA-256 checksums. Screening does not create canonical stock, assessment, input, or output records.

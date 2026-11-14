# NOAA Southeastern U.S. Mutton Snapper — SEDAR 79 (2024)

## Assessment and stock unit

SEDAR 79 is the latest detailed production assessment located for NOAA Stock SMART unit 11342, with observations through 2023. It is one combined Southeastern U.S. assessment unit spanning the Gulf of Mexico and South Atlantic council areas; the Caribbean is a separate population boundary. The joint Gulf and South Atlantic SSC review in March 2025 found the assessment consistent with best scientific information.

The final Stock Synthesis base model uses ages 1–40, combined sexes, one area, and one annual season. The assessment report and supporting documents were retrieved on 2026-10-31. Their URLs, byte counts, and SHA-256 values are retained in `provenance/discovery_noaa_mutton_snapper_sedar79_2024/sources.csv`; local copies remain in the ignored `source_cache/discovery_noaa_mutton_snapper_sedar79_2024/` directory.

## Inputs and assumptions recovered

- **Commercial catch information:** Table 2 reports Commercial Longline and Commercial Other landings biomass for 1981–2023 in metric tons whole weight, with log-scale standard errors. Commercial Other releases are reported for 1993–2023 in thousands of fish, with absolute standard errors.
- **Recreational catch information:** Table 8 reports East and West landings and releases for 1981–2023 in thousands of fish. The reported log-scale standard errors are stored separately from each catch series.
- **Abundance indices:** Table 9 provides seven mean-scaled series and their CVs and sample sizes: Commercial Longline CPUE, GOM Combined Stereo Video, RVC Dry Tortugas, RVC Florida Keys, RVC Southeast Florida, Indian River YOY, and SERFS Video. Six are aggregate abundance indices. Indian River YOY is an age-0 recruitment index. These are not age-specific abundance surfaces.
- **Biology and mortality:** Table 10 gives the fixed whole-weight relationship (6.63e-06 × MaxTL^3.1601; kg and cm), growth settings, maturity parameters (A50 3.48 years, alpha -2.535, beta -13.021), female fraction 0.5, and reference M 0.129 year^-1. The report describes M as 5.4/tmax and scales it by age through growth.
- **Timing:** Spawning peaks in June and settlement is assigned to January. Table 9 does not establish one common sampling-time fraction for all indices, so index `sampling_time` is left blank.

## Outputs recovered

- Table 11 reports model-output maximum total length, age-specific M, and maturity for ages 1–40. These are stored as static age surfaces without an artificial year dimension.
- Weight-at-age is stored as a **derived source output**, calculated from Table 11 maximum total length and the fixed Table 10 whole-weight relationship. It is not separately tabulated in the report.
- Table 15 reports four fleet-specific annual apical-F series and combined F at age 3 for 1981–2023.
- Table 16 reports annual total biomass, SSB, total abundance, age-1 recruitment, and SSB/SSB0 for 1981–2023.
- The source tables report rounded point estimates but no annual or age-specific uncertainty. No confidence limits or standard errors are added to those outputs.

## Gaps and completeness

The assessment fits catch-weighted length compositions and conditional age-at-length by fleet and year. The reviewed public files do not include the complete numeric model-ready composition arrays or a run-matched Stock Synthesis data/control archive. No marginal catch-at-age series is reported. These composition observations were not digitized or reconstructed.

The annual indices are aggregate, apart from the age-0 YOY recruitment series. Numeric annual N-at-age and F-at-age surfaces were not found. Table 15 provides only fleet apical F and total F at age 3. Index-specific timing fractions remain unavailable.

The canonical record is therefore marked **partial** for assumptions, inputs, and outputs. It retains the verified annual catch observations, aggregate indices, model biology surfaces, and tabulated annual population/mortality outputs. It is not a complete reproduction of the assessment inputs and does not yet support a defensible tinyAM translation with the available age-composition information.

## Source references

- [SEDAR 79 project page](https://sedarweb.org/assessments/sedar-79/)
- [SEDAR 79 final assessment report](https://sedarweb.org/documents/sedar-79-southeastern-us-mutton-snapper-final-stock-assessment-report/)
- [SEDAR 79-DW-03 size and age information](https://sedarweb.org/documents/sedar-79-dw-03-size-and-age-information-for-mutton-snapper-lutjanus-analis-collected-in-association-with-fishery-dependent-monitoring-along-floridas-coast/)
- [SEDAR 79-DW-12 reproduction report](https://sedarweb.org/documents/sedar-79-dw-12-mutton-snapper-reproduction/)
- [SEDAR 79-DW-22 age, growth, and natural mortality report](https://sedarweb.org/documents/sedar-79-dw-22-descriptions-of-age-growth-and-natural-mortality-of-mutton-snapper-lutjanus-analis-collected-from-fisheries-independent-and-dependent-sources-in-the-southeastern-united-states-fro/)
- [Joint Gulf and South Atlantic SSC review](https://sedarweb.org/documents/gulf-and-sa-ssc-review-of-sedar-79-southeastern-u-s-mutton-snapper/)

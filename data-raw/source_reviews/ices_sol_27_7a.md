# Sole in ICES Division 7.a (Irish Sea), 2026

## Assessment `ices_sol_27_7a_2026`

The SAIO record `ices_sol_27_7a` covers common sole (*Solea solea*) in the Irish Sea, ICES Division 7.a (`sol.27.7a`). The 2026 WGCSE SAM assessment used for advice includes data through 2025.

## Inputs and assumptions

WGCSE 2026 Tables 19.2–19.5 provide catch numbers-at-age, catch weights-at-age, and stock weights-at-age for ages 1–10+ in 1970–2025. Catch numbers and recruitment are reported in thousands of fish; weights are kg per fish. Age 10 is the plus group. The production model excludes age-1 catch before 2003.

Table 19.9 provides the UK(E&W)-BTS-Q3 age index for ages 1–7 from 1988–2025, with 2020 missing, and a Belgian commercial beam-trawl biomass index from 2004–2025, with 2017–2018 missing. The index multipliers and the Belgian likelihood weights are not reported. The UK survey sampling interval is 0.75–0.85 of the year; the SAM data setup uses its midpoint, 0.8. Belgian sampling time is 0 in the assessment setup. The Belgian series is treated as a spawning-stock biomass index.

Natural mortality is fixed at ages 1–10+ and is reported in the 2026 report as values carried forward from the 2024 benchmark. The applied model uses a revised time-varying maturity ogive, but its numerical input file is absent from the public assessment repository and its values are not recoverable from the report. Do not substitute the earlier maturity ogive.

The assessment uses SAM/TMB, a random walk for log recruitment, and AR(1) correlation for fishing mortality. Catch observations use AR correlation; the UK and Belgian survey series are independent. F states at ages 9 and 10+ are shared. UK survey q at ages 6 and 7 is shared; Belgian q is separate.

## Outputs

Tables 19.13–19.15 report fishing mortality-at-age, start-of-year numbers-at-age, and spawning-stock biomass-at-age for 1970–2025. Table 19.16 reports recruitment, total stock biomass, spawning-stock biomass, fitted catch, and Fbar ages 3–7 for 1970–2025 with Low and High bounds. These bounds agree with the ICES Standard Graphs 2.5th and 97.5th percentiles.

The PDF wraps several digits in Table 19.14. Age-1 numbers were taken from Table 19.16 recruitment after checking the unwrapped age-1 values. Four additional wrapped cells were visually checked against the table image: age 2 in 2016, 2019 and 2021, and age 3 in 2021. These small source-table repairs are noted on the imported output rows.

Table 19.16 and ICES Standard Graphs agree on the 2024 and 2025 estimates and bounds. For 2025, recruitment is 20,093 thousand fish, total stock biomass is 5,107 tonnes, SSB is 3,845 tonnes, and Fbar is 0.197 per year. The report and graph series resolve the biomass labels in the earlier screening note.

## Screening and import status

The assessment is imported as partial and age-data eligibility remains unresolved. Catch, weight, M, survey-index, and fitted-output values are available, but numerical revised maturity and Belgian observation weights are not. The public repository contains the assessment scripts but not the numerical data files or a native fitted object.

The public repository reads the revised maturity ogive from `mo.txt`, but the cached source archive contains scripts without the numerical `boot/initial/data/` files. A 2026-11-14 recheck of the pinned repository and the public [Stockassessment.org user3 directory](https://stockassessment.org/datadisk/stockassessment/userdirs/user3/) did not recover those files or a run-matched fitted object. The Standard Graphs series verifies the aggregate outputs. The revised maturity remains unresolved.

## Sources and cache

- [2026 WGCSE report, section 19](https://doi.org/10.17895/ices.pub.32625759)
- [2026 advice](https://doi.org/10.17895/ices.advice.30932405)
- [2024 benchmark report](https://doi.org/10.17895/ices.pub.25471987.v1)
- [ICES Standard Graphs, advice key 22641](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22641)
- [Pinned assessment repository](https://github.com/ices-advice/2026_sol.27.7a/tree/bff4518e75378685700c849a24c5ba9c86e5a575/2026_sol.27.7a_assessment)

Cached source files, retrieval dates, revisions, byte sizes, and SHA-256 checksums are listed in `data-raw/provenance/ices_sol_27_7a_2026/sources.csv`; local files are under the ignored `source_cache/ices_sol_27_7a/ices_sol_27_7a_2026/` directory.

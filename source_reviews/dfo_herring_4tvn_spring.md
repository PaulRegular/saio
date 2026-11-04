# Southern Gulf spring-spawning herring

## Assessment record

The canonical database represents the official 2024 assessment to 2023, the most recent assessment with detailed numerical tables recovered for this stock.

DFO Research Document 2024/058 is primarily a data and supporting document. It does not provide a complete specification of the fitted statistical catch-at-age (SCA) model.

The official 2026 assessment to 2025 is recorded separately. DFO Science Advisory Report 2026/028 publishes selected 2024–2025 estimates for April 1 SSB, age-2 recruitment, and grouped M for ages 8–11+; these values are recorded under the separate 2026 event. The detailed input tables, full methods, age-specific population/F/M series, and complete uncertainty outputs remain unavailable while the Research Document is in preparation. No 2026-run data or estimates are mixed into the 2024 record.

DFO Research Document 2022/068 provides the most recent detailed SCA methods description used in this review. Its equations and parameter settings are retained as methodological context, but are not assumed to be independently verified for every component of the 2024 assessment.

Source material is cached under `source_cache/dfo_sgsl_herring_spring_2023/`, including the 2024 supporting document, 2022 methods report, 2026 Science Advisory Report, acoustic biomass CSV and dictionary, historical acoustic unit documentation, and file manifest.

## Inputs and assumptions recovered

### Catch and population structure

The 2024 document provides fixed- and mobile-gear spring catch-at-age and weight-at-age, spring fixed-gear CPUE by age, acoustic age-index values, and January 1 abundance, biomass-at-age and fishing-mortality-at-age estimates.

The assessment covers 1978–2023 and ages 2–11+, with age 11 as the plus group.

The 2023 mobile-gear spring catch-at-age is reconstructed as zero because the annual landings table reports no mobile-gear spring catch that year. This is identified as a reconstruction rather than an independently reported catch-at-age series.

### Survey observations and acoustic units

The two survey series are:

- Spring fixed-gear CPUE, available for 1990–2021.
- The spring-spawner 4Tmno acoustic survey, with age-index observations for ages 2–10 in 1994–2023.

The 2024 supporting report describes acoustic trawl samples weighted by acoustic density to allocate the survey signal by spawning component and age. Its Table 15 is an abundance-at-age index, not raw trawl sample counts.

Table 15 does not identify a numerical scale multiplier. DFO Research Document 2016/060, Table 16, explicitly labels the corresponding historical acoustic series in thousands of fish.

For example, the 1994 age-4 observation is 100,087 in the earlier table and 100,062 in the 2024 report; the 2006 age-4 observation is 24,601 in both. These differences are consistent with historical revisions rather than a change in units.

The canonical database therefore retains the published 2024 acoustic index values in thousand fish.

A separate biomass-scale check supports this interpretation. The 2023 acoustic age-index values sum to 55,619 thousand fish, while a later official spring biomass estimate of 7,358 t implies an average weight of approximately 0.132 kg per fish. Treating the table as individual fish would imply approximately 132 kg per fish.

The later biomass estimate provides a scale cross-check only; it is not a verified 2024-run biomass input.

### Acoustic biomass provenance

The Open Government acoustic biomass CSV and its dictionary report spring biomass in tonnes over 1994–2025.

The later CSV values remain separate from the 2024 assessment record. Its 2024–2025 observations are not inputs to the 2024 run.

The latest CSV is not confirmed to reproduce every historical biomass input used by the official 2024 SCA model.

Examples include:

- 2022: 27,209 t in the latest CSV versus 27,268.7 t in the 2024 supporting report.
- 2023: 19,363 t in the latest CSV versus 19,363.8 t in the report, consistent after rounding.
- 2021: 23,147.68 t in the latest CSV versus 37,953.1 t in the 2022 methods report.

The reasons for these revisions and the exact historical aggregate-biomass likelihood inputs remain unresolved.

## Documented SCA model structure

DFO Research Document 2022/068 describes the SCA model used as methodological context for the 2024 assessment.

### Recruitment and abundance

Recruitment enters at age 2 and varies annually.

Older cohorts are propagated through survival, with initial-cohort deviations handled separately from the ordinary annual recruitment process.

### Fishing mortality

Fishing mortality is represented using annual fishing intensity and logistic fishery selectivity.

The documented selectivity periods are:

- 1978–1989.
- 1990–2004.
- 2005 onward.

A schematic representation is:

`F[a,t] = F[t] * S[a,period(t)]`

where the logistic selectivity curve varies among periods.

This imposes a structured age pattern on fishing mortality rather than independently estimating a full time series of F for every age.

The 2024 supporting report does not fully restate these equations or confirm every historical parameter grouping.

### Natural mortality

Natural mortality varies between years in two age groups:

- Ages 2–6.
- Ages 7–11+.

The documented model uses random walks on log M, with fixed annual increment SD of 0.075 and initial-M prior means of 0.2.

The initial-state prior is material: the random walks alone do not anchor the initial mortality level.

The numerical fitted M-at-age surface was not recovered from the 2024 assessment tables.

### CPUE catchability

The 2022 methods describe a single annual fully recruited CPUE catchability coefficient, varying through a random walk on the log scale.

The documented process is:

`log(q[t]) = log(q[t-1]) + epsilon[t]`

with annual increments distributed as:

`epsilon[t] ~ N(0, 0.1^2)`

The 1990 catchability establishes the initial level.

The documented CPUE observation structure also uses age-dependent selectivity, rather than unrelated age-specific annual catchability trajectories.

The temporal catchability process and the age-selectivity pattern are distinct model components.

The fixed increment SD of 0.1 is the last documented value. Its continued use in the official 2024 run has not been independently confirmed.

### Observation likelihoods

The documented SCA uses age compositions and aggregate biomass indices for spring CPUE and the acoustic survey.

The 2022 methods describe a multivariate-logistic age-composition likelihood. Small age proportions are grouped with adjacent ages until they exceed 0.01.

The acoustic biomass likelihood is lognormal, uses ages 4–8, and carries likelihood weight 3. The documented CPUE biomass component uses ages 4–10 and weight 1.

The 2024 supporting document does not confirm that these age groupings and weights remained unchanged in every respect.

## Biological inputs and derived source outputs

### Weights and maturity

Maturity is knife-edge between ages 3 and 4: ages 2–3 are immature, and ages 4–11+ are mature.

The documented beginning-year stock-weight construction combines fixed- and mobile-gear weights, then uses a geometric mean across adjacent age-year cells.

The complete fitted stock-weight surface and precise gear-combination rule were not published.

### Derived population outputs

The canonical database includes derived total January 1 abundance and biomass, obtained by summing the reported ages 2–11+.

It also includes January 1 mature biomass, calculated from the reported biomass-at-age and knife-edge maturity schedule.

They are identified as derived source outputs, without additional uncertainty estimates.

The source's published biomass-at-age represents January 1 biomass.

January 1 mature biomass is distinct from the official assessment's April 1 SSB. Reconstructing April 1 SSB would require pre-spawning survival from the unavailable fitted M surface.

## Sources

- [DFO Research Document 2024/058](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41256384.pdf)
- [DFO Research Document 2022/068](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41091589.pdf)
- [DFO Research Document 2016/060, Table 16: acoustic units](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/365860.pdf)
- [DFO Science Advisory Report 2026/028](https://publications.gc.ca/collections/collection_2026/mpo-dfo/fs70-6/Fs70-6-2026-028-eng.pdf)

The relevant source documents, cached numerical files and manifest are retained under `source_cache/dfo_sgsl_herring_spring_2023/`.

The stock does not yet have a verified Charbonneau identifier in the local crosswalk, so no identifier is assigned.

## Source context

Official age-specific M estimates and their uncertainty remain unavailable. Exact observation-model settings for the 2024 assessment are not fully recoverable from the supporting document.

## Source context

The canonical record represents the official 2024 Southern Gulf spring-spawning herring assessment, with detailed inputs and outputs through 2023. Source completeness remains partial.

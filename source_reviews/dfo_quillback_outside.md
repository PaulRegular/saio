# DFO Outside Quillback Rockfish

## Assessment unit and run

This is the distinct British Columbia Outside management unit, comprising coastal waters outside Groundfish Management Area 4B. The latest detailed assessment located is the 2021 management-procedure analysis, published as DFO Research Document 2024/028 in January 2025, with its peer-reviewed Science Advisory Report published as 2023/041. The conditioning model is Stock Synthesis 3 version 3-30-19-01; it is not a conventional annual production assessment.

The model spans 1918–2021 and has a maximum age of 70 with a plus group. It separates North (5BCDE) and South (5A3CD) areas, with coastwide recruitment and no movement after settlement.

## Inputs and outputs found

The operating models are conditioned on historical catches, aggregate abundance indices, fishery and survey age compositions, and commercial mean weight. Index series include the outside hard-bottom longline survey, the International Pacific Halibut Commission longline survey, and the Hecate Strait synoptic trawl survey. The reported age compositions are proportions from samples, not absolute age-specific abundance indices. A complete numeric annual catch-at-age matrix and run-matched age-composition input files were not recovered in the reviewed cache.

Natural mortality is fixed within scenarios, with reference values of 0.046 and 0.056 per year. The report describes age-based biology and female maturity, but complete machine-readable run-matched weight-at-age and maturity-at-age surfaces were not recovered. The survey series are identified, but model-scale fractional timing was not verified.

The report provides annual spawning-biomass and fishing-mortality/reference-point trajectories and posterior summaries for the terminal year. Numeric, run-matched annual N-at-age and F-at-age arrays were not located. The research document describes SS3 input files (`data.ss` and `control.ss`), but a version-pinned public archive containing those files was not verified during this screen.

## Screening decision

The unit is a verified provisional new DFO stock unit, but eligibility for the age-input set remains unresolved. The operating model uses age compositions and an age-structured population, but the reviewed public sources do not establish complete numeric catch-age inputs, recoverable model data files, fractional survey timing, or run-matched annual age-specific outputs. No canonical database values were added.

## Sources and cache

- Huynh, Q.C., Siegle, M.R., and Haggarty, D.R. 2025. [Research Document 2024/028](https://open-science.canada.ca/server/api/core/bitstreams/d02461e4-0a5d-4004-b684-b37be53a86cb/content). Cached locally with the ignored source cache.
- DFO. 2023. [Science Advisory Report 2023/041](https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41209862.pdf). Cached locally with the ignored source cache.

The local `sources.csv` manifest records retrieval dates and SHA-256 checksums. The candidate register records both report URLs and the unresolved input/output details.

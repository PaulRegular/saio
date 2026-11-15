# NOAA Gulf smoothhound complex

## Identity and current assessment

NOAA Stock SMART lists stock 14230, the Gulf Smoothhound Complex, with the
2015 SEDAR 39 assessment as fully accepted and data through 2012. The detailed
SEDAR report identifies a Gulf of Mexico *Mustelus* spp. complex. Species-level
identification and life-history information were limited, so the assessment
was conducted for the complex rather than for an individual smoothhound
species. No matching stock record was found in the canonical database; this
screen assigns a discovery-register unit only.

## Inputs and model

The final SEDAR 39 report states that no age-composition information was
available. It describes catch and aggregate abundance-index series, length
observations used in deriving catch weights, and life-history information used
to inform productivity. The accepted model is a WinBUGS state-space Bayesian
surplus-production model. It estimates aggregate exploitable numbers, biomass
and harvest rates; it does not estimate age-specific abundance, fishing
mortality, or natural mortality, and does not fit an age-composition
likelihood.

## Screening decision

This assessment is **ineligible for the age-disaggregated source-curation set**.
Its official model is not age structured, and the source explicitly says age
compositions were unavailable. Aggregate observations and age-related life
history do not constitute age-specific observation inputs. The row remains in
the candidate register for audit completeness; no canonical inputs, outputs,
assessment event were added.

## Sources and provenance

- [NOAA Stock SMART, stock 14230](https://apps-st.fisheries.noaa.gov/stocksmart/?stockid=14230).
- [SEDAR 39 project page](https://sedarweb.org/assessments/sedar-39/).
- [SEDAR 39 final stock assessment report, Gulf of Mexico smoothhound sharks](https://sedarweb.org/documents/sedar-39-final-stock-assessment-report-hms-gulf-of-mexico-smoothhound-shark/).
- The final report PDF is cached in the ignored local source cache at
  `source_cache/discovery_noaa_smoothhound_2026/`, with retrieval date, URL,
  pinned assessment identity, byte count and SHA-256 in `sources.csv`.
- The NOAA Stock SMART snapshot is pinned to revision
  `664c4237e26520b260a090e1821a2cee5d1cdf07`, retrieved 2026-10-28.

**Review date:** 2026-11-02

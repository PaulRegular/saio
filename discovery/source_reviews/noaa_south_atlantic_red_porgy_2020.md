# NOAA South Atlantic red porgy (Stock SMART 10100)

## Unit and assessment

The South Atlantic red porgy management unit is distinct from all current DFO and ICES entries found in the discovery register and from the canonical tinyAM stock table. The NOAA Stock SMART row is therefore provisionally new, under `noaa_south_atlantic_red_porgy`.

The latest completed full assessment located is SEDAR 60, completed in April 2020 with data through 2017. The assessment used the Beaufort Assessment Model (BAM), a statistical catch-age model, over ages 1–14+ and years 1972–2017. The 2026 South Atlantic council schedule and 2027–2028 statements of work still identify SEDAR 60 as the preceding assessment and plan a later update; no completed successor assessment was located by the review date, 2026-10-29.

## Data and outputs

- **Catch:** The assessment fits annual landings for commercial handline and trawl, headboat, and MRIP fleets, plus dead discards for handline, headboat, and MRIP. Table 10 reports commercial landings in 1,000 lb whole weight and recreational landings and all discards in 1,000 fish. Fishery age compositions are used for handline and headboat; trawl uses a pooled length composition because ages were unavailable. The report presents age and length compositions in figures rather than as complete machine-readable matrices. Reconstructed catch-at-age would need to digitize the fishery compositions and derive trawl ages from its length composition and fixed growth inputs.
- **Survey:** The model fits the Southeast Regional Headboat Survey index for 1973–1998 and the combined SERFS chevron trap/video index for 1990–2017. Table 14 reports index values and CVs. SERFS chevron trap age compositions inform selectivity; converting the aggregate survey index into an age-specific index for tinyAM would be an explicit reconstruction, not the native observation likelihood.
- **Biology:** Table 15 gives fixed mid-year weights-at-age, sex ratio, maturity-at-age by sex, and natural mortality for ages 1–14+. The base run uses one time-invariant female maturity vector. Growth is specified using fixed von Bertalanffy parameters and a fixed length-weight relationship.
- **Mortality:** Natural mortality is fixed and decreases with age using a growth-based Charnov form. It is scaled to the same survival from age 3 through age 25 as a constant M of 0.22 per year.
- **Timing:** The model is annual, and its indices are predicted from beginning-of-year abundance. Spawning is represented at February 1 (year fraction 0.167). The final assessment report does not specify a single effective within-year timing for either abundance index; a tinyAM fit would need a stated timing approximation.
- **Outputs:** Table 16 reports numeric total abundance-at-age in 1,000 fish for ages 1–14+ over 1972–2017. The assessment also reports annual SSB, total biomass, apical fishing mortality, recruitment, age-specific fishing-mortality results, and survey/fishery fits.

## Screening decision

This stock is **eligible for source curation**. The assessment provides catch totals, age and length compositions, survey indices, age-specific biological inputs, mortality assumptions, and numeric abundance-at-age outputs. This is eligibility for documented source reconstruction, not a claim that native catch-at-age is directly reported or that tinyAM can reproduce the BAM likelihood. Any digitized fishery compositions, trawl age reconstruction, or age-specific survey index must be labeled as derived and approximate. No canonical database records or numerical assessment values were changed during this screen; import remains `not_started`.

## Cached sources

The ignored local cache is `source_cache/discovery_noaa_red_porgy_sedar60/`. Its `sources.csv` records each cached PDF's URL, retrieval date, and SHA-256 checksum.

Sources: [SEDAR 60 Stock Assessment Report](https://sedarweb.org/documents/sedar-60-stock-assessment-report-south-atlantic-red-porgy/), [SEDAR 60 project record](https://sedarweb.org/assessments/sedar-60/), [SAFMC 2026 assessment schedule](https://safmc.net/documents/a3_species_for_2026_stock_assessments-pdf/), and [SAFMC 2027–2028 SEDAR statements of work](https://safmc.net/documents/sedar_a3_statements-of-work-for-2027-2028-sedar-stock-assessments-pdf/).
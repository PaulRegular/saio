# NOAA Gulf of Alaska skate component crosswalk

Review date: 2026-11-02
Inventory records: `NOAA:10727` and `NOAA:10730`
Candidate units: `noaa_goa_big_skate` and `noaa_goa_longnose_skate`

## Assessment identity

NOAA Stock SMART lists Big skate (`10727`, assessment `13084`) and Longnose skate (`10730`, assessment `13093`) as full-acceptance operational assessments for 2023, with data through 2023. Both records identify the same December 2023 Gulf of Alaska Skate SAFE chapter as their final assessment report. The chapter explicitly manages three separate units: Big skate, Longnose skate, and Other skates. Each receives its own GOA-wide random-effects biomass estimate. Big and Longnose skate additionally have regional harvest apportionment.

The three Stock SMART records map to three distinct current management units in the same SAFE chapter. Their 2024 biomass estimates are distinct: 37,804 t for Big skate, 33,804 t for Longnose skate, and 8,869 t for Other skates. The `NOAA:11005` record is the residual Other skates group, not a parent record for all three units. The register therefore retains three separate stock-unit keys and avoids treating regional apportionment as another stock.

## Inputs and outputs found

- **Catch:** The 2023 SAFE reports aggregate catches by group in tonnes, not catch numbers-at-age. Fishery length compositions are described but are not used to determine stock status.
- **Survey:** Bottom-trawl survey biomass is used in random-effects models. The source does not report an age-specific abundance index or age-composition likelihood for either group.
- **Biology:** The assessment is biomass-based and does not use or report group-specific annual weight-at-age or maturity-at-age inputs.
- **Mortality:** The 2023 SAFE fixes natural mortality at `M = 0.1` for Big and Longnose skate; there is no age-specific M surface.
- **Timing:** The report uses annual survey biomass but does not specify a within-year timing fraction.
- **Outputs:** Group-level survey-biomass estimates and exploitation rates are available. The report does not provide N-at-age, F-at-age, SSB, or recruitment. Regional biomass allocation for Big and Longnose skate is not an age-specific population output.

## Decision

Screen `NOAA:10727` and `NOAA:10730` as separate ineligible current stock units. They share a detailed assessment chapter with `NOAA:11005`, but each has its own assessment ID and species-specific biomass series. None is age-structured. No canonical stock, assessment, input, or output rows were added.

## Sources

The source files and provenance are cached under the gitignored `source_cache/discovery_noaa_goa_skates_2023_2026/` directory; its `sources.csv` manifest records retrieval dates, revisions, sizes and SHA-256 checksums.

- [2023 GOA Skates SAFE chapter](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOAskate.pdf)
- [2024 GOA SAFE introduction](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C2+GOA+Groundfish+SAFE+Introduction.pdf&p=ab2770e7-ed6f-4a2f-a69d-5cbd0bda1896.pdf)
- [2026 GOA Skates SAFE chapter, pre-dissemination version](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=18.+GOA+Skates.pdf&p=9922f1ff-0fcc-45a5-ac9f-d901b861aa53.pdf)

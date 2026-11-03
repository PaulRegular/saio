# NOAA Gulf of Alaska Other skates group

Review date: 2026-11-02
Inventory record: `NOAA:11005`
Candidate unit: `noaa_goa_other_skates`

## Assessment identity

NOAA Stock SMART identifies assessment 13101 as the full-acceptance 2023 operational assessment for stock ID 11005, with data through 2023 and model `Survey Abundance` / REMA. The 2024 Gulf of Alaska SAFE introduction confirms that 2023 was the latest full operational assessment at that time. The 2023 SAFE explicitly treats Big skate, Longnose skate, and Other skates as three separate current management units. Stock SMART records 10727 and 10730 are the two named species units, each with a separate assessment ID and biomass series. Stock ID 11005, despite its broad “Gulf of Alaska Skate Complex” label, corresponds to the residual Other skates group: the 2023 SAFE reports 2024 biomass estimates of 37,804 t for Big skate, 33,804 t for Longnose skate, and 8,869 t for Other skates, matching the three Stock SMART estimates.

The September 2026 GOA skates chapter is later, but it labels itself pre-dissemination peer-review material and says it has not been formally disseminated. It is not treated here as an accepted production run. It was reviewed only to check whether the method or evidence changed: it continues to describe a biomass-only random-effects approach and reports updated survey biomass through 2025.

## Inputs and outputs found

- **Catch:** The 2023 SAFE reports aggregate catch by management group in tonnes, not catch numbers-at-age. It says fishery observers have collected length compositions since 2009, but those compositions are not used to determine stock status.
- **Survey:** The accepted assessment uses AFSC bottom-trawl survey biomass, with a survey history extending from 1984 through 2023. The 2026 pre-dissemination update gives survey biomass through 2025. Neither is an age-specific index or an age-composition series.
- **Weights and maturity:** No run-specific weight-at-age or maturity-at-age series is reported or used by this assessment. The Stock SMART biological-input score is not evidence of age-specific biological inputs.
- **Mortality:** Natural mortality is fixed at 0.1 for each of the three skate assessment groups; no age-specific M surface is estimated.
- **Timing:** The assessment is a biomass-only random-effects model using annual survey observations. The source does not specify a within-year timing fraction.
- **Outputs:** The 2023 report provides survey-biomass estimates and exploitation-rate summaries, including regional biomass for Big and Longnose skates. It does not provide N-at-age, F-at-age, SSB, or recruitment.

The 2023 report describes REMA as a random-effects model applied to biomass estimates, rather than an age-structured population model. Thus the absent age series are not merely missing tables for a hidden age-structured assessment.

## Decision

Classify `NOAA:11005` as the distinct **Other skates** current stock unit and **ineligible** for age-structured source curation. Its catch and survey biomass are useful for the current management assessment but do not meet the database's age-disaggregated input requirement. Keep Big skate and Longnose skate as their own stock units under `NOAA:10727` and `NOAA:10730`. These three units share a SAFE chapter but are not regional variants or duplicate stock cases. No canonical stock, assessment, input, or output records were added was attempted.

## Cached sources

The PDFs are cached locally under the gitignored `source_cache/discovery_noaa_goa_skates_2023_2026/`; `sources.csv` records the source URL, retrieval date, document revision, byte size, and SHA-256 checksum.

- 2023 GOA Skates SAFE, the accepted operational assessment: <https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOAskate.pdf>
- 2024 GOA SAFE introduction, confirming the most recent full/operational run was conducted in 2023: <https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C2+GOA+Groundfish+SAFE+Introduction.pdf&p=ab2770e7-ed6f-4a2f-a69d-5cbd0bda1896.pdf>
- September 2026 GOA Skates SAFE chapter, explicitly pre-dissemination: <https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=18.+GOA+Skates.pdf&p=9922f1ff-0fcc-45a5-ac9f-d901b861aa53.pdf>

# NOAA Gulf of Alaska northern rock sole screen

## Identity and latest official run

NOAA Stock SMART rows 10836, 15412, and 15413 refer to Gulf of Alaska northern rock sole (*Lepidopsetta polyxystra*). Row 10836 is the older Gulf-wide identifier through 2020; current Stock SMART rows 15412 and 15413 refer to central and western GOA model components and carry monitoring updates through 2024. The 2021 full assessment represented these spatial areas within one species-specific two-area growth-morph model. They are grouped under `candidate_unit_id = noaa_goa_northern_rock_sole` and are not three stock cases.

The preferred northern rock sole model in the 2021 assessment was Model 21.2. The 2023 and 2025 SAFE material did not provide a later full fit; the 2025 catch-report chapter states that no assessment was conducted that year. The last full model therefore remains the 2021 production assessment, with subsequent Stock SMART monitoring records distinguished from new full model runs.

## Inputs and outputs

The model covered ages 0-30 and used annual total rock sole catch split evenly between northern and southern rock sole. Fishery inputs were length compositions for 1997-2021, not catch-at-age. The NMFS GOA bottom-trawl survey supplied biomass estimates with uncertainty, survey length compositions, and conditional age-at-length information. Northern rock sole survey age data are listed through 2017; the report says 2019 ages were unavailable. The assessment is age-structured internally, but its documented fishery observations do not contain the catch-at-age series required for the current tinyAM translation screen.

Female M was fixed at 0.2 and male M was estimated. The preferred 2021 Model 21.2 reported male M of 0.232 in central GOA and 0.254 in western GOA. Maturity was a fixed age-based input and growth used a length-weight relationship, but numeric maturity and weight-at-age vectors were not recovered from these sources. The report provides survey biomass, total biomass, female SSB, M and harvest-reference outputs by area. Complete annual N-at-age and F-at-age arrays were not located.

## Screening decision

This is one current GOA northern rock sole unit represented by three source-list rows. It is provisionally new relative to the canonical database; the existing northern rock sole record is for the Eastern Bering Sea and is not a match. It is screened ineligible for a tinyAM age-structured translation from the recovered official inputs because fishery compositions are lengths and catch is annual total biomass rather than catch-at-age. No unsupported conversion from length composition or survey CAAL to fishery age composition is made.

## Sources and cached files

- NOAA, 2021, *Assessment of Northern and Southern Rock Sole Stocks in the Gulf of Alaska*, preferred northern rock sole Model 21.2: <https://apps-afsc.fisheries.noaa.gov/Plan_Team/2021/GOAnsrocksole.pdf>.
- NOAA, 2023, off-cycle harvest projection based on the 2021 assessment: <https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOAnsrocksole.pdf>.
- NPFMC, December 2025, *GOA Shallow Water Flatfish SAFE chapter*, catch report noting no assessment in 2025: <https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=4.+Shallow-Water+Flatfish.pdf&p=969301d9-957a-48ed-8d78-094a02ffce04.pdf>.
- NOAA Stock SMART snapshot, pinned and checksummed in `discovery/README.md`, identifies the legacy and current regional stock IDs and their assessment years.

The three reports are cached under `source_cache/discovery_noaa_goa_rock_sole_2026/`; `sources.csv` records retrieval dates, URLs, SHA-256 checksums, and source roles.

# NOAA Gulf of Alaska southern rock sole screen

## Identity and latest official run

NOAA Stock SMART rows 10040, 15414, and 15415 refer to Gulf of Alaska southern rock sole (*Lepidopsetta bilineata*). Row 10040 is the older Gulf-wide identifier through 2020; current Stock SMART rows 15414 and 15415 refer to central and western GOA model components and carry monitoring updates through 2024. The 2021 full assessment represented these spatial areas within one species-specific two-area growth-morph model. They are grouped under `candidate_unit_id = noaa_goa_southern_rock_sole` and are not three stock cases.

The preferred southern rock sole model in the 2021 assessment was Model 21.1. The 2023 report provides harvest projections based on the 2021 fit. The 2025 SAFE catch-report chapter explicitly reports that no assessment was conducted that year because of the federal shutdown. The 2021 model therefore remains the latest full assessment; Stock SMART monitoring updates are distinguished from full model runs.

## Inputs and outputs

The model covered ages 0-30 and used annual total rock sole catch split evenly between northern and southern rock sole. Fishery inputs were length compositions for 1997-2021, not catch-at-age. Survey inputs include biomass estimates with uncertainty, length compositions, and conditional age-at-length samples for southern rock sole in 1996-2019. The assessment is age-structured internally, but its documented fishery observations do not contain the catch-at-age series required for the current tinyAM translation screen. Survey CAAL does not replace fishery catch-at-age.

Female M was fixed at 0.2 and male M was estimated. The preferred 2021 Model 21.1 reported male M of 0.253 in central GOA and 0.271 in western GOA. Maturity was a fixed age-based input and growth used a length-weight relationship, but numeric maturity and weight-at-age vectors were not recovered from these sources. The report provides survey biomass, total biomass, female SSB, M, and harvest-reference outputs by area, but not complete annual N-at-age and F-at-age arrays.

## Screening decision

This is one current GOA southern rock sole unit represented by three source-list rows. It is provisionally new relative to the canonical database; the existing northern rock sole record is for the Eastern Bering Sea and is not a match. It is screened ineligible for a tinyAM age-structured translation from the recovered official inputs because fishery compositions are lengths and catch is annual total biomass rather than catch-at-age. No unsupported conversion from length composition or survey CAAL to fishery age composition is made.

## Sources and cached files

- NOAA, 2021, *Assessment of Northern and Southern Rock Sole Stocks in the Gulf of Alaska*, preferred southern rock sole Model 21.1: <https://apps-afsc.fisheries.noaa.gov/Plan_Team/2021/GOAnsrocksole.pdf>.
- NOAA, 2023, off-cycle harvest projection based on the 2021 assessment: <https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOAnsrocksole.pdf>.
- NPFMC, December 2025, *GOA Shallow Water Flatfish SAFE chapter*, catch report noting no assessment in 2025: <https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=4.+Shallow-Water+Flatfish.pdf&p=969301d9-957a-48ed-8d78-094a02ffce04.pdf>.
- NOAA Stock SMART snapshot, pinned and checksummed in `discovery/README.md`, identifies the legacy and current regional stock IDs and their assessment years.

The three reports are cached under `source_cache/discovery_noaa_goa_rock_sole_2026/`; `sources.csv` records retrieval dates, URLs, SHA-256 checksums, and source roles.

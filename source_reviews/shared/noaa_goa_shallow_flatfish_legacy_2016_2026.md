# NOAA Gulf of Alaska shallow-water flatfish: legacy crosswalk

Review date: 2026-11-02
Inventory record: `NOAA:11009`
Current assessment groups: other shallow-water flatfish, northern rock sole, and southern rock sole

## Assessment identity

NOAA Stock SMART lists assessment 9489 (2016, data through 2016) as a full-acceptance partial update using Stock Synthesis. NOAA's archival page describes 2016 as an off-year executive summary and identifies the 2015 report as the last full rock-sole assessment. The 2016 source does not establish an independent current assessment for all eight species in the management complex.

The current management complex still contains eight species, but it is not one age-structured assessment. The 2021 SAFE describes northern and southern rock sole as separate Tier 3 age-structured assessments. The other six species are Tier 5 and use survey-biomass random-effects models. The current discovery register already represents these three groups separately:

- Other shallow-water flatfish: `NOAA:11803`
- Northern rock sole: `NOAA:10836`, `NOAA:15412`, `NOAA:15413`
- Southern rock sole: `NOAA:10040`, `NOAA:15414`, `NOAA:15415`

The 2024 SAFE says 2021 was the last full assessment and anticipated a full assessment in 2025. The February 2026 assessment-priority document then deferred the full shallow-water-flatfish assessment and called for a harvest projection. The September 2026 Plan Team agenda lists shallow-water flatfish under harvest projections. The separately posted 2026 SAFE chapter is still ahead of its scheduled review period, so it is not treated here as an accepted production run.

## Inputs and outputs found

- **Catch:** The broad complex has annual catches by species and fishery, reported as totals. It does not form one current catch-at-age assessment. The rock-sole age-structured models and Tier 5 remainder are screened under their own candidate records.
- **Survey:** The GOA bottom-trawl survey supplies biomass and length information. The 2021 report says the rock-sole models also use conditional age-at-length; the other six species use survey biomass in random-effects models. It notes that aging of GOA flatfish has been sporadic.
- **Biology and mortality:** There is no single age-specific biological or mortality surface for all eight species. The 2021 report uses M = 0.2 for the Tier 5 remainder and separate sex- and area-specific mortality values for northern and southern rock sole.
- **Timing:** Surveys are biennial. The reviewed sources do not specify one within-year timing fraction for a single age-structured model covering the former aggregate.
- **Outputs:** The Tier 5 group has aggregate survey-biomass estimates and management advice. Rock-sole model outputs belong to the two separate species assessments. The broad legacy record is not a distinct current age-specific output series.

## Decision

Mark `NOAA:11009` as an **ambiguous legacy identity** and **ineligible as a separate current-unit candidate**. Its former eight-species grouping is represented by three current assessment groups, so it must not be counted as an additional stock or used to combine component data. This decision does not change the source screens for the three current groups. No canonical stock, assessment, input, or output rows were added.

## Cached sources

Source files are stored under the gitignored `source_cache/discovery_noaa_goa_shallow_flatfish_2016_2026/`. The local `sources.csv` manifest records the URLs, retrieval date, revision labels, byte sizes, and SHA-256 checksums.

- [NOAA 2016 shallow-water-flatfish archive page](https://www.fisheries.noaa.gov/resource/data/2016-assessment-shallow-water-flatfish-complex-gulf-alaska)
- [2015 full northern and southern rock sole assessment](https://apps-afsc.fisheries.noaa.gov/REFM/Docs/2015/GOAnsrocksole.pdf)
- [2021 GOA shallow-water-flatfish SAFE chapter](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2021/GOAshallowflat.pdf)
- [2024 GOA shallow-water-flatfish SAFE chapter](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAshallowflat.pdf)
- [2026 GOA shallow-water-flatfish SAFE chapter](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=4.+GOA+Shallow-water+Flatfish.pdf&p=e8b5e9b8-f5ed-47cb-8ed0-8e13089f9231.pdf)
- [February 2026 groundfish assessment priorities](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=D2+Groundfish+Stock+Assessment+Priorities.pdf&p=ff7dee7e-242d-42e7-85c7-2479d7eeac96.pdf)
- [September 2026 GOA shallow-water-flatfish harvest projection](https://drive.google.com/open?id=1rH572n5VqDzy7ld9AQmxpd9JGNHVVEKm)

# Northern rockfish in the Bering Sea and Aleutian Islands

## Unit and current assessment

NOAA Stock SMART ID 10416 is the Bering Sea/Aleutian Islands (BSAI) northern rockfish unit (*Sebastes polyspinis*). It is distinct from the Gulf of Alaska unit (Stock SMART 10417). Searches of the canonical stock table and the other organization rows in the discovery register found no existing match for either unit.

The latest detailed full assessment is the 2023 BSAI SAFE chapter. The 2025 catch report says the scheduled 2025 full assessment was not conducted during the federal shutdown. The September 2026 SAFE chapter is a harvest projection, not a new population-model fit: it states the 2023 assessment remains the latest full assessment, updates catches through 2026, carries the 2023 estimates forward, and identifies 2027 as the next scheduled operational assessment. Stock SMART's 2024 inventory year should not be treated as the latest full-model year.

The 2023 full assessment, 2025 catch report, and 2026 harvest-projection chapter are cached under `source_cache/noaa_northern_rockfish_20261029/`; `sources.csv` records retrieval dates, URLs and checksums. The 2026 SSC review is cached there to document the assessment schedule.

## Inputs and source screen

The 2023 assessment reports fishery catch through 2022 and projects 2023 catch. Fishery age compositions are available for 2000–2009, 2011, 2013, 2015, 2017 and 2019–2021. The assessment age grid begins at recruitment age 3 and uses a 40+ plus group. Catch-at-age is not supplied as a direct annual observation series. it must be labelled as a downstream reconstruction.

Aleutian Islands survey biomass estimates and age compositions are reported for 1991, 1994, 1997, 2000, 2002, 2004, 2006, 2010, 2012, 2014, 2016, 2018 and 2022. An age-specific survey index could be reconstructed from survey biomass and the corresponding age composition. It is not the native likelihood input, which includes aggregate survey biomass and age composition separately. Survey years are not annual. The assessment defines population and fishery weight-at-age vectors in kg and uses an age-specific maturity vector. The exact vectors and transformations must be checked against source tables/native model materials during extraction.

Natural mortality is estimated with a prior. The full assessment reports M near 0.052, which is carried into the 2026 harvest projection rather than re-estimated there. The annual model's survey timing fraction is not stated.

## Outputs and eligibility

The 2023 SAFE reports fitted age-structured outputs, including population numbers at age, recruitment, fishing mortality and female spawning biomass. The 2026 projection report also provides age-3+ total biomass, female spawning biomass, exploitation summaries and future projections. These are sufficient to make the BSAI unit provisionally eligible for source curation, provided all catch-age and survey-index reconstruction is explicit. No values have been imported into the canonical database.

Sources:

- [2023 BSAI full assessment](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAInork.pdf)
- [2025 BSAI catch report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C5+BSAI+2025+Catch+Reports.pdf&p=b2b4068a-522e-42f6-a0ca-68a7ffa83ae7.pdf)
- [2026 BSAI harvest-projection chapter](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=13.+BSAI+Northern+Rockfish.pdf&p=c7d07ded-c246-4798-883b-1aacc01d8172.pdf)
- [2026 SSC assessment review plan](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=F+2026+Groundfish+Stock+Assessment+SSC+Review.pdf&p=2aa31081-76e1-4025-af01-e17fd99ba0d6.pdf)

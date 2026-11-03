# NOAA Alaska aggregate assessments reviewed in 2024

This screen covers six NOAA Stock SMART regional entries and five distinct candidate units. All five units are ineligible for the current age-structured source set: the reviewed production sources describe aggregate survey biomass, index methods, or ecosystem trends, and do not establish the required age-specific catch and abundance inputs, biological surfaces, and fitted population outputs.

Stock SMART input scores are discovery metadata. The data dictionary says composition score 1 means major coverage gaps and no use in the assessment; score 2 means enough size or age composition for data-limited methods. Neither score proves that the accepted model uses an age-composition likelihood.

| Stock SMART ID | Latest listed year | Area | Latest detailed source | Finding |
|---|---:|---|---|---|
| 10973 | 2020 | Bering Sea and Aleutian Islands | [2024 BSAI Other Flatfish SAFE](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIoflat.pdf); [2024 BSAI SAFE introduction](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/BSAIintro.pdf); [December 2024 SSC final report](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=SSC+Report+Dec+2024_FINAL.pdf&p=2587e1ac-2a37-4a80-b68b-7a8c7e7a02ca.pdf) | Stock SMART still lists assessment 11254 (2020), but the 2024 SAFE and SSC report document a later operational update. The 2024 run added catches and survey biomass, adopted REMA for aggregate biomass, and was supported by the SSC. It does not provide age-specific inputs or outputs. |
| 10974 | 2024 | Bering Sea and Aleutian Islands | [2024 BSAI Other Rockfish SAFE](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=BSAI+Other+Rockfish++2024.pdf&p=3bf7a4e8-904c-420f-a95f-0efe07afcef2.pdf) | Biomass is estimated from trawl-survey biomass and observation errors; age-structured inputs or outputs were not verified. |
| 11405 | 2023 | Bering Sea and Aleutian Islands | [2023 Alaska sculpin ecosystem report](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/sculpin.pdf) | Shared ecosystem report summarizes survey and catch trends; no fitted age-structured population series was verified. |
| 11448 | 2023 | Gulf of Alaska | [2023 Alaska sculpin ecosystem report](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/sculpin.pdf) | Same report and candidate unit as ID 11405; retain as a regional inventory row, not a second independent assessment. |
| 11803 | 2024 | Gulf of Alaska | [2024 GOA Shallow Water Flatfish SAFE](https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/GOAshallowflat.pdf) | The residual Tier 5 complex uses survey-based biomass estimation; age-structured inputs or outputs were not verified. |
| 11804 | 2023 | Gulf of Alaska | [2024 GOA Other Rockfish update](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=GOA+Other+Rockfish+2024.pdf&p=f71d8d41-5d34-4947-a7a6-e0466e00bc6b.pdf) | The 2024 update changed the complex membership and catch series but did not refit Tier 4/5 models because no new survey data were available. The 2023 model remains the latest model-based result; it is biomass-based, not age-structured. |

For sculpins, NOAA Stock SMART lists two regional IDs (11405 and 11448), while the 2023 ecosystem report combines Gulf of Alaska, Eastern Bering Sea, and Aleutian Islands trends. Both rows therefore link to `noaa_alaska_sculpin_complex` and count as one assessment unit.

The GOA shallow-water flatfish report separates Tier 3 northern and southern rock sole from the residual Tier 5 other shallow-water flatfish complex. That residual group is not merged with the older broader GOA shallow-water flatfish complex.

The 2024 BSAI Other Flatfish update is an important distinction: its most recent Stock SMART row is from 2020, but the official 2024 SAFE and SSC report document a newer production update. The register retains the Stock SMART year as inventory metadata and records the newer production assessment in its review notes and evidence.

The official reports and NOAA Stock SMART data dictionary are cached locally in the gitignored `source_cache/discovery_noaa_alaska_aggregates_2024/`, with retrieval dates, URLs, revisions, and SHA-256 hashes in `sources.csv`.

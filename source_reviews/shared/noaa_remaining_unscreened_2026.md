# NOAA Stock SMART candidates screened 2026-11-02

This review resolves the 17 NOAA rows that were still marked `not_started` in
the discovery register.

## Decisions

| NOAA ID | Inventory unit | Screen | Evidence and unit decision |
|---|---|---|---|
| 10689 | North Atlantic blue shark | Ineligible | The 2023 ICCAT production assessment reports catch, CPUE, and size compositions, with no age-composition likelihood or age-specific population output. Age-based biology does not make the observations age-disaggregated. |
| 10989 | Caribbean parrotfishes complex | Ineligible | The cited 2009 SEDAR item is a data-evaluation workshop, not an accepted age-structured production assessment with age inputs and population outputs. |
| 11402 | Bering Sea/Aleutian Islands skate complex | Ambiguous legacy aggregate; ineligible | The 2007 aggregate overlaps the present Alaska skate and Other Skates harvest units. The current assessment treats Alaska skate with an age-structured Tier 3 model and Other Skates with an aggregate Tier 5 biomass method; the old row cannot be assigned to either as a distinct current unit. |
| 11444 | Bering Sea/Aleutian Islands Other Skates | Ineligible | The 2023 production assessment estimates aggregate biomass from survey indices with the Tier 5 REMA approach. It does not provide an age-disaggregated likelihood or fitted age surfaces. |
| 11712 | Pacific bigeye thresher | Ineligible | The WCPFC product is a sustainability-risk assessment. It describes catch, CPUE, and observer information and explicitly identifies limited age data. Verify native input/output files before eligibility. |
| 11724 | Western/Central Pacific oceanic whitetip | Ineligible | The 2025 WCPFC assessment is the latest detailed production fit. It documents catch, aggregate CPUE, and length compositions, not an age-composition likelihood or age-specific abundance series. |
| 11763 | Atlantic/Gulf scalloped hammerhead | Unresolved | SEDAR 77 later produced age-structured assessment material, but NOAA's 2026 review states that CIE reviewers recommended it not be used for OFL advice. The latest accepted operational assessment in Stock SMART is an aggregate surplus-production model; verify whether SEDAR 77 qualifies for source curation before deciding. |
| 14821 | California blue/deacon rockfish | Eligible | The 2017 accepted assessment has a public Stock Synthesis model archive, age and length observations, abundance indices, biological assumptions, and comparable population outputs. Keep California separate from Oregon; the 2019 item is a catch update, not a replacement fit. |
| 14822 | Oregon blue/deacon rockfish | Eligible | The 2017 accepted assessment has a public Stock Synthesis model archive, age and length observations, abundance indices, biological assumptions, and comparable population outputs. Keep Oregon separate from California. |
| 15052 | Northern California gopher/black-and-yellow rockfish | Eligible | The 2019 accepted assessment has public Stock Synthesis model files, age and length observations, abundance indices, biological assumptions, and comparable population outputs. |
| 15310 | Southern California vermilion/sunset rockfish | Eligible | The 2021 accepted assessment has public Stock Synthesis model files, conditional age-at-length observations, aggregate abundance indices, biological assumptions, and comparable population outputs. Retain the combined species unit south of Point Conception. |
| 15335 | Northern California vermilion/sunset rockfish | Eligible | The 2021 accepted assessment has public Stock Synthesis model files, conditional age-at-length observations, aggregate abundance indices, biological assumptions, and comparable population outputs. Retain the combined species unit north of Point Conception. |
| 15351 | Southern California blue rockfish | Ineligible | The latest inventory assessment is a data-limited DCAC analysis, not an age-structured production model. This southern unit is separate from the 2017 California blue/deacon model, which spans Point Conception to the Oregon/California border. |
| 15439 | St. Thomas/St. John Grouper Unit 3 | Ineligible | The 2014 accepted assessment uses a non-equilibrium mean-length estimator; it does not provide age-disaggregated inputs or fitted population outputs. |
| 15512 | St. Croix Grouper Unit 4 | Ineligible | The 2014 accepted assessment uses a non-equilibrium mean-length estimator; it does not provide age-disaggregated inputs or fitted population outputs. |
| 15577 | Puerto Rico Grouper Unit 6 | Ineligible | The 2014 accepted assessment uses a non-equilibrium mean-length estimator; it does not provide age-disaggregated inputs or fitted population outputs. |

The rockfish cases retain native Stock Synthesis composition inputs for later
extraction. The five eligible rows are eligible
for source curation, not a claim that they are already numerically imported or
complete source records. Common thresher remains unresolved pending verification of
run-matched source files. Scalloped hammerhead also remains unresolved because
SEDAR 77 is not the accepted OFL basis.

## Sources

- [ICCAT 2023 Blue Shark Stock Assessment Meeting report](https://iccat.int/Documents/Meetings/Docs/2023/REPORTS/2023_BSH_ENG.pdf)
- [SEDAR Caribbean Fisheries Data Evaluation](https://sedarweb.org/docs/sar/CaribData_Final_0.pdf)
- [NOAA 2023 BSAI skate assessment](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/BSAIskate.pdf)
- [WCPFC 2018 Pacific-wide bigeye thresher risk assessment](https://meetings.wcpfc.int/file/6120/download)
- [NOAA 2018 common thresher assessment record](https://repository.library.noaa.gov/view/noaa/18085)
- [WCPFC 2025 oceanic whitetip shark assessment](https://meetings.wcpfc.int/system/files/2025-07/SC21-SA-WP-08_2025%20Oceanic%20whitetip%20shark%20assesment_neubauer-Rev1.pdf)
- [SEDAR 77 hammerhead assessment record](https://sedarweb.org/assessments/sedar-77/)
- [NOAA HMS Advisory Panel 2026 presentation](https://www.fisheries.noaa.gov/s3/2026-05/hms_ap_sefsc_spring2026.pdf)
- [PFMC groundfish assessment reports and model files](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [NOAA assessment status list](https://www.fisheries.noaa.gov/s3/2021-04/Appendix-D.pdf)

The locally cached PDFs and their retrieval dates and SHA-256 checksums are in
the ignored `source_cache/discovery_noaa_screen_backlog_2026/sources.csv` file.

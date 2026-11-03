# China rockfish, U.S. Pacific Coast (2015)

Review date: 2026-11-01. NOAA Stock SMART lists three 2019 entries for China rockfish (*Sebastes nebulosus*): northern, central and southern Pacific Coast. These are three separate assessment units, not three assessment years or one coastwide stock. The northern model covers Washington; the central model covers Oregon and California north of 40°10′ N; the southern model covers California south of 40°10′ N.

The latest detailed full assessment located is the 2015 PFMC assessment. The 2025 Pacific Coast Groundfish SAFE still lists 2015 as the most recent assessment for each of the three areas. The 2019 Stock SMART label therefore should not be treated as evidence of a newer full assessment; the 2019 action was a catch-only projection based on the 2015 model. The assessment report provides model data, control, starter and forecast files in appendices A–D.

## Inputs and assumptions

The three models are independent, sex-aggregated Stock Synthesis models. They track ages 0–80 and use age-composition bins with a plus group at age 50. Central and southern catch histories begin in 1900; the northern model begins with the Washington catch history in 1967. The fitted time series ends in 2014, with 2015 onward handled as projections. The assessment uses fishery-dependent abundance indices, length compositions, and age data that include conditional age-at-length samples; coverage varies by area and fleet. Southern-area models also include discard data. There are seven fishery-dependent abundance indices across the three areas: one northern, three central and three southern. No fishery-independent survey index was used. Keep inputs and model components assigned to their assessment area.

The assessment estimates growth by age. Its biological information includes weight–length relationships, sparse maturity-at-length data, and posterior-predictive fecundity relationships. After STAR review, natural mortality is fixed at 0.07 in all three models. Recruitment deviations are not estimated. These are assessment assumptions to preserve in any subsequent source extraction; they are not claims that a complete annual age-specific observation matrix is directly published.

The accepted assessment inputs are not a ready-made tinyAM data set. Catch-at-age and age-specific index series would require documented reconstruction from the native catches, compositions, index data and biological relationships. Composition sampling years are sparse relative to the assessment time series, so any reconstruction must retain that limitation and must not be presented as observed annual age-specific data.

## Outputs and screening decision

The 2025 SAFE gives the latest official status summaries and identifies the 2015 assessment as the latest for all three areas. The 2015 assessment and its supporting tables provide model-specific population-status outputs. Review and extract the area-specific output tables during source curation; do not combine the three area models.

Screen each area as **eligible for source curation**, conditional on verifying the native model data and the detailed output tables. The assessment has age-composition information, age-specific biology, catch and index inputs, and comparable population outputs. This eligibility does not mean catch-at-age or index-at-age is directly available, nor that the inputs are ready for tinyAM translation. No canonical stock, assessment, input or output records are added by this screen.

## Sources

- [2015 China rockfish assessment and appendices](https://www.pcouncil.org/documents/2016/04/status-of-china-rockfish-off-the-u-s-pacific-coast-in-2015-april-2016.pdf)
- [2025 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [2022 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2022/09/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2022.pdf/), which describes the 2019 action as a catch-only projection based on the 2015 assessment.

The 2015 assessment, 2022 and 2025 SAFE documents, and NOAA metadata snapshot are cached locally under the gitignored `source_cache/discovery_noaa_china_rockfish_2019/`; `sources.csv` records their URLs, retrieval date, byte sizes and SHA-256 checksums.

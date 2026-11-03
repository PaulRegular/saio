# Gulf of Alaska Dover sole (NOAA Stock SMART 10021)

## Stock unit and assessment used for advice

Stock SMART ID 10021 is Gulf of Alaska (*Microstomus pacificus*) Dover sole. It is distinct from the existing US West Coast Dover sole unit (Stock SMART ID 10022). No current GOA Dover sole stock record was found in the canonical database.

The latest completed full age-structured assessment located is the 2023 update, preferred Model 19.3.1, with data through September 27, 2023. The 2024 SAFE introduction says that the next full assessment was planned for 2027. The 2025 harvest projection used the accepted 2023 fit with updated catches for 2026-2027 specifications. The September 2026 Plan Team projection is a recommendation for later specifications; its final SAFE comment period had not begun as of this review date. Thus the 2023 assessment remains the latest completed full model run.

The detailed 2023 SAFE chapter and the NOAA AFSC `goa_deepwater` repository's `CIE 2026/2023 Accepted Run` files were cached locally under `source_cache/discovery_noaa_goa_dover_10021/`. The repository files are pinned to commit `b698cc59c8a33d7f424b4d5bc0fe3ae9961ae3be`; the local `sources.csv` records each URL, retrieval date, byte count, and SHA-256. The cache also contains the 2025 projection input and summary outputs and the NPFMC 2025 specifications-process document.

There is a version-label discrepancy to retain: the 2023 SAFE chapter reports Stock Synthesis 3.30.21, while the `starter.ss` and `data.ss` headers in the pinned CIE accepted-run directory say 3.30.13. The model name, terminal year, and data structure identify the run, but the version difference has not been resolved. The pinned repository contains assessment inputs and projection files, not a full `Report.sso` output directory.

## Inputs and age-data screen

The assessment's fishery input is catch biomass in tonnes from 1978 through September 2023. Fishery length compositions are available from 1991 through September 2023 in two-centimetre bins from 6 to 70 cm. The assessment report explicitly states that no otoliths have been collected from catches; fishery selectivity is inferred from length data and the model's growth relationship. The official assessment is age-structured, but the source does not provide fishery catch-at-age.

The GOA bottom-trawl survey provides aggregate biomass in tonnes: triennial observations from 1984-1999 and biennial observations from 2001-2023. Survey length compositions and conditional age-at-length samples are also included. The conditional samples used for age likelihoods are from 1993, 1996, 1999, and 2003-2021; the 1984, 1987, 1990, and 2001 age data are excluded. The report explains that the age samples are conditioned on length to estimate growth and avoid double-counting them with the length-composition likelihood. Combining the same-year survey length and age-at-length samples can produce a marginal survey age composition, but that is not a direct age-specific abundance index.

A catch-at-age reconstruction would need to transfer a survey-derived age-at-length relationship to fishery length compositions or use the assessment's fitted growth parameters. The assessment does not document such a conversion as fishery age observations, and the report describes cohort-specific growth and uncertainty in fishery selectivity. I therefore do not treat the fishery length compositions alone as source-supported catch-at-age. This candidate is ineligible for the current age-disaggregated input screen, although its source data may still be useful for a later length-based translation or a separately justified reconstruction.

The model estimates age- and sex-specific growth, uses a weight-length relationship to derive weight-at-age, and fits an age-based logistic maturity relationship. These are model-derived biological surfaces, not fixed observed weight-at-age and maturity-at-age vectors. Natural mortality is estimated separately for sexes and time blocks, with a recent 2014-2023 block.

The native data file records survey month 6 (June); its month 5 setting is spawning timing, not survey timing.

## Available outputs and limitations

The 2023 SAFE tables provide age-3+ total biomass, female spawning biomass, age-3 and age-0 recruitment, and natural-mortality estimates with selected uncertainty summaries. The report states that a time series of numbers-at-age is available separately, but that numeric 2023 file was not recovered during this screen. The pinned assessment repository has no `Report.sso` or age-specific output table. The later projection files provide harvest-projection outputs, not a replacement age-specific fitted-output series.

## Decision

Screened as a new stock unit and ineligible for the current age-input candidate set because fishery catch-at-age cannot be recovered from the documented source inputs without a substantial unverified age-length transfer. This does not mean the age-structured NOAA assessment is unsupported.

## Sources

- [2023 GOA Deepwater Flatfish SAFE chapter](https://apps-afsc.fisheries.noaa.gov/Plan_Team/2023/GOAdeepflat.pdf)
- [2024 GOA SAFE introduction and assessment schedule](https://apps-st.fisheries.noaa.gov/sis/docServlet?fileAction=download&fileId=10289)
- [2025 NPFMC groundfish specifications process](https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C4C5+Groundfish+Specs+Process+Dec+2025.pdf&p=0b5e829c-989e-415f-a71e-77d69b319759.pdf)
- [Pinned NOAA GOA deepwater flatfish assessment repository](https://github.com/noaa-afsc/goa_deepwater/tree/b698cc59c8a33d7f424b4d5bc0fe3ae9961ae3be)
- [2026 NPFMC Plan Team meeting details and projection recommendations](https://meetings.npfmc.org/Meeting/Details/5140)
- [2026 final SAFE comment-period schedule](https://meetings.npfmc.org/Meeting/Details/7163)

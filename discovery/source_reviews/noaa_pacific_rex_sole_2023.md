# NOAA Pacific Coast Rex Sole

## Stock and assessment

NOAA Stock SMART ID 10059 identifies Pacific Coast rex sole (*Glyptocephalus zachirus*), a stock unit separate from Gulf of Alaska rex sole (IDs 10058, 15410 and 15411). Stock SMART lists 2023 assessment ID 12970 as locked. The 2023 PFMC assessment is the latest detailed production assessment located; its model uses data through 2022. No rex sole record is currently present in the canonical database. Cross-organization identity reconciliation remains pending.

## Inputs and assumptions

The public 2023 assessment and its native Stock Synthesis archive provide the source material for curation. The model has two fishery fleets, three survey index fleets, one annual 12-month season, and 34 age bins. It includes catch biomass and fishery length compositions, with discards modeled separately from landings beginning in 2002. No fishery age-composition input is present in the native data file.

The NWFSC West Coast Groundfish Bottom Trawl Survey (WCGBTS) contributes length compositions and conditional age-at-length observations. The native data file assigns age-at-length rows to survey fleet 5, with observations from 2007–2019. The report describes 620 aged fish (350 females, 231 males and 39 unsexed). These are conditional age-at-length observations, not a marginal survey age composition or an age-specific abundance index. The survey biomass indices, survey length compositions and conditional age-at-length observations could support a documented age-specific index reconstruction. Similarly, fishery catch-at-age could be reconstructed from fishery length compositions and an age-length key informed by the aged survey samples and fitted growth relationship. Both are derived approximations; neither should be represented as a native observed age series.

Age-specific weight and maturity would need to be derived from the model's growth and weight-at-length inputs and the reported maturity-at-length relationship. The report attributes maturity and fecundity information to Hosie and Horton (1977); the maturity-curve slope is assumed from Abookire (2006). The control file specifies a one-parameter natural-mortality structure. Confirm its active status, estimated value and uncertainty against the final base-run parameter and output files before importing.

The assessment uses three aggregate survey-index fleets and a single annual season. The exact within-year survey timing encoded by the native input must be checked before translation to a fractional-year timing. Do not infer timing solely from the survey's late-May-to-October field season.

## Outputs and screening decision

The public native run archive includes `Report.sso` and associated model output files. Its report configuration enables numeric numbers-at-age, catch-at-age, fishing-mortality-at-age and biomass-at-age outputs, as well as fitted age-composition output. The assessment report provides aggregate spawning output and recruitment summaries. Confirm the output scales, year/age coverage and uncertainty conventions against the selected production run before import.

Screening decision: provisionally new and eligible for source curation. The official run supplies age information, survey indices, biological sources and numeric age-specific model outputs. This supports further source curation, but does not establish translation readiness. Preserve the native likelihood data and label every reconstructed age series as approximate.

The assessment identifies uncertain growth and natural mortality, limited aged samples concentrated in 2007–2019, and a high WCGBTS catchability estimate (3.97) as important limitations. These should be carried into any later audit and comparison.

## Sources

- [2023 Status of Rex Sole along the U.S. West Coast assessment](https://www.pcouncil.org/documents/2024/02/status-of-rex-sole-glyptocephalus-zachirus-along-the-u-s-west-coast-in-2023.pdf/)
- [2023 Rex Sole Stock Synthesis model files](https://www.pcouncil.org/documents/2024/02/rex-sole-2023-model-files.zip/)
- NOAA Stock SMART entity 10059; the retrieved entity record and source manifest are in the ignored local `source_cache/discovery_noaa_pacific_rex_2023/` folder.

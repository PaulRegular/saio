# NOAA Canary Rockfish, U.S. West Coast

## Assessment and cached sources

NOAA Stock SMART ID 10415 is the U.S. West Coast management unit for *Sebastes pinniger*. It is separate from the DFO British Columbia canary rockfish unit. The selected production assessment is the 2023 Stock Synthesis 3.30.21 run, published in 2024 and fitted through 2022. Its model report contains historical estimates through 2022 and management projections through 2034. Stock SMART's 2025 inventory label and later harvest actions do not identify a newer full assessment.

The [NOAA repository record](https://repository.library.noaa.gov/view/noaa/72904) identifies the assessment. The [assessment report PDF](https://www.pcouncil.org/documents/2024/02/status-of-canary-rockfish-sebastes-pinniger-along-the-u-s-west-coast-in-2023.pdf/) and [2023 model-file archive](https://www.pcouncil.org/documents/canary-rockfish-2023-model-files-zip-file/) are cached locally under `source_cache/discovery_noaa_canary_2023/`. Their retrieval dates and SHA-256 checksums are in the gitignored `sources.csv` manifest. The NOAA repository PDF download was inaccessible, so the report was cached from the Pacific Fishery Management Council copy.

## Native inputs

The archive's `data.ss` contains 1,965 annual catch records for 15 fishery fleets from 1892–2022. Catch is total removals (landings plus dead discards), in metric tonnes; `catch_se` is 0.05. There is no observed catch-at-age input series.

There are 178 aggregate index observations in the native file. Unit code 1 denotes a relative biomass index whose multiplier is not stated; code 32 is the standardized pre-recruit catch-per-tow index. Both use SS3 lognormal error type 0, and the input log-scale standard errors are retained. Fleets 16–27 are legacy entries not used in the 2023 base assessment; fleets 28–31 are the active adult and pre-recruit series. Index rows are coded to month 7. The stored sampling-time value of 0.5 follows the model's `(month - 1) / 12` convention; it is not an average of actual survey dates.

The archive also contains 606 length-composition records for 1968–2022, with 2 cm bins labelled 12–66, and 3,829 age-composition records for 1980–2022, with bins 1–35 and ageing-error codes 1–8. Some age records are conditional age-at-length observations; their length limits are data-bin indices under `Lbin_method=2`, not lengths in centimetres. Negative signed years identify provisional rows excluded from the likelihood. Negative signed fleet IDs retain expected values but exclude the composition from the likelihood. Sex code 3 carries one joint observation with separate female and male frequency vectors; the repeated sample size must not be added across those rows. Frequency values are preserved as supplied without normalization.

These composition samples are likelihood inputs, not catch-at-age or standardized age-specific survey indices. Catch numbers-at-age and survey indices-at-age could be approximated from source totals, composition information, and model-generated weights, but no such derived observations are included in the canonical import. In particular, survey age compositions are conditional at length. No unsupported scaling or missing age values are supplied.

## Model assumptions and reported outputs

The model is annual, coastwide, and sex-specific. The report surfaces contain morphs 1 and 2, which align with sexes 1 and 2 in the exported biological and mortality tables. Female natural mortality is estimated at 0.0779404 per year; male natural mortality is fixed at 0.0643 per year. Maturity is a fixed age-logistic function, with female Mat50 10.87 and slope −0.688. Weight-at-age and maturity-at-age in the database are model-generated outputs, not observed biological input series.

The native `Report.sso` provides N, biomass, M, fleet-specific F, and model-estimated dead catch numbers at age. Its age columns 0–40 are retained as printed; the age-composition input bins 1–35 are not expanded to match them. Annual outputs include total biomass (`Bio_all`), summary biomass age 5+ (`Bio_smry`), spawning output (`SpawnBio`, million eggs), and age-0 recruitment (`Recruit_0`, thousand fish). Total abundance is derived by summing reported N-at-age across sexes and ages; no uncertainty is assigned to that derived total.

The assessment reports 95% intervals for recruitment in Table iii (2013–2023) and 2023 spawning output in Table v. Spawning output is not SSB. The native report does not provide age-specific uncertainty intervals, and the archived `derived_posteriors.sso` is a single estimate rather than posterior draws. Those values remain unavailable.

The source record is therefore partial for tinyAM inputs: aggregate catches, aggregate indices, and composition samples are available, but direct observed catch-at-age, direct survey index-at-age, standalone observed weight-at-age, and numerical maturity-at-age inputs are not. The import retains these distinctions and the official fitted surfaces without claiming that the original likelihood has been reproduced.

## References

- [NOAA assessment record](https://repository.library.noaa.gov/view/noaa/72904)
- [2023 Canary Rockfish assessment PDF](https://www.pcouncil.org/documents/2024/02/status-of-canary-rockfish-sebastes-pinniger-along-the-u-s-west-coast-in-2023.pdf/)
- [2023 Stock Synthesis model-file archive](https://www.pcouncil.org/documents/canary-rockfish-2023-model-files-zip-file/)
- [Stock Synthesis 3.30 user manual](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html), for signed-year/fleet and age-composition conventions.

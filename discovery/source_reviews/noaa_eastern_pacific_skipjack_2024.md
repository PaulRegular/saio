# NOAA Stock SMART 10160: Eastern Pacific skipjack, 2024

Reviewed 2026-10-29. The NOAA inventory entry corresponds to the IATTC 2024
benchmark assessment of eastern Pacific skipjack tuna (*Katsuwonus pelamis*).
Stock SMART records the IATTC as lead laboratory, identifies the assessment as
fully accepted, and reports data through 2023. The official report treats the
EPO as one stock for assessment and management. No matching canonical tinyAM
stock record was found.

## Assessment and observations

The benchmark is a quarterly Stock Synthesis 3.30.22 beta model for 2006–2023.
It has 21 modeled age classes (0 through 20+ quarters), a 1-cm population
length grid from 2 to 110 cm, and combines sexes. These are model dimensions,
not observations at age: the report says reliable aging is unavailable and
ages fish by assuming a growth relationship, including that 37-cm fish are
two quarters old.

The assessment fits quarterly catch estimates for fisheries and length
compositions. Purse-seine composition classes use 1-cm bins from 20 to 100+
cm; longline compositions use 5-cm bins from 40 to 100+ cm. No catch-at-age or
age-composition likelihood is reported, and the report explains that absolute
age is not needed for the model's length-based population processes. Catch
and size information therefore cannot be converted to observed catch-at-age
without imposing an unsupported age-length reconstruction.

Five aggregate abundance/biomass indices were considered. The reference model
uses a relative-abundance index from echosounder buoys and one tag-recapture
absolute biomass estimate (2020 quarter 2, CV 0.3); the other indices are not
used in the reference model. The indices and their associated length
compositions are not age-specific.

Growth is estimated with a growth-cessation model informed by tagging and
length compositions. Weight-at-age is derived from mean length-at-age and the
length-weight relationship `5.53e-6 * L^3.336`. M is specified by length using
Hampton (2000), with interpolation between length-class midpoints and a
constant value above 65 cm. Maturity and batch fecundity are specified as
length relationships, with maturity taken from the central EPO area. These
biological schedules are not observed age-specific input series.

The report presents model-derived quarterly recruitment with 95% confidence
intervals, spawning biomass and spawning-biomass ratios, and an exploitation
rate proxy based on catch divided by biomass of fish aged two quarters and
older. The NOAA Stock SMART summary reports terminal 2023 SSB of 17,809 metric
tonnes. These outputs establish that official population estimates are
available, but do not supply the age-disaggregated observations required by
the current candidate screen.

## Screening decision

This unit is **ineligible** for the current age-disaggregated input set. The
2024 assessment is age-structured internally, but its fitted observations are
catch, aggregate abundance/biomass indices and length compositions. It has no
observed catch-at-age, age composition or age-specific survey series. Age
states, weights and biological schedules derived through assumed growth do
not substitute for age-based observations.

The official generated Stock Synthesis output website links run inputs and
outputs but states that the files and derivative content may not be publicly
redistributed without IATTC permission. That restricted material was not
cached. The public report and NOAA summary are cached or linked below. No
assessment event or numerical input/output record was added to the canonical
database; import status remains `not_started`.

## Sources

- [IATTC SAC-15-04: Skipjack tuna benchmark assessment 2024](https://www.iattc.org/GetAttachment/f57dece1-81ba-4771-8fa8-3362320a368a/SAC-15-04_Skipjack-tuna-benchmark-assessment-2024.pdf)
- [IATTC generated Stock Synthesis output page](https://www.iattc.org/StockAssessments/2024/SKJWebsite/plots/_SS_output.html) — run files are linked here; redistribution notice recorded above.
- [IATTC SAC-15 meeting page](https://www.iattc.org/en-US/Event/DetailMeeting/Meeting-SAC-15) — assessment document and meeting record.
- [NOAA Pacific skipjack status](https://www.fisheries.noaa.gov/species/pacific-skipjack-tuna/seafood) — identifies the EPO as assessed in 2024.
- [NOAA Stock SMART](https://apps-st.fisheries.noaa.gov/stocksmart) — inventory ID 10160 and assessment summary.

The IATTC report PDF is stored in the gitignored
`source_cache/discovery_iattc_eastern_skipjack_2024/`; `sources.csv` records its
retrieval date, URL and SHA-256 checksum. The IATTC-native run files were not
downloaded or redistributed.

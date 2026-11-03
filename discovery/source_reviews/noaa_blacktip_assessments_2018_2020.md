# NOAA Atlantic and Gulf blacktip shark source screen

The NOAA Stock SMART snapshot identifies two separate U.S. assessment units for *Carcharhinus limbatus*: Atlantic (NOAA stock 11026) and Gulf of Mexico (NOAA stock 11027). The source documents and assessment histories keep these units distinct. The older Atlantic/Gulf large coastal shark complex is a different, aggregate management record and is not crosswalked to either unit.

## Latest detailed official runs located

- **Atlantic:** NOAA Stock SMART records the SEDAR 65 assessment as fully accepted, with assessment year 2021 and data through 2018. SEDAR's final report is dated 2020 and describes the accepted Stock Synthesis base model. The model is age structured, but fits catch, aggregate CPUE indices, length compositions, and life-history biology. Composition input is length in 5-cm fork-length bins; the report does not document a catch-at-age likelihood or an age-specific abundance index.
- **Gulf of Mexico:** NOAA Stock SMART records the fully accepted 2018 full update to SEDAR 29 with data through 2016. The September 2018 addendum re-ran the scenarios after new calibrated MRIP recreational catch estimates. The state-space age-structured production model has abundance-at-age outputs and age-specific biological schedules, but the report explicitly says age-composition observations were unavailable and length compositions were used to develop selectivity outside the model. The fitted observations are catch and aggregate relative-abundance indices.

## Eligibility decision

Both units are **ineligible for the age-disaggregated source-curation set** under the inventory screen. Their model structures and age-specific outputs do not supply age-specific observation inputs. Length compositions alone do not meet the stated age-input criterion. The two NOAA inventory rows remain separately linked to candidate units, with no canonical stock or assessment records created and no tinyAM translation attempted.

This decision does not claim that no age, weight, maturity, or mortality biology exists. The assessments use age-specific life-history information: Atlantic blacktip fixes sex- and age-specific natural mortality and derives maturity/pup production from biology; Gulf blacktip reports age-specific natural mortality, maternity/fecundity and weight-at-age schedules. Those are model assumptions, not age-specific observed catch or survey likelihoods.

## Sources and provenance

- NOAA Stock SMART snapshot, pinned revision `664c4237e26520b260a090e1821a2cee5d1cdf07`, retrieved 2026-10-28; candidate rows 11026 and 11027.
- [SEDAR 65 HMS Atlantic Blacktip Shark final assessment](https://sedarweb.org/documents/sedar-65-hms-atlantic-blacktip-shark-final-stock-assessment-report/), including Sections II and III and Appendix 1 on length frequencies. The model configuration identifies catch, CPUE, length compositions and life history; age-specific natural mortality is fixed from life-history methods.
- [SEDAR 29 Gulf of Mexico Blacktip Shark 2018 update](https://sedarweb.org/documents/2018-update-sedar-29-hms-gulf-of-mexico-blacktip-shark/) and [September 2018 addendum](https://sedarweb.org/documents/addendum-to-2018-update-to-sedar-29-hms-gulf-of-mexico-blacktip-shark/). The update states age-composition data were unavailable and length compositions were not directly input to the model; the addendum documents reruns using revised MRIP recreational catch estimates.
- Detailed PDFs and retrieval metadata are stored locally under `source_cache/discovery_noaa_blacktip_2026/` (gitignored).

**Review date:** 2026-11-02
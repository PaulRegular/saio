# U.S. Pacific Coast petrale sole: discovery review

## Assessment year and stock identity

NOAA Stock SMART identifies stock 10011 as petrale sole on the U.S. Pacific Coast. It is distinct from the Canadian British Columbia unit in the canonical database.

The 2023 PFMC benchmark is the latest completed full assessment located. The 2025 PFMC document is a catch-only projection, not an updated age-structured assessment. A June 2026 PFMC planning document still describes the 2023 benchmark as the current assessment and places an update in a later cycle. Use the 2023 run for source curation; do not treat the projection as a replacement assessment.

## Native inputs and outputs

The public 2023 archive includes petrale_data.ss, petrale_control.ss, starter, forecast and fitted output files. Stock Synthesis 3.30.21.00 models data through 2022 with two sexes and population age bins through 40. It has North and South commercial fleets plus Triennial and WCGBTS survey fleets. Commercial age-frequency observations and annual fleet catches support a documented reconstruction of catch numbers-at-age; the native model fits compositions rather than direct catch-at-age observations.

The two trawl surveys provide aggregate abundance indices. WCGBTS length and age samples support an approximate age split, including marginal survey age compositions retained for display but not fitted. The report states that the Triennial survey has no age data, so do not create an age-specific Triennial index. Survey index records use month 7, and the fleet timing code is 1007; preserve this source convention and document any translation to fractional-year timing.

The model estimates sex-specific growth and natural mortality, with meta-analytical M priors. The report specifies externally estimated sex-specific length-weight relationships and a female maturity schedule; age-specific weights and maturity require documented derivation through growth. The fitted Report.sso includes numbers-at-age, fishing mortality-at-age, catch-at-age and natural mortality. The terminal 2023 spawning-output estimate is 7.68553 trillion eggs, matching the report's rounded 7.686; it is not SSB in tonnes.

The 2023 source report, model archive and 2025 projection are cached under source_cache/discovery_noaa_petrale_10011/. The 2026 PFMC planning PDF is cached in the same folder. URLs, retrieval dates and SHA-256 checksums are recorded in sources.csv.

## Screening decision

NOAA:10011 is eligible for source curation and a translation attempt. The official archive supports catch-at-age reconstruction from catches and fishery age compositions, and an approximate WCGBTS age split from survey compositions and its aggregate index. Triennial age-specific indices are unavailable. Age weights and maturity require derivation from official model biology. These are explicit transformations, not direct inputs or proof of an equivalent likelihood.

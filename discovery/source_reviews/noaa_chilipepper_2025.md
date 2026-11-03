# US coastwide chilipepper rockfish: discovery review

## Current stock identity

The 2025 assessment models *Sebastes goodei* as one population in US waters from the US-Mexico border to the US-Canada border, covering California, Oregon and Washington. Stock SMART identifies the current Pacific Coast entry as NOAA:17357. The canonical database has no *S. goodei* record.

Stock SMART also lists NOAA:10395 as Chilipepper - Southern Pacific Coast, with 2017 as its latest assessment. The assessment report describes earlier southern and Oregon assessment boundaries, followed by a 2025 coastwide assessment. The report does not provide a formal crosswalk between the two Stock SMART identifiers. Treat 10395 as a historical boundary entry, not a separate current stock candidate; retain its identity relation as unresolved rather than counting it again.

## Evidence from the 2025 assessment

The official report and PFMC model archive identify Stock Synthesis 3.30.23.1, model years 1875-2024, two sexes and ages 0-35+. The native data file contains annual catches for eight fishery fleets, in metric tonnes, plus four fishery-independent series. The two trawl surveys have biomass indices and age/length samples; CalCOFI supplies a spawning-output index and RREAS supplies a young-of-year recruitment index.

The model uses length compositions and conditional age-at-length (CAAL) data. The report explicitly says all age data are modeled conditional on length. Fishery totals, catch-expanded length compositions and CAAL samples provide quantities from which a catch-at-age series can be constructed, but the assessment does not supply catch-at-age directly. The two trawl surveys' length and CAAL samples similarly permit an approximate age split of their aggregate indices; they are not observed age-specific abundance indices. These transformations must preserve the native compositions and be documented downstream.

The model does not use empirical weight-at-age input. Growth is estimated, weight-at-length is specified, and the model reports derived biology and weight-at-age. The assessment reuses the 2015 female maturity-at-length relationship; a maturity-at-age surface therefore requires conversion using growth. Female M is informed by a lognormal prior with median 5.4/Amax and log-scale SD 0.31; male M is estimated as an exponential offset without an explicit prior. Native report output includes natural mortality by age and sex. Survey and composition records are marked July (month 7); retain that source timing and document its conversion to tinyAM's timing scale.

The archive includes Chili_2025.dat, Chili_2025.ctl and Report.sso. Report.sso enables numbers-at-age, F-at-age, catch-at-age, natural mortality, and other fitted output tables. Its run date is 2026-02-02, terminal model year 2024, and its 2025 spawning-output estimate is 9,924.9 billion eggs, matching the published report's rounded 9,925. This verifies the association of the archive with the published assessment on a key value; cross-check the requested annual surfaces against the report before importing them. Spawning output is in eggs, not SSB in tonnes.

## Screening decision

NOAA:17357 is eligible for source curation and a translation attempt. Catch-at-age and age-split trawl indices require documented reconstruction from the native catch, length and CAAL observations; weights and maturity at age require documented derivation from official model biology. This eligibility records source readiness, not direct equivalence to the official likelihood or a claim that tinyAM can reproduce the assessment. NOAA:10395 is excluded as a separate current stock entry because the 2025 assessment represents the present coastwide unit; the exact identifier crosswalk remains undocumented.

The report, PFMC model archive, and regional assessment listing are cached under source_cache/discovery_noaa_chilipepper_2025/. Their URLs, retrieval date and SHA-256 checksums are in sources.csv. The archive checksum is 2365BFF1D8657734DD9A0AFC70AE9938FED03009D679D8A87AACBF069915AADC.

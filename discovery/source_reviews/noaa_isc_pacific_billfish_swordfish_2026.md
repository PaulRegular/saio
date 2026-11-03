# Pacific swordfish and marlin candidates

**Review date:** 2026-11-02
**Scope:** NOAA Stock SMART candidates 11642, 11643, 11692, and 11706.

## Stock identity and assessment run

NOAA Fisheries currently lists two managed swordfish stocks: Western and Central North Pacific (WCNPO), last assessed in 2023, and Eastern Pacific, last assessed in 2014. Keep those inventory units distinct. The 2023 ISC North Pacific swordfish model uses a broader assessment area, with WCNPO and the IATTC area north of 10°N represented as fleet/area components. The 2014 EPO assessment defines a separate EPO production-model unit. These boundaries are not identical, so the two NOAA inventory rows should not be merged on the basis of the shared species or adjacent areas alone.

The ISC 2023 WCNPO striped marlin assessment remains the basis of the current ISC26 stock-status advice. Its assessment period is 1977–2020. The Pacific blue marlin candidate's Stock SMART row is stale: ISC completed a new pan-Pacific assessment in 2026 through 2024, superseding the 2021 run listed by Stock SMART.

No matching canonical tinyAM stock was found for these four NOAA assessment units.

## Inputs and outputs

| Candidate | Latest detailed run | Inputs used | Reported outputs | Screen |
|---|---|---|---|---|
| NOAA:11642 WCNPO swordfish | ISC 2023, data through 2021 | Fleet catches, standardized fishery CPUE, and quarterly length compositions in 5-cm bins. The age- and length-structured Stock Synthesis model does not use catch-at-age, population age compositions, or age-specific abundance indices. | Age-1+ population biomass, spawning biomass, recruitment at age 0, and average F for ages 1–10. No annual N-at-age or F-at-age surface was identified in the report. | Ineligible |
| NOAA:11643 Eastern Pacific swordfish | ISC 2014, data through 2012 | Bayesian state-space surplus-production model using catches and standardized CPUE. It is not an age-structured model and does not use age-disaggregated observations. | Exploitable biomass and harvest rate with uncertainty, not N-at-age, F-at-age, or recruitment-at-age. | Ineligible |
| NOAA:11692 WCNPO striped marlin | ISC 2023, data through 2020 | Fleet catches, standardized CPUE, and length/size compositions. The age- and length-structured Stock Synthesis model does not use catch-at-age, population age compositions, or age-specific abundance indices. | Age-1+ biomass, spawning biomass, recruitment at age 0, and average F for ages 3–12. No annual N-at-age or F-at-age surface was identified in the report. | Ineligible |
| NOAA:11706 Pacific blue marlin | ISC 2026, data through 2024 | Fleet catches, standardized CPUE, and length or weight size compositions. The age-structured Stock Synthesis model does not use catch-at-age, population age compositions, or age-specific abundance indices. | Age-1+ biomass, female spawning biomass, recruitment at age 0, and fishing mortality. No annual N-at-age or F-at-age surface was identified in the report. | Ineligible |

Age-structured model states and age-specific life-history parameters are not evidence of observed age-disaggregated inputs. These four assessments rely on length/size compositions or aggregate production-model inputs, so they do not meet the source-screening requirements for age-structured tinyAM candidates. Their official aggregate outputs remain useful for understanding assessment coverage but do not change that input decision.

The reports describe life-history information and mortality assumptions used by their models, but the reviewed assessment inputs do not provide the required run-matched catch numbers-at-age or age-specific survey observations. The fishery CPUE indices are not independent survey indices with a within-year survey timing. No canonical assessment, input, or output records were created, and no tinyAM translation was attempted.

## Cached sources

The four assessment PDFs are stored in the ignored local source cache at `source_cache/discovery_noaa_pacific_billfish_2026/`. Its `sources.csv` records the source URLs, retrieval date, byte counts, checksums, and assessment revision.

## Sources

- [NOAA North Pacific swordfish stock status](https://www.fisheries.noaa.gov/species/north-pacific-swordfish/seafood)
- [ISC 2023 North Pacific swordfish assessment](https://isc.fra.go.jp/pdf/ISC23/ISC23_ANNEX11-Stock_Assessment_Report_for_North_Pacific_Ocean_Swordfish_FINAL.pdf)
- [ISC 2014 North Pacific swordfish assessment](https://isc.fra.go.jp/pdf/ISC14/Annex9-NP_Swordfish_Stock_Assessment_2014.pdf)
- [ISC 2023 WCNPO striped marlin assessment](https://meetings.wcpfc.int/system/files/2023-08/SC19-SA-WP-11%20ISC23%20ANNEX%2014%20-%20Stock%20Assessment%20Report%20for%20WCNPO%20Striped%20Marlin%20-%20FINAL.pdf)
- [ISC 2026 Pacific blue marlin assessment](https://www.isc.fra.go.jp/pdf/ISC26/ISC26_ANNEX_09_Stock_Assessment_Report_for_Blue_Marlin_in_the_Pacific_Ocean.pdf)
- [ISC26 swordfish advice](https://isc.fra.go.jp/recommendation/isc26/isc26_swordfish.html)
- [ISC26 striped marlin advice](https://isc.fra.go.jp/recommendation/isc26/isc26_stripedmarlin.html)
- [ISC26 Pacific blue marlin advice](https://isc.fra.go.jp/recommendation/isc26/isc26_bluemarlin.html)

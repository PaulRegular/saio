# ICES salmon, anglerfish, and thresher screens

Review date: 2026-11-01. The inventory uses the 2026 ICES stock list. These screens update only the discovery register; they add no canonical stock, assessment, input, or output records.

## Atlantic salmon: NAC, NEAC, and WGC

The latest detailed assessment located is the [2026 ICES Working Group on North Atlantic Salmon (WGNAS) report](https://iceslibrary.figshare.com/articles/report/Working_Group_on_North_Atlantic_Salmon_WGNAS_/32034120) (DOI 10.17895/ices.pub.32034120.v1), with supporting online tables. It covers the 2025 status year and uses a joint stage-based life-cycle assessment across North Atlantic stock units.

The tables report catches by sea age, including 1SW and 2SW, for 1980-2025, and regional returns, spawners, pre-fishery abundance, and related quantities. The model uses 2SW as a proxy for all multi-sea-winter fish. Outputs include medians and 5th/95th percentiles; return/spawner tables extend through 2025, NAC PFA through 2024, and NEAC PFA tables include forecasts beyond the observed period. The NAC biological summary reports sex proportions and eggs per female by 1SW/MSW. WGC fishery tables report sea-age/origin composition and sample weights/fork lengths. Translation readiness remains separate.

sal.nac.all and sal.neac.all are eligible for source curation based on age/stage-resolved inputs and official population outputs, but share one candidate unit so the joint assessment is counted once. No exact canonical stock match was found. sal.wgc.all is the West Greenland mixed-stock fishery affecting NAC and NEAC populations; it is identity-ambiguous and excluded as an independent stock.

Current sources are cached under the gitignored source_cache/discovery_ices_remaining_units_2026/. sources.csv records URLs, retrieval dates, sizes, DOI where available, and SHA-256. The 2025 WGNAS report and advice are retained as historical material, superseded by 2026.

## Anglerfish: anf.27.1-2

The latest Norwegian assessment located for advice in 2026 is the Institute of Marine Research report [HI kvoteråd 2026 - Breiflabb nord for 62°N](https://www.hi.no/hi/nettrapporter/rapport-fra-havforskningen-2025-79), published as Report 2025-79 and using data through mid-October 2025. It identifies JABBA, a surplus-production model using commercial landings and Coastal Reference Fleet CPUE. It provides aggregate relative biomass and fishing-pressure summaries, not age-specific inputs or population outputs. The candidate is new to the canonical database but ineligible for age-disaggregated source curation.

## Thresher shark: thr.27.nea

The ICES 2026 stock-list record describes an Alopias spp. Northeast Atlantic grouping last assessed in 2023 (category 6.3). The reviewed [2023 WGEF report](https://iceslibrary.figshare.com/articles/report/Report_of_the_Working_Group_on_Elasmobranch_Fishes_WGEF_/24190332) and [2024 WGEF report](https://iceslibrary.figshare.com/articles/report/Report_of_the_Working_Group_on_Elasmobranch_Fishes_WGEF_/26935504) describe irregular, unreliable catches and no quantitative age-structured assessment for the grouping. No age-specific inputs or N/F/M-at-age outputs were identified. It is a new, screened ineligible candidate; no canonical record was added.

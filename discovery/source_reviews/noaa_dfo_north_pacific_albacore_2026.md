# North Pacific albacore: NOAA/DFO cross-agency review

## Identity and current assessment

NOAA Stock SMART ID 11682 (`Thunnus alalunga`, Albacore - North Pacific) and the DFO Pacific Sustainability Survey entry (`Albacore Tuna - North Pacific`) refer to the same shared North Pacific stock assessed by the International Scientific Committee for Tuna and Tuna-like Species (ISC). The 2026 ISC assessment defines one stock from the equator to 55 degrees N, between 120 degrees E and 100 degrees W. Canada is an ISC member and contributed fishery data. Neither agency row maps to a separate canonical tinyAM stock yet; both are grouped under the provisional discovery unit `north_pacific_albacore`, counted as one potential stock unit.

The current production run is the ISC 2026 benchmark (ISC/26/ANNEX/08), using data through 2024 and Stock Synthesis 3.30.24. It supersedes the 2023 assessment. NOAA Stock SMART's inventory snapshot still lists assessment year 2023, and DFO's 2025-26 tuna plan also predates the 2026 assessment; neither inventory date is treated as current-run evidence. The ISC report says the base model converged with a final gradient of 2.723e-04, after 50 runs from different starting values because the likelihood surface was bumpy. The report concludes the base case likely reached a global minimum.

## Observations and biological assumptions

The official model is a quarterly, age- and sex-structured Stock Synthesis model. It fits three observation types: fishery-specific catch, relative abundance, and length compositions. Fleet catch is compiled by calendar year and quarter for 1994-2024 in original units of metric tonnes or thousands of fish. The base case fits one relative abundance index: standardized Japanese longline CPUE, Area 2, Quarter 2 (F10), for 1996-2024. This is a fishery index rather than a survey. Length compositions are fitted for selected fisheries, with fleet-specific sample-size multipliers and several mirrored selectivities.

The base-case observation data are not age-disaggregated: no fishery catch-at-age or age-composition likelihood and no age-specific abundance index are reported. Model-derived catch-at-age is not an observed catch input. The assessment's publicly available numerical report and figures cannot turn length compositions into observed age compositions without source-supported age-length sampling arrays. ISC's assessment-data page says access to stock assessment data files requires a non-disclosure agreement; no native run data bundle was found in the reviewed public material. Therefore this stock is screened **ineligible for the current age-disaggregated tinyAM translation set**, while remaining a well-documented age-structured assessment for source inventory purposes.

Important fixed biology includes sex-specific growth, non-sex-specific seasonal weight-at-length, a female maturity schedule of 50% at age 5 and 100% at ages 6+, and fixed age- and sex-specific natural mortality. M follows a Lorenzen size-based schedule through ages 0-2 and is 0.38 per year for males and 0.49 for females from age 3. Spawning and recruitment are placed in Quarter 2 (April-June). The single fitted F10 index also represents Quarter 2; no survey timing applies to it.

## Reported outputs and remaining source work

The report provides numeric annual estimates through 2024 for age-1+ biomass, female spawning biomass, recruitment, and fishing intensity, with uncertainty for the main aggregate quantities. It plots historical catch-at-age and sex-specific F-at-age, but machine-readable age-specific trajectories were not found. N-at-age is an internal model quantity used in projections; the reviewed public report does not provide a numeric historical N-at-age table. The report is cached locally for follow-up extraction, but source observations remain unavailable as open model files. No canonical numerical records are added by this discovery screen.

This screening result concerns the current tinyAM age-input criteria, not whether the ISC assessment is age-structured or whether a future data-access agreement could provide additional inputs. If the underlying composition data become public, revisit age-specific source eligibility without mixing 2023 and 2026 runs.

## Sources

- [ISC 2026 North Pacific albacore assessment, Annex 8](https://www.isc.fra.go.jp/pdf/ISC26/ISC26_ANNEX_08-Stock_Assessment_Report_for_Albacore_Tuna_in_the_North_Pacific_Ocean_v1.pdf)
- [ISC stock assessment reports and data-file access note](https://isc.fra.go.jp/reports/stock_assessments.html)
- [NOAA Stock SMART](https://www.fisheries.noaa.gov/resource/tool-app/stock-smart)
- [DFO Pacific Tuna 2025-26 IFMP summary](https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/tuna-thon-ifmp-pgip-sm-eng.html)
- [IATTC 2026 assessment executive summary](https://www.iattc.org/GetAttachment/a10c525a-36ad-451b-b0fc-f52c532b0281/SAC-17-INF-I_ISC_ALBWG_2026_NPALB_StockAssessment_Executive_Summary_IATTC_SAC_DRAFT-EN.pdf)

The 2026 ISC Annex PDF and checksum manifest are cached under `source_cache/discovery_north_pacific_albacore/`.

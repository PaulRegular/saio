# NOAA Atlantic bluefish — 2025 management-track assessment

## Assessment and sources

NOAA Stock SMART identifies assessment 13933 as the 2025 Atlantic Coast bluefish management-track run, with data through 2024. The June 2025 peer-review panel concluded that the assessment met its terms of reference and represented the best scientific information available. The assessment updates the 2022 research-track WHAM model and the 2023 management-track update.

The source cache is under source_cache/discovery_noaa_bluefish_2025/. The tracked manifest in provenance/discovery_noaa_bluefish_2025/sources.csv records source URLs, retrieval dates, revisions, file sizes, and SHA-256 hashes. The 2025 and 2022 archive-container checksums changed when re-downloaded on 2026-11-11 UTC; the cited report and working-paper files extracted from them retain the previously recorded member hashes.

Sources:

- NOAA, [2025 Atlantic Bluefish SASINF assessment bundle](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2025&species_id=32&stock_id=6&review_type_id=2&filename=2025_BLF_UNIT.zip), including the report, input figures, fitted-results figures, and WHAM tables.
- NOAA, [June 2025 management-track peer-review panel report](https://www.fisheries.noaa.gov/s3/2025-07/2025-June-Management-Track-Peer-Review-Panel-Report-508.pdf).
- NOAA, [2022 Bluefish Research Track SASINF archive, part 1](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=32&stock_id=6&review_type_id=5&filename=2022_BLF_UNIT_1.zip), including the assessment report and working papers on natural mortality and fishery inputs.
- NOAA, [2022 Bluefish Research Track SASINF archive, part 2](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2022&species_id=32&stock_id=6&review_type_id=5&filename=2022_BLF_UNIT_2.zip).
- NOAA, [2023 independent peer-review report](https://www.st.nmfs.noaa.gov/Assets/Quality-Assurance/documents/peer-review-reports/2023/2023_04_Medley_Bluefish_%26_Spiny_Dogfish_Review_Report.pdf).

## Inputs recovered

The 2025 report's Table 1 reports commercial and recreational landings and discards in metric tonnes for 2015–2024. Those four published component series were imported as catch-biomass inputs. Their sums agree with the report's “Catch for Assessment” totals within 1 tonne, consistent with rounding. They are not catch-at-age observations, and the full historical catch series was not recovered from the current-run bundle.

The current-run input PDF shows fishery and survey age compositions for ages 0–5 and 6+ as bubble plots. It does not provide numeric composition cells or sample sizes. Nine aggregate index series are plotted on rescaled axes; numeric index values and the scaling needed to recover them are not provided. The report also plots annual stock-, fleet-, and survey-specific weight-at-age and maturity-at-age, but does not tabulate their numeric current-run arrays. These plotted values were not digitized or inferred.

The 2022 research-track working paper documents an age-varying Lorenzen weight-based natural-mortality method. The 2025 report says projections use five-year averages of natural mortality, maturity, selectivity, and weights-at-age. The 2025 archive does not provide the fitted current-run M-at-age vector or WHAM model code, so the 2022 values were not substituted.

The available input figures and report do not establish exact fractional survey timing or current-run likelihood weights. These remain unresolved.

## Outputs recovered

The 2025 SASINF WHAM tables report:

- Table 2: abundance-at-age for 1985–2024, ages 0–5 and 6+, in thousands of fish.
- Table 3: total fishing mortality-at-age for 1985–2024, ages 0–5 and 6+.
- Tables 4–5: commercial and recreational fishing mortality-at-age for the same years and age groups.
- Report Table 1: SSB, fully selected fishing mortality, and age-0 recruitment for 2015–2024. SSB is in metric tonnes and recruitment is in thousands of fish.

The annual age-specific tables do not report standard errors or confidence intervals. The selected 2015–2024 summary series also have no annual intervals in Table 1. Numeric SSB and recruitment for years before 2015, and the fitted current-run M-at-age surface, remain unavailable as tables.

Table 1 in the cached WHAM parameter tables was subsequently imported as 66 fitted-parameter outputs. The import retains the reported estimate, standard error, and 95% confidence limits, including fully selected q, process parameters, and estimated selectivity parameters. Fixed entries without reported uncertainty are omitted. Parameter values remain on the source-reported scale; scientific notation for q is stored as its equivalent decimal. The table does not state parameter units, so outputs are labeled with the native parameter scale. This adds parameter uncertainty but does not supply annual uncertainty for N-at-age or F-at-age.

The record is partial: current-run catch-at-age, index values, numeric age compositions and sample sizes, biological arrays, exact survey timing, M-at-age, and annual uncertainty for N/F-at-age were not recoverable from the reviewed public files.

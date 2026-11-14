# China rockfish, U.S. Pacific Coast (2015)

Review date: 2026-11-13.

The 2015 PFMC assessment contains three independent Stock Synthesis models: northern Washington, central Oregon and California north of 40°10′ N, and southern California south of 40°10′ N. The 2025 Pacific Coast Groundfish SAFE still identifies the 2015 assessment as the latest full assessment for these areas. The 2019 Stock SMART label refers to a catch-only projection based on the 2015 model, not a newer full assessment.

## Inputs and assumptions captured

The assessment report reproduces the area-specific native Stock Synthesis data files in Appendix A. This import captures annual catch biomass by source fleet for 1900–2014, preserving the model's structural zeroes and metric-ton units. The models use annual time steps, two model genders, ages 0–80, mid-year fleet timing, and fixed natural mortality of 0.07 per year. The selected base models do not estimate recruitment deviations.

The report also documents fishery-dependent abundance indices, length and age-composition data, growth and weight-length relationships, and maturity-at-length information. These are not fully imported here. The import does not convert composition samples into annual catch-at-age or index-at-age and does not infer standalone annual weights or maturity schedules. The native model's central-area data file includes 11 fishery fleets and one additional survey/index fleet; only the catch block is imported.

## Outputs captured and limitations

Tables 43–45 provide area-specific annual total biomass, spawning biomass, depletion, age-0 recruitment, total catch, relative exploitation rate, and spawning-potential ratio for 1900–2014. Their 2015 row reports total biomass, spawning biomass, depletion and age-0 recruitment as forecasts. Biomass and catch are metric tons; age-0 recruitment is thousands of fish. The 2015 area reference tables (k–m) provide confidence intervals for depletion and spawning output. Spawning output is retained in billions of eggs and is distinct from spawning biomass in metric tons.

The table's “relative exploitation rate” is retained under its reported label because the extraction did not establish its calculation. The imported tables do not provide annual N-at-age, F-at-age or M-at-age surfaces, nor annual uncertainty for the time series. All three assessment records therefore remain partial.

## Sources

- [2015 China rockfish assessment and Appendices A–D](https://www.pcouncil.org/documents/2016/04/status-of-china-rockfish-off-the-u-s-pacific-coast-in-2015-april-2016.pdf)
- [2025 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2024/08/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2025.pdf/)
- [2022 Pacific Coast Groundfish SAFE](https://www.pcouncil.org/documents/2022/09/status-of-the-pacific-coast-groundfish-fishery-stock-assessment-and-fishery-evaluation-july-2022.pdf/), identifying the 2019 action as a catch-only projection based on the 2015 assessment.

The detailed report, 2022 and 2025 SAFE documents, and NOAA metadata snapshot are cached under the gitignored `source_cache/discovery_noaa_china_rockfish_2019/`. Their URLs, retrieval dates, revisions, byte sizes and SHA-256 checksums are recorded in `provenance/discovery_noaa_china_rockfish_2019/sources.csv`.

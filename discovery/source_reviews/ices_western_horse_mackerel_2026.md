# Western horse mackerel: current-run source screen

## Unit and latest assessment

ICES identifies `hom.27.2a3a4a5b6a7a-ce-k8` as the western horse mackerel assessment unit in the Northeast Atlantic and adjacent waters. The 2026 ICES advice uses assessment key 25892 and was released on 30 September 2026. It advises a 2027 catch of no more than 79,223 tonnes. The 2026 Stock Assessment Graphs source table reports age-0 recruitment, SSB, and total F for ages 1–10, with lower and upper bounds. It does not provide current-run N-at-age.

The code was expanded in 2024 from the previous `hom.27.2a4a5b6a7a-ce-k8` code to include Division 3.a. This is one current western horse mackerel unit; its fisheries and the component surveys are not counted as separate candidates. The existing database records southern horse mackerel in Division 9.a and North Sea horse mackerel in 4.b/4.c/7.d, which are different units.

## What the latest detailed report establishes

The detailed WGWIDE 2025 report is the latest run-specific assessment report located. It describes the 2025 update to the 2024 benchmark model, fitted with Stock Synthesis 3.30.23.2 as a single fleet, sex, and area age-based model. The 2025 update adds 2024 catch, recruitment-index, and acoustic-index data. The report does not verify the inputs or model changes used for the 2026 production assessment, so its data are not treated as current-run inputs.

| Evidence | 2025 detailed assessment |
|---|---|
| Catch-at-age | Table 7.3.4.1, 1982–2024, ages 0–15, thousands of fish; catch sampling in 2024 covered 69% of reported catch. |
| Weight-at-age | Catch weights-at-age are reported; stock weights are assumed equal to catch weights. |
| Abundance indices | The model uses four indices: total annual egg production (SSB proxy), an age-0 recruitment index (2003–2024, thousands of recruits, with CVs), a combined biomass index from spring PELACUS/PELGAS/WESPAS surveys, and standardized commercial CPUE (2017–2022; not estimated in 2023–2024). |
| Maturity | Table 7.5.1.1 gives a fixed age ogive inferred from a length-based ogive and age-length keys, ages 0–15. |
| Natural mortality | Table 7.5.2.1 gives age-specific M for ages 0–15, estimated with the Gislason relationship. |
| Outputs | Tables 7.7.3.1 and 7.7.3.2 report N-at-age (thousands) and F-at-age; Table 7.7.3.3 reports recruitment, biomass, SSB, catch, and Fbar. |

The 2025 assessment therefore demonstrates a substantial age-based input and output record for this unit. Survey timing is not one common fraction: MEGS samples January–July, PELACUS March/April, PELGAS in May, and WESPAS in June/July. The 2025 report says the 2025 egg-survey results would be used in the 2026 assessment, but no detailed 2026 report or run-matched input set was found. The 2026 source review also checked the current ICES SID and the WGWIDE GitHub repository; that repository had no assessment data or model files at retrieval.

## Decision and current-run gaps

The stock is recorded as a new, screened candidate, with eligibility unresolved for the current 2026 assessment. The prior 2025 report confirms age-at-catch, age-0 recruitment information, biological inputs, and N/F-at-age outputs, but these cannot be assumed to be the 2026 input arrays. The latest run's catch-at-age, weights, maturity, mortality, survey-index inputs, and any N/F-at-age outputs remain unverified. The current 2026 SAG output is useful but does not fill those input gaps.

Revisit when the detailed 2026 WGWIDE report or run-matched model inputs become public. No canonical assessment, input, or output rows were added, and no tinyAM translation was attempted.

## Sources

- [ICES 2026 advice, assessment key 25892](https://asd.ices.dk/viewAdvice/7226)
- [ICES 2026 Stock Assessment Graphs source data, key 25892](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=25892)
- [WGWIDE 2025 report, Western horse mackerel chapter](https://doi.org/10.17895/ices.pub.30233824.v3)
- [WKBHMB 2024 benchmark report](https://doi.org/10.17895/ices.pub.25002482.v2)
- [ICES Stock Information Database](https://sid.ices.dk/Default.aspx)
- [ICES WGWIDE working-group repository](https://github.com/ices-eg/wg_WGWIDE)

The 2025 chapter and current 2026 advice and source table are cached locally under `source_cache/discovery_ices_western_horse_mackerel_2026/`. `sources.csv` records retrieval dates, revisions, sizes, and SHA-256 checksums. The 2024 benchmark report is cached under `source_cache/discovery_ices_north_sea_horse_mackerel_2026/` and was inspected for model context.
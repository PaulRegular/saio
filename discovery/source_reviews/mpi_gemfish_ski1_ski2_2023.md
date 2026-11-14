# Northern gemfish (SKI 1 and SKI 2), 2023 assessment

## Assessment and stock identity

Fisheries New Zealand's 2023 full quantitative assessment treats SKI 1 and SKI 2 as one northern gemfish biological stock. The 2023 Stock Synthesis model represents one population and separates catches and selectivity by area, fishery, and season. The 2025 Fisheries Assessment Plenary still identifies the 2023 assessment as the most recent full assessment for this unit. The later assessment of southern gemfish in SKI 3 and SKI 7 is a different stock and is not combined here.

The assessment report identifies Stock Synthesis 3.30.17. The assessment year and terminal model year are 2023; model year 2023 represents the 2022/23 fishing year. The report says the 2023 catch was assumed equal to the 2022 catch.

## Sources

- Middleton, Langley, Horn, and Robertson. 2024. *The 2023 stock assessment of gemfish (Rexea solandri) in SKI 1 and SKI 2*. Fisheries New Zealand FAR 2024/45. [Report page](https://fs.fish.govt.nz/Page.aspx?dk=25773&pk=113) · [PDF](https://fs.fish.govt.nz/Doc/25773/FAR-2024-45-2023-stock-assessment-gemfish-SKI1-SKI2.pdf.ashx).
- Middleton, Robertson, Horn, and Langley. 2024. *Age composition of northern gemfish in 2012, 2014, and 2022*. Fisheries New Zealand FAR 2024/44. [PDF](https://fs.fish.govt.nz/Doc/25772/FAR-2024-44-Age-composition-northern-gemfish-2012-2014-2022.pdf.ashx).
- Fisheries Assessment Plenary, May 2025, Volume 1. [PDF](https://fs.fish.govt.nz/Doc/26039/gemfish-ski-fisheries-assessment-plenary-may-2025-volume-1.pdf.ashx).

The three PDFs are cached under `source_cache/mpi_gemfish_ski1_ski2_2023/`. Their retrieval URLs, retrieval date, and SHA-256 checksums are recorded in `provenance/mpi_gemfish_ski1_ski2_2023_sources.csv`.

## Inputs recovered

- **Commercial catch:** FAR 2024/45 Table C.1 reports catch biomass in tonnes for 1950–2023. Values are separated between SKI 1 and SKI 2, target and non-target fisheries, and two seasons. Season 1 is October–April and Season 2 is May–September. The 2023 entries repeat 2022 as an assumed terminal catch.
- **Abundance index:** Table C.2 reports 33 daily HOK-SKI target-fishery CPUE indices and standard errors for 1990–2022. This is a fishery-based abundance index, not a research-survey index. The assessment uses a lognormal likelihood and adds process error of 0.1.
- **Age composition:** Tables C.3–C.5 report 28 joint sex-and-age catch-composition observations: 16 SKI 1 target observations, 5 SKI 2 target observations, and 7 SKI 2 non-target observations. The reported age categories are 1–14 and 15+, with the final category stored as age 15 and documented as 15+. The values across both sexes form each composition and are retained as printed; small departures from one reflect table rounding. The report gives only ranges of effective sample sizes by fishery group, not the individual values.
- **Biology and model assumptions:** The base case fixes natural mortality at 0.25 per year for both sexes. It documents sex-specific growth and length–weight parameters and a female logistic maturity ogive with A50 7.2 years and width 3.5 years. A direct age-specific weight surface and complete numerical maturity vector are not tabulated.
- **Model structure:** The population has 20 age classes per sex, with age 20+ as the population plus group. The published age compositions use a 15+ category. Recruitment follows a Beverton–Holt relationship with fixed steepness 0.90; deviations are estimated for 1975–2017 and fixed to zero for 2018–2023. Composition ageing error is specified as CV 0.08.

## Outputs recovered and remaining gaps

Table 7 reports base-case MCMC medians and 95% intervals for unfished spawning biomass, 2023 spawning biomass, the 40% SB0 target, biomass ratios, and the fishing-mortality reference ratio. These values are recorded in `database/outputs.csv` with the reported definitions and units.

The report presents annual biomass, recruitment, and fishing mortality in figures, but does not tabulate their full numerical trajectories. Numeric annual N-at-age, F-at-age, and M-at-age surfaces were not recovered. No age-specific uncertainty arrays or fitted Stock Synthesis files were located in the reviewed public sources. Accordingly, inputs, assumptions, and outputs are marked partial.

## Data review decision

This is a source-ready current unit for the New Zealand wave: its detailed report publishes the catch series, an abundance index with uncertainty, the fitted age-composition vectors, key biological assumptions, and comparable terminal biomass estimates. The limitations above remain explicit in the canonical records; plotted trajectories and unsupported biological surfaces are not transcribed as numeric data.

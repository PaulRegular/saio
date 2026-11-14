# Red gurnard GUR 3: 2022 source screen

## Stock unit and current assessment

GUR 3 is the Fisheries New Zealand management unit for red gurnard (*Chelidonichthys kumu*) off the east coast of the South Island. The latest full assessment identified in the May 2026 Fisheries Assessment Plenary remains the 2022 production assessment, using data through the 2020/21 fishing year (model year 2021). The proposed 2026–27 research plan schedules an updated GUR 3 assessment for completion in 2027; it is not yet a published production run.

The 2022 assessment used Stock Synthesis 3.30.17, with an annual model from 1985–2021, two sexes, ages 1–9 and a 10+ group, and an exploited-equilibrium initial population in 1985. Catch is for the whole GUR 3 QMA, while the CPUE and Kaharoa ECSI survey indices cover FMA 3; the report estimates that about 25% of catch has been taken outside FMA 3 since 2000.

## Source data that can be preserved

- Table A3 gives annual catch biomass in tonnes for the BT-MIX and BT-FLA fisheries for model years 1985–2021. These values include the assessment's 10% allowance for commercial under-reporting. Recreational catch estimates were below 5 t and were excluded; customary catch was unavailable and excluded.
- Table A4 gives 24 base-model survey biomass observations in tonnes with survey-specific CVs: 13 winter 30–400 m observations, five summer 30–400 m observations, and six winter 10–400 m observations. It also gives six winter 10–30 m values used only by a sensitivity model that replaces the 10–400 m series. The importer preserves both the base-model series and those sensitivity-only values with their paired CVs.
- Table A5 gives female and male components of the winter 30–400 m age-composition proportions in 1992–1994, ages 1–9 and 10+. The sex components sum to approximately one together for each year; they are not separately renormalized. The model used multinomial likelihoods with ESS 20. The report does not give raw sample counts; ESS is not a raw sample size.
- Tables A6a, A6b, A7, and A8 give female and male components of the survey length-composition proportions for winter 30–400 m, winter 10–400 m, and summer 30–400 m surveys. The sex components are preserved as printed and sum to approximately one together for each year. The model used ESS 10 for these observations.
- The source importer preserves 74 catch-biomass records, 60 survey-biomass/CV records, 60 age-composition proportions, 1,932 length-composition proportions (42 sex-by-year samples across 46 length bins), and 30 fixed age-specific M/maturity values. The database input record remains partial because the CPUE values are not tabulated and commercial catch-at-age is not available.
- The model used fixed M of 0.29 y⁻¹ for females and 0.35 y⁻¹ for males; maturity of 0 at age 1, 0.5 at age 2, and 1 at ages 3+; a 50:50 sex ratio; von Bertalanffy growth parameters; and a length–weight relationship. The report provides the parameters, not a precomputed weight-at-age input series.
- Tables 14–17 provide 19 imported aggregate output summaries: MPD and MCMC biomass/F summaries, source-reported MCMC intervals, yield estimates, and 2026 projection probabilities. These are aggregate outputs; annual numerical N-at-age and F-at-age surfaces are not tabulated.

## Important gaps and screening decision

The official assessment explicitly had no commercial fishery age or length compositions. Its catch input is catch biomass, not catch numbers-at-age, and the survey age compositions cannot be used to manufacture fishery catch-at-age. The report describes 32 BT-MIX CPUE index observations for 1990–2021 at CV 0.20, but does not tabulate the numerical index series. No run-matched native Stock Synthesis input/output files were located in the reviewed public source listings. The survey age compositions and survey biomass are source-reported, but do not provide a full annual age-specific abundance series; the source also does not give a fractional-year survey timing value.

GUR 3 is selected for **partial source curation** because the report provides exact, age-disaggregated survey compositions, survey biomass, fixed biological assumptions, catch biomass, and comparable SSB/F summary outputs. The source importer records only values printed in the assessment report and leaves the input and output completeness statuses partial. The missing fishery age composition and unprinted CPUE vector prevent a complete age-disaggregated input set; they remain explicit gaps. The published output tables do not support numerical annual N-at-age or F-at-age comparisons.

## Sources and cached files

- [FAR 2022/21: A stock assessment of red gurnard in GUR 3 for 2022](https://fs.fish.govt.nz/Doc/25168/FAR-2022-21-Red-Gurnard-Stock-Assessment-GUR3-2022-4291.pdf.ashx)
- [Fisheries Assessment Plenary, May 2026, Volume 3](https://fs.fish.govt.nz/Doc/26243/Fisheries-Assessment-Plenary-May-2026-Volume-3.pdf.ashx)
- [Proposed Fisheries Research Services for 2026–27](https://www.mpi.govt.nz/dmsdocument/71944/direct)

The assessment and research-plan PDFs are cached under the ignored `source_cache/nz_red_gurnard_gur3_2022/` directory. The shared 2026 Plenary PDF is cached under `source_cache/nz_red_gurnard_gur7_2022/`. Retrieval dates and SHA-256 checksums are recorded in `provenance/mpi_red_gurnard_gur3_2022_sources.csv`.

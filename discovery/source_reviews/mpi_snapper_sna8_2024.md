# Snapper in SNA 8 — 2024 assessment

## Stock unit and current assessment

The current management stock is SNA 8, covering the west coast of New Zealand's North Island. The 2025 Fisheries Assessment Plenary identifies 2024 as the most recent assessment year. FAR 2024/49 documents the 2024 production assessment, updated with catch, composition, CPUE, and Kaharoa survey data. The assessment uses Stock Synthesis and has model year 2023 corresponding to the 2022/23 fishing year; current status outputs refer to the 2023/24 fishing year.

The assessment contains several fisheries and sampling strata, including north and south areas. These are observation and model dimensions within SNA 8, not additional stock records.

## Recoverable inputs

- **Commercial catch and age composition:** FAR 2024/49 Tables 3 and 4 summarize 27 single-trawl (BT) and 18 bottom-pair-trawl (BPT) age-composition observations. Appendices A6 and A7 provide the observed proportions-at-age and CVs. The model also uses commercial and recreational catch histories. Composition proportions are distinct from catch numbers-at-age.
- **Survey abundance:** FAR 2024/49 Table 5 reports Kaharoa trawl survey abundance estimates for ages 1+ through 4+ (model ages 2–5), in thousands of fish. Figures 23 and 36 show the age-specific time series and uncertainty. The November 2022 survey is assigned to model year 2023.
- **Other abundance data:** The assessment includes BT and BPT CPUE series and two absolute biomass estimates from 1990 and 2002 tagging programmes.
- **Weights and growth:** The assessment fixes a length-weight relationship and three time-block growth parameter sets. FAR 2024/50 reports mean weight-at-age and CVs for selected 2022–23 sampled fisheries; it does not publish a complete annual weight-at-age surface for all assessment fisheries.
- **Maturity:** The Base Case fixes a length-based logistic ogive with L50 = 35 cm, L5 = 26 cm, and L95 = 44 cm. The assessment does not tabulate a fixed age-based maturity vector.
- **Mortality and timing:** Natural mortality is fixed at 0.075 per year. The model uses an annual 1 October–30 September year, with October–January and February–September seasons; spawning occurs at the start of the year. Surveys are conducted in November, but a single within-year survey fraction is not stated.

## Reported outputs and limits

FAR 2024/49 Table 10 reports the Base_Frec median 2023–24 spawning biomass as 49,830 t (95% interval 39,807–62,665), and F2024/FSB40% as 0.999 (95% interval 0.814–1.204). It also reports the probability that current F is below FSB40%, target yield, and vulnerable biomass. Annual SSB and F trajectories are plotted, but complete annual numerical N-at-age, F-at-age, M-at-age, recruitment, and SSB series are not tabulated in this source.

The 2024 assessment and 2025 Plenary PDF are cached locally. The assessment's appendices contain recoverable age-composition values, while survey CVs and complete biological surfaces require further source review. Native Stock Synthesis input and output files have not yet been located.

## Database import

The partial canonical import records the assessment's 1931–2024 model catch history in tonnes for five fleets from Table A3. These are model catch inputs and include historical apportionments or reconstructions; they should not all be read as observed landings. It also records all 27 combined single-trawl CPUE values listed in Table A2, with the source 95% limits in row notes. Table 7 reports 26 likelihood observations, so the status of the additional listed row remains unresolved.

Table 5's nine Kaharoa survey observations are recorded for model ages 2–5 in thousands of fish. Survey calendar years are mapped to the report's model years; numerical age-specific CVs are not tabulated. The import preserves the 2022–23 north bottom-trawl age composition from FAR 2024/50 Appendix 5 as proportions, with the reported bootstrap CV and `n` fields kept separate from assessment effective sample sizes. The >29 group is represented at age 30. This is a composition sample, not catch numbers-at-age. The other commercial composition observations documented in the assessment remain to be imported.

FAR 2024/50 Appendix 8's empirical north bottom-trawl sampled-landings weights-at-age and bootstrap CVs are recorded separately. They describe the sampled catch and are not substituted for the assessment's fixed length-weight relationship or time-varying growth assumptions. The database also records the reported fixed natural mortality, growth, maturity, recruitment, likelihood and timing assumptions.

Five Base_Frec values from Table 10 are imported: current spawning biomass and its 95% interval, F relative to FSB40% and its interval, the probability that F is below FSB40%, target yield and its interval, and MPD vulnerable biomass. No uncertainty is assigned where the report does not provide it. Annual numerical population outputs, tagging biomass observations, BPT CPUE, recreational length compositions, the remaining composition observations, and numerical survey CVs are not included in this import. Assessment input and output completeness therefore remain partial. The annual population trajectories are shown graphically but are not tabulated as complete numerical series.

## Source files

The three cached PDFs and their URLs, retrieval dates, and SHA-256 checksums are listed in provenance/mpi_snapper_sna8_2024_sources.csv. The cache uses the official FAR 2024/49 assessment, FAR 2024/50 age-composition report, and the May 2025 SNA 8 Plenary.

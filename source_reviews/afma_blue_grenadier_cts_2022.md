# Blue Grenadier, Commonwealth Trawl Sector: 2022 assessment

## Assessment unit and run

AFMA manages Blue Grenadier in the Commonwealth Trawl Sector (CTS) as one stock, with spawning and non-spawning fisheries. The Great Australian Bight Trawl Sector is a separate stock unit and is not part of this assessment.

The 2022 technical paper describes an updated preliminary base case built with Stock Synthesis 3.30.19.01 and data through 2021. SERAG's November 2022 meeting records advice from the updated Tier 1 assessment and its three-year RBC. AFMA's 2026 species summary identifies 2022 as the last full Tier 1 assessment and describes the 2025 run as an update. The database therefore keeps the 2022 applied assessment as a separate historical record and retains the current 2025 update as the current record. The 2022 report is explicitly preliminary and the final native run files were not located, so the exact final model data and estimates beyond reported values remain uncertain.

## Sources and provenance

- [Tuck and Bessell-Browne, Blue Grenadier stock assessment based on data up to 2021](https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-blue-grenadier-2022.pdf), presented to SERAG 1 in October 2022.
- [SERAG Meeting 2, November 2022 minutes](https://www.afma.gov.au/sites/default/files/2023-06/SERAG-Nov-2022-minutes.pdf), Blue Grenadier agenda item and Attachment G.
- [AFMA, 2026 SESSF Species Summaries](https://www.afma.gov.au/sites/default/files/2026-01/SESSF-Species-Summaries-2026.pdf), which distinguishes the last full 2022 assessment from the 2025 update.
- [Tuck and Bessell-Browne, 2021 Blue Grenadier assessment](https://www.afma.gov.au/sites/default/files/2025-02/stock-assessment-for-blue-grenadier-2021.pdf), reviewed as the predecessor run but not used to fill 2022 inputs.

The 2022 report and meeting minutes are cached under the gitignored `source_cache/australia_afma_blue_grenadier_2025/` directory; the predecessor 2021 report is cached under `source_cache/afma_blue_grenadier_2021/`. Retrieval dates and SHA-256 checksums are recorded in `provenance/afma_blue_grenadier_cts_2022/manifest.csv`.

## Inputs and assumptions recovered

The report states that the assessment uses catches, non-spawning CPUE, discards, retained and discarded length compositions, conditional age-at-length data, age-reading error, acoustic biomass, and 1994/1995 female egg-survey biomass. The exact numeric catch, CPUE, discard, composition, egg-survey, and age-error series were not present in the reviewed production-run sources. Older 2021 values are not substituted for the 2022 run.

Table 2 reports spawning-ground acoustic biomass for 2003–2010, plus 2019–2021. The 2019 estimate is a sensitivity and is excluded from the tuned base case. The 2022 base case uses the 2003–2010 and 2020–2021 observations. The database stores the ten source-table biomass values, the assessment CVs, and the sampling CVs separately. The assessment applies a turnover multiplier of two to the spawning-ground observations, raises assessment CVs below 0.30 to 0.30, and estimates an extra variance component. The stored observations remain on the reported source scale, with the model treatment stated in the transformation field.

The report describes an age- and size-structured, two-sex Stock Synthesis model. It assumes unfished equilibrium at the start of 1960, an age-20 plus group, Beverton–Holt recruitment with fixed steepness 0.75, recruitment deviations from 1974–2018, sex-specific age- and time-invariant estimated M, and sex-specific von Bertalanffy growth with cohort deviations through 2018. There are two fleets: a spawning fleet in Zone 40 off western Tasmania during June–August and a non-spawning fleet in other months and areas. Selectivity is logistic for the spawning fleet and dome-shaped for the non-spawning fleet.

The report provides female and male length-weight coefficients, female maturity-at-length parameters, and the fraction of mature fish spawning. It does not provide numerical weight-at-age or maturity-at-age surfaces. The acoustic survey timing fraction within the year is not stated; annual observations are formulated by calendar year.

## Outputs recovered

The 2022 report reports unfished female spawning biomass of 35,680 tonnes, 2023 projected spawning biomass at 1.24 times B0, and estimated M of 0.239 per year for females and 0.246 per year for males. SERAG's Attachment G reports annual RBC recommendations of 20,168 tonnes for 2023, 17,182 tonnes for 2024, and 14,590 tonnes for 2025, including discards. No uncertainty intervals are reported for these values in the reviewed sources.

Annual recruitment, abundance-at-age, fishing mortality-at-age, natural mortality-at-age, and their uncertainty were not recoverable as numerical series. The source record is partial and the reported biological parameters do not supply the missing age-specific schedules.

## Separation from the current update

The 2025 record remains current and contains only the data and outputs reported for that update. No 2022 acoustic observations, assumptions, or output estimates were copied into the 2025 record. Likewise, the 2022 record does not use the updated 2025 acoustic series.

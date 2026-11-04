# NAFO cod in Divisions 3NO, 2021 assessment

## Assessment and sources

The latest detailed full production assessment located is the 2021 NAFO ADAPT assessment of cod in Divisions 3N and 3O. Catch and survey inputs extend through 2019, and population estimates extend through 2020. A 2022 state-space assessment is exploratory and is not a replacement production run. The 2025 report provides interim monitoring rather than a new detailed full assessment. No public fitted object or production ADAPT code was located.

The assessment and comparison sources are:

- NAFO SCR 2021/031, detailed assessment: <https://www.nafo.int/Portals/0/PDFs/sc/2021/scr21-031.pdf>
- NAFO SCR 2022/039, exploratory state-space assessment: <https://www.nafo.int/Portals/0/PDFs/sc/2022/scr22-039.pdf>
- NAFO SCS 2025/13, interim monitoring: <https://www.nafo.int/Portals/0/PDFs/sc/2025/scs25-13.pdf>

Cached source URLs, retrieval dates and SHA-256 checksums are in `provenance/nafo_cod_3no_2021/manifest.csv`. The cached PDFs and rendered source pages are local-only under the ignored `source_cache/` directory.

## Inputs and assumptions

Table 4 reports commercial catch numbers-at-age for ages 2–12 from 1959–2019 in thousands of fish. Table 5 reports catch weights-at-age for ages 3–12 over the same years in kg/fish. These scanned tables were digitized from the report; source values and year/age coverage are preserved.

Table 16 reports spring Canadian RV mean numbers per tow at ages 2–10 for 1984–2005 and 2007–2019. Table 17 reports autumn RV indices for ages 2–10 in 1990–2013 and 2015–2019. Table 18 reports the juvenile survey for ages 2–10 in 1989–1994. The three series remain separate. Their units are fish per tow. The report describes Engel-to-Campelen conversions for the pre-Campelen periods and Campelen observations thereafter. It gives seasonal survey dates; no single fraction-of-year sampling time is assigned.

The assessment uses catch-at-age and all three age-specific survey series. Catch-at-age was treated as exact, with no observation error. Survey residuals are log differences between the observed index and catchability times abundance, with equal weighting across ages, years and surveys. M was fixed at 0.2 per year. The assessment estimated age-specific catchabilities for ages 2–10 for each survey and survivor parameters at ages 3–12 in 2020 and age 12 in 1994–2019. It used no plus group and set F at age 12 to the average F for ages 6–9 in 1959–1993.

Table 19 reports annual female maturity ogives for ages 2–12 from 1959–2020 as proportions. The source describes cohort probit estimation and the extrapolation or averaging used when a cohort model did not fit. Table 23 gives beginning-of-year stock weights-at-age for ages 3–12 in kg/fish; these are distinct from the catch weights in Table 5. Natural mortality is fixed at 0.2 per year for ages 2–12.

## Outputs and completeness

Table 20 reports estimates and standard errors for survivor parameters and age-specific survey catchabilities. Survivor parameter estimates are stored separately from the bias-adjusted population numbers in Table 21. The report also gives relative errors and bias columns; the database stores the estimate, standard error and relative error, while those additional bias columns remain available in the source report. Table 20's survivor standard errors are not standard errors for the separate bias-adjusted N-at-age series.

Table 21 gives bias-adjusted population numbers-at-age for ages 2–12 and total abundance for 1959–2020, in thousands of fish. Table 22 gives fishing mortality at ages 2–12 and Fbar for ages 6–9 and 4–6 for 1959–2019, in year⁻¹. Table 24 reports biomass-at-age for ages 3–12 and total biomass for ages 3+ and 6+ for 1959–2020, in tonnes. Table 25 directly reports mature biomass-at-age and SSB for 1959–2020 in tonnes; the import preserves reported SSB rather than recalculating it from rounded components. The scanned table's age-specific mature biomass rows are checked against reported SSB within the rounding of the printed values.

The report does not tabulate uncertainty for the bias-adjusted population, fishing mortality, biomass-at-age or SSB series. The record is **partial** for outputs because those uncertainties are unavailable, even though their reported point estimates and the Table 20 survivor and catchability standard errors are included. Assumptions are **partial** because the report does not provide the production ADAPT code or fitted object. Inputs are marked **complete** for the streams specified by the assessment: catch-at-age, the three fitted survey series, fixed M, and the supporting weight and maturity series used for biomass calculations.

This is source curation only. No tinyAM settings, fits or comparison results are represented here.
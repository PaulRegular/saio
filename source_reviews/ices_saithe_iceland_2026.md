# Icelandic saithe 2026 (`pok.27.5a`)

Source review revision: 2026-10-23.

## Official assessment and inputs

The latest detailed production assessment is MFRI's 2026 assessment of saithe in ICES Division 5.a, Iceland grounds. It is an age-based SAM assessment. The assessment is marked current and applied for advice in 2026. The detailed MFRI tables and the ICES SAG XML provide the numerical inputs and reported outputs; no native SAM fit object was recovered.

- **Catch:** Table 5 reports commercial catch numbers-at-age for 1980–2025, ages 3–14+, in thousand fish. Age 14 is the plus group.
- **Stock weight:** Table 8 reports 1980–2026 values in grams per fish. The values are stored in the reported unit.
- **Maturity:** Table 9 reports proportions-at-age for 1980–2026.
- **Survey:** Table 10 reports the spring SMB abundance index by age for 1985–2026, ages 3–14+. The physical scale multiplier is not stated, so the values remain on the published index scale. The 28 blank age-year cells are retained as missing observations. The source identifies a March survey but not the exact SAM sampling fraction; the tinyAM translation uses 0.20 as a month-midpoint approximation.
- **Natural mortality:** M is fixed at 0.2 per year for all modeled ages.
- **Catch weights:** Table 6 is supplementary; the report does not identify it as an input to this assessment, so it is not treated as a fitted input.

The report identifies the F ages as 4–9 and describes default data weighting. It describes recruitment as a moving average of prior years. The 2025 ICES WKICEGAD benchmark report describes a piecewise-constant stock-recruitment function with no breakpoints in its benchmark configuration, and a random-walk F process with AR(1) correlation across ages. The exact 2026 production settings are not fully published, so those benchmark details are not assumed to be the exact 2026 configuration. The MFRI report describes a 1979 model start, while the recovered numerical tables begin in 1980; the imported series retain their published coverage.

## Outputs and unresolved definitions

MFRI Table 14 reports numbers-at-age for 1980–2026, and Table 15 reports fishing mortality-at-age for 1980–2025. ICES SAG key 22624 reports SSB, recruitment at age 3, age-4+ reference biomass, and FishingPressure. The first three series are available through 2026; FishingPressure is available through 2025. ICES SAG identifies its intervals as 95%. SSB and reference biomass are in tonnes; recruitment is in thousand fish. Age-specific uncertainty is not available.

MFRI Table 2 has distinct annual `F` and `HR` columns. Through 2025, `HR` agrees to rounding with the ICES SAG `FishingPressure` series, while Table 2 `F` does not. The Table 2 `F` column's age range and calculation are not defined in the recovered material; it is not relabeled as Fbar. The database retains the defined SAG FishingPressure series as Fbar for ages 4–9 and does not create a 2026 Fbar, because SAG leaves that year blank and the age-specific F table ends in 2025.

Reference biomass is specifically for ages 4+ and is not SSB. The 2026 population and biomass estimates extend one year beyond the last catch and age-specific F observations. The assessment's exact 2026 terminal configuration, observation covariance, and point-estimate timing are unresolved. Assumptions and outputs remain marked partial; the reported input series are recovered for their published coverage.

## Sources and cached files

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/3_pol_2026_1_techreport_en.html)
- [MFRI 2026 assessment tables](https://www.hafogvatn.is/static/extras/images/3_pol_2026_1_tables_en.html)
- [MFRI 2026 advice](https://www.hafogvatn.is/static/extras/images/3_pol_2026_1_advice_en.html)
- [ICES 2025 WKICEGAD benchmark report](https://doi.org/10.17895/ices.pub.28444499)
- [ICES SAG source data, stock key 22624](https://standardgraphs.ices.dk/ViewSourceData.aspx?key=22624)
- [ICES SAG XML source data](https://sag.ices.dk/SAG_API/StockXmlDownload/22624)

Cached source files are in the gitignored `source_cache/ices_saithe_iceland_2026/` directory. Its manifest records retrieval URLs, timestamps, sizes, and SHA-256 hashes. Values were imported by `scripts/database/129_import_ices_saithe_iceland_2026.R`.
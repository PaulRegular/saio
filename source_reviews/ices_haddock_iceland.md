# Icelandic haddock (ices_haddock_iceland)

## Icelandic haddock (had.27.5a)

### Assessment record

The 2025 benchmark is retained as a historical assessment record. The 2026 official assessment is now the current detailed record; see [the 2026 source review](ices_haddock_iceland.md). The two runs retain separate inputs and outputs.

The 2025 benchmark replaced the previous assessment framework with the state-space assessment model (SAM). The assessment uses catch numbers-at-age, catch weights, stock weights, maturity, spring and autumn survey indices-at-age, and estimated abundance and fishing mortality-at-age.

The assessment covers ages 1–12+, with age 12 as the plus group. Detailed catch and biological input tables end in 2024, while population estimates extend through 2025. The canonical database records 1979–2024 as the detailed fitted input period and retains the 2025 estimates separately.

The 2026 MFRI report confirms that the assessment continues to use the 2025 benchmark framework, fixes natural mortality at 0.2, and allows selectivity-at-age to vary over time.

The 2026 age-specific input and output matrices are documented separately in the 2026 source review. No 2026 values are substituted into this 2025 record.

### Inputs and assumptions

- **Catch:** Commercial catch-at-age is reported directly in thousands of fish, ages 1–12+.
- **Weights:** Catch weights come from commercial samples. Stock weights are derived from the March survey.
- **Maturity:** Maturity-at-age comes from the March survey. The source reports that pre-1985 stock-weight and maturity vectors use 1985 values.
- **Spring survey:** IS-SMB, March, 1985–2025.
- **Autumn survey:** IS-SMH, October, 1995–2024.
- **Survey units:** Official tables label indices as numbers but do not establish calibrated physical units. Values are retained on their native scales.
- **Survey timing:** The database records 0.20 for March and 0.80 for October, based on survey months. These are approximations, not verified native SAM sampling fractions.
- **Natural mortality:** Fixed at 0.2 per year for all ages.
- **Spawning timing:** The official assessment uses pre-spawning mortality fractions of 0.4 for F and 0.3 for M.
- **Outputs:** Summary tables provide recruitment, SSB and length-based reference biomass, with reported uncertainty. Age-specific output uncertainty was not recovered.

The 2025 record also includes total abundance derived by summing the reported
numbers-at-age across ages 1–11 and the 12+ group for each year, 1979–2025.
No uncertainty is calculated for this sum. The newer 2026 record remains
separate and has its own reported age-specific population series.

The official reference biomass represents fish measuring at least 45 cm and is distinct from total age-structured biomass.

### Sources reviewed

- [MFRI 2025 assessment tables](https://dt.hafogvatn.is/astand/2025/2_HAD_en.html)
- [MFRI 2025 technical report](https://www.hafogvatn.is/static/extras/images/02-had_2025_techreport_en.html)
- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/2_had_2026_1_techreport_en.html)
- [ICES WKICEGAD 2025 benchmark report](https://doi.org/10.17895/ices.pub.28444499.v1)

The numerical MFRI table exports used for the 2025 record are cached under the gitignored `source_cache/melanogrammus_aeglefinus/ices_haddock_iceland_2025/` directory. Their filenames and access notes are listed in that directory's README.

### Record summary

This historical record represents the 2025 benchmark SAM assessment for Icelandic haddock. The current detailed assessment is the separate 2026 run.

## Icelandic haddock 2026 (had.27.5a)

Source review revision: 2026-10-22.

### Assessment record

The 2026 official Icelandic haddock assessment is the current detailed database record. MFRI's 2026 technical report and associated tables provide the year's assessment inputs and selected fitted outputs. The 2025 benchmark remains a separate historical assessment and is not used to fill gaps in the 2026 record.

The assessment continues the 2025 WKICEGAD benchmark SAM framework. The report describes time-varying selectivity and fixed natural mortality of 0.2 per year. The public tables report ages 1-12, with age 12 representing the plus group. Catch and fishing mortality-at-age extend through 2025, spring survey and biological surfaces through 2026, and abundance and aggregate assessment summaries through 2026.

### Inputs and assumptions

- **Catch:** Commercial catch numbers-at-age are reported in thousands of fish for 1979-2025, ages 1-12+.
- **Catch weights:** Catch weights-at-age are in grams per fish. The table lists 4,000 g for every age in 2026, while no 2026 catch-at-age is reported. The row is excluded from the fitted catch-weight series; its role in the assessment projections is not specified. The canonical fitted input therefore ends in 2025.
- **Stock weights:** Stock weight-at-age is reported in grams per fish for 1979-2026. Pre-1985 values repeat the 1985 age vector.
- **Maturity:** Proportion mature at age is reported for 1979-2026. Pre-1985 values repeat the 1985 age vector.
- **IS-SMB:** March groundfish survey indices-at-age are reported for 1985-2026. The source labels them as numbers but does not specify a physical unit; values are retained on their native scale.
- **IS-SMH:** October groundfish survey indices-at-age are reported for 1995-2025. The source does not identify a physical unit and some older-age cells are blank; only published values are stored.
- **Natural mortality:** Fixed at 0.2 per year for ages 1-12.
- **Timing:** The source identifies the survey months but does not provide exact SAM sampling fractions. Recorded settings 0.20 for March and 0.80 for October are month-midpoint approximations.
- **SAM details:** The 2026 report describes the 2025 benchmark model as its basis, but the exact process covariance and parameter-sharing settings are not fully specified in the public tables.

### Recovered outputs and remaining gaps

The database records stock numbers-at-age in thousands for 1979-2026 and fishing mortality-at-age per year for 1979-2025. The assessment summary provides SSB, reference biomass, recruitment, landings, an annual `F` column and harvest rate. The point estimates and reported low/high values for SSB, reference biomass and recruitment are retained; the table does not specify the interval coverage, so these are not labeled as 95% intervals. Age-specific uncertainty and fitted observation predictions are not available in the recovered tables.

The annual summary's `F` column does not define an age range or averaging rule. It is therefore not imported as Fbar. The age-specific fishing mortality table is preserved separately. Native SSB uses pre-spawning mortality fractions of 0.4 for F and 0.3 for M.

Inputs, assumptions and outputs remain marked partial because the public material does not provide the complete SAM likelihood/covariance configuration, all age-specific uncertainty, or interval coverage for the summary ranges.

### Sources

- [MFRI Icelandic haddock assessment page](https://www.hafogvatn.is/en/harvesting-advice/haddock)
- [MFRI 2026 assessment tables](https://www.hafogvatn.is/static/extras/images/2_had_2026_1_tables_en.html)
- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/2_had_2026_1_techreport_en.html)
- [ICES WKICEGAD 2025 benchmark report](https://doi.org/10.17895/ices.pub.28444499.v1)

The official HTML tables, technical report and advice page were cached locally under `source_cache/melanogrammus_aeglefinus/ices_haddock_iceland_2026/`. The cache manifest records source URLs, retrieval date, file sizes and SHA-256 checksums.

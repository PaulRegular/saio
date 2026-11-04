# Icelandic haddock (had.27.5a)

## Assessment record

The 2025 benchmark is retained as a historical assessment record. The 2026 official assessment is now the current detailed record; see [the 2026 source review](ices_haddock_iceland_2026.md). The two runs retain separate inputs and outputs.

The 2025 benchmark replaced the previous assessment framework with the state-space assessment model (SAM). The assessment uses catch numbers-at-age, catch weights, stock weights, maturity, spring and autumn survey indices-at-age, and estimated abundance and fishing mortality-at-age.

The assessment covers ages 1–12+, with age 12 as the plus group. Detailed catch and biological input tables end in 2024, while population estimates extend through 2025. The canonical database records 1979–2024 as the detailed fitted input period and retains the 2025 estimates separately.

The 2026 MFRI report confirms that the assessment continues to use the 2025 benchmark framework, fixes natural mortality at 0.2, and allows selectivity-at-age to vary over time.

The 2026 age-specific input and output matrices are documented separately in the 2026 source review. No 2026 values are substituted into this 2025 record.

## Inputs and assumptions

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

## Sources reviewed

- [MFRI 2025 assessment tables](https://dt.hafogvatn.is/astand/2025/2_HAD_en.html)
- [MFRI 2025 technical report](https://www.hafogvatn.is/static/extras/images/02-had_2025_techreport_en.html)
- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/2_had_2026_1_techreport_en.html)
- [ICES WKICEGAD 2025 benchmark report](https://doi.org/10.17895/ices.pub.28444499.v1)

The numerical MFRI table exports used for the 2025 record are cached under the gitignored `source_cache/iceland_haddock_2025/` directory. Their filenames and access notes are listed in that directory's README.

## Record summary

This historical record represents the 2025 benchmark SAM assessment for Icelandic haddock. The current detailed assessment is the separate 2026 run.

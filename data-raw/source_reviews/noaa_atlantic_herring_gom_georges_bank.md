# NOAA Atlantic herring, Gulf of Maine and Georges Bank

SAIO stock `noaa_atlantic_herring_gom_georges_bank`. Assessment `noaa_atlantic_herring_gom_georges_bank_2026`.

## Stock and assessment

NOAA Stock SMART identifies Atlantic herring as stock 10572. The 2026 Management Track WHAM assessment is the latest assessment used for advice and includes data through 2025. The June 2026 peer review found it technically sufficient and identified it as the best available assessment for management. The model unit is the U.S. Gulf of Maine and Georges Bank stock complex; it includes Canadian catches but is not a one-to-one match to DFO 4VWX herring.

## Inputs and assumptions

The run archive provides fixed- and mobile-fleet catch-age proportions for ages 1–8+ in 1987–2025. These are proportions, not catch numbers-at-age. Matching fleet catch totals for the full model period were not recovered; report totals are available only for 2018–2025. Do not convert the proportions to numbers without the corresponding run-specific catch totals.

The model uses four NEFSC trawl series, a summer shrimp survey, and an acoustic survey. Their numeric index series and age compositions are not included in the archive tables. The acoustic series has no age composition in the assessment. The run archive plots age compositions and biological surfaces, but does not provide complete numeric survey, weight-at-age, or maturity-at-age arrays. Natural mortality is described as constant across ages and years, but its numeric value and exact within-year survey timings were not recovered. The 2025 Research Track values are not substituted for 2026 Management Track inputs.

## Outputs

WHAM Tables 2–5 report abundance-at-age and total, mobile-fleet, and fixed-fleet fishing mortality-at-age for ages 1–8+ in 1987–2025. Total F agrees with the sum of fleet-specific F to the tables' rounding precision. Table 1 of the 2026 report gives SSB, age-1 recruitment, and mobile-fleet Fbar ages 7–8 for 2018–2025. Recruitment is also available for 1987–2025 as age-1 abundance from Table 2, and mobile Fbar for 1987–2025 is the arithmetic mean of Table 4 ages 7 and 8; both derived series reproduce the reported Table 1 values over 2018–2025.

The WHAM parameter table reports catchability and other parameter estimates with the supplied standard errors and 95% confidence bounds; uncertainty is left blank where the source has no value. The 2026 report gives 2025 SSB as 35,258 mt, while the [ASMFC species page](https://asmfc.org/species/atlantic-herring/) shows 35,528 mt. This import follows the run-specific 2026 assessment report and retains the discrepancy as a source-version note rather than blending values.

## Screening and import status

The assessment is imported as partial and age-data eligibility remains unresolved. The import preserves the native fleet proportions and the reported N/F surfaces but does not invent missing fleet catch scaling, survey observations, biology, M, or timing. These gaps prevent a complete reconstruction of the model inputs.

## Source cache

The official run archive was retrieved on 2026-10-29. Its source files are kept under the ignored `source_cache/noaa_atlantic_herring_gom_georges_bank/noaa_atlantic_herring_gom_georges_bank_2026/` directory and are recorded with sizes, retrieval dates, and SHA-256 checksums in `data-raw/provenance/noaa_atlantic_herring_gom_georges_bank_2026/sources.csv`.

- [2026 Management Track archive](https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=21&stock_id=6&review_type_id=6&filename=2026_HER_UNIT.zip)
- [June 2026 Management Track peer review](https://www.fisheries.noaa.gov/s3/2026-07/june-2026-management-track-peer-review-panel-report_508_20260710.pdf)
- [ASMFC Atlantic herring page](https://asmfc.org/species/atlantic-herring/), retained as a cross-check for the SSB discrepancy.
- [2025 Research Track report](https://repository.library.noaa.gov/view/noaa/71350/noaa_71350_DS1.pdf), used only for assessment-development context.

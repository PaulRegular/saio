# Icelandic cod (`cod.27.5a`)

## Assessment represented

The canonical record `ices_cod_iceland_2026` represents the MFRI 2026 annual production assessment for cod in ICES Division 5.a (Iceland grounds). The stock identity is reconciled to the existing Charbonneau–Keith metadata row `ck_ices_nwwg_morhua_ice5a`. ICES lists this as stock `cod.27.5a`; the MFRI assessment uses MUPPET, not SAM.

The assessment and ICES NWWG chapter are the newest detailed production sources recovered for this record. The source tables are machine-readable arrays embedded in the official MFRI report page. No exact 2026 fitted object or production-run configuration files were recovered. The cached `Muppet_HCR` repository snapshot is pinned to commit `2a4ed80b6b12050ff7b152e748b96c3f5bc5b961`; it supplies historical framework context, not the 2026 fitted assessment.

## Sources and cache

The source files, retrieval dates, URLs, and SHA-256 hashes are in the ignored local cache manifest at `source_cache/ices_cod_iceland_2026/manifest.csv`.

- [MFRI 2026 technical report](https://www.hafogvatn.is/static/extras/images/1_cod_2026_1_techreport_en.html)
- [MFRI 2026 machine-readable tables](https://www.hafogvatn.is/static/extras/images/1_cod_2026_1_tables_en.html)
- [ICES NWWG 2026 report](https://doi.org/10.17895/ices.pub.32414577)
- [ICES stock annex (2021)](https://doi.org/10.17895/ices.pub.18622199); the direct document endpoint returned HTTP 401 during review.
- [MFRI 2021 HCR evaluation](https://www.hafogvatn.is/static/extras/images/technicalreporthcr_cod_2021.pdf)
- [Historical MUPPET HCR source, pinned revision](https://github.com/Hafro/Muppet_HCR/tree/2a4ed80b6b12050ff7b152e748b96c3f5bc5b961)

The 2025 MFRI report is cached as continuity context, not used as a source for 2026 values.

## Curated coverage

| Record | Coverage | Unit / treatment |
|---|---|---|
| Commercial catch-at-age | 1955–2025, ages 3–14 | Thousand fish; aggregated across 20 source métiers (two areas, two seasons, five gear classes) |
| March groundfish index (IS-SMB) | 1985–2026, ages 1–14 | Native index scale; exact index scaling is not stated in the embedded table |
| October groundfish index (IS-SMH) | 1996–2025, ages 1–14 in the published table; modeled ages 3–13 | Native index scale; the 2011 survey was not conducted, so blank age-3–13 cells remain absent and no values are imputed |
| Catch weights | 1955–2026, ages 1–14 | Grams per fish; 2026 entries are short-term projection values |
| Stock and spawning-stock weights | 1955–2026, ages 1–14 | Grams per fish; separate surfaces retained |
| Maturity | 1955–2026, ages 1–14 | Proportion mature |
| Fixed M | Time-invariant, ages 1–14 | 0.2 per year |
| Population numbers | 1955–2026, ages 1–14 | Thousand fish |
| Fishing mortality | 1955–2025, ages 1–14 | Per year |
| Summary outputs | 1955–2026 where reported | SSB, B4+, age-3 recruitment; Fbar and harvest rate through 2025 |

The 2021 MUPPET HCR framework uses age 14 as a terminal age without a plus group; the exact 2026 age-14 treatment was not separately recovered. The 2026 MFRI table page reports rounded values. The canonical records preserve those published values and do not reconstruct missing precision. `total_numbers` is derived by summing N-at-age over ages 3–14 for comparison on the tinyAM age grid. A separate `total_numbers_all_ages` series sums ages 1–14. Neither derived series has uncertainty.

## Assumptions and translation limits

The 2026 report describes MUPPET as a separable statistical catch-at-age model, with gradual temporal changes in F and correlated residuals for survey indices. M is fixed at 0.2 per year. The report identifies catch-at-age aggregated across 20 métiers and the October survey ages 3–13. The 2021 MUPPET configuration provides March and October sampling-time values of 0.2 and 0.8 and four selectivity periods. These historical settings are retained as translation assumptions with explicit notes; the exact 2026 production settings could not be verified.

The 2026 report text says pre-1985 stock weights and maturity were held constant at 1985 values, while its published machine-readable tables show varying pre-1985 values. The table series are preserved unchanged; the conflict remains unresolved. The report narrative gives 2026 SSB as 371,000 tonnes, whereas the machine-readable summary table reports 377,277 tonnes. The database keeps the table value and records the discrepancy. The table's high/low bounds are preserved without labeling their probability level.

Other unavailable details include the exact survey covariance matrices and likelihood weights, native parameter activation and sharing, production-run object, and age-specific uncertainty for N and F. Therefore assumptions, inputs, and outputs are all marked `partial` even though the recovered series cover the main observations, biology, and point estimates.

## Validation

The importer checks embedded table names, age columns, finite source values, expected row counts, and source dimensions before writing records. Blank source cells are omitted rather than filled. The source test checks the expected year-age coverage, units, provenance, table/report discrepancies, and absence of assessment records outside the selected source run. The associated tinyAM translation uses only ages 3–14; it cannot reproduce the source model's full survey covariance, selectivity blocks, or 2026 MUPPET population structure.

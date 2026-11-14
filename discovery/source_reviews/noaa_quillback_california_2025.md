# NOAA California Quillback Rockfish — 2025 assessment

## Stock and assessment

NOAA Stock SMART ID 15342 is the California Quillback Rockfish assessment
unit. It is separate from any Canadian Quillback stock. No matching
canonical California record was found; the register treats the unit as
provisionally new pending cross-inventory reconciliation.

The adopted 2025 assessment uses data through 2024 and has a native
Stock Synthesis 3.30.23.1 model bundle. The model spans 1916–2024, uses one
area and one sex, has 80 population age classes, and uses age-composition
bins 1–60.

## Evidence and limits

- The native data file contains total removals in metric tonnes for 1916-2024 and
  conditional age-at-length composition rows. Of 253 such rows, 128 positive-year
  rows from 2010-2024 are active; 125 negative-year rows are excluded from the
  likelihood. The reported age samples span 2007-2024, so the active rows and
  retained inactive rows remain distinct. These compositions are not direct
  catch-at-age observations. The model derives weight-at-age from its growth and
  length-weight relationship; `Report.sso` includes fitted biomass-at-age.
  Maturity is length-based and natural mortality is fixed at 0.068 per year.
- Survey index observations are recorded in July; spawning is in January. Preserve survey timing when converting observations to fractional-year
  values.
- `Report.sso` includes annual numbers-at-age, catch-at-age, biomass-at-age,
  and F-at-age. The report gives spawning output and recruitment estimates
  with uncertainty.

This unit is eligible for source curation because its official model archive
contains removals, index observations, compositions, and fitted age-specific
outputs. The report identifies biological and mortality assumptions. Catch-at-age
and age-specific survey indices are not direct observations and would require
additional documented inputs for reconstruction.

## Cross-check of the native archive

The archive's `natage.csv` matches the beginning-of-year population numbers-at-age in `Report.sso`; it is a fitted output, not a length-at-age growth input.
Of the 253 conditional age-composition rows in `2025_ca_quillback.dat`, 128 have positive year codes and 125 have negative year codes. The manual says negative-year rows are excluded from the likelihood. The positive rows support the report's description of conditional age-at-length data in the base fit; the inactive rows remain clearly identified.


- [Stock Synthesis 3.30 User Manual, composition-data rules](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html)

## Sources and local cache

The detailed report and native model archive were retrieved on 2026-10-29
and cached under `source_cache/discovery_noaa_quillback_ca_2025/`. The
ignored `sources.csv` manifest records source URLs, retrieval date, file
sizes, and SHA-256 checksums.

- [2025 California Quillback assessment report](https://www.pcouncil.org/documents/2026/01/status-of-quillback-rockfish-in-u-s-waters-off-california-in-2025.pdf/)
- [2025 California Quillback native model files](https://www.pcouncil.org/documents/ca-quillback-2025-model-files-zip-file/)
- [PFMC groundfish assessment document index](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)

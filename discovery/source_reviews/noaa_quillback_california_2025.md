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

- The model uses total removals in metric tonnes for 1916–2024. Fishery
  age-composition observations include commercial ages from 2007–2024. These compositions are not direct catch-at-age observations. The
  native data records July survey observations. The model derives weight-at-age from growth and its length-weight
  relationship; `Report.sso` includes biomass-at-age output. Maturity uses a
  length-based logistic relationship. Natural mortality is fixed at 0.068
  per year in the base model; the report identifies M and steepness as fixed
  at prior values and explores M in its uncertainty analysis.
- Survey index observations are recorded in July; spawning is in January. Preserve survey timing when converting observations to fractional-year
  values.
- `Report.sso` includes annual numbers-at-age, catch-at-age, biomass-at-age,
  and F-at-age. The report gives spawning output and recruitment estimates
  with uncertainty.

This is eligible for source curation because the official model files
provide age-composition inputs, biological data, and fitted age-specific
outputs. A would approximate the source likelihood;
catch-at-age and age-specific indices would be reconstructed rather than
directly observed.

## Sources and local cache

The detailed report and native model archive were retrieved on 2026-10-29
and cached under `source_cache/discovery_noaa_quillback_ca_2025/`. The
ignored `sources.csv` manifest records source URLs, retrieval date, file
sizes, and SHA-256 checksums.

- [2025 California Quillback assessment report](https://www.pcouncil.org/documents/2026/01/status-of-quillback-rockfish-in-u-s-waters-off-california-in-2025.pdf/)
- [2025 California Quillback native model files](https://www.pcouncil.org/documents/ca-quillback-2025-model-files-zip-file/)
- [PFMC groundfish assessment document index](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)

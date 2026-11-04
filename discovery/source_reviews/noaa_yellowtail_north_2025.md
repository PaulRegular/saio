# NOAA Northern Yellowtail Rockfish — 2025 assessment

## Stock and assessment

NOAA Stock SMART ID 10393 is the U.S. northern Yellowtail Rockfish unit,
north of 40°10′ N. It is not the DFO Canadian coastwide unit. No matching
canonical U.S. northern stock record was found; the candidate is provisional
until cross-inventory reconciliation is complete.

The 2025 benchmark assessment was adopted for management advice and uses data
through 2024. The report and native model bundle identify Stock Synthesis
3.30.23.1. It is a single-area, two-sex model with 40 population ages and
composition bins 1–30.

## Evidence and limits

- The model input has three fishery catch fleets (commercial, at-sea hake,
  recreational), with catch in biomass units reported in metric tonnes. The
  fit uses fishery age and length compositions. It does not use a direct
  annual catch-at-age observation series. Triennial age and length compositions and WCGBTS
  conditional age-at-length data are available. An age-specific abundance
  index is not directly observed and would require a clearly documented
  reconstruction from an aggregate index and age information.
- Sex-specific weight-at-age follows from the fitted growth curves and
  estimated sex-specific weight-at-length relationships. Female age-based
  maturity is estimated from 232 aged histological samples collected north
  of 40.167° N during 2016–2023. Natural mortality is estimated with a
  lognormal prior based on maximum age; the prior uses age 43, the 99.9th
  percentile of PacFIN age observations.
- The native input records July for the survey index observations and for
  Triennial/WCGBTS age data; spawning is in January. Preserve individual
  observation months when interpreting fractional-year timing.
- `Report.sso` includes annual numbers-at-age, catch-at-age, biomass-at-age,
  F-at-age, recruitment and spawning output. The report provides uncertainty
  for key population quantities.

This is eligible for source curation because the native assessment files
include observed age-composition data, age-specific biological information,
and fitted age-specific outputs.

## Sources and local cache

The detailed report and native model archive were retrieved on 2026-10-29
and cached under `source_cache/discovery_noaa_yellowtail_2025/`. The manifest
records URLs, retrieval date, sizes, and SHA-256 checksums.

- [2025 Northern Yellowtail Rockfish assessment report](https://www.pcouncil.org/documents/2026/01/status-of-the-yellowtail-rockfish-stock-off-the-u-s-west-coast-north-of-40-10-in-2025.pdf/)
- [2025 Yellowtail Rockfish model files](https://www.pcouncil.org/documents/yellowtail-rockfish-2025-model-files-zip-file/)
- [PFMC groundfish assessment document index](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [2025 Yellowtail STAR review summary](https://www.pcouncil.org/documents/2025/08/ssc-groudfish-subcommittee-2025-groundfish-stock-assessments-report-part-1.pdf/)

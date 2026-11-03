# NOAA Rougheye and Blackspotted Rockfish — 2025 assessment

## Stock and assessment

NOAA Stock SMART ID 14516 is the U.S. West Coast Rougheye/Blackspotted
management complex. The assessment treats Rougheye (*Sebastes aleutianus*)
and Blackspotted (*Sebastes melanostictus*) as one complex because they are
difficult to distinguish visually in catches. This is one assessment unit,
not two candidate stocks. No matching canonical record was found; the
register's new-unit classification remains provisional pending cross-source
reconciliation.

The adopted 2025 assessment uses data through 2024 and includes a native
Stock Synthesis bundle, which identifies version 3.30.23.2. The model uses
one area, two sexes, 140 population ages, and a January spawning month.

## Evidence and limits

- The six fishery fleets include retained and discard streams and use catch
  biomass in metric tonnes. Fishery conditional age-at-length (CAAL)
  observations enter the likelihood. Marginal age compositions are present
  for fit evaluation but are not a separate age-composition likelihood.
  These data do not provide a direct annual catch-at-age input; a tinyAM
  catch-at-age series would need to be reconstructed from catches, sampled
  ages, and weights, with fleet coverage gaps kept explicit.
- Four survey indices are included: Triennial, Alaska slope, Northwest slope,
  and WCGBTS. Survey age and length observations and their observation timing
  are documented in the report and native files. The native assessment does
  not directly fit an age-specific abundance index, so any such tinyAM input
  would be a documented reconstruction from aggregate survey indices and
  age compositions.
- The assessment derives weight-at-age from its growth and weight-at-length
  relationships and uses a length-based maturity relationship. Natural
  mortality is sex-specific: female M is estimated, while male M is fixed at
  0.036 per year following likelihood-profile analysis. The report explores
  additional M scenarios as a major uncertainty.
- The model data file retains survey observation months; preserve each series'
  recorded timing in any fractional-year conversion.
- `Report.sso` contains annual numbers-at-age, catch-at-age, biomass-at-age,
  F-at-age, and natural-mortality output. The report provides spawning
  output, recruitment, and management summaries with uncertainty.

This case is eligible for source curation because the official assessment
contains age-composition inputs, biological information, and fitted
age-specific outputs. A tinyAM translation would approximate the source
likelihood and must preserve the single combined complex rather than model
the two constituent species as two new assessment cases.

## Sources and local cache

The detailed report and native model archive were retrieved on 2026-10-29
and cached under `source_cache/discovery_noaa_rougheye_2025/`. Their URLs,
sizes, and SHA-256 checksums are in the ignored `sources.csv` manifest.

- [2025 Rougheye and Blackspotted Rockfish assessment report](https://www.pcouncil.org/documents/2026/01/status-of-rougheye-and-blackspotted-rockfishes-stock-off-the-u-s-west-coast-in-2025.pdf/)
- [2025 Rougheye/Blackspotted native model files](https://www.pcouncil.org/documents/rougheye-blackspotted-2025-model-files-zip-file/)
- [PFMC groundfish assessment document index](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)

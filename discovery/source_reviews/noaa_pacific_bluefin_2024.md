# Pacific bluefin tuna, Pacific-wide (`NOAA:11687`), 2024

## Assessment identity and current run

NOAA Stock SMART lists Pacific bluefin tuna (`Thunnus orientalis`, stock ID
11687) under PIFSC and records assessment 13484 as a fully accepted 2024 Stock
Synthesis 3.30 assessment, with data through 2023. The matching 2024 ISC
Pacific Bluefin Tuna Working Group benchmark report is the detailed public
source for that run. It models one pan-Pacific stock and uses fishing years
1983–2022; fishing year 2022 ends in June 2023. This candidate is distinct
from the western Atlantic bluefin unit and North Pacific albacore. No matching
canonical stock record was found.

## Inputs, assumptions, and outputs

The assessment is internally age structured, but the fitted observations are
not age-disaggregated. The production model uses quarterly retained and
discarded catches and size compositions where available, plus annual
standardized CPUE-based abundance indices from Japanese longline, Chinese
Taipei longline, and Japanese troll fleets. The 2024 report says the Japanese
longline adult index after 2020 and Japanese troll recruitment index after
2010 were excluded from the base case. The data-preparation workshop also
reviewed age-group-specific VAST indices but retained the longer aggregate
GLMM-South index; it noted that the VAST age groups were inconsistent with the
assessment growth curve. The report does not document observed catch-at-age or
age-specific abundance indices as base-case likelihood inputs.

The report's annual catch-at-age series is an estimated model output, computed
from growth, observed catch, and selectivity; it is not observed catch-at-age.
The assessment does provide age-related biological information: fixed
age-length-weight values, fixed mature proportions of 0 at ages 0–2, 0.2 at
age 3, 0.5 at age 4, and 1.0 at age 5 and older, and fixed natural mortality
of 1.6, 0.386, and 0.25 per year at ages 0, 1, and 2+, respectively. The
assessment reports spawning biomass, recruitment, age-specific fishing
mortality summaries, and estimated catch-at-age. The public ISC catalogue
states that the stock-assessment data files require a non-disclosure agreement;
the native input matrices and complete numerical output bundle were not
publicly available in the reviewed sources.

The assessment is therefore screened **ineligible** for the age-disaggregated
input set. A model's internal age structure and age-derived outputs do not
substitute for age-disaggregated observations. The public evidence supports
CPUE and length-based source review, but it does not support a faithful
age-based tinyAM input translation under the current eligibility rules. No
canonical stock, assessment event, or numerical input/output rows were added.

## Sources and local cache

- [ISC 2024 Pacific bluefin tuna stock assessment (Annex 13)](https://isc.fra.go.jp/pdf/ISC24/ISC24_ANNEX13-Pacific_Bluefin_Tuna_Stock_Assessment_in_2024-FINAL.pdf)
- [ISC 2024 PBFWG data-preparation workshop report (Annex 10)](https://isc.fra.go.jp/pdf/ISC24/ISC24_ANNEX10-Report_PBFWG_Workshop_February_29-March_8-April_11-12-FINAL.pdf)
- [ISC stock-assessment report catalogue](https://isc.fra.go.jp/reports/stock_assessments.html)
- NOAA Stock SMART metadata snapshot: assessment 13484, data through 2023, PIFSC, fully accepted.

The three public files are cached in the ignored local directory
`source_cache/discovery_noaa_pacific_bluefin_2024/`. The manifest records
their source URLs, retrieval date, and SHA-256 checksums.

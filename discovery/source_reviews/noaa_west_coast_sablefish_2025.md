# NOAA West Coast Sablefish — 2025 assessment

## Stock and assessment

NOAA Stock SMART ID 10466 is the U.S. West Coast Sablefish management unit.
It is separate from the Alaska and British Columbia units, despite sharing the
species name (*Anoplopoma fimbria*). The 2025 official assessment fits data
through 2024 and includes forecasts through 2036. The two-sex model tracks
ages 0-70; observed age-composition bins span 0-50, with age 50 as the terminal
accumulator.

The report states Stock Synthesis version 3.30.24. The bundled input echo and
`Report.sso` identify version 3.30.23.1, compiled December 5, 2024. The
assessment is identified by its 2025 run and source bundle; the version
discrepancy is retained rather than resolved by assumption.

## Recovered inputs and assumptions

The native data file contains 620 annual catch-biomass records in metric tons
across trawl, hook-and-line, and pot retained and discard fleets. The
accompanying `catch_se` is retained as the standard error of log catch. The
assessment does not provide direct catch numbers-at-age for every year.
Catch-at-age reconstruction would require explicit use of catch totals,
sampled age compositions, and weights; unsampled fleet-years must not be filled
from fitted states.

Four aggregate biomass indices are supplied: early and late Triennial surveys,
NWFSC Slope Survey, and WCGBTS. They comprise 35 records, use SS3 units code 1
and lognormal error, and retain native index scales. A further five observations
are a recruitment-deviation index (special units code 36, normal error), not an
abundance survey. Index months are July for the early Triennial, NWFSC Slope,
and WCGBTS series and August for the late Triennial series. Canonical timing
fractions use `(month - 1) / 12`, while preserving source month.

The native file has 57 length-composition rows and 273 age-composition rows.
Frequency values are retained exactly as supplied, without normalization.
Source sex, partition, effective sample size, age-error code, month, and signed
fleet code are retained. Negative fleet composition rows are retained but
excluded from the total likelihood. The age compositions describe samples;
they are not an age-specific abundance index.

`wtatage.ss` provides 980 rows for ages 0-30, sexes, and model fleets or roles:
mature weight, mid-season population weight, beginning-season weight, and
fleet-specific weights. It includes baseline year `-1890` and annual schedules
for 2003-2036; 2025-2036 are forecast inputs, and age 30 is the terminal group.
The mature-weight schedule is maturity multiplied by weight-at-age, not a
standalone maturity proportion. It is based on external spatial maturity
estimates; the report describes the coastwide schedule as biomass-weighted
using WCGBTS biomass. The spatial maturity curve differs between north and
south.

Natural mortality is estimated as a constant shared across ages and sexes.
`Report.sso` gives 0.087777 yr-1; its lognormal prior median is 0.072 yr-1 with
SD 0.31.

## Recovered outputs and limitations

The machine-readable report supplies fitted and forecast numbers-at-age,
fleet-specific fishing mortality-at-age, natural mortality-at-age, SSB, and
recruitment from 1890 through 2036. Total abundance is derived by summing
numbers-at-age across ages 0-70 and both sexes; no uncertainty is calculated
for this derived quantity. SSB and recruitment point estimates are retained
from the report table. Recent 95% intervals for SSB (2015-2025) and recruitment
(2015-2024) are transcribed from report Tables II-III. The report does not
provide age-specific uncertainty in these extracted surfaces.

The canonical record is partial: catch numbers-at-age and standalone maturity
proportions are unavailable, and the aggregate survey indices plus age
compositions are not a directly observed age-specific abundance series. Fitted
N/F/M surfaces are assessment outputs, not source observations. These limits
must remain explicit in any later.

## Sources and local cache

The report and native model archive were retrieved on 2026-10-29 and are cached
under `source_cache/discovery_noaa_sablefish_2025/`. Their URLs, sizes,
retrieval date, and SHA-256 checksums are recorded in the ignored `sources.csv`
manifest.

- [2025 West Coast Sablefish assessment report](https://www.pcouncil.org/documents/2026/02/status-of-the-sablefish-off-the-u-s-west-coast-in-2025.pdf/)
- [2025 West Coast Sablefish native model files](https://www.pcouncil.org/documents/sablefish-2025-model-files/)
- [PFMC groundfish assessment document index](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)

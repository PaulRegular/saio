# NOAA Vermilion rockfish (OR/WA), 2021 source curation

## Stock unit and assessments

The Pacific Fishery Management Council retains Vermilion rockfish (OR/WA) as
one managed stock unit. The accepted 2021 benchmark has separate Oregon and
Washington Stock Synthesis assessments. These component model outputs are
stored separately under one stock record; no estimates are pooled.

- Oregon Stock SMART ID 15338: [2021 assessment report](https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-oregon-coast-in-2021.pdf/) and [model archive](https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-or-zip-file/).
- Washington Stock SMART ID 15339: [2021 assessment report](https://www.pcouncil.org/documents/2021/10/status-of-vermilion-rockfish-sebastes-miniatus-along-the-us-west-washington-state-coast-in-2021.pdf/) and [model archive](https://www.pcouncil.org/documents/vermillion-rockfish-2021-model-files-wa-zip-file/).
- [2021 STAR panel report](https://www.pcouncil.org/documents/2021/10/vermilion-and-sunset-rockfishes-stock-assessment-review-star-panel-report.pdf/).
- The [Council's June 2025 meeting record](https://www.pcouncil.org/documents/2026/01/june-2025-meeting-record.pdf/) retains the OR/WA managed-stock label. The [February 2026 preliminary assessment recommendations](https://www.pcouncil.org/documents/2026/02/d-8-a-nmfs-report-1-preliminary-nmfs-recommendations-for-2027-groundfish-stock-assessments.pdf/) identify the 2021 benchmark as the latest completed assessment in the reviewed material.

The archived model files use Stock Synthesis 3.30.16.00. Both assessments cover
one annual area and two sexes, use data through 2020, and have machine-readable
Report.sso trajectories through 2022.

## Inputs retained

The canonical database contains one stock, two assessment records, 69,016 input
rows, and 21 model-assumption rows.

| Component | Catch records | Aggregate index records | Length frequencies | Conditional age frequencies |
|---|---:|---:|---:|---:|
| Oregon | 258 annual catches, 1892–2020 | 20 ORBS observations, 2001–2020, plus 20 native log-scale SD rows | 2,160 bin rows | 43,626 age-bin rows |
| Washington | 72 annual catches, 1949–2020 | None | 504 bin rows | 22,356 age-bin rows |

Catch retains each model's native scale: Oregon catch is biomass in metric
tonnes; Washington catch is numbers in thousands of fish. Length and age
frequency rows preserve the native frequencies, sex code, sample size,
partition, source month, age-error code, and conditional length interval.
Frequencies are not normalized. Composition data are not treated as annual
numbers-at-age.

The Oregon Recreational Boat Survey (ORBS) input is an aggregate index in fish
per angler-hour. The assessment describes a summer index based on May–September
trips; the model data encode month 7. The index values and log-scale standard
errors are preserved. A fractional-year time is not assigned because the
report does not specify one. ORBS age samples were not shown to match the
standardized index sample, so the index is not disaggregated by age.

Washington has no abundance index in the accepted model. Its report explains
that the nearshore survey was not used because the methods had not been reviewed
and the data were not considered sufficiently robust.

## Outputs retained

The canonical database contains 254,494 output rows across the separate
component assessments. These include fitted N-at-age, biomass-at-age,
F-at-age and M-at-age surfaces; derived total abundance; annual total biomass,
recruitment and spawning output; and generated biological surfaces from the
model archives.

Spawning output is reported in millions of eggs and is not spawning biomass
(SSB). Aggregate recruitment and spawning-output intervals reported for
2011–2021 are retained. Washington's spawning-output lower limits are reported
as less than 0.01; those values remain missing as numeric lower bounds. No
standard errors are derived from the intervals, and age-specific uncertainty
is not available.

## Source limitations and provenance

The reports and archives support verified source records, but the database
does not contain direct annual catch-at-age observations or age-specific
abundance indices. Reconstructing catch-at-age from composition samples would
require additional assumptions, especially outside sampled years, and has not
been done. Maturity is specified at length; generated maturity-fecundity
surfaces are not presented as maturity proportions. The report's longer
management forecasts exceed the short forecast range in the cached
machine-readable outputs.

Cached source PDFs, archives and extracted model files are listed with URLs,
retrieval dates, byte counts and SHA-256 checksums in
provenance/noaa_vermilion_rockfish_or_wa_2021/sources.csv. The source files
remain local under the ignored source_cache/ directory.


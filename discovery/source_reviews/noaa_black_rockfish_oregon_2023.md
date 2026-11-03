# Oregon black rockfish: 2023 assessment

## Stock and assessment

NOAA Stock SMART ID 14407 identifies the Oregon black rockfish unit
(*Sebastes melanops*). The 2023 official assessment is the current detailed
production assessment for this unit. Its Stock Synthesis reference model is
annual, covers 1892–2022, and forecasts through 2034. It has one area, two
sexes, and ages 0–40, with age 40 serving as the accumulator group.

The report describes spawning output at the start of 2023 as 674 billion eggs,
with a 95% asymptotic interval of 487–861 billion eggs. The `TIME_SERIES` value
in the cached model report is 674.102 for that year. The official table value
and interval are retained alongside the machine-readable point estimate.

## Recovered inputs and assumptions

The native data file contains 524 annual catch-biomass rows from 1892–2022 for
four fishery fleets. Catch is in metric tonnes. Its `catch_se` field is 0.01;
the fleet settings disable catch multipliers, so this is retained as a source
setting and is not represented as an independent catch-likelihood SD.

There are 78 aggregate index rows from 1981–2022 across six index fleets. The
series use the native Stock Synthesis index scale, with no physical multiplier
stated in the source file. Five use biomass units and one (Tag) uses numbers.
All use lognormal error type 0, and the supplied `se_log` values are retained
on the log scale. Source month is preserved; `sampling_time` is calculated as
`(month - 1) / 12`.

The native file also contains 179 length-composition rows for ages/lengths at
length-bin lower edges 10–64 cm and 1,816 age-composition rows for ages 0–40.
Raw frequency values, sex code, source fleet sign, sample size, partition,
age-error code, source month, and conditional length limits are preserved
without normalization. Ages are conditional on length where the source gives a
non-negative length interval; `-1/-1` denotes an unconditioned age sample. In
the source convention, negative fleet codes mark provisional compositions that
are evaluated for reporting but omitted from the total likelihood. Composition
samples are not age-specific abundance indices.

The assessment uses parametric growth and maturity rather than supplied
weight-at-age and maturity-at-age observation tables. `wtatage.ss_new` is a
model-generated output, not an input file used by this run. Its population and
fleet weight schedules and its maturity-times-fecundity series are retained as
model outputs; the latter is not a maturity proportion. Maturity is a
length-based logistic function and fecundity is modelled as eggs proportional
to length raised to a fitted power.

Natural mortality is estimated as one constant per sex. The report gives
female M = 0.19 and male M = 0.17 per year. The control file specifies a
standard Beverton–Holt spawner–recruit relationship and main recruitment
deviations for 1988–2017. The source model files retain other fleet, age-error,
growth, and selectivity settings.

## Recovered outputs and limitations

The model report supplies sex-specific numbers-at-age (thousand fish),
biomass-at-age (metric tonnes), natural mortality-at-age, fleet-specific
fishing mortality-at-age, and annual total biomass, age-0 recruitment, and
spawning output. Outputs are retained through the 2034 forecast horizon and
forecast years are identified in the row notes. Total abundance is derived by
summing reported beginning-of-year numbers over sexes and ages 0–40; no
uncertainty is assigned to that derived series. The report does not provide
age-specific uncertainty for the extracted surfaces. The 2023 spawning-output
interval is the only interval added from the report table in this import.

The canonical record is therefore partial. Catch-at-age and age-specific
survey-abundance indices are not direct source observations; age compositions
remain composition samples. The report's spawning-output measure is in eggs,
not spawning biomass in tonnes. Weight and maturity surfaces are model-derived,
not separately observed input tables. These differences must remain explicit
if a later is attempted.

## Sources and local cache

The official report and model-file archive are cached under
`source_cache/discovery_noaa_black_rockfish_2023/`. The ignored
`sources.csv` manifest records retrieval dates, URLs, file sizes, SHA-256
checksums, and the revision/archive identity.

- [2023 Oregon Black Rockfish assessment](https://www.pcouncil.org/documents/2024/02/status-of-black-rockfish-sebastes-melanops-in-2023-in-state-and-federal-waters-off-oregon.pdf/)
- [Official Oregon Stock Synthesis model files](https://www.pcouncil.org/documents/black-rockfish-or-2023-model-files-zip-file/)
- [PFMC groundfish assessment documents](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [Stock Synthesis 3.30 manual](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html)

No or model fit was attempted as part of this source import.

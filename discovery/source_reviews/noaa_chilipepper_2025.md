# U.S. Pacific Coast chilipepper rockfish: source review

## Current stock and assessment

The current assessment unit is the U.S. coastwide *Sebastes goodei* population from the U.S.-Mexico border to the U.S.-Canada border, covering California, Oregon and Washington. NOAA Stock SMART identifies this current unit as NOAA:17357. The legacy NOAA:10395 entry describes an earlier southern-area assessment; the 2025 report does not give a formal identifier crosswalk, so the exact relation remains unresolved and NOAA:10395 is not treated as a second current stock.

The 2025 production benchmark is the latest detailed assessment for NOAA:17357. It uses Stock Synthesis 3.30.23.1, one area, two sexes, ages 0-35+ and data through 2024. The report was published after the assessment year. The pinned native archive contains Chili_2025.dat, Chili_2025.ctl and Report.sso; its Report.sso forecast spawning output is 9,924.9 billion eggs for 2025, matching the report's rounded 9,925. The source files, URLs, retrieval date and checksums are recorded in provenance/discovery_noaa_chilipepper_2025/sources.csv. The source cache is local and gitignored.

## Inputs captured

Importer: scripts/database/641_import_noaa_chilipepper_2025.R. The import preserves native Stock Synthesis inputs and does not reconstruct fitted quantities as observations.

- 756 annual catch-biomass rows across eight fishery fleets, in metric tons, with a matching log-scale catch SD for each row. Seven -999 equilibrium sentinels are excluded.
- 146 aggregate index observations and their se_log values. Two are fishery CPUE series; the others are WCGBT, Triennial, CalCOFI spawning output and RREAS age-0 recruitment indices. Stock Synthesis units codes 1, 30 and 33 are retained in the unit descriptions. Twenty-two negative source years mark evaluation-only index rows; the canonical year is stored as its calendar-year magnitude and the signed source year is retained in observation_id and notes.
- 91,512 native conditional age-at-length frequency cells and 13,338 length-frequency cells. Ages are 0-35; length bins are 8-60 cm in 2-cm steps. The source sex codes, sample sizes, partitions, age-error definitions and age-composition length bounds are retained. Fifty-seven negative source-year length-composition rows are identified as evaluation-only.
- Three age-error definitions, each with its source age midpoints and SDs.

These data do not contain observed catch-at-age or an observed age-specific trawl index. Age samples are conditional on length. Model-estimated catch numbers-at-age are kept as outputs and are not presented as observed inputs.

## Assumptions and outputs captured

The importer records the main model dimensions, July sampling time (month 7, sampling_time = 0.5), index unit codes, composition structure, biological model and uncertainty limitations. Female natural mortality has a lognormal prior with median 5.4/Amax and log-scale SD 0.31; male M is estimated as an exponential offset without an explicit prior. Growth and weight-at-length are modelled, and the 2025 assessment reuses the 2015 female maturity-at-length relationship.

From Report.sso, the database contains annual 1875-2024 abundance-at-age, biomass-at-age, model-estimated catch numbers-at-age, fleet-specific F-at-age, M-at-age, Z-at-age, total and summary biomass, spawning output, recruitment, and a derived total-abundance series. Age 35 is retained as the plus group; M and Z have separate output ages 0-34. Total abundance is calculated by summing the reported numbers-at-age over both sexes and ages. The report's 2025 forecast spawning output and fraction-unfished values and 95% intervals are also captured from Table e.

## Remaining source gaps

No .par or CompReport.sso is included in the archive. Age-specific uncertainty and composition predictions therefore remain unavailable. The archived Report.sso contains fitted length-based biological output, but the current output schema does not represent those length-scale surfaces. The model control file is retained and its source assumptions are summarized, but its complete parameterization is not transcribed into individual database rows. Assessment completeness remains partial for inputs, assumptions and outputs to make these gaps clear.

# NOAA northern Yellowtail rockfish: source review

## Stock unit and assessment run

NOAA Stock SMART identifies stock 10393 as Yellowtail rockfish (*Sebastes flavidus*) in the Northern Pacific Coast region. The 2025 PFMC benchmark covers the U.S. portion north of 40°10′ N and is a separate management unit from the Canadian coastwide stock. The detailed assessment report and official Stock Synthesis archive identify a single-area, two-sex model with data through 2024. The native files identify Stock Synthesis 3.30.23.1. The report's `Report.sso` includes fitted historical output and forecasts through 2036.

Sources are cached locally under `source_cache/discovery_noaa_yellowtail_2025/`. The report and model archive URLs, retrieval dates and checksums are recorded in `sources.csv`; checksums for the extracted files used in the import are recorded in `provenance/noaa_yellowtail_rockfish_north_2025_sources.csv`.

## Native inputs

The native data file has three fishery fleets and four survey/index fleets. It contains 408 annual fishery catch rows from 1889–2024, in metric tonnes, plus three `year=-999` initialization placeholders that are excluded. The native `catch_se` values are retained separately without assigning an interpretation beyond the source field.

The four survey/index fleets have 54 aggregate observations from 1980–2024, all recorded in month 7. Their Stock Synthesis unit codes are 0 for the Oregon–Washington hook-and-line index (numbers), 1 for the Triennial and WCGBTS indices (biomass), and 33 for the SMURF recruitment index. The original values and `se_log` values are preserved without rescaling. Month 7 is represented as `sampling_time=0.5` using the database's month-start convention. These are aggregate index observations, not age-specific abundance indices.

The model also uses 178 length-composition records and 855 age-composition records from 1972–2024. Length-bin labels are 20–56 cm in 2 cm steps; age-composition bins are 1–30. The age data include marginal age frequencies and conditional age-at-length records. Native frequency cells, sample sizes, partitions, sex codes, age-error codes, length limits and signed fleet flags are retained without normalizing the source vectors. The data file specifies zero discard fleets and disables mean-body-weight observations. It does not supply direct catch-at-age observations.

The native age-error codes and composition fields are preserved. The full Stock Synthesis data and control files remain in the local cache because some likelihood configuration details are not represented as individual canonical observations.

## Assumptions and reported outputs

The model has one area, two sexes, population age bins 0–40, one annual season, three fishing fleets and four survey/index fleets. It uses sex-specific von Bertalanffy growth, age-based maturity, a standardized Beverton–Holt stock–recruitment relationship, fixed steepness 0.718 and fixed sigma-R 0.5. Early recruitment deviations begin in 1932; main deviations span 1962–2018. Natural mortality is estimated with a maximum-age-based lognormal prior; age 43 is identified as the 99.9th percentile of PacFIN ages, and male M is parameterized as an offset from female M. Survey catchability is estimated. The model's weight-at-age and maturity-at-age surfaces are biological outputs, not observations supplied in the data file.

The imported native outputs include annual numbers, biomass, spawning output, recruitment, catch-at-age, F-at-age, M-at-age and beginning-of-year weight-at-age. Age-specific surfaces span fitted years through 2024 and report forecasts through 2036. Total abundance is derived from reported numbers-at-age over ages 0–40 and both sexes; no uncertainty is assigned to that derived total. The report calls the reproductive metric spawning output and reports it in trillions of eggs, which is not biomass in tonnes.

The report publishes rounded 95% intervals for spawning output in 2015–2025 and recruitment in 2015–2024 (Tables ii and iii). Those bounds are stored as published. The source does not report uncertainty intervals for age-specific state or biological surfaces. Reported 2025 rows are forecast values, not fitted historical observations.

## Coverage and limits

The canonical source record is partial because catch-at-age and age-specific survey indices are not direct likelihood inputs, some control-file details remain in the cached native source rather than the canonical tables, and the report does not give uncertainty for age surfaces. These gaps are kept explicit; fitted states are not substituted for missing observations. The imported biological and mortality surfaces are kept separate from source observations.

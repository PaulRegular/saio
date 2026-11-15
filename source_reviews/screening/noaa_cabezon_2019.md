# Oregon cabezon — 2019 PFMC assessment

## Assessment and stock unit

The 2019 PFMC assessment is the latest detailed Oregon cabezon assessment located. Its Oregon (ORS) component is a single-area, sex- and age-structured Stock Synthesis model. The native input ends in 2018; the model output includes forecasts after that year. The native report identifies Stock Synthesis 3.30.13.00-safe.

The PFMC's September 2025 action removed the Oregon and California portions of cabezon from the federal Groundfish Fishery Management Plan. The Oregon assessment remains relevant as the March 2026 draft 2027–2028 harvest specifications cite the 2019 Oregon model for its OFL projection. This record represents the latest detailed assessment and documented use of the Oregon unit; it does not imply that Oregon cabezon remains in the federal FMP.

## Recovered inputs

The canonical database now contains the model's native catch biomass and observation-error fields: 196 annual rows for four fisheries, 1970–2018, in metric tons. The four `year = -999` equilibrium/sentinel records are not calendar-year observations and were not imported.

The native input contains 68 aggregate CPUE observations and 68 log-scale standard errors:

| Series | Rows | Years | Scale code |
|---|---:|---|---|
| Logbook | 15 | 2004–2018 | Biomass (1) |
| Onboard | 17 | 2002–2018 | Numbers (0) |
| ORBS | 18 | 2001–2018 | Numbers (0) |
| MRFSS | 18 | 1980–2000 | Numbers (0) |

All CPUE and composition records use month 7. The database preserves the source month and records sampling time as 0.5. The four indices are aggregate lognormal series, not age-specific abundance indices.

The input file also contains 129 length-composition records over 4–92 cm bins at 2 cm spacing and 597 age-composition records over ages 0–20 (20 is the plus group). Of the age records, 525 are conditional age-at-length samples and 72 are marginal frequencies marked evaluation-only by negative fleet codes. The import retains the native frequency cells, sample sizes, sex grouping, length bounds, partition, age-error codes, and signed fleet code in each observation identifier. It does not normalize or expand these sample frequencies into catch-at-age observations.

The fitted model has no observed catch-numbers-at-age input and no age-specific abundance index. Fitted catch-at-age is retained only in the outputs table.

## Biological and mortality assumptions

Sex-specific growth is estimated. Oregon length–weight relationships were estimated outside the assessment from ORBS biological records and PacFIN and then held fixed. The Oregon maturity ogive was estimated externally from biological samples and fixed; it is not supplied as a standalone maturity-at-age input vector. Fecundity is proportional to weight and fixed. The model-derived population weight-at-age surface is retained as an output and is cross-checked against biomass-at-age divided by numbers-at-age.

Natural mortality is fixed by sex: 0.24 year⁻¹ for females and approximately 0.28 year⁻¹ for males. The native `M_at_age` surface reports the male value as 0.279958 year⁻¹. Recruitment follows a Beverton–Holt relationship, with steepness fixed at 0.7 and recruitment CV fixed at 0.5. The full control file remains cached for the remaining selectivity and likelihood details.

## Recovered outputs and uncertainty

The native `Report.sso` provides historical 1970–2018 fitted surfaces for numbers-at-age, biomass-at-age, fleet-specific F-at-age, dead catch-at-age, and natural mortality at ages 0–19. Model-derived population weight-at-age is retained for ages 0–20. Annual spawning biomass/output, total biomass, and age-0 recruitment are also imported for 1970–2018. Total abundance is derived by summing the reported numbers-at-age across ages and sexes; its uncertainty is left blank because the joint covariance is not available.

Table ES7 provides 95% asymptotic confidence intervals for spawning output in 2007–2019. For 2007–2018, these intervals are attached to the corresponding higher-precision `Report.sso` point estimates. The table's 2019 assessment-year forecast is retained separately with scenario `assessment forecast` and the table values 177 metric tons (128–226). The executive-summary narrative rounds the lower limit to 129; the table value is retained and the discrepancy is recorded.

Age-specific standard errors or intervals for abundance, biomass, F, M, catch, or weight are not reported. The 2019 Table ES7 interval is the only annual state uncertainty imported from the reviewed sources.

## Source files and provenance

The assessment report, supplementary tables, STAR Panel report, and 2019 ORS, SCS, and NCS Stock Synthesis archives are cached under the ignored local `source_cache/discovery_noaa_cabezon_2019/` folder. The tracked checksums, URLs, sizes, and retrieval date are in `provenance/noaa_cabezon_oregon_2019_sources.csv`. The ORS archive supplied the inputs and `Report.sso`; the SCS and NCS archives were used to verify the assessment components and screen the separate California units.

- [2019 PFMC assessment and appendices](https://www.pcouncil.org/documents/2019/10/assessing-cabezon-scorpaenichthys-marmoratus-stocks-in-waters-off-of-california-and-oregon-with-catch-limit-estimation-for-washington-state-10-18-2019.pdf/)
- [2019 supplementary tables](https://www.pcouncil.org/documents/2019/10/cabezon-supplementary-tables-october-2019.xlsx/)
- [2019 STAR Panel report](https://www.pcouncil.org/documents/2019/10/cabezon-star-panel-report-may-6-10-2019.pdf/)
- [PFMC groundfish assessment archive](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [September 2025 PFMC meeting record](https://www.pcouncil.org/documents/september-2025-meeting-record/)
- [Draft 2027–2028 harvest specifications](https://www.pcouncil.org/documents/2025/10/f-3-attachment-1-draft-harvest-specifications-sections-of-the-pacific-coast-groundfish-fishery-2027-2028-harvest-specification-and-management-measures.pdf/)

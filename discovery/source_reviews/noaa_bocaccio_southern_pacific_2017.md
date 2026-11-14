# NOAA Stock SMART 10413: Southern Pacific Coast bocaccio, 2017 fitted assessment

Reviewed 2026-11-11. NOAA Stock SMART 10413 identifies Southern Pacific Coast bocaccio, *Sebastes paucispinis*. This is geographically distinct from British Columbia bocaccio and northern U.S. Pacific bocaccio units.

## Assessment selection and stock unit

The 2017 NOAA/PFMC update is the latest detailed fitted assessment located for the current Southern Pacific Coast unit. It covers the Conception, Monterey and Eureka INPFC areas, south of 43 degrees N to the U.S.-Mexico border, and uses data through 2016. The update carries forward the age information from the 2015 assessment. NOAA's 2025 document is a catch-only projection based on that fit, not a new population-model fit. The 2026 coastwide stock-definition proposal was not implemented at this review and does not replace the Southern Pacific Coast unit.

## Inputs and assumptions recovered

The native Stock Synthesis 3.24U archive provides one annual area, two sexes, age bins 0-21, six fishery catch series, and CPUE input covering 1892-2016. The six catch series are annual biomass in metric tons. The input declares catch-error settings of 0.01 by fleet; the file describes these as initialization/F-method settings, so they are recorded as assumptions rather than observation error.

The CPUE block contains 232 aggregate observations across 13 used series. Stock Synthesis unit code 0 denotes numbers, 1 biomass and 2 fishing mortality; only codes 0 and 1 occur in these observations. Log-scale errors and the model's within-year fleet timing are retained. No age-specific abundance index is present.

The native input contains 882 conditional age-at-length records and 314 length-composition records, with age bins 0-21 and length bins 10-76 cm at 2-cm increments. There are two sexes. Combined-sex records are retained as combined; records coded for both sexes are stored separately by sex. Source sample sizes, partitions, length bounds, age-error definitions, years, fleet codes and timing are preserved. These are composition data, not direct marginal catch-at-age observations. The 2017 update carries forward the 2015 age data; the assessment reports more than 8,000 fish aged, including nearly 3,000 from the NWFSC bottom-trawl survey.

Two age-error definitions are in the native input and are stored by true age. The model carries forward length-weight, maturity and fecundity relationships from 2015 while estimating growth. No standalone observed weight-at-age or maturity-at-age input schedule is supplied. Natural mortality is estimated with a lognormal prior and has no age, year or sex variation.

## Outputs recovered

The report's Table 18 provides annual summary biomass, spawning output, depletion, age-0 recruitment, total catch, SPR and relative exploitation rate. The import retains these values on the report's scales, with the source depletion percentage converted to an SSB-to-unfished-output proportion. Table 5 provides 2.5th and 97.5th percentile limits for spawning output, recruitment and depletion for 2007-2017; the point estimates match Table 18.

Table 18 labels its biomass series "Age 1+ biomass"; Table 5 labels the overlapping 2007-2017 series "Age 0+ biomass." The reported values match, but the captions differ, so the imported summary-biomass records retain the Table 18 label and carry a note about the discrepancy.

The cached model archive contains the data, control, forecast and starter files, but no fitted Report.sso, parameter file or uncertainty report. The assessment report does not provide numerical annual N-at-age or F-at-age tables. These surfaces, associated uncertainty, and independent age-specific biological schedules are not invented. The 2025 catch-only projection remains separate from the 2017 fitted assessment.

## Sources and cache

- [PFMC 2017 Bocaccio assessment update](https://www.pcouncil.org/documents/2017/02/stock-assessment-update-status-of-bocaccio-sebastes-paucispinnis-in-the-conception-monterey-and-eureka-inpfc-areas-for-2017.pdf)
- [PFMC 2017 Bocaccio model files](https://www.pcouncil.org/documents/2017-bocaccio-model-files-zip-file-47-kb/)
- [NOAA 2025 catch-only projection](https://www.pcouncil.org/documents/2025/08/g-3-attachment-18-catch-only-projection-for-bocaccio-in-2025.pdf/)
- [NOAA Bocaccio stock information](https://www.fisheries.noaa.gov/species/bocaccio)
- [NOAA Amendment 37 stock-definition action](https://www.fisheries.noaa.gov/action/amendment-37-pacific-coast-groundfish-fishery-management-plan-stock-definitions)

The detailed report, model archive and projection are cached in the local ignored cache at source_cache/discovery_noaa_bocaccio_southern_pacific_2017/. Their URLs, retrieval dates and SHA-256 values are recorded in provenance/discovery_noaa_bocaccio_southern_pacific_2017/sources.csv. The importer is scripts/database/642_import_noaa_bocaccio_southern_pacific_2017.R. Input and output completeness remain partial.

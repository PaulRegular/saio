# NOAA Pacific Coast Darkblotched Rockfish

## Stock and assessment

NOAA Stock SMART ID 10562 is the U.S. Pacific Coast unit of *Sebastes crameri*, covering Washington, Oregon and California. It is separate from Canadian waters occupied by the species.

The latest detailed full age-structured assessment located is the 2017 update of the 2015 model, using data through 2016 and Stock Synthesis 3.30.01.12. Later 2019 and 2025 activity is catch-only projection, not a newer fitted age-structured assessment. The accepted 2017 report and run-matched model archive are cached in the ignored source cache; tracked file provenance and checksums are in `provenance/discovery_noaa_darkblotched_2017/sources.csv`.

## Inputs captured

The native model file contains three annual catch-biomass fleets (metric tons) for 1915-2016, with native log-scale catch standard errors. Stock Synthesis `-999` sentinel rows are not calendar-year observations and are not entered as catches.

There are 31 aggregate biomass-index observations from four active bottom-trawl survey series, all in July and in metric tons: AFSC shelf (`AKSHLF`), AFSC slope (`AKSLP`), NWFSC slope (`NWSLP`) and NWFSC shelf-slope (`NWCBO`). The month-to-year conversion gives sampling time 0.5, consistent with the fleet table. **Correction to the earlier review:** the supplied model data contain 14 active NWCBO observations from 2003-2016; the earlier statement that those rows were commented out was incorrect. The assessment report describes all four surveys and their use in estimating abundance indices and generating age/length frequencies.

The source has 941 age-composition rows for 1980-2016 and 98 length-composition rows for 1977-2016. The model uses ages 0-35 for composition, population ages 0-45 (age 45 accumulator), and 30 length bins labelled 4-62 cm in 2-cm increments. Fishery marginal age frequencies and survey conditional age-at-length frequencies are stored as their supplied source frequencies; sample sizes, sex, partition, age-error code, conditional length bounds, and signed fleet identifiers are retained. Negative fleet-code rows are evaluation-only and do not enter the likelihood. Two age-reading SD definitions by true age (0-45) are also recorded.

The native control and assessment report describe sex-specific growth and weight-length relationships, female maturity and fecundity relationships, and mortality assumptions. A separate observed weight-at-age or maturity-at-age schedule is not provided. Catch-at-age and survey abundance-at-age are not direct observation inputs; they have not been reconstructed from composition data.

## Outputs captured and remaining gaps

`Report.sso` provides the historical 1915-2016 series and run-matched numbers-at-age, biomass-at-age, model-estimated catch numbers-at-age, M-at-age and Z-at-age. Total fishing mortality at age is derived as Z minus M. Total abundance is derived by summing N-at-age; spawning depletion is derived as `SpawnBio` divided by the virgin (`VIRG`) spawning-output baseline. These definitions and the distinction between model-estimated catch-at-age outputs and observed catch inputs are recorded in the database.

The 2016 report-matched checks are total biomass 19,431.1 mt, summary biomass 19,425.9 mt, spawning output 1,355.11 million eggs, age-0 recruitment 2,598.3 thousand fish and spawning-output ratio about 0.3823. The stored spawning-output series retains the native egg scale; the report presents it in million eggs. The report also identifies the 2017 projection separately; it is not mixed into the 2016 terminal historical fit.

The archive contains `Report.sso` but no `.par` or `CompReport.sso`. Age-specific uncertainty, standard errors and composition predictions are therefore unavailable in the database. Inputs, assumptions and outputs remain marked partial. The model is suitable for source comparison, but the absent direct catch-at-age, age-specific index, standalone observed weight/maturity schedules and uncertainty remain explicit limitations.

## References

- [2017 Darkblotched Rockfish assessment update](https://www.pcouncil.org/documents/2018/01/status-of-the-darkblotched-rockfish-resource-off-the-continental-u-s-pacific-coast-in-2017-update-of-2015-assessment-model.pdf/)
- [PFMC Groundfish assessment and model-file archive](https://www.pcouncil.org/stock-assessments-star-reports-stat-reports-rebuilding-analyses-terms-of-reference/groundfish-stock-assessment-documents/)
- [2019 catch update](https://www.pcouncil.org/documents/2019/09/agenda-item-h-5-attachment-20.pdf/)
- [2025 Groundfish SAFE status report](https://www.pcouncil.org/documents/2025/08/ssc-groundfish-subcommittee-2025-groundfish-stock-assessment-report-2.pdf/)

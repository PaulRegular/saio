# NOAA California copper rockfish, 2023

## Assessment unit and source set

Stock SMART IDs 15332 and 15333 identify the north and south California model
areas used in one 2023 assessment family. The candidate register therefore
counts this as one stock, while the source records retain separate model areas.
The assessment uses Stock Synthesis 3.30.21 and data through 2022; the report
also gives 2023 spawning-output estimates. Washington (ID 15330) and Oregon
(ID 15331) are separate assessment areas and are not included here.

The source set includes both area reports, both native model archives, the
STAR review, and the pre-assessment workshop report. URLs, retrieval dates,
archive revisions, sizes, and SHA-256 checksums are recorded in
provenance/discovery_noaa_copper_california_2023/sources.csv. Downloaded
files and extracted model directories are in the ignored local source cache.

## Inputs retained

The north model contains 327 annual fishery catch-biomass rows and the south
model 326. The reports describe catches in metric tons. Each area has four
fishery fleets. The source catch-error setting (0.01) is recorded as a model
setting, not as an observation standard error.

The north and south models contain 76 and 77 aggregate biomass-index
observations, respectively. The source identifies these as biomass indices
with lognormal error type 0. Original values and log-scale standard errors are
retained. Index months are preserved; the stored within-year timing is
(month - 1) / 12.

The source has 219 north and 185 south length-composition rows, plus 489 north
and 771 south age-composition rows. The age rows include 450 north and 747 south
conditional age-at-length records; the remainder are marginal age
compositions. Frequencies are kept on their original scales with sample sizes,
sex codes, age-error codes, partitions, and source observation identity.
Frequencies are not converted to catch-at-age or age-specific abundance.
Lbin_method=3 means the conditional length bounds are in centimetres. Source
age labels cover 0–50, with age 50 serving as the accumulator group.

Natural mortality is fixed at 0.108 per year for both sexes. The models use
sex-specific growth and length-weight relationships and length-logistic
maturity. The reports and native files do not provide standalone observed
weight-at-age or maturity-at-age matrices; age-specific biology is
model-derived. Recruitment follows Beverton-Holt with steepness fixed at 0.72;
the recruitment-deviation start year is 1970 in the north model and 1965 in the
south model.

## Outputs retained

Native fitted outputs include beginning-of-year N-at-age and biomass-at-age,
fishing mortality by fishery fleet and sex, and fitted dead catch-at-age for
ages 0–50 through 2022. Fitted catch-at-age is a model output, not an observed
catch-at-age input. Total abundance is derived by summing N-at-age over ages
and sexes; recruitment and spawning output are retained from model time series.
The official reports express spawning output in billions of eggs and provide
95% intervals for 2013–2023. Age-specific N, biomass, F, catch, and derived
total abundance have no reported uncertainty.

The north and south outputs remain separate. There is no single combined
California N-at-age or F-at-age surface in the source model.

## Completeness and gaps

Inputs and outputs are marked partial. The assessment has aggregate catch and
survey inputs and rich composition samples, but not observed annual
catch-at-age numbers or a direct age-specific survey abundance series.
Empirical age-specific weight and maturity matrices are not supplied, and
uncertainty is unavailable for age-specific population and mortality outputs.
The archived control files retain likelihood and age-error settings not
expanded into separate canonical records.

## Sources

- [2023 North California assessment](https://www.pcouncil.org/documents/2024/03/status-of-copper-rockfish-along-the-u-s-california-coast-north-of-point-conception-in-2023.pdf/)
- [2023 North California Stock Synthesis archive](https://www.pcouncil.org/documents/ca-copper-rockfish-north-2023-model-files-zip-file/)
- [2023 South California assessment](https://www.pcouncil.org/documents/2024/02/status-of-copper-rockfish-sebastes-caurinus-along-the-u-s-california-coast-south-of-point-conception-in-2023-november-2023.pdf/)
- [2023 South California Stock Synthesis archive](https://www.pcouncil.org/documents/ca-copper-rockfish-south-2023-model-files-2023-zip-file/)
- [2023 Copper/Rex Sole/Shortspine STAR panel report](https://www.pcouncil.org/documents/2023/06/star-panel-1-report-for-copper-rockfish-in-ca-rex-sole-and-shortspine-thornyhead.pdf/)
- [2023 pre-assessment workshop report](https://www.pcouncil.org/documents/report-of-the-pre-assessment-workshop-for-2023-groundfish-stock-assessments-of-copper-rockfish-canary-rockfish-and-black-rockfish/)

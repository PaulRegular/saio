# NOAA California copper rockfish, 2023

## Assessment unit and run

Stock SMART IDs 15332 and 15333 describe the north and south sub-area models
used in the 2023 California copper rockfish assessment. The candidate register
links these model areas to one California assessment family so they are not
counted as two new stocks. Their observations and fitted outputs remain
area-specific. The official documents describe the California population as
reassessed with north and south models; Washington (ID 15330) and Oregon (ID
15331) are separate assessment areas last assessed in 2021 and are outside this
screen.

The 2023 models use data through 2022, cover model years 1916–2022 and ages
0–50, and represent females and males separately. The Pacific Fishery
Management Council's STAR review describes two California sub-area models and
identifies the fitted data as catch, indices, length compositions, and age
compositions. The model archive contains native Stock Synthesis inputs, control
files, starters and fitted reports for both areas. The 2023 production source
files and checksums are recorded in the ignored local cache at
`source_cache/discovery_noaa_copper_california_2023/sources.csv`.

## Inputs and outputs

The north model has four fishery catch fleets and five survey or biological
fleets; the south model has four fishery catch fleets and six survey or
biological fleets. Catch is entered as biomass. The active native age-composition
blocks contain 489 rows for the north model (450 conditional age-at-length rows
and 39 marginal-age rows) and 771 rows for the south model (747 conditional
age-at-length rows and 24 marginal-age rows). Conditional observations span
2001–2022 in the north model and
2004–2022 in the south model. Marginal-age observations span 1978–2022 in the
north model and 1975–2022 in the south model. These are observed composition
records in the fitted data, not annual catch numbers-at-age.

The assessments also use aggregate indices and length compositions. They do not
provide direct annual survey abundance-at-age input series. the transformation must retain the composition's source and
sampling basis. Do not label reconstructed quantities as directly observed
age-specific indices or catch.

The Stock Synthesis control and report files specify fixed natural mortality of
0.108 per year for both model sexes. The models use sex-specific growth and
length-weight relationships and a length-logistic maturity relationship, from
which age-specific biological surfaces are derived. They have one 12-month
season and January spawning. Survey timing is coded by month in the native
fleet table: month 7 in the north model and months 7 and 9 in the south model.
The timing codes should not be converted to a fractional-year value without a
documented convention.

Both fitted reports include age-specific catch, numbers, fishing mortality and
biomass outputs through 2022, as well as aggregate spawning output and
recruitment. The north and south model surfaces must remain separate in later
source extraction and comparisons. No canonical database stock, assessment,
input or output rows were added in this screening step.

## Screening decision

Screen this as one new eligible California assessment family for source
curation. Their reconstruction is
supportable from native model inputs but must be documented and kept distinct
from observed quantities. This is stronger age evidence than the single
survey-year age-length key available for Pacific Coast spiny dogfish, but it
still requires more care than a model with direct annual catch-at-age and
age-specific indices.

The source check in
`scripts/database/476_screen_noaa_copper_california_2023.R` verifies the source
manifest, model periods, age bins, age-composition row structure and coverage,
fixed mortality settings and reported population-at-age surfaces.

## Sources

- [2023 North California assessment](https://www.pcouncil.org/documents/2024/03/status-of-copper-rockfish-along-the-u-s-california-coast-north-of-point-conception-in-2023.pdf/)
- [2023 North California Stock Synthesis files](https://www.pcouncil.org/documents/ca-copper-rockfish-north-2023-model-files-zip-file/)
- [2023 South California assessment](https://www.pcouncil.org/documents/2024/02/status-of-copper-rockfish-sebastes-caurinus-along-the-u-s-california-coast-south-of-point-conception-in-2023-november-2023.pdf/)
- [2023 South California Stock Synthesis files](https://www.pcouncil.org/documents/ca-copper-rockfish-south-2023-model-files-zip-file/)
- [2023 Copper/Rex Sole/Shortspine STAR panel report](https://www.pcouncil.org/documents/2023/06/star-panel-1-report-for-copper-rockfish-in-ca-rex-sole-and-shortspine-thornyhead.pdf/)
- [2023 copper rockfish preassessment workshop report](https://www.pcouncil.org/documents/report-of-the-pre-assessment-workshop-for-2023-groundfish-stock-assessments-of-copper-rockfish-canary-rockfish-and-black-rockfish/)

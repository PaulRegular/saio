# California black rockfish, 2023 assessment

## Assessment and stock unit

The 2023 California assessment is the current production assessment for
California black rockfish (*Sebastes melanops*). NOAA Stock SMART records
17194 and 17195 are grouped as one California stock unit. Their area labels do
not map one-to-one to the model boundary. The assessment represents the stock
with separate North and Central sub-area models divided at Point Arena; their
observations, biology, and model outputs remain separate in SAIO.

The reference-model archive fits through 2022 and reports forecasts through
2024. It contains two Stock Synthesis 3.30.21.00 components, each with one
area, one season, two sexes, and ages 0-50 (age 50 is the 50+ accumulator).
The full assessment report and the post-STAR executive summary retain
provisional front matter. The NOAA peer-review record and STAR panel report
provide assessment provenance, but the final assessment link cited by NOAA
could not be recovered. This publication caveat is retained rather than
treated as a source-data discrepancy.

## Inputs recovered

The native files contain 695 North and 646 Central annual catch-biomass
observations through 2022. The one \`-999\` initialization row in each model is
not an observation and is excluded. Catch units are metric tonnes; the source
catch multipliers are disabled.

The models contain 82 North and 144 Central aggregate CPUE observations.
Commercial indices use SS3 units code 1 (biomass scale); survey indices use
code 0 (numbers scale). The physical multipliers are not stated, so values
remain on their native relative scales. Error type 0 is lognormal and the
source \`se_log\` values are preserved separately. Observations are from July,
recorded at \`sampling_time = 0.5\`. Negative signed fleet identifiers are
preserved in row notes because they mark observations excluded from the total
likelihood.

The import retains 201 North and 185 Central raw length-composition rows and
324 North and 208 Central raw age-composition rows. Length bins are the native
2-cm labels from 8 to 60 cm. Age frequencies cover ages 0-50, with 50 as the
accumulator. Sample sizes, partitions, ageing-error codes, sex codes, signed
fleet IDs, and conditional length intervals are retained. Sex code 0 uses the
combined distribution in the source female vector; sex code 3 supplies a
joint female/male composition and both vectors are preserved. Negative source
fleet or year signs are identified in notes because those rows are not part of
the total likelihood.

These composition samples are not catch numbers-at-age or age-specific
abundance indices. The native files provide no direct observed catch-at-age
matrix or age-specific survey-abundance series. Growth, maturity, and
fecundity are parameterized in the control files; no standalone observed
weight-at-age or maturity-at-age input vector was found. Generated
component-specific weight and maturity-fecundity surfaces are retained as
model outputs, not relabelled as original observations.

## Outputs and source differences

The reference archive provides sex-specific N-at-age and biomass-at-age for
1875-2024, fleet-specific F-at-age for 1875-2024, and M-at-age for 1875-2023.
The database retains age 50 as a 50+ accumulator for N, biomass, and F; the
source M table has values only for ages 0-49. The archived time series also
provides total biomass, age-0 recruitment, and spawning output. Total
abundance by sub-area is derived by summing N-at-age over ages and sexes; no
uncertainty is assigned to that sum. Forecast years 2023-2024 are identified
in the row notes.

The published post-STAR summary reports 2023 spawning output of 410 billion
eggs for North (95% asymptotic interval 175-645) and 145 billion eggs for
Central (interval 36-253). Its statewide Table ES5 reports 555 billion eggs.
These are kept as separate \`official_document\` output rows. The archived
model's North 2023 value is 410.223 billion eggs, while its Central value is
136.324 billion eggs; the archive's Central 2024 value is 136.304. Thus the
archive's Central 2023 output does not match the published table value. Both
are retained with distinct source types and scenarios; no value is substituted
or adjusted.

Natural mortality is constant by age and year in both components. The North
control file estimates sex-specific M parameters; its report gives 0.210260
for females and 0.199847 for males. The Central control file fixes its
sex-specific values; its report gives 0.210260 for females and 0.199846 for
males. Age-specific uncertainty was not available in the imported tables.
Published uncertainty is available only for the 2023 spawning-output table
values described above.

## Sources

- [2023 California black rockfish assessment report](https://www.pcouncil.org/documents/g-2-situation-summary-adopt-stock-assessments/g-2-attachment-8-draft-executive-summary-of-status-of-black-rockfish-sebastes-melanops-in-u-s-waters-off-california-in-2023/)
- [Post-STAR executive summary](https://www.pcouncil.org/documents/2023/08/black-rockfish-in-california-stock-stock-assessment-executive-summary-post-star-panel.pdf/)
- [2023 California native model archive](https://www.pcouncil.org/documents/black-rockfish-ca-2023-model-files-zip/)
- [2023 Black Rockfish STAR panel report](https://www.pcouncil.org/documents/2023/11/stock-assessment-review-star-panel-report-for-black-rockfish.pdf/)
- [NOAA peer-review record](https://www.noaa.gov/information-technology/stock-assessment-review-panel-review-of-2023-stock-assessments-for-black-rockfish-off-washington)
- [Stock Synthesis 3.30 user manual](https://nmfs-ost.github.io/ss3-doc/SS330_User_Manual_release.html)

The retrieved files, revisions, retrieval date, byte sizes, and SHA-256 checksums
are listed in \`provenance/noaa_black_rockfish_california_2023_sources.csv\`.
